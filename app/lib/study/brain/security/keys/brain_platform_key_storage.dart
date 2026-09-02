import 'dart:io';

import '../models/brain_key_bundle.dart';

import 'brain_key_storage.dart';
import 'brain_linux_key_storage.dart';

// ============================================================
// BRAIN PLATFORM KEY STORAGE
// ============================================================
//
// Implementação de BrainKeyStorage que seleciona o armazenamento
// seguro correspondente ao sistema operacional.
//
// Nesta etapa:
//
// Linux
//   ↓
// BrainLinuxKeyStorage
//   ↓
// Secret Service
//
// Futuramente:
//
// Windows
//   ↓
// DPAPI / Credential Manager
//
// macOS
//   ↓
// Keychain
//
// ============================================================
//
// IMPORTANTE:
//
// Nenhum fallback inseguro é permitido.
//
// Se uma plataforma ainda não tiver implementação segura,
// lançamos UnsupportedError.
//
// NÃO caímos silenciosamente para:
//
// - arquivo;
// - SharedPreferences;
// - SQLite;
// - memória.
//
// ============================================================

class BrainPlatformKeyStorage
    extends
        BrainKeyStorage {
  BrainPlatformKeyStorage({
    BrainKeyStorage? linuxStorage,
  }) : _linuxStorage =
           linuxStorage ??
           BrainLinuxKeyStorage();

  // ============================================================
  // PLATFORM STORAGE
  // ============================================================

  final BrainKeyStorage _linuxStorage;

  // ============================================================
  // IS SUPPORTED
  // ============================================================

  bool get isSupported {
    return Platform.isLinux;
  }

  // ============================================================
  // RESOLVE
  // ============================================================

  BrainKeyStorage _resolveStorage() {
    if (Platform.isLinux) {
      return _linuxStorage;
    }

    throw UnsupportedError(
      'EVRYLUX Brain ainda não possui armazenamento '
      'seguro de Master Key para '
      '${Platform.operatingSystem}.',
    );
  }

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
  }) {
    return _resolveStorage().saveKeyBundle(
      vaultId: vaultId,
      bundle: bundle,
    );
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
  }) {
    return _resolveStorage().loadKeyBundle(
      vaultId: vaultId,
    );
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
  }) {
    return _resolveStorage().containsKeyBundle(
      vaultId: vaultId,
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
  }) {
    return _resolveStorage().deleteKeyBundle(
      vaultId: vaultId,
    );
  }
}
