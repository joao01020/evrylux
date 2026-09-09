import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'update_manifest.dart';
import 'update_manifest_service.dart';

enum UpdateDownloadPhase {
  idle,
  downloading,
  verifying,
  ready,
  cancelled,
  failed,
}

class UpdateDownloadCancelled implements Exception {
  const UpdateDownloadCancelled();
  @override
  String toString() => 'Download cancelado.';
}

class UpdateDownloadProgress {
  const UpdateDownloadProgress(this.received, this.total);
  final int received;
  final int total;
  double get fraction => total == 0 ? 0 : received / total;
}

class UpdateDownloadResult {
  const UpdateDownloadResult({
    required this.file,
    required this.asset,
    required this.version,
  });
  final File file;
  final UpdateAsset asset;
  final String version;
}

/// Abstração pequena para testes sem desativar a verificação TLS.
abstract class UpdateDownloadTransport {
  Future<UpdateDownloadResponse> open(Uri uri);
  void close();
}

class UpdateDownloadResponse {
  const UpdateDownloadResponse({
    required this.statusCode,
    required this.contentLength,
    required this.stream,
  });
  final int statusCode;
  final int contentLength;
  final Stream<List<int>> stream;
}

class SecureUpdateTransport implements UpdateDownloadTransport {
  SecureUpdateTransport() {
    _client.connectionTimeout = const Duration(seconds: 15);
    _client.idleTimeout = const Duration(seconds: 15);
  }

  final HttpClient _client = HttpClient();

  @override
  Future<UpdateDownloadResponse> open(Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.fragment.isNotEmpty) {
      throw const FormatException('URL de download não permitida.');
    }
    final request = await _client.getUrl(uri);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    final response = await request.close();
    return UpdateDownloadResponse(
      statusCode: response.statusCode,
      contentLength: response.contentLength,
      stream: response,
    );
  }

  @override
  void close() => _client.close(force: true);
}

/// Um job por download. O fechamento da janela não cancela o job.
class UpdateDownloadJob {
  UpdateDownloadJob({
    required this.manifestService,
    UpdateDownloadTransport? transport,
    Future<Directory> Function()? stagingDirectory,
  }) : _transport = transport ?? SecureUpdateTransport(),
       _stagingDirectory = stagingDirectory ?? _defaultStagingDirectory;

  final UpdateManifestService manifestService;
  final UpdateDownloadTransport _transport;
  final Future<Directory> Function() _stagingDirectory;

  bool _cancelled = false;
  bool _started = false;

  void cancel() {
    _cancelled = true;
    _transport.close();
  }

  void _checkCancelled() {
    if (_cancelled) throw const UpdateDownloadCancelled();
  }

  static Future<Directory> _defaultStagingDirectory() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/evrylux-updater/staging');
  }

  Future<UpdateDownloadResult> download({
    required UpdateAsset asset,
    required String version,
    required void Function(UpdateDownloadProgress) onProgress,
    void Function(UpdateDownloadPhase)? onPhase,
  }) async {
    if (_started) throw StateError('Este download já foi iniciado.');
    _started = true;
    if (asset.size > 4 * 1024 * 1024 * 1024) {
      throw const FormatException('Pacote excede o limite de 4 GiB.');
    }

    Directory? workingDirectory;
    IOSink? output;
    var outputClosed = false;

    try {
      _checkCancelled();
      final root = await _stagingDirectory();
      await root.create(recursive: true);
      _checkCancelled();
      workingDirectory = await root.createTemp('release-');

      onPhase?.call(UpdateDownloadPhase.downloading);
      final response = await _transport.open(asset.url);
      _checkCancelled();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Servidor retornou HTTP ${response.statusCode}.');
      }

      if (response.contentLength > asset.size) {
        throw const FormatException('Pacote maior que o esperado.');
      }

      final partial = File('${workingDirectory.path}/package.part');
      output = partial.openWrite(mode: FileMode.write);
      var received = 0;
      onProgress(UpdateDownloadProgress(0, asset.size));

      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 60),
      )) {
        _checkCancelled();
        received += chunk.length;
        if (received > asset.size) {
          throw const FormatException('Pacote maior que o esperado.');
        }
        output.add(chunk);
        onProgress(UpdateDownloadProgress(received, asset.size));
      }

      _checkCancelled();
      await output.flush();
      await output.close();
      outputClosed = true;

      if (received != asset.size) {
        throw const FormatException('Download incompleto.');
      }

      onPhase?.call(UpdateDownloadPhase.verifying);
      await manifestService.verifyDownloadedFile(file: partial, asset: asset);
      _checkCancelled();

      final verified = File('${workingDirectory.path}/package.verified');
      await partial.rename(verified.path);
      _checkCancelled();

      onPhase?.call(UpdateDownloadPhase.ready);
      return UpdateDownloadResult(
        file: verified,
        asset: asset,
        version: version,
      );
    } catch (_) {
      // Não remove arquivos de outras versões nem dados do usuário.
      if (workingDirectory != null) {
        try {
          if (!outputClosed) await output?.close();
        } catch (_) {
          // Continua a limpeza mesmo se o sink falhar.
        }
        try {
          if (await workingDirectory.exists()) {
            await workingDirectory.delete(recursive: true);
          }
        } catch (_) {
          // O erro original é preservado.
        }
      }
      if (_cancelled) throw const UpdateDownloadCancelled();
      rethrow;
    } finally {
      _transport.close();
    }
  }
}
