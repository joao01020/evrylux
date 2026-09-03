import '../../security/keys/brain_key_service.dart';
import '../ports/brain_device_master_key_port.dart';

// ============================================================
// BRAIN KEY SERVICE DEVICE MASTER KEY ADAPTER
// ============================================================
//
// Conecta a Fase 07 ao BrainKeyService das Fases 01/02.
//
// Fluxo:
//
// BrainDeviceAuthorizationService / BrainDeviceGateService
//        ↓
// BrainDeviceMasterKeyPort
//        ↓
// BrainKeyService
//        ↓
// BrainKeyStorage
//        ↓
// secure storage da plataforma
//
// IMPORTANTE:
//
// - não cria um segundo storage da Master Key;
// - não conhece Supabase;
// - não conhece UI;
// - não faz key wrapping;
// - não serializa Master Key em arquivo comum;
// - apenas delega operações seguras ao BrainKeyService.
//
// ============================================================

class BrainKeyServiceDeviceMasterKeyAdapter
    implements BrainDeviceMasterKeyPort {
  const BrainKeyServiceDeviceMasterKeyAdapter({
    required BrainKeyService keyService,
  }) : _keyService = keyService;

  final BrainKeyService _keyService;

  // ============================================================
  // HAS MASTER KEY
  // ============================================================

  @override
  Future<bool> hasMasterKey({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    return _keyService.hasKeyBundle(vaultId: cleanVaultId);
  }

  // ============================================================
  // EXPORT
  // ============================================================

  @override
  Future<List<int>> exportMasterKey({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    return _keyService.exportMasterKeyBytes(vaultId: cleanVaultId);
  }

  // ============================================================
  // IMPORT
  // ============================================================

  @override
  Future<void> importMasterKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    await _keyService.importMasterKeyBytes(
      vaultId: cleanVaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKeyBytes,
    );
  }
}
