import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/updater/update_download_service.dart';
import 'package:EVRYLUX/core/updater/update_manifest.dart';
import 'package:EVRYLUX/core/updater/update_manifest_service.dart';

class FakeTransport implements UpdateDownloadTransport {
  FakeTransport(this.response);
  final UpdateDownloadResponse response;
  bool closed = false;
  @override
  Future<UpdateDownloadResponse> open(Uri uri) async => response;
  @override
  void close() {
    closed = true;
  }
}

void main() {
  late Directory directory;
  late UpdateManifestService verifier;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('evrylux-stage2-');
    verifier = UpdateManifestService(
      manifestUrl: Uri.parse('https://updates.example.com/latest.json'),
      trustedPublicKeys: const {},
      allowedDownloadHosts: const {'updates.example.com'},
    );
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<UpdateAsset> assetFor(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return UpdateAsset.fromMap(
      {
        'platform': 'linux',
        'architecture': 'x64',
        'format': 'tar.gz',
        'url': 'https://updates.example.com/test.tar.gz',
        'size': bytes.length,
        'sha256': hash.bytes
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join(),
      },
      allowedHosts: const {'updates.example.com'},
    );
  }

  UpdateDownloadJob job(UpdateDownloadResponse response) => UpdateDownloadJob(
    manifestService: verifier,
    transport: FakeTransport(response),
    stagingDirectory: () async => directory,
  );

  test('Download válido mantém pacote verificado e progresso', () async {
    final bytes = utf8.encode('pacote de teste');
    final progress = <UpdateDownloadProgress>[];
    final result =
        await job(
          UpdateDownloadResponse(
            statusCode: 200,
            contentLength: bytes.length,
            stream: Stream.value(bytes),
          ),
        ).download(
          asset: await assetFor(bytes),
          version: '1.0.1',
          onProgress: progress.add,
        );
    expect(await result.file.readAsBytes(), bytes);
    expect(progress.last.fraction, 1);
    expect(result.file.path.endsWith('package.verified'), isTrue);
  });

  test('Hash inválido remove o arquivo parcial', () async {
    final bytes = utf8.encode('pacote correto');
    final downloader = job(
      UpdateDownloadResponse(
        statusCode: 200,
        contentLength: bytes.length,
        stream: Stream.value(utf8.encode('pacote erradoo')),
      ),
    );
    await expectLater(
      downloader.download(
        asset: await assetFor(bytes),
        version: '1.0.1',
        onProgress: (_) {},
      ),
      throwsFormatException,
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test('Download incompleto é rejeitado', () async {
    final bytes = utf8.encode('pacote completo');
    await expectLater(
      job(
        UpdateDownloadResponse(
          statusCode: 200,
          contentLength: -1,
          stream: Stream.value(bytes.sublist(0, 3)),
        ),
      ).download(
        asset: await assetFor(bytes),
        version: '1.0.1',
        onProgress: (_) {},
      ),
      throwsFormatException,
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test('HTTP inesperado é rejeitado', () async {
    final bytes = utf8.encode('pacote');
    await expectLater(
      job(
        UpdateDownloadResponse(
          statusCode: 302,
          contentLength: 0,
          stream: const Stream<List<int>>.empty(),
        ),
      ).download(
        asset: await assetFor(bytes),
        version: '1.0.1',
        onProgress: (_) {},
      ),
      throwsA(isA<HttpException>()),
    );
  });

  test('Cancelamento interrompe e limpa o download', () async {
    final bytes = utf8.encode('pacote completo');
    late UpdateDownloadJob downloader;
    downloader = job(
      UpdateDownloadResponse(
        statusCode: 200,
        contentLength: bytes.length,
        stream: Stream.fromIterable([bytes.sublist(0, 3), bytes.sublist(3)]),
      ),
    );
    await expectLater(
      downloader.download(
        asset: await assetFor(bytes),
        version: '1.0.1',
        onProgress: (progress) {
          if (progress.received > 0) downloader.cancel();
        },
      ),
      throwsA(isA<UpdateDownloadCancelled>()),
    );
    expect(await directory.list().toList(), isEmpty);
  });

  test('Um job não pode ser iniciado duas vezes', () async {
    final bytes = utf8.encode('pacote');
    final downloader = job(
      UpdateDownloadResponse(
        statusCode: 200,
        contentLength: bytes.length,
        stream: Stream.value(bytes),
      ),
    );
    await downloader.download(
      asset: await assetFor(bytes),
      version: '1.0.1',
      onProgress: (_) {},
    );
    await expectLater(
      downloader.download(
        asset: await assetFor(bytes),
        version: '1.0.1',
        onProgress: (_) {},
      ),
      throwsStateError,
    );
  });
}
