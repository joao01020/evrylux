import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'brain_device_local_secrets.dart';

abstract class BrainDeviceSecureStorage {
  Future<BrainDeviceLocalSecrets?> load();
  Future<void> save(BrainDeviceLocalSecrets secrets);
  Future<void> clear();
}

class PlatformBrainDeviceSecureStorage implements BrainDeviceSecureStorage {
  PlatformBrainDeviceSecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  static const _key = 'evrylux.brain.device_identity.v1';
  final FlutterSecureStorage _storage;
  @override
  Future<BrainDeviceLocalSecrets?> load() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map)
      throw const FormatException('Identidade segura inválida.');
    return BrainDeviceLocalSecrets.fromMap(Map<String, dynamic>.from(decoded));
  }

  @override
  Future<void> save(BrainDeviceLocalSecrets secrets) =>
      _storage.write(key: _key, value: jsonEncode(secrets.toMap()));
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class InMemoryBrainDeviceSecureStorage implements BrainDeviceSecureStorage {
  BrainDeviceLocalSecrets? _value;
  @override
  Future<BrainDeviceLocalSecrets?> load() async => _value;
  @override
  Future<void> save(BrainDeviceLocalSecrets secrets) async {
    _value = secrets;
  }

  @override
  Future<void> clear() async {
    _value = null;
  }
}
