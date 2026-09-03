abstract class BrainDeviceMasterKeyPort {
  // ============================================================
  // HAS MASTER KEY
  // ============================================================
  //
  // Gate da Fase 07 usa esta operação para confirmar que o
  // dispositivo autorizado também possui a Master Key local.
  //
  // Não exporta bytes.
  //
  // ============================================================

  Future<bool> hasMasterKey({required String vaultId});

  // ============================================================
  // EXPORT MASTER KEY
  // ============================================================
  //
  // Usado somente durante aprovação de um novo dispositivo.
  //
  // ============================================================

  Future<List<int>> exportMasterKey({required String vaultId});

  // ============================================================
  // IMPORT MASTER KEY
  // ============================================================
  //
  // Usado pelo novo dispositivo depois de abrir o envelope E2EE.
  //
  // ============================================================

  Future<void> importMasterKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  });
}

// ============================================================
// CALLBACK IMPLEMENTATION
// ============================================================
//
// Útil para testes e composição sem acoplar diretamente ao
// BrainKeyService.
//
// ============================================================

class CallbackBrainDeviceMasterKeyPort implements BrainDeviceMasterKeyPort {
  CallbackBrainDeviceMasterKeyPort({
    required Future<bool> Function(String vaultId) hasMasterKey,
    required Future<List<int>> Function(String vaultId) exportMasterKey,
    required Future<void> Function({
      required String vaultId,
      required int keyVersion,
      required List<int> masterKeyBytes,
    })
    importMasterKey,
  }) : _hasMasterKey = hasMasterKey,
       _exportMasterKey = exportMasterKey,
       _importMasterKey = importMasterKey;

  final Future<bool> Function(String vaultId) _hasMasterKey;

  final Future<List<int>> Function(String vaultId) _exportMasterKey;

  final Future<void> Function({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  })
  _importMasterKey;

  @override
  Future<bool> hasMasterKey({required String vaultId}) {
    return _hasMasterKey(vaultId);
  }

  @override
  Future<List<int>> exportMasterKey({required String vaultId}) {
    return _exportMasterKey(vaultId);
  }

  @override
  Future<void> importMasterKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) {
    return _importMasterKey(
      vaultId: vaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKeyBytes,
    );
  }
}
