import 'dart:convert';

import '../models/brain_device_record.dart';
import '../ports/brain_device_master_key_port.dart';
import '../ports/brain_device_remote_port.dart';
import '../security/brain_device_crypto_service.dart';
import '../security/brain_device_local_secrets.dart';
import 'brain_device_identity_service.dart';

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

    return _remote.registerDevice(
      vaultId: cleanVaultId,
      localSecrets: local,
    );
  }

  Future<List<BrainDeviceRecord>> listDevices({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _requireLocalSecrets();

    return _remote.listDevices(
      vaultId: cleanVaultId,
      requesterDeviceId: local.deviceId,
      requesterAuthorizationSecretBase64:
          local.authorizationSecretBase64,
    );
  }

  Future<bool> isCurrentDeviceAuthorized({
    required String vaultId,
  }) async {
    final local = await _requireLocalSecrets();

    return _remote.isAuthorized(
      vaultId: vaultId.trim(),
      deviceId: local.deviceId,
      authorizationSecretBase64:
          local.authorizationSecretBase64,
    );
  }

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
      throw StateError(
        'Um dispositivo não pode aprovar a si mesmo.',
      );
    }

    final currentAuthorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64:
          local.authorizationSecretBase64,
    );

    if (!currentAuthorized) {
      throw StateError(
        'Este dispositivo não está autorizado a aprovar outro.',
      );
    }

    if (!await _masterKeyPort.hasMasterKey(
      vaultId: cleanVaultId,
    )) {
      throw StateError(
        'Este dispositivo não possui a Master Key do Vault.',
      );
    }

    final target = await _remote.getDevice(
      vaultId: cleanVaultId,
      requesterDeviceId: local.deviceId,
      requesterAuthorizationSecretBase64:
          local.authorizationSecretBase64,
      targetDeviceId: cleanTargetDeviceId,
    );

    if (target == null) {
      throw StateError('Dispositivo alvo não encontrado.');
    }

    if (!target.isPending) {
      throw StateError(
        'Dispositivo alvo não está pendente.',
      );
    }

    if (target.isRecoveryExpired) {
      throw StateError(
        'A solicitação de recuperação expirou. '
        'Crie uma nova solicitação no novo dispositivo.',
      );
    }

    final requestId = target.recoveryRequestId?.trim() ?? '';
    final expiresAt = target.recoveryExpiresAt;

    if (requestId.isEmpty || expiresAt == null) {
      throw StateError(
        'Solicitação de recuperação sem binding válido.',
      );
    }

    final expected =
        expectedTargetFingerprint.trim().toUpperCase();
    final stored =
        target.keyFingerprint.trim().toUpperCase();

    if (expected.isEmpty || expected != stored) {
      throw StateError(
        'Fingerprint do novo dispositivo não confere.',
      );
    }

    // Never trust a stored fingerprint independently from the public key.
    final computedFingerprint =
        await _cryptoService.fingerprintPublicKey(
          base64Url.decode(target.publicKeyBase64),
        );

    if (computedFingerprint != stored) {
      throw StateError(
        'A chave pública do dispositivo não corresponde ao fingerprint.',
      );
    }

    final masterKey = await _masterKeyPort.exportMasterKey(
      vaultId: cleanVaultId,
    );

    if (masterKey.length != 32) {
      throw StateError(
        'Master Key exportada possui tamanho inválido.',
      );
    }

    final envelope = await _cryptoService.wrapMasterKey(
      sender: local,
      targetDeviceId: target.deviceId,
      targetPublicKeyBase64: target.publicKeyBase64,
      targetKeyFingerprint: stored,
      recoveryRequestId: requestId,
      recoveryExpiresAt: expiresAt,
      vaultId: cleanVaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKey,
    );

    await _remote.approveDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64:
          local.authorizationSecretBase64,
      targetDeviceId: target.deviceId,
      envelope: envelope,
    );
  }

  Future<bool> importPendingMasterKey({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _requireLocalSecrets();

    // Atomic claim+consume on the backend.
    final envelope = await _remote.claimPendingEnvelope(
      vaultId: cleanVaultId,
      targetDeviceId: local.deviceId,
      targetAuthorizationSecretBase64:
          local.authorizationSecretBase64,
    );

    if (envelope == null) {
      return false;
    }

    if (envelope.vaultId != cleanVaultId) {
      throw StateError(
        'Envelope pertence a outro Vault.',
      );
    }

    if (envelope.targetDeviceId != local.deviceId) {
      throw StateError(
        'Envelope pertence a outro dispositivo.',
      );
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

    final imported = await _masterKeyPort.hasMasterKey(
      vaultId: envelope.vaultId,
    );

    if (!imported) {
      throw StateError(
        'Master Key não ficou disponível após a importação. '
        'Por segurança o envelope já foi consumido; '
        'inicie uma nova recuperação.',
      );
    }

    return true;
  }

  Future<void> revokeDevice({
    required String vaultId,
    required String targetDeviceId,
  }) async {
    final cleanVaultId = vaultId.trim();
    final cleanTargetDeviceId = targetDeviceId.trim();

    if (cleanVaultId.isEmpty ||
        cleanTargetDeviceId.isEmpty) {
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
      authorizationSecretBase64:
          local.authorizationSecretBase64,
    );

    if (!currentAuthorized) {
      throw StateError(
        'Este dispositivo não está autorizado a revogar outro.',
      );
    }

    final target = await _remote.getDevice(
      vaultId: cleanVaultId,
      requesterDeviceId: local.deviceId,
      requesterAuthorizationSecretBase64:
          local.authorizationSecretBase64,
      targetDeviceId: cleanTargetDeviceId,
    );

    if (target == null) {
      throw StateError(
        'Dispositivo alvo não encontrado.',
      );
    }

    if (target.isRevoked) {
      return;
    }

    await _remote.revokeDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64:
          local.authorizationSecretBase64,
      targetDeviceId: cleanTargetDeviceId,
    );
  }

  Future<BrainDeviceLocalSecrets> _requireLocalSecrets() async {
    final local = await _identityService.loadLocalSecrets();

    if (local == null) {
      throw StateError(
        'Identidade local de dispositivo inexistente.',
      );
    }

    return local;
  }
}
