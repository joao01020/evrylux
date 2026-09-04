import '../models/brain_device_record.dart';
import 'brain_device_authorization_service.dart';

import '../../vault/services/brain_vault_service.dart';

// ============================================================
// BRAIN RECOVERY DEVICE SERVICE — FASE 16
// ============================================================
//
// Orquestra a recuperação de um Vault existente em um novo
// dispositivo sem transportar a Master Key em plaintext.
//
// Fluxo:
//
// NOVO DISPOSITIVO
//   ↓
// gera/reutiliza identidade X25519 local
//   ↓
// registra-se como pending no Vault informado
//   ↓
// dispositivo já autorizado confere fingerprint e aprova
//   ↓
// Master Key é entregue em envelope E2EE
//   ↓
// novo dispositivo importa a Master Key no secure storage
//   ↓
// cria o manifest local usando o MESMO vaultId
//
// Este service:
// - não conhece UI;
// - não conhece senha;
// - não serializa Master Key;
// - não cria storage alternativo de chave;
// - não ignora conflito com outro Vault local.
//
// ============================================================

class BrainRecoveryDeviceService {
  BrainRecoveryDeviceService({
    required BrainDeviceAuthorizationService authorizationService,
    required BrainVaultService vaultService,
  }) : _authorizationService = authorizationService,
       _vaultService = vaultService;

  final BrainDeviceAuthorizationService _authorizationService;
  final BrainVaultService _vaultService;

  // ============================================================
  // REQUEST RECOVERY
  // ============================================================
  //
  // Registra este computador como dispositivo pending do Vault.
  //
  // Se já houver um Vault local DIFERENTE, falha fechado para
  // impedir substituição acidental de identidade criptográfica.
  //
  // ============================================================

  Future<BrainDeviceRecord> requestRecovery({
    required String vaultId,
    required String deviceName,
  }) async {
    final cleanVaultId = vaultId.trim();
    final cleanDeviceName = deviceName.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('Informe o Vault ID que será recuperado.');
    }

    if (cleanDeviceName.isEmpty) {
      throw ArgumentError('Nome do dispositivo inválido.');
    }

    final localManifest = await _vaultService.loadLocalManifest();

    if (localManifest != null &&
        localManifest.vaultId != cleanVaultId) {
      throw StateError(
        'Já existe outro Vault neste dispositivo. '
        'A recuperação foi bloqueada para não substituir dados locais.',
      );
    }

    return _authorizationService.registerCurrentDevice(
      vaultId: cleanVaultId,
      deviceName: cleanDeviceName,
    );
  }

  // ============================================================
  // COMPLETE RECOVERY
  // ============================================================
  //
  // Executado DEPOIS que outro dispositivo autorizado aprovou
  // este computador.
  //
  // 1. importa envelope E2EE;
  // 2. persiste Master Key no secure storage;
  // 3. cria/abre o manifest do MESMO Vault;
  // 4. nunca gera outra Master Key quando a importada já existe.
  //
  // Retorna false enquanto ainda não houver envelope aprovado.
  //
  // ============================================================

  Future<bool> completeRecovery({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('Informe o Vault ID que será recuperado.');
    }

    final localManifest = await _vaultService.loadLocalManifest();

    if (localManifest != null &&
        localManifest.vaultId != cleanVaultId) {
      throw StateError(
        'O Vault local pertence a outra identidade. '
        'A recuperação foi bloqueada.',
      );
    }

    final imported = await _authorizationService.importPendingMasterKey(
      vaultId: cleanVaultId,
    );

    if (!imported) {
      return false;
    }

    if (localManifest == null) {
      await _vaultService.createVault(
        vaultId: cleanVaultId,
      );
    } else {
      await _vaultService.openVault();
    }

    return true;
  }
}
