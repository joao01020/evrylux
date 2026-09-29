import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../study/brain/devices/security/brain_device_local_secrets.dart';
import '../../study/brain/security/keys/brain_key_storage.dart';
import '../../study/brain/security/models/brain_key_bundle.dart';

class WebBrainSecureStorage extends BrainKeyStorage {
  WebBrainSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _deviceKey = 'evrylux.web.brain.device.v1';
  static const _vaultKey = 'evrylux.web.brain.vault_id.v1';
  static const _keyNamespace = 'evrylux.web.brain.master_key.v1';
  static const _trustNamespace = 'evrylux.web.brain.trusted_access.v1';

  Future<BrainDeviceLocalSecrets?> loadDevice() async {
    final raw = await _storage.read(key: _deviceKey);
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Identidade Web do Brain inválida.');
    }
    return BrainDeviceLocalSecrets.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<void> saveDevice(BrainDeviceLocalSecrets secrets) {
    return _storage.write(key: _deviceKey, value: jsonEncode(secrets.toMap()));
  }

  Future<void> clearDevice() => _storage.delete(key: _deviceKey);

  Future<String?> loadVaultId() async {
    final value = await _storage.read(key: _vaultKey);
    final clean = value?.trim() ?? '';
    return clean.isEmpty ? null : clean;
  }

  Future<void> saveVaultId(String vaultId) {
    final clean = vaultId.trim();
    if (clean.isEmpty) throw ArgumentError('vaultId não pode ser vazio.');
    return _storage.write(key: _vaultKey, value: clean);
  }

  String _bundleKey(String vaultId) => '$_keyNamespace.${vaultId.trim()}';
  String _trustKey(String vaultId) => '$_trustNamespace.${vaultId.trim()}';

  @override
  Future<void> saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = vaultId.trim();
    if (cleanVaultId.isEmpty) throw ArgumentError('vaultId não pode ser vazio.');
    bundle.validate();
    await _storage.write(
      key: _bundleKey(cleanVaultId),
      value: jsonEncode(<String, dynamic>{
        'master_key_b64': base64UrlEncode(bundle.masterKeyBytes),
        'key_version': bundle.keyVersion,
        'created_at': bundle.createdAt.toUtc().toIso8601String(),
      }),
    );
  }

  @override
  Future<BrainKeyBundle?> loadKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();
    if (cleanVaultId.isEmpty) return null;
    final raw = await _storage.read(key: _bundleKey(cleanVaultId));
    if (raw == null || raw.trim().isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) throw const FormatException('Master Key Web inválida.');
    final map = Map<String, dynamic>.from(decoded);
    final bytes = base64Url.decode(map['master_key_b64']?.toString() ?? '');
    final version = int.tryParse(map['key_version']?.toString() ?? '');
    final createdAt = DateTime.tryParse(map['created_at']?.toString() ?? '');
    if (bytes.length != 32 || version == null || version <= 0 || createdAt == null) {
      throw const FormatException('Master Key Web incompleta.');
    }
    final bundle = BrainKeyBundle(
      masterKeyBytes: List<int>.unmodifiable(bytes),
      keyVersion: version,
      createdAt: createdAt.toUtc(),
    );
    bundle.validate();
    return bundle;
  }

  @override
  Future<bool> containsKeyBundle({required String vaultId}) async {
    return (await loadKeyBundle(vaultId: vaultId)) != null;
  }

  @override
  Future<void> deleteKeyBundle({required String vaultId}) async {
    final clean = vaultId.trim();
    if (clean.isEmpty) return;
    await _storage.delete(key: _bundleKey(clean));
  }

  Future<void> saveTrustedAccess({
    required String vaultId,
    required String deviceId,
    DateTime? verifiedAt,
  }) async {
    final cleanVaultId = vaultId.trim();
    final cleanDeviceId = deviceId.trim();
    if (cleanVaultId.isEmpty || cleanDeviceId.isEmpty) {
      throw ArgumentError('vaultId e deviceId são obrigatórios.');
    }

    await _storage.write(
      key: _trustKey(cleanVaultId),
      value: jsonEncode(<String, dynamic>{
        'device_id': cleanDeviceId,
        'verified_at': (verifiedAt ?? DateTime.now().toUtc())
            .toUtc()
            .toIso8601String(),
      }),
    );
  }

  Future<Map<String, dynamic>?> loadTrustedAccess({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();
    if (cleanVaultId.isEmpty) return null;

    final raw = await _storage.read(key: _trustKey(cleanVaultId));
    if (raw == null || raw.trim().isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Trusted access Web inválido.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  Future<bool> isTrustedAccessValid({
    required String vaultId,
    required String deviceId,
    required Duration maxAge,
  }) async {
    final trust = await loadTrustedAccess(vaultId: vaultId);
    if (trust == null) return false;

    final trustedDeviceId = trust['device_id']?.toString().trim() ?? '';
    final verifiedAtRaw = trust['verified_at']?.toString().trim() ?? '';
    final verifiedAt = DateTime.tryParse(verifiedAtRaw)?.toUtc();

    if (trustedDeviceId.isEmpty || verifiedAt == null) {
      return false;
    }

    if (trustedDeviceId != deviceId.trim()) {
      return false;
    }

    return DateTime.now().toUtc().difference(verifiedAt) <= maxAge;
  }

  Future<void> clearTrustedAccess({required String vaultId}) async {
    final clean = vaultId.trim();
    if (clean.isEmpty) return;
    await _storage.delete(key: _trustKey(clean));
  }

  Future<void> clearSessionSecrets({String? vaultId}) async {
    if (vaultId != null && vaultId.trim().isNotEmpty) {
      await deleteKeyBundle(vaultId: vaultId);
      await clearTrustedAccess(vaultId: vaultId);
    }
    await _storage.delete(key: _vaultKey);
    await clearDevice();
  }
}
