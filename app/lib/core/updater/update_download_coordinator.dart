import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'update_download_service.dart';
import 'update_manifest.dart';
import 'update_manifest_service.dart';

/// Configuração confiável embutida no build, nunca recebida do Supabase.
class UpdateReleaseConfig {
  const UpdateReleaseConfig._();

  static const manifestUrl = String.fromEnvironment(
    'EVRYLUX_UPDATE_MANIFEST_URL',
  );
  static const keyId = String.fromEnvironment('EVRYLUX_UPDATE_KEY_ID');
  static const publicKey = String.fromEnvironment('EVRYLUX_UPDATE_PUBLIC_KEY');
  static const downloadHost = String.fromEnvironment(
    'EVRYLUX_UPDATE_DOWNLOAD_HOST',
  );

  static bool get configured =>
      manifestUrl.isNotEmpty &&
      keyId.isNotEmpty &&
      publicKey.isNotEmpty &&
      downloadHost.isNotEmpty;

  static UpdateManifestService createVerifier() {
    if (!configured) {
      throw StateError(
        'Atualizador ainda não configurado para esta instalação.',
      );
    }
    final uri = Uri.parse(manifestUrl);
    final host = downloadHost.toLowerCase();
    if (host.isEmpty || host.contains('/') || host.contains(':')) {
      throw const FormatException('Domínio de atualização inválido.');
    }
    return UpdateManifestService(
      manifestUrl: uri,
      trustedPublicKeys: {keyId: publicKey},
      allowedDownloadHosts: {host},
    );
  }
}

class UpdateDownloadCoordinator extends ChangeNotifier {
  UpdateDownloadCoordinator({
    required this.verifier,
    required this.currentVersion,
    required this.currentDataSchema,
    required this.platform,
    required this.architecture,
    UpdateDownloadJob Function(UpdateManifestService)? jobFactory,
  }) : _jobFactory =
           jobFactory ??
           ((verifier) => UpdateDownloadJob(manifestService: verifier));

  final UpdateManifestService verifier;
  final String currentVersion;
  final int currentDataSchema;
  final String platform;
  final String architecture;
  final UpdateDownloadJob Function(UpdateManifestService) _jobFactory;

  static UpdateDownloadCoordinator? _shared;

  static UpdateDownloadCoordinator shared({
    required String currentVersion,
    required int currentDataSchema,
  }) {
    return _shared ??= UpdateDownloadCoordinator(
      verifier: UpdateReleaseConfig.createVerifier(),
      currentVersion: currentVersion,
      currentDataSchema: currentDataSchema,
      platform: Platform.operatingSystem,
      architecture: _nativeArchitecture(),
    );
  }

  static String _nativeArchitecture() {
    final abi = Abi.current();
    if (abi == Abi.linuxX64 || abi == Abi.windowsX64) return 'x64';
    if (abi == Abi.linuxArm64 || abi == Abi.windowsArm64) return 'arm64';
    throw UnsupportedError('Arquitetura não suportada: $abi');
  }

  UpdateDownloadPhase _phase = UpdateDownloadPhase.idle;
  UpdateDownloadPhase get phase => _phase;
  UpdateDownloadProgress _progress = const UpdateDownloadProgress(0, 0);
  UpdateDownloadProgress get progress => _progress;
  String? _message;
  String? get message => _message;
  UpdateDownloadResult? _ready;
  UpdateDownloadResult? get ready => _ready;
  String? _readyEnvelope;
  String? get readyEnvelope => _readyEnvelope;
  UpdateDownloadJob? _job;
  bool _busy = false;
  bool _cancelRequested = false;
  bool get busy => _busy;

  void _notify() => notifyListeners();

  void cancel() {
    if (!_busy) return;
    _cancelRequested = true;
    _job?.cancel();
  }

  Future<void> start({required String notificationVersion}) async {
    if (_busy) return;
    _busy = true;
    _cancelRequested = false;
    _phase = UpdateDownloadPhase.downloading;
    _message = 'Verificando a release assinada...';
    _progress = const UpdateDownloadProgress(0, 0);
    _notify();

    try {
      final envelope = await verifier.fetchSignedEnvelope().timeout(
        const Duration(seconds: 60),
      );
      final manifest = await verifier.verifyEnvelope(envelope);
      if (_cancelRequested) throw const UpdateDownloadCancelled();
      if (!manifest.isNewerThan(currentVersion)) {
        throw StateError('Esta versão já está instalada.');
      }
      if (ReleaseVersion(notificationVersion).compareTo(manifest.version) !=
          0) {
        throw StateError('A notificação não corresponde à release assinada.');
      }
      if (manifest.dataSchema != currentDataSchema ||
          !manifest.supportsDataSchema(currentDataSchema)) {
        throw StateError(
          'Esta release não é compatível com o esquema de dados atual.',
        );
      }
      final asset = manifest.assetFor(
        platform: platform,
        architecture: architecture,
      );
      if (asset == null) {
        throw UnsupportedError('Não há pacote para $platform/$architecture.');
      }
      // A URL da notificação é apenas metadado legado.
      // A escolha do pacote vem exclusivamente do manifesto assinado.

      final job = _jobFactory(verifier);
      _job = job;
      if (_cancelRequested) job.cancel();
      _message = 'Baixando atualização...';
      _notify();
      final result = await job.download(
        asset: asset,
        version: manifest.version.value,
        onProgress: (progress) {
          _progress = progress;
          _notify();
        },
        onPhase: (phase) {
          _phase = phase;
          _message = phase == UpdateDownloadPhase.verifying
              ? 'Verificando integridade...'
              : 'Baixando atualização...';
          _notify();
        },
      );

      // Não descarta uma release já verificada até haver substituta.
      _ready = result;
      _readyEnvelope = envelope;
      _phase = UpdateDownloadPhase.ready;
      _message = 'Pacote verificado. Pronto para instalação.';
    } on UpdateDownloadCancelled {
      _phase = UpdateDownloadPhase.cancelled;
      _message = 'Download cancelado.';
    } catch (error) {
      _phase = UpdateDownloadPhase.failed;
      _message = error.toString();
    } finally {
      _job = null;
      _busy = false;
      _notify();
    }
  }
}
