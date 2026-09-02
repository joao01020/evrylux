import '../models/brain_key_bundle.dart';

// ============================================================
// BRAIN KEY STORAGE
// ============================================================
//
// Contrato de armazenamento seguro das chaves do Cérebro.
//
// Esta abstração será implementada posteriormente utilizando
// armazenamento seguro específico do sistema operacional.
//
// Exemplos futuros:
//
// Linux:
// - Secret Service
// - GNOME Keyring
// - KWallet
//
// Windows:
// - Credential Manager
// - DPAPI
//
// macOS:
// - Keychain
//
// IMPORTANTE:
//
// Implementações de produção NÃO podem armazenar a Master Key
// em:
//
// - SharedPreferences;
// - JSON;
// - SQLite plaintext;
// - .env;
// - arquivo comum.
//
// ============================================================

abstract class BrainKeyStorage {
  const BrainKeyStorage();

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  });

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    BrainKeyBundle?
  >
  loadKeyBundle({
    required String vaultId,
  });

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  containsKeyBundle({
    required String vaultId,
  });

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  deleteKeyBundle({
    required String vaultId,
  });
}

// ============================================================
// IN MEMORY BRAIN KEY STORAGE
// ============================================================
//
// Implementação SOMENTE para:
//
// - testes;
// - desenvolvimento isolado da Fase 01.
//
// NÃO é persistente.
//
// Reiniciar o app apaga as chaves.
//
// NÃO usar como armazenamento definitivo em produção.
//
// ============================================================

class InMemoryBrainKeyStorage
    extends
        BrainKeyStorage {
  InMemoryBrainKeyStorage();

  final Map<
    String,
    BrainKeyBundle
  >
  _items =
      <
        String,
        BrainKeyBundle
      >{};

  // ============================================================
  // SAVE
  // ============================================================

  @override
  Future<
    void
  >
  saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError(
        'vaultId não pode estar vazio.',
      );
    }

    bundle.validate();

    _items[cleanVaultId] = bundle;
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

    return _items[cleanVaultId];
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

    return _items.containsKey(
      cleanVaultId,
    );
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

    _items.remove(
      cleanVaultId,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================
  //
  // Útil somente em testes.
  //
  // ============================================================

  Future<
    void
  >
  clear() async {
    _items.clear();
  }
}
