import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import 'update_download_coordinator.dart';

/// Handoff to the independently packaged user-level updater.
/// Never accepts installation commands or executable paths from the network.
class UpdateInstallationService {
  const UpdateInstallationService._();

  static const bool managedRelease = bool.fromEnvironment(
    'EVRYLUX_MANAGED_RELEASE',
  );
  static bool _handoffInProgress = false;

  static String get _helperName => Platform.isWindows
      ? 'evrylux-updater-helper.exe'
      : 'evrylux-updater-helper';

  static Directory get installRoot {
    if (Platform.isWindows) {
      final local = Platform.environment['LOCALAPPDATA'];
      if (local == null || local.isEmpty) {
        throw StateError('LOCALAPPDATA indisponível.');
      }
      return Directory(p.join(local, 'EVRYLUX', 'installation'));
    }
    if (Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home == null || home.isEmpty) {
        throw StateError('HOME indisponível.');
      }
      return Directory(
        p.join(home, '.local', 'share', 'evrylux', 'installation'),
      );
    }
    throw UnsupportedError('Atualização não disponível neste sistema.');
  }

  static File get helper =>
      File(p.join(installRoot.path, 'updater', _helperName));

  static Future<bool> isManagedInstallation(String version) async {
    if (!managedRelease || kDebugMode || !await helper.exists()) {
      return false;
    }
    final current = File(p.join(installRoot.path, 'current.json'));
    if (!await current.exists()) return false;
    final data = jsonDecode(await current.readAsString());
    if (data is! Map || data['version'] != version) return false;
    final expected = p.normalize(
      p.absolute(
        p.join(
          installRoot.path,
          'versions',
          version,
          Platform.isWindows ? 'EVRYLUX.exe' : 'app',
        ),
      ),
    );
    final actual = p.normalize(p.absolute(Platform.resolvedExecutable));
    if (Platform.isWindows) {
      return actual.toLowerCase() == expected.toLowerCase();
    }
    return actual == expected;
  }

  static Map<String, String> get _helperEnvironment {
    final environment = Map<String, String>.from(Platform.environment);
    environment.removeWhere((key, _) => key.startsWith('_PYI_'));
    // Start an independent PyInstaller onefile instance. Its bootloader
    // must not reuse the updater's unpacked runtime.
    environment['PYINSTALLER_RESET_ENVIRONMENT'] = '1';
    return environment;
  }

  static Future<void> _atomicJson(File file, Map<String, dynamic> data) async {
    await file.parent.create(recursive: true);
    final temp = File('${file.path}.${_nonce()}.tmp');
    try {
      final sink = temp.openWrite();
      sink.write(jsonEncode(data));
      await sink.flush();
      await sink.close();
      await temp.rename(file.path);
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  static String _nonce() {
    final random = Random.secure();
    return List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }

  static Future<void> installReady({
    required UpdateDownloadCoordinator coordinator,
    required Future<void> Function() beforeExit,
  }) async {
    if (_handoffInProgress) {
      throw StateError('Uma instalação já está sendo preparada.');
    }
    _handoffInProgress = true;
    try {
      await _installReady(coordinator: coordinator, beforeExit: beforeExit);
    } finally {
      _handoffInProgress = false;
    }
  }

  static Future<void> _installReady({
    required UpdateDownloadCoordinator coordinator,
    required Future<void> Function() beforeExit,
  }) async {
    final ready = coordinator.ready;
    final envelope = coordinator.readyEnvelope;
    if (ready == null || envelope == null) {
      throw StateError('Nenhum pacote verificado está disponível.');
    }
    if (!await isManagedInstallation(coordinator.currentVersion)) {
      throw StateError(
        'Instalação gerenciada não encontrada. '
        'Instale primeiro uma release oficial do EVRYLUX.',
      );
    }

    // Revalidate against the trusted build configuration, not the
    // notification URL or a manifest supplied by the caller.
    final verifier = UpdateReleaseConfig.createVerifier();
    final manifest = await verifier.verifyEnvelope(envelope);
    if (manifest.version.value != ready.version ||
        !manifest.isNewerThan(coordinator.currentVersion)) {
      throw StateError('Release diferente do pacote preparado.');
    }
    final asset = manifest.assetFor(
      platform: coordinator.platform,
      architecture: coordinator.architecture,
    );
    if (asset == null ||
        asset.sha256 != ready.asset.sha256 ||
        asset.size != ready.asset.size) {
      throw StateError('Pacote incompatível com a release assinada.');
    }
    if (manifest.dataSchema != AppDatabase.schemaVersion ||
        manifest.minDataSchema > AppDatabase.schemaVersion ||
        manifest.maxDataSchema < AppDatabase.schemaVersion) {
      throw StateError('Esquema de dados incompatível.');
    }

    if (!await ready.file.exists()) {
      throw StateError('Pacote verificado não encontrado.');
    }
    final root = installRoot;
    final staging = Directory(p.join(root.path, 'staging'));
    await staging.create(recursive: true);
    final nonce = _nonce();
    final package = File(p.join(staging.path, '$nonce.verified'));
    final request = File(p.join(root.path, 'state', 'inbox', '$nonce.json'));

    try {
      await ready.file.copy(package.path);
      await verifier.verifyDownloadedFile(file: package, asset: asset);

      final support = await getApplicationSupportDirectory();
      final documents = await getApplicationDocumentsDirectory();

      await _atomicJson(request, {
        'envelope': jsonDecode(envelope),
        'package': package.path,
        'version': ready.version,
        'previous': coordinator.currentVersion,
        'pid': pid,
        'nonce': nonce,
        'support': support.path,
        'documents': p.join(documents.path, 'evrylux'),
      });

      // The helper acknowledges the verified/prepared handoff BEFORE the
      // application closes. A failed helper launch leaves the app running.
      final handoff = File(p.join(root.path, 'state', 'handoff.json'));
      if (await handoff.exists()) await handoff.delete();

      await Process.start(
        helper.path,
        ['apply', '--request', request.path, '--ui'],
        workingDirectory: root.path,
        environment: _helperEnvironment,
        mode: ProcessStartMode.detached,
      );

      final deadline = DateTime.now().add(const Duration(minutes: 10));
      while (DateTime.now().isBefore(deadline)) {
        if (await handoff.exists()) {
          try {
            final data = jsonDecode(await handoff.readAsString());
            if (data is Map &&
                data['nonce'] == nonce &&
                data['status'] == 'failed') {
              throw StateError(
                data['message']?.toString() ??
                    'O instalador recusou a atualização.',
              );
            }
            if (data is Map &&
                data['nonce'] == nonce &&
                data['status'] == 'prepared') {
              await beforeExit();
              // The helper now owns backup, activation, health check,
              // rollback and relaunch. No files are replaced by Flutter.
              exit(0);
            }
          } on FormatException {
            // Atomic handoff not yet available.
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      throw StateError(
        'O instalador não confirmou a preparação. '
        'O EVRYLUX continuará aberto.',
      );
    } catch (_) {
      // Preserve verified packages if a helper may still be using them.
      rethrow;
    }
  }

  /// Called only after the main engine initialized and rendered a frame.
  static Future<void> reportHealthy({
    required String nonce,
    required String version,
  }) async {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(nonce)) return;
    if (!await isManagedInstallation(version)) return;
    final result = await Process.run(
      helper.path,
      ['health', '--nonce', nonce, '--version', version],
      workingDirectory: installRoot.path,
      environment: _helperEnvironment,
    );
    if (result.exitCode != 0) {
      debugPrint('[UPDATER] Confirmação de inicialização não aceita.');
    }
  }
}
