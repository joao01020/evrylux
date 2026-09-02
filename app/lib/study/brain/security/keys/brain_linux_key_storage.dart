import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/brain_key_bundle.dart';

import 'brain_key_storage.dart';

// ============================================================
// BRAIN LINUX KEY STORAGE
// ============================================================
//
// Implementação persistente do BrainKeyStorage para Linux.
//
// Fluxo:
//
// BrainKeyService
//      ↓
// BrainKeyStorage
//      ↓
// BrainLinuxKeyStorage
//      ↓
// flutter_secure_storage
//      ↓
// Secret Service / Keyring do sistema
//
// ============================================================
//
// IMPORTANTE:
//
// A Master Key:
//
// - NÃO vai para arquivo comum;
// - NÃO vai para SharedPreferences;
// - NÃO vai para SQLite;
// - NÃO vai para .env;
// - NÃO vai para SyncQueue;
// - NÃO vai para Supabase;
// - NÃO vai para o próprio Vault.
//
// ============================================================
//
// O BrainKeyBundle deliberadamente NÃO possui toJson/fromJson.
//
// A persistência é responsabilidade desta classe.
//
// ============================================================

class BrainLinuxKeyStorage
    extends
        BrainKeyStorage {
  BrainLinuxKeyStorage({
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage =
           secureStorage ??
           const FlutterSecureStorage();

  // ============================================================
  // SECURE STORAGE
  // ============================================================

  final FlutterSecureStorage _secureStorage;

  // ============================================================
  // NAMESPACE
  // ============================================================

  static const String _namespace = 'evrylux.brain.vault';

  static const String _masterKeyField = 'master_key';

  static const String _keyVersionField = 'key_version';

  static const String _createdAtField = 'created_at';

  // ============================================================
  // NORMALIZE VAULT ID
  // ============================================================

  String _normalizeVaultId(
    String vaultId,
  ) {
    final normalized = vaultId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'vaultId não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // STORAGE KEY
  // ============================================================

  String _storageKey({
    required String vaultId,
    required String field,
  }) {
    final cleanVaultId = _normalizeVaultId(
      vaultId,
    );

    return '$_namespace.'
        '$cleanVaultId.'
        '$field';
  }

  // ============================================================
  // MASTER KEY STORAGE KEY
  // ============================================================

  String _masterKeyStorageKey(
    String vaultId,
  ) {
    return _storageKey(
      vaultId: vaultId,
      field: _masterKeyField,
    );
  }

  // ============================================================
  // KEY VERSION STORAGE KEY
  // ============================================================

  String _keyVersionStorageKey(
    String vaultId,
  ) {
    return _storageKey(
      vaultId: vaultId,
      field: _keyVersionField,
    );
  }

  // ============================================================
  // CREATED AT STORAGE KEY
  // ============================================================

  String _createdAtStorageKey(
    String vaultId,
  ) {
    return _storageKey(
      vaultId: vaultId,
      field: _createdAtField,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================
  //
  // Gravamos os três campos separadamente dentro do secure
  // storage.
  //
  // A Master Key é codificada em Base64 apenas para representação.
  //
  // Base64 NÃO é criptografia.
  //
  // A proteção vem do Secret Service utilizado por
  // flutter_secure_storage no Linux.
  //
  // ============================================================

  @override
  Future<
    void
  >
  saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = _normalizeVaultId(
      vaultId,
    );

    bundle.validate();

    final encodedMasterKey = base64UrlEncode(
      bundle.masterKeyBytes,
    );

    final encodedKeyVersion = bundle.keyVersion.toString();

    final encodedCreatedAt = bundle.createdAt.toUtc().toIso8601String();

    final masterKeyStorageKey = _masterKeyStorageKey(
      cleanVaultId,
    );

    final keyVersionStorageKey = _keyVersionStorageKey(
      cleanVaultId,
    );

    final createdAtStorageKey = _createdAtStorageKey(
      cleanVaultId,
    );

    // ==========================================================
    // WRITE MASTER KEY
    // ==========================================================

    await _secureStorage.write(
      key: masterKeyStorageKey,
      value: encodedMasterKey,
    );

    try {
      // ========================================================
      // WRITE KEY VERSION
      // ========================================================

      await _secureStorage.write(
        key: keyVersionStorageKey,
        value: encodedKeyVersion,
      );

      // ========================================================
      // WRITE CREATED AT
      // ========================================================

      await _secureStorage.write(
        key: createdAtStorageKey,
        value: encodedCreatedAt,
      );
    } catch (
      error
    ) {
      // ========================================================
      // ROLLBACK
      // ========================================================
      //
      // Nunca queremos deixar um BrainKeyBundle parcialmente
      // persistido.
      //
      // ========================================================

      try {
        await _secureStorage.delete(
          key: masterKeyStorageKey,
        );

        await _secureStorage.delete(
          key: keyVersionStorageKey,
        );

        await _secureStorage.delete(
          key: createdAtStorageKey,
        );
      } catch (
        _
      ) {
        // Não mascarar o erro original.
      }

      rethrow;
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  @override
  Future<
    BrainKeyBundle?
  >
  loadKeyBundle({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return null;
    }

    final masterKeyRaw = await _secureStorage.read(
      key: _masterKeyStorageKey(
        cleanVaultId,
      ),
    );

    final keyVersionRaw = await _secureStorage.read(
      key: _keyVersionStorageKey(
        cleanVaultId,
      ),
    );

    final createdAtRaw = await _secureStorage.read(
      key: _createdAtStorageKey(
        cleanVaultId,
      ),
    );

    // ==========================================================
    // NOTHING STORED
    // ==========================================================

    if (masterKeyRaw ==
            null &&
        keyVersionRaw ==
            null &&
        createdAtRaw ==
            null) {
      return null;
    }

    // ==========================================================
    // PARTIAL / CORRUPTED STATE
    // ==========================================================

    if (masterKeyRaw ==
            null ||
        keyVersionRaw ==
            null ||
        createdAtRaw ==
            null) {
      throw StateError(
        'BrainKeyBundle incompleto no armazenamento seguro.',
      );
    }

    // ==========================================================
    // DECODE MASTER KEY
    // ==========================================================

    late final List<
      int
    >
    masterKeyBytes;

    try {
      masterKeyBytes = base64Url.decode(
        masterKeyRaw,
      );
    } catch (
      _
    ) {
      throw const FormatException(
        'Master Key armazenada possui formato inválido.',
      );
    }

    // ==========================================================
    // KEY VERSION
    // ==========================================================

    final keyVersion = int.tryParse(
      keyVersionRaw.trim(),
    );

    if (keyVersion ==
            null ||
        keyVersion <=
            0) {
      throw const FormatException(
        'keyVersion armazenada possui formato inválido.',
      );
    }

    // ==========================================================
    // CREATED AT
    // ==========================================================

    final createdAt = DateTime.tryParse(
      createdAtRaw.trim(),
    );

    if (createdAt ==
        null) {
      throw const FormatException(
        'createdAt armazenado possui formato inválido.',
      );
    }

    // ==========================================================
    // REBUILD BUNDLE
    // ==========================================================

    final bundle = BrainKeyBundle(
      masterKeyBytes:
          List<
            int
          >.unmodifiable(
            masterKeyBytes,
          ),
      keyVersion: keyVersion,
      createdAt: createdAt.toLocal(),
    );

    bundle.validate();

    return bundle;
  }

  // ============================================================
  // EXISTS
  // ============================================================

  @override
  Future<
    bool
  >
  containsKeyBundle({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    final masterKeyExists = await _secureStorage.containsKey(
      key: _masterKeyStorageKey(
        cleanVaultId,
      ),
    );

    final keyVersionExists = await _secureStorage.containsKey(
      key: _keyVersionStorageKey(
        cleanVaultId,
      ),
    );

    final createdAtExists = await _secureStorage.containsKey(
      key: _createdAtStorageKey(
        cleanVaultId,
      ),
    );

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (!masterKeyExists &&
        !keyVersionExists &&
        !createdAtExists) {
      return false;
    }

    // ==========================================================
    // INCONSISTENT
    // ==========================================================

    if (!masterKeyExists ||
        !keyVersionExists ||
        !createdAtExists) {
      throw StateError(
        'BrainKeyBundle incompleto no armazenamento seguro.',
      );
    }

    return true;
  }

  // ============================================================
  // DELETE
  // ============================================================

  @override
  Future<
    void
  >
  deleteKeyBundle({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return;
    }

    await _secureStorage.delete(
      key: _masterKeyStorageKey(
        cleanVaultId,
      ),
    );

    await _secureStorage.delete(
      key: _keyVersionStorageKey(
        cleanVaultId,
      ),
    );

    await _secureStorage.delete(
      key: _createdAtStorageKey(
        cleanVaultId,
      ),
    );
  }
}
