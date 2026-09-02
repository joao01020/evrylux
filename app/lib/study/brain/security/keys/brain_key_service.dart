import '../crypto/brain_secure_random.dart';
import '../exceptions/brain_crypto_exception.dart';
import '../models/brain_key_bundle.dart';
import 'brain_key_storage.dart';

// ============================================================
// BRAIN KEY SERVICE
// ============================================================
//
// Responsável pelo ciclo local inicial da Master Key.
//
// Nesta Fase 01:
//
// - gerar Master Key;
// - validar Master Key;
// - criar BrainKeyBundle;
// - salvar através de BrainKeyStorage;
// - carregar através de BrainKeyStorage;
// - criar chave caso ainda não exista.
//
// NÃO pertence à Fase 01:
//
// - autorização de novos dispositivos;
// - wrapped keys;
// - sincronização da chave;
// - Recovery Device;
// - rotação real de chave;
// - recuperação de conta.
//
// ============================================================

class BrainKeyService {
  BrainKeyService({
    BrainSecureRandom? secureRandom,
    BrainKeyStorage? storage,
  }) : _secureRandom =
           secureRandom ??
           BrainSecureRandom(),
       _storage =
           storage ??
           InMemoryBrainKeyStorage();

  final BrainSecureRandom _secureRandom;

  final BrainKeyStorage _storage;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int masterKeyLengthBytes = BrainKeyBundle.masterKeyLengthBytes;

  static const int initialKeyVersion = BrainKeyBundle.initialKeyVersion;

  // ============================================================
  // CREATE
  // ============================================================

  BrainKeyBundle createKeyBundle() {
    final bytes = _secureRandom.generateMasterKey();

    final bundle = BrainKeyBundle(
      masterKeyBytes:
          List<
            int
          >.unmodifiable(
            bytes,
          ),
      keyVersion: initialKeyVersion,
      createdAt: DateTime.now().toUtc(),
    );

    validateKeyBundle(
      bundle,
    );

    return bundle;
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validateKeyBundle(
    BrainKeyBundle bundle,
  ) {
    if (bundle.masterKeyBytes.length !=
        masterKeyLengthBytes) {
      throw BrainCryptoException.invalidKey(
        message:
            'Master Key inválida: esperado '
            '$masterKeyLengthBytes bytes.',
      );
    }

    if (bundle.keyVersion <=
        0) {
      throw BrainCryptoException.invalidKey(
        message: 'Versão da Master Key inválida.',
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para armazenamento da chave.',
      );
    }

    validateKeyBundle(
      bundle,
    );

    try {
      await _storage.saveKeyBundle(
        vaultId: cleanVaultId,
        bundle: bundle,
      );
    } catch (
      error
    ) {
      if (error
          is BrainCryptoException) {
        rethrow;
      }

      throw BrainCryptoException.keyStorageFailed(
        cause: error,
      );
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

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

    try {
      final bundle = await _storage.loadKeyBundle(
        vaultId: cleanVaultId,
      );

      if (bundle ==
          null) {
        return null;
      }

      validateKeyBundle(
        bundle,
      );

      return bundle;
    } catch (
      error
    ) {
      if (error
          is BrainCryptoException) {
        rethrow;
      }

      throw BrainCryptoException.keyStorageFailed(
        cause: error,
      );
    }
  }

  // ============================================================
  // REQUIRE
  // ============================================================

  Future<
    BrainKeyBundle
  >
  requireKeyBundle({
    required String vaultId,
  }) async {
    final bundle = await loadKeyBundle(
      vaultId: vaultId,
    );

    if (bundle ==
        null) {
      throw BrainCryptoException.keyNotFound();
    }

    return bundle;
  }

  // ============================================================
  // GET OR CREATE
  // ============================================================

  Future<
    BrainKeyBundle
  >
  getOrCreateKeyBundle({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido.',
      );
    }

    final existing = await loadKeyBundle(
      vaultId: cleanVaultId,
    );

    if (existing !=
        null) {
      return existing;
    }

    final created = createKeyBundle();

    await saveKeyBundle(
      vaultId: cleanVaultId,
      bundle: created,
    );

    return created;
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  hasKeyBundle({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    try {
      return await _storage.containsKeyBundle(
        vaultId: cleanVaultId,
      );
    } catch (
      error
    ) {
      throw BrainCryptoException.keyStorageFailed(
        cause: error,
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

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

    try {
      await _storage.deleteKeyBundle(
        vaultId: cleanVaultId,
      );
    } catch (
      error
    ) {
      throw BrainCryptoException.keyStorageFailed(
        cause: error,
      );
    }
  }
}
