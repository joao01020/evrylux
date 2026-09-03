import '../models/brain_device_record.dart';
import '../ports/brain_device_master_key_port.dart';
import '../ports/brain_device_remote_port.dart';
import '../security/brain_device_crypto_service.dart';
import '../security/brain_device_local_secrets.dart';
import 'brain_device_identity_service.dart';

// ============================================================
// BRAIN DEVICE AUTHORIZATION SERVICE
// ============================================================
//
// Orquestra:
//
// - registro do dispositivo atual;
// - leitura de dispositivos;
// - aprovação de dispositivo pending;
// - wrapping da Master Key;
// - importação do envelope no dispositivo alvo;
// - revogação.
//
// Não conhece UI.
//
// ============================================================

class BrainDeviceAuthorizationService {
  BrainDeviceAuthorizationService({
    required BrainDeviceIdentityService identityService,
    required BrainDeviceRemotePort remote,
    required BrainDeviceMasterKeyPort masterKeyPort,
    BrainDeviceCryptoService? cryptoService,
  }) : _identityService = identityService,
       _remote = remote,
       _masterKeyPort = masterKeyPort,
       _cryptoService = cryptoService ?? BrainDeviceCryptoService();

  final BrainDeviceIdentityService _identityService;

  final BrainDeviceRemotePort _remote;

  final BrainDeviceMasterKeyPort _masterKeyPort;

  final BrainDeviceCryptoService _cryptoService;

  // ============================================================
  // REGISTER CURRENT DEVICE
  // ============================================================

