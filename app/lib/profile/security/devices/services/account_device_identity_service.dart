import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class AccountDeviceIdentityService {
  AccountDeviceIdentityService({
    FlutterSecureStorage? storage,
    Uuid? uuid,
  })  : _storage = storage ??
            const FlutterSecureStorage(),
        _uuid = uuid ??
            const Uuid();

  static const String _deviceIdKey =
      'evrylux.account.device_identity.v1';

  final FlutterSecureStorage _storage;

  final Uuid _uuid;

  Future<
    String
  >
  getOrCreateDeviceId() async {
    final existing = await _storage.read(
      key: _deviceIdKey,
    );

    if (existing != null &&
        existing.trim().isNotEmpty) {
      return existing.trim();
    }

    final created = _uuid.v4();

    await _storage.write(
      key: _deviceIdKey,
      value: created,
    );

    return created;
  }

  Future<
    void
  >
  clear() {
    return _storage.delete(
      key: _deviceIdKey,
    );
  }

  String get deviceName {
    final host = Platform.localHostname.trim();

    final platform = platformLabel;

    if (host.isNotEmpty) {
      return '$host • $platform';
    }

    return 'EVRYLUX • $platform';
  }

  String get platformLabel {
    if (Platform.isLinux) {
      return 'Linux Desktop';
    }

    if (Platform.isWindows) {
      return 'Windows Desktop';
    }

    if (Platform.isMacOS) {
      return 'macOS';
    }

    if (Platform.isAndroid) {
      return 'Android';
    }

    if (Platform.isIOS) {
      return 'iOS';
    }

    return Platform.operatingSystem.trim().isNotEmpty
        ? Platform.operatingSystem
        : 'Dispositivo';
  }
}
