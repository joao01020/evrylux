import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/devices/models/brain_device_record.dart';
import '../../study/brain/devices/security/brain_device_crypto_service.dart';
import '../../study/brain/devices/services/brain_device_supabase_service.dart';
import 'web_brain_secure_storage.dart';

class WebBrainDeviceManagementService {
  WebBrainDeviceManagementService({
    required WebBrainSecureStorage storage,
    SupabaseClient? client,
    BrainDeviceCryptoService? crypto,
  }) : _storage = storage,
       _client = client ?? Supabase.instance.client,
       _crypto = crypto ?? BrainDeviceCryptoService() {
    _remote = BrainDeviceSupabaseService(client: _client);
  }

  final WebBrainSecureStorage _storage;
  final SupabaseClient _client;
  final BrainDeviceCryptoService _crypto;
  late final BrainDeviceSupabaseService _remote;

  void _requireAuth() {
    if (_client.auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
  }

  Future<String> currentDeviceId() async {
    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    return local.deviceId;
  }

  Future<List<BrainDeviceRecord>> listDevices({required String vaultId}) async {
    _requireAuth();

    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    final authorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!authorized) {
      throw StateError(
        'Este navegador não está autorizado a gerenciar o Cérebro.',
      );
    }

    final devices = await _remote.listDevices(
      vaultId: cleanVaultId,
      requesterDeviceId: local.deviceId,
      requesterAuthorizationSecretBase64: local.authorizationSecretBase64,
    );

    return List<BrainDeviceRecord>.unmodifiable(devices);
  }

  Future<Map<String, String>> listCustomNames({required String vaultId}) async {
    _requireAuth();

    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    try {
      final result = await _client.rpc(
        'list_brain_device_custom_names',
        params: <String, dynamic>{
          'p_vault_id': cleanVaultId,
          'p_requester_device_id': local.deviceId,
          'p_requester_secret': local.authorizationSecretBase64,
        },
      );

      if (result is! List) {
        return const <String, String>{};
      }

      final names = <String, String>{};

      for (final raw in result) {
        if (raw is! Map) {
          continue;
        }

        final row = Map<String, dynamic>.from(raw);
        final deviceId = row['device_id']?.toString().trim() ?? '';
        final customName = row['custom_name']?.toString().trim() ?? '';

        if (deviceId.isNotEmpty && customName.isNotEmpty) {
          names[deviceId] = customName;
        }
      }

      return Map<String, String>.unmodifiable(names);
    } on PostgrestException {
      return const <String, String>{};
    }
  }

  Future<String> renameDevice({
    required String vaultId,
    required String targetDeviceId,
    required String newName,
  }) async {
    _requireAuth();

    final cleanVaultId = vaultId.trim();
    final cleanTarget = targetDeviceId.trim();
    final cleanName = newName.trim();

    if (cleanVaultId.isEmpty ||
        cleanTarget.isEmpty ||
        cleanName.length < 2 ||
        cleanName.length > 80) {
      throw ArgumentError('Dados inválidos para renomear o dispositivo.');
    }

    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    final authorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!authorized) {
      throw StateError(
        'Este navegador não está autorizado a renomear dispositivos.',
      );
    }

    final result = await _client.rpc(
      'rename_brain_device',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_requester_device_id': local.deviceId,
        'p_requester_secret': local.authorizationSecretBase64,
        'p_target_device_id': cleanTarget,
        'p_device_name': cleanName,
      },
    );

    final saved = result?.toString().trim() ?? '';

    return saved.isEmpty ? cleanName : saved;
  }

  Future<void> approvePendingDevice({
    required String vaultId,
    required BrainDeviceRecord target,
    required String expectedFingerprint,
  }) async {
    _requireAuth();

    final cleanVaultId = vaultId.trim();
    final expected = expectedFingerprint.trim().toUpperCase();

    if (cleanVaultId.isEmpty || expected.isEmpty) {
      throw ArgumentError('Vault e fingerprint precisam ser informados.');
    }

    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    if (local.deviceId == target.deviceId) {
      throw StateError('Um dispositivo não pode aprovar a si mesmo.');
    }

    final authorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!authorized) {
      throw StateError(
        'Este navegador não está autorizado a aprovar outro dispositivo.',
      );
    }

    final freshTarget = await _remote.getDevice(
      vaultId: cleanVaultId,
      requesterDeviceId: local.deviceId,
      requesterAuthorizationSecretBase64: local.authorizationSecretBase64,
      targetDeviceId: target.deviceId,
    );

    if (freshTarget == null) {
      throw StateError('Dispositivo pendente não encontrado.');
    }

    if (!freshTarget.isPending) {
      throw StateError('Este dispositivo não está mais pendente.');
    }

    if (freshTarget.isRecoveryExpired) {
      throw StateError(
        'A solicitação de autorização expirou. '
        'Abra novamente o Cérebro no novo dispositivo.',
      );
    }

    final stored = freshTarget.keyFingerprint.trim().toUpperCase();

    if (expected != stored) {
      throw StateError(
        'O fingerprint informado não corresponde ao dispositivo.',
      );
    }

    final computed = await _crypto.fingerprintPublicKey(
      base64Url.decode(base64Url.normalize(freshTarget.publicKeyBase64)),
    );

    if (computed.toUpperCase() != stored) {
      throw StateError(
        'A chave pública do dispositivo não corresponde ao fingerprint.',
      );
    }

    final requestId = freshTarget.recoveryRequestId?.trim() ?? '';
    final expiresAt = freshTarget.recoveryExpiresAt;

    if (requestId.isEmpty || expiresAt == null) {
      throw StateError('A solicitação pendente não possui binding válido.');
    }

    final bundle = await _storage.loadKeyBundle(vaultId: cleanVaultId);

    if (bundle == null) {
      throw StateError(
        'A Master Key do Cérebro não está disponível neste navegador.',
      );
    }

    bundle.validate();

    final envelope = await _crypto.wrapMasterKey(
      sender: local,
      targetDeviceId: freshTarget.deviceId,
      targetPublicKeyBase64: freshTarget.publicKeyBase64,
      targetKeyFingerprint: stored,
      recoveryRequestId: requestId,
      recoveryExpiresAt: expiresAt,
      vaultId: cleanVaultId,
      keyVersion: bundle.keyVersion,
      masterKeyBytes: bundle.masterKeyBytes,
    );

    await _remote.approveDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64: local.authorizationSecretBase64,
      targetDeviceId: freshTarget.deviceId,
      envelope: envelope,
    );
  }

  Future<void> revokeDevice({
    required String vaultId,
    required BrainDeviceRecord target,
  }) async {
    _requireAuth();

    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError('Identidade local deste navegador não está disponível.');
    }

    if (local.deviceId == target.deviceId) {
      throw StateError('Este dispositivo não pode ser revogado por esta tela.');
    }

    if (target.isRevoked) {
      return;
    }

    final authorized = await _remote.isAuthorized(
      vaultId: cleanVaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );

    if (!authorized) {
      throw StateError(
        'Este navegador não está autorizado a revogar outro dispositivo.',
      );
    }

    await _remote.revokeDevice(
      vaultId: cleanVaultId,
      approverDeviceId: local.deviceId,
      approverAuthorizationSecretBase64: local.authorizationSecretBase64,
      targetDeviceId: target.deviceId,
    );
  }
}