  Future<BrainDeviceRecord> registerCurrentDevice({
    required String vaultId,
    required String deviceName,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _identityService.getOrCreateLocalSecrets(
      deviceName: deviceName,
    );

    return _remote.registerDevice(vaultId: cleanVaultId, localSecrets: local);
  }

  // ============================================================
  // LIST DEVICES
  // ============================================================

  Future<List<BrainDeviceRecord>> listDevices({required String vaultId}) {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    return _remote.listDevices(vaultId: cleanVaultId);
  }

  // ============================================================
  // CURRENT DEVICE AUTHORIZED?
  // ============================================================

  Future<bool> isCurrentDeviceAuthorized({required String vaultId}) async {
    final local = await _requireLocalSecrets();

    return _remote.isAuthorized(
      vaultId: vaultId.trim(),
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );
  }

  // ============================================================
  // APPROVE DEVICE
  // ============================================================
  //
  // A:
  // authorized + Master Key
  //
  // B:
  // pending + public key conhecida
  //
  // A cria envelope E2EE para B.
  //
  // ============================================================

  Future<void> approveDevice({
    required String vaultId,
    required String targetDeviceId,
    required String expectedTargetFingerprint,
    required int keyVersion,
  }) async {
    final cleanVaultId = vaultId.trim();

    final cleanTargetDeviceId = targetDeviceId.trim();

    if (cleanVaultId.isEmpty || cleanTargetDeviceId.isEmpty) {
      throw ArgumentError('vaultId/deviceId inválido.');
    }

    final local = await _requireLocalSecrets();

    if (local.deviceId == cleanTargetDeviceId) {
      throw StateError('Um dispositivo não pode aprovar a si mesmo.');
    }

    final currentAuthorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!currentAuthorized) {
      throw StateError('Este dispositivo não está autorizado a aprovar outro.');
    }

    final hasMasterKey = await _masterKeyPort.hasMasterKey(
      vaultId: cleanVaultId,
    );

    if (!hasMasterKey) {
      throw StateError('Este dispositivo não possui a Master Key do Vault.');
    }

    final target = await _remote.getDevice(
      vaultId: cleanVaultId,
      deviceId: cleanTargetDeviceId,
    );

    if (target == null) {
      throw StateError('Dispositivo alvo não encontrado.');
    }

    if (!target.isPending) {
      throw StateError('Dispositivo alvo não está pendente.');
    }

    final expected = expectedTargetFingerprint.trim().toUpperCase();

    final actual = target.keyFingerprint.trim().toUpperCase();

    if (expected.isEmpty || expected != actual) {
      throw StateError('Fingerprint do novo dispositivo não confere.');
    }

    final masterKey = await _masterKeyPort.exportMasterKey(
      vaultId: cleanVaultId,
    );

    if (masterKey.length != 32) {
      throw StateError('Master Key exportada possui tamanho inválido.');
    }

    final envelope = await _cryptoService.wrapMasterKey(
      sender: local,
      targetDeviceId: target.deviceId,
      targetPublicKeyBase64: target.publicKeyBase64,
      vaultId: cleanVaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKey,
    );

    await _remote.approveDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64: local.authorizationSecretBase64,
      targetDeviceId: target.deviceId,
      envelope: envelope,
    );
  }

  // ============================================================
  // IMPORT PENDING MASTER KEY
  // ============================================================
  //
  // Executado no dispositivo B.
  //
  // B baixa o envelope destinado ao próprio deviceId,
  // descriptografa localmente e importa a Master Key através do
  // BrainKeyService adapter.
  //
  // ============================================================

  Future<bool> importPendingMasterKey({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _requireLocalSecrets();

    final envelope = await _remote.loadPendingEnvelope(
      vaultId: cleanVaultId,
      targetDeviceId: local.deviceId,
      targetAuthorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (envelope == null) {
      return false;
    }

    if (envelope.vaultId != cleanVaultId) {
      throw StateError('Envelope pertence a outro Vault.');
    }

    if (envelope.targetDeviceId != local.deviceId) {
      throw StateError('Envelope pertence a outro dispositivo.');
    }

    final masterKey = await _cryptoService.unwrapMasterKey(
      target: local,
      envelope: envelope,
    );

    await _masterKeyPort.importMasterKey(
      vaultId: envelope.vaultId,
      keyVersion: envelope.keyVersion,
      masterKeyBytes: masterKey,
    );

    // Confirma persistência antes de consumir o envelope.
    final imported = await _masterKeyPort.hasMasterKey(
      vaultId: envelope.vaultId,
    );

    if (!imported) {
      throw StateError('Master Key não ficou disponível após a importação.');
    }

    await _remote.markEnvelopeConsumed(
      vaultId: cleanVaultId,
      targetDeviceId: local.deviceId,
      targetAuthorizationSecretBase64: local.authorizationSecretBase64,
      envelopeId: envelope.envelopeId,
    );

    return true;
  }

  // ============================================================
  // REVOKE DEVICE
  // ============================================================
  //
  // Revogação:
  //
  // authorized -> revoked
  //
  // Consequência:
  //
  // BrainDeviceGateService passa a retornar false para aquele
  // dispositivo e a SyncQueue do Brain deixa os itens pendentes.
  //
  // A revogação NÃO consegue apagar uma Master Key que já exista
  // fisicamente no dispositivo remoto.
  //
  // Para proteger dados futuros contra uma máquina comprometida,
  // será necessária rotação de Master Key.
  //
  // ============================================================

  Future<void> revokeDevice({
    required String vaultId,
    required String targetDeviceId,
  }) async {
    final cleanVaultId = vaultId.trim();

    final cleanTargetDeviceId = targetDeviceId.trim();

    if (cleanVaultId.isEmpty || cleanTargetDeviceId.isEmpty) {
      throw ArgumentError('vaultId/deviceId inválido.');
    }

    final local = await _requireLocalSecrets();

    if (local.deviceId == cleanTargetDeviceId) {
      throw StateError(
        'Revogação do próprio dispositivo exige um fluxo separado.',
      );
    }

    final currentAuthorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!currentAuthorized) {
      throw StateError('Este dispositivo não está autorizado a revogar outro.');
    }

    final target = await _remote.getDevice(
      vaultId: cleanVaultId,
      deviceId: cleanTargetDeviceId,
    );

    if (target == null) {
      throw StateError('Dispositivo alvo não encontrado.');
    }

    if (target.isRevoked) {
      // Idempotente.
      return;
    }

    await _remote.revokeDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64: local.authorizationSecretBase64,
      targetDeviceId: cleanTargetDeviceId,
    );
  }

  // ============================================================
  // REQUIRE LOCAL SECRETS
  // ============================================================

  Future<BrainDeviceLocalSecrets> _requireLocalSecrets() async {
    final local = await _identityService.loadLocalSecrets();

    if (local == null) {
      throw StateError('Identidade local de dispositivo inexistente.');
    }

    return local;
  }
}
