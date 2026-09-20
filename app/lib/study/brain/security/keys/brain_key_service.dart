import 'dart:developer' as developer;

import '../crypto/brain_secure_random.dart';
import '../exceptions/brain_crypto_exception.dart';
import '../models/brain_key_bundle.dart';
import 'brain_key_storage.dart';

// ============================================================
// BRAIN KEY SERVICE
// ============================================================
//
// Responsável pelo ciclo local da Master Key do Cérebro.
//
// FASE 01:
//
// - gerar Master Key;
// - validar Master Key;
// - criar BrainKeyBundle;
// - salvar através de BrainKeyStorage;
// - carregar através de BrainKeyStorage;
// - criar chave caso ainda não exista.
//
// FASE 07:
//
// - exportar os bytes da Master Key somente para fluxo interno
//   de autorização de dispositivo;
// - importar uma Master Key recebida por envelope E2EE;
// - validar vaultId, keyVersion e tamanho da chave;
// - impedir sobrescrita silenciosa de uma chave diferente;
// - continuar usando BrainKeyStorage como única persistência.
//
// IMPORTANTE:
//
// - este service NÃO conhece Supabase;
// - este service NÃO conhece UI;
// - este service NÃO conhece dispositivos diretamente;
// - este service NÃO faz key wrapping;
// - este service NÃO transmite chave;
// - este service NÃO salva Master Key fora do BrainKeyStorage;
// - a Master Key nunca deve ser serializada em plaintext para rede,
//   arquivo comum, SharedPreferences ou SyncQueue.
//
// A Fase 07 deve acessar este service através de um adapter/port.
//
// ============================================================

class BrainKeyService {
  BrainKeyService({BrainSecureRandom? secureRandom, BrainKeyStorage? storage})
    : _secureRandom = secureRandom ?? BrainSecureRandom(),
      _storage = storage ?? InMemoryBrainKeyStorage();

  final BrainSecureRandom _secureRandom;

  final BrainKeyStorage _storage;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int masterKeyLengthBytes = BrainKeyBundle.masterKeyLengthBytes;

  static const int initialKeyVersion = BrainKeyBundle.initialKeyVersion;

  // ============================================================
  // STORAGE ERROR HANDLING
  // ============================================================

  Never _throwStorageError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (error is BrainCryptoException) {
      throw error;
    }

    developer.log(
      '[BRAIN KEY STORAGE] Falha em $operation',
      name: 'EVRYLUX.BrainKeyService',
      error: error,
      stackTrace: stackTrace,
    );

    throw BrainCryptoException.keyStorageFailed(cause: error);
  }

  // ============================================================
  // CREATE
  // ============================================================

  BrainKeyBundle createKeyBundle() {
    final bytes = _secureRandom.generateMasterKey();

    final bundle = BrainKeyBundle(
      masterKeyBytes: List<int>.unmodifiable(bytes),
      keyVersion: initialKeyVersion,
      createdAt: DateTime.now().toUtc(),
    );

    validateKeyBundle(bundle);

    return bundle;
  }

  // ============================================================
  // CREATE FROM IMPORTED BYTES — FASE 07
  // ============================================================

  BrainKeyBundle createImportedKeyBundle({
    required List<int> masterKeyBytes,
    required int keyVersion,
    DateTime? createdAt,
  }) {
    final normalizedBytes = List<int>.unmodifiable(masterKeyBytes);

    final bundle = BrainKeyBundle(
      masterKeyBytes: normalizedBytes,
      keyVersion: keyVersion,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
    );

    validateKeyBundle(bundle);

    return bundle;
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validateKeyBundle(BrainKeyBundle bundle) {
    if (bundle.masterKeyBytes.length != masterKeyLengthBytes) {
      throw BrainCryptoException.invalidKey(
        message:
            'Master Key inválida: esperado '
            '$masterKeyLengthBytes bytes.',
      );
    }

    if (bundle.keyVersion <= 0) {
      throw BrainCryptoException.invalidKey(
        message: 'Versão da Master Key inválida.',
      );
    }

    for (final byte in bundle.masterKeyBytes) {
      if (byte < 0 || byte > 255) {
        throw BrainCryptoException.invalidKey(
          message: 'Master Key contém byte inválido.',
        );
      }
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para armazenamento da chave.',
      );
    }

    validateKeyBundle(bundle);

    try {
      await _storage.saveKeyBundle(vaultId: cleanVaultId, bundle: bundle);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'saveKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<BrainKeyBundle?> loadKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return null;
    }

    try {
      final bundle = await _storage.loadKeyBundle(vaultId: cleanVaultId);

      if (bundle == null) {
        return null;
      }

      validateKeyBundle(bundle);

      return bundle;
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'loadKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // REQUIRE
  // ============================================================

  Future<BrainKeyBundle> requireKeyBundle({required String vaultId}) async {
    final bundle = await loadKeyBundle(vaultId: vaultId);

    if (bundle == null) {
      throw BrainCryptoException.keyNotFound();
    }

    return bundle;
  }

  // ============================================================
  // GET OR CREATE
  // ============================================================

  Future<BrainKeyBundle> getOrCreateKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(message: 'vaultId inválido.');
    }

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing != null) {
      return existing;
    }

    final created = createKeyBundle();

    await saveKeyBundle(vaultId: cleanVaultId, bundle: created);

    return created;
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<bool> hasKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    try {
      return await _storage.containsKeyBundle(vaultId: cleanVaultId);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'containsKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // EXPORT MASTER KEY — FASE 07
  // ============================================================

  Future<List<int>> exportMasterKeyBytes({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para exportação da Master Key.',
      );
    }

    final bundle = await requireKeyBundle(vaultId: cleanVaultId);

    validateKeyBundle(bundle);

    return List<int>.unmodifiable(List<int>.from(bundle.masterKeyBytes));
  }

  // ============================================================
  // IMPORT MASTER KEY — FASE 07
  // ============================================================

  Future<BrainKeyBundle> importMasterKeyBytes({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
    DateTime? createdAt,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para importação da Master Key.',
      );
    }

    final imported = createImportedKeyBundle(
      masterKeyBytes: masterKeyBytes,
      keyVersion: keyVersion,
      createdAt: createdAt,
    );

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing != null) {
      final sameVersion = existing.keyVersion == imported.keyVersion;

      final sameKey = _constantTimeEquals(
        existing.masterKeyBytes,
        imported.masterKeyBytes,
      );

      if (sameVersion && sameKey) {
        return existing;
      }

      throw BrainCryptoException.invalidKey(
        message:
            'Já existe uma Master Key diferente para este Vault. '
            'Importação recusada para evitar sobrescrita insegura.',
      );
    }

    await saveKeyBundle(vaultId: cleanVaultId, bundle: imported);

    return imported;
  }

  // ============================================================
  // MATCHES EXISTING KEY — FASE 07
  // ============================================================

  Future<bool> matchesExistingKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty ||
        keyVersion <= 0 ||
        masterKeyBytes.length != masterKeyLengthBytes) {
      return false;
    }

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing == null) {
      return false;
    }

    if (existing.keyVersion != keyVersion) {
      return false;
    }

    return _constantTimeEquals(existing.masterKeyBytes, masterKeyBytes);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return;
    }

    try {
      await _storage.deleteKeyBundle(vaultId: cleanVaultId);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'deleteKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // CONSTANT-TIME BYTE COMPARISON
  // ============================================================

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    var difference = 0;

    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }

    return difference == 0;
  }
}
