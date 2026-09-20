import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/brain_key_bundle.dart';
import 'brain_key_storage.dart';

class BrainLinuxKeyStorage extends BrainKeyStorage {
  BrainLinuxKeyStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? _createSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static FlutterSecureStorage _createSecureStorage() {
    if (Platform.isMacOS) {
      return const FlutterSecureStorage(
        mOptions: MacOsOptions(usesDataProtectionKeychain: false),
      );
    }

    return const FlutterSecureStorage();
  }

  static const String _namespace = 'evrylux.brain.vault';

  static const String _masterKeyField = 'master_key';

  static const String _keyVersionField = 'key_version';

  static const String _createdAtField = 'created_at';

  String _normalizeVaultId(String vaultId) {
    final normalized = vaultId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('vaultId não pode estar vazio.');
    }

    return normalized;
  }

  String _storageKey({required String vaultId, required String field}) {
    final cleanVaultId = _normalizeVaultId(vaultId);

    return '$_namespace.$cleanVaultId.$field';
  }

  String _masterKeyStorageKey(String vaultId) {
    return _storageKey(vaultId: vaultId, field: _masterKeyField);
  }

  String _keyVersionStorageKey(String vaultId) {
    return _storageKey(vaultId: vaultId, field: _keyVersionField);
  }

  String _createdAtStorageKey(String vaultId) {
    return _storageKey(vaultId: vaultId, field: _createdAtField);
  }

  @override
  Future<void> saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = _normalizeVaultId(vaultId);

    bundle.validate();

    final encodedMasterKey = base64UrlEncode(bundle.masterKeyBytes);

    final encodedKeyVersion = bundle.keyVersion.toString();

    final encodedCreatedAt = bundle.createdAt.toUtc().toIso8601String();

    final masterKeyStorageKey = _masterKeyStorageKey(cleanVaultId);

    final keyVersionStorageKey = _keyVersionStorageKey(cleanVaultId);

    final createdAtStorageKey = _createdAtStorageKey(cleanVaultId);

    await _secureStorage.write(
      key: masterKeyStorageKey,
      value: encodedMasterKey,
    );

    try {
      await _secureStorage.write(
        key: keyVersionStorageKey,
        value: encodedKeyVersion,
      );

      await _secureStorage.write(
        key: createdAtStorageKey,
        value: encodedCreatedAt,
      );
    } catch (_) {
      try {
        await _secureStorage.delete(key: masterKeyStorageKey);

        await _secureStorage.delete(key: keyVersionStorageKey);

        await _secureStorage.delete(key: createdAtStorageKey);
      } catch (_) {
        // Não mascarar o erro original.
      }

      rethrow;
    }
  }

  @override
  Future<BrainKeyBundle?> loadKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return null;
    }

    final masterKeyRaw = await _secureStorage.read(
      key: _masterKeyStorageKey(cleanVaultId),
    );

    final keyVersionRaw = await _secureStorage.read(
      key: _keyVersionStorageKey(cleanVaultId),
    );

    final createdAtRaw = await _secureStorage.read(
      key: _createdAtStorageKey(cleanVaultId),
    );

    if (masterKeyRaw == null && keyVersionRaw == null && createdAtRaw == null) {
      return null;
    }

    if (masterKeyRaw == null || keyVersionRaw == null || createdAtRaw == null) {
      throw StateError('BrainKeyBundle incompleto no armazenamento seguro.');
    }

    late final List<int> masterKeyBytes;

    try {
      masterKeyBytes = base64Url.decode(masterKeyRaw);
    } catch (_) {
      throw const FormatException(
        'Master Key armazenada possui formato inválido.',
      );
    }

    final keyVersion = int.tryParse(keyVersionRaw.trim());

    if (keyVersion == null || keyVersion <= 0) {
      throw const FormatException(
        'keyVersion armazenada possui formato inválido.',
      );
    }

    final createdAt = DateTime.tryParse(createdAtRaw.trim());

    if (createdAt == null) {
      throw const FormatException(
        'createdAt armazenado possui formato inválido.',
      );
    }

    final bundle = BrainKeyBundle(
      masterKeyBytes: List<int>.unmodifiable(masterKeyBytes),
      keyVersion: keyVersion,
      createdAt: createdAt.toLocal(),
    );

    bundle.validate();

    return bundle;
  }

  @override
  Future<bool> containsKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    final masterKeyExists = await _secureStorage.containsKey(
      key: _masterKeyStorageKey(cleanVaultId),
    );

    final keyVersionExists = await _secureStorage.containsKey(
      key: _keyVersionStorageKey(cleanVaultId),
    );

    final createdAtExists = await _secureStorage.containsKey(
      key: _createdAtStorageKey(cleanVaultId),
    );

    if (!masterKeyExists && !keyVersionExists && !createdAtExists) {
      return false;
    }

    if (!masterKeyExists || !keyVersionExists || !createdAtExists) {
      throw StateError('BrainKeyBundle incompleto no armazenamento seguro.');
    }

    return true;
  }

  @override
  Future<void> deleteKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return;
    }

    await _secureStorage.delete(key: _masterKeyStorageKey(cleanVaultId));

    await _secureStorage.delete(key: _keyVersionStorageKey(cleanVaultId));

    await _secureStorage.delete(key: _createdAtStorageKey(cleanVaultId));
  }
}
