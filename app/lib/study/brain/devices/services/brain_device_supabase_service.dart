import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_device_key_envelope.dart';
import '../models/brain_device_record.dart';
import '../ports/brain_device_remote_port.dart';
import '../security/brain_device_local_secrets.dart';

class BrainDeviceSupabaseService implements BrainDeviceRemotePort {
  BrainDeviceSupabaseService({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  void _requireAuth() {
    if (_client.auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
  }

  @override
  Future<BrainDeviceRecord> registerDevice({
    required String vaultId,
    required BrainDeviceLocalSecrets localSecrets,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'register_brain_device',
      params: {
        'p_device_id': localSecrets.deviceId,
        'p_vault_id': vaultId,
        'p_device_name': localSecrets.deviceName,
        'p_public_key_b64': localSecrets.publicKeyBase64,
        'p_key_fingerprint': localSecrets.keyFingerprint,
        'p_auth_secret': localSecrets.authorizationSecretBase64,
      },
    );

    if (result is! Map) {
      throw const FormatException(
        'Resposta inválida ao registrar dispositivo.',
      );
    }

    return BrainDeviceRecord.fromMap(
      Map<String, dynamic>.from(result),
    );
  }

  @override
  Future<List<BrainDeviceRecord>> listDevices({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'list_brain_devices',
      params: {
        'p_vault_id': vaultId,
        'p_requester_device_id': requesterDeviceId,
        'p_requester_secret': requesterAuthorizationSecretBase64,
      },
    );

    if (result == null) {
      return const <BrainDeviceRecord>[];
    }

    if (result is! List) {
      throw const FormatException(
        'Lista remota de dispositivos inválida.',
      );
    }

    return result
        .map(
          (row) => BrainDeviceRecord.fromMap(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(
          growable: false,
        );
  }

  @override
  Future<BrainDeviceRecord?> getDevice({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
    required String targetDeviceId,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'get_brain_device',
      params: {
        'p_vault_id': vaultId,
        'p_requester_device_id': requesterDeviceId,
        'p_requester_secret': requesterAuthorizationSecretBase64,
        'p_target_device_id': targetDeviceId,
      },
    );

    if (result == null) {
      return null;
    }

    if (result is! Map) {
      throw const FormatException(
        'Dispositivo remoto inválido.',
      );
    }

    return BrainDeviceRecord.fromMap(
      Map<String, dynamic>.from(result),
    );
  }

  @override
  Future<bool> isAuthorized({
    required String vaultId,
    required String deviceId,
    required String authorizationSecretBase64,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'brain_device_is_authorized',
      params: {
        'p_vault_id': vaultId,
        'p_device_id': deviceId,
        'p_auth_secret': authorizationSecretBase64,
      },
    );

    return result == true;
  }

  @override
  Future<void> approveDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
    required BrainDeviceKeyEnvelope envelope,
  }) async {
    _requireAuth();

    await _client.rpc(
      'approve_brain_device',
      params: {
        'p_vault_id': vaultId,
        'p_approver_device_id': approverDeviceId,
        'p_approver_secret': approverAuthorizationSecretBase64,
        'p_target_device_id': targetDeviceId,
        'p_envelope': envelope.toMap(),
      },
    );
  }

  @override
  Future<void> revokeDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
  }) async {
    _requireAuth();

    await _client.rpc(
      'revoke_brain_device',
      params: {
        'p_vault_id': vaultId,
        'p_approver_device_id': approverDeviceId,
        'p_approver_secret': approverAuthorizationSecretBase64,
        'p_target_device_id': targetDeviceId,
      },
    );
  }

  @override
  Future<BrainDeviceKeyEnvelope?> claimPendingEnvelope({
    required String vaultId,
    required String targetDeviceId,
    required String targetAuthorizationSecretBase64,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'claim_brain_device_envelope',
      params: {
        'p_vault_id': vaultId,
        'p_target_device_id': targetDeviceId,
        'p_target_secret': targetAuthorizationSecretBase64,
      },
    );

    if (result == null) {
      return null;
    }

    if (result is! Map) {
      throw const FormatException(
        'Envelope remoto inválido.',
      );
    }

    return BrainDeviceKeyEnvelope.fromMap(
      Map<String, dynamic>.from(result),
    );
  }
}
