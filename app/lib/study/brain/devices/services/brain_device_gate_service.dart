import '../ports/brain_device_master_key_port.dart';
import '../ports/brain_device_remote_port.dart';
import 'brain_device_identity_service.dart';

// ============================================================
// BRAIN DEVICE GATE SERVICE
// ============================================================
//
// Gate de segurança para o Cloud do Cérebro.
//
// O sync só é permitido quando TODOS os requisitos abaixo forem
// verdadeiros:
//
// - usuário autenticado;
// - BrainDataMode permite Cloud;
// - existe identidade local de dispositivo;
// - existe Master Key para o Vault local;
// - dispositivo está autorizado no backend.
//
// Qualquer erro:
// false
//
// FAIL CLOSED.
//
// ============================================================

class BrainDeviceGateService {
  BrainDeviceGateService({
    required BrainDeviceIdentityService identityService,
    required BrainDeviceRemotePort remote,
    required BrainDeviceMasterKeyPort masterKeyPort,
  }) : _identityService = identityService,
       _remote = remote,
       _masterKeyPort = masterKeyPort;

  final BrainDeviceIdentityService _identityService;

  final BrainDeviceRemotePort _remote;

  final BrainDeviceMasterKeyPort _masterKeyPort;

  // ============================================================
  // CAN USE CLOUD
  // ============================================================

  Future<bool> canUseCloud({
    required String vaultId,
    required bool isAuthenticated,
    required bool dataModeAllowsCloud,
  }) async {
    final cleanVaultId = vaultId.trim();

    // ----------------------------------------------------------
    // LOCAL / AUTH
    // ----------------------------------------------------------

    if (cleanVaultId.isEmpty || !isAuthenticated || !dataModeAllowsCloud) {
      return false;
    }

    // ----------------------------------------------------------
    // LOCAL DEVICE IDENTITY
    // ----------------------------------------------------------

    final local = await _identityService.loadLocalSecrets();

    if (local == null) {
      return false;
    }

    // ----------------------------------------------------------
    // LOCAL MASTER KEY
    // ----------------------------------------------------------
    //
    // Um device autorizado sem a Master Key não deve transmitir
    // objetos do Brain nem ser tratado como plenamente habilitado.
    //
    // ----------------------------------------------------------

    try {
      final hasMasterKey = await _masterKeyPort.hasMasterKey(
        vaultId: cleanVaultId,
      );

      if (!hasMasterKey) {
        return false;
      }
    } catch (_) {
      return false;
    }

    // ----------------------------------------------------------
    // REMOTE AUTHORIZATION
    // ----------------------------------------------------------
    //
    // pending  -> false
    // revoked  -> false
    // unknown  -> false
    // erro     -> false
    //
    // ----------------------------------------------------------

    try {
      return await _remote.isAuthorized(
        vaultId: cleanVaultId,
        deviceId: local.deviceId,
        authorizationSecretBase64: local.authorizationSecretBase64,
      );
    } catch (_) {
      return false;
    }
  }
}
