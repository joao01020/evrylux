import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrainRecoveryFileAuthorizationService {
  BrainRecoveryFileAuthorizationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> registerVerifier({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
    required String deviceId,
    required String authorizationSecretBase64,
  }) async {
    _requireAuth();

    final cleanVaultId = _required(vaultId, 'vaultId');
    final cleanDeviceId = _required(deviceId, 'deviceId');
    final cleanSecret = _required(
      authorizationSecretBase64,
      'authorizationSecret',
    );

    _validateKey(keyVersion: keyVersion, masterKeyBytes: masterKeyBytes);

    final authorized = await _client.rpc(
      'brain_device_is_authorized',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': cleanDeviceId,
        'p_auth_secret': cleanSecret,
      },
    );

    if (authorized != true) {
      throw StateError(
        'Somente um dispositivo autorizado pode gerar uma '
        'chave de recuperação.',
      );
    }

    final proofHex = await _proofHex(
      vaultId: cleanVaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKeyBytes,
    );

    final saved = await _client.rpc(
      'save_brain_recovery_file_verifier',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': cleanDeviceId,
        'p_auth_secret': cleanSecret,
        'p_key_version': keyVersion,
        'p_proof_hex': proofHex,
      },
    );

    if (saved != true) {
      throw StateError('O servidor não confirmou a chave de recuperação.');
    }
  }

  Future<void> authorizeCurrentDevice({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
    required String deviceId,
    required String authorizationSecretBase64,
  }) async {
    _requireAuth();

    final cleanVaultId = _required(vaultId, 'vaultId');
    final cleanDeviceId = _required(deviceId, 'deviceId');
    final cleanSecret = _required(
      authorizationSecretBase64,
      'authorizationSecret',
    );

    _validateKey(keyVersion: keyVersion, masterKeyBytes: masterKeyBytes);

    final proofHex = await _proofHex(
      vaultId: cleanVaultId,
      keyVersion: keyVersion,
      masterKeyBytes: masterKeyBytes,
    );

    final authorized = await _client.rpc(
      'authorize_brain_device_with_recovery_file',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': cleanDeviceId,
        'p_auth_secret': cleanSecret,
        'p_key_version': keyVersion,
        'p_proof_hex': proofHex,
      },
    );

    if (authorized != true) {
      throw StateError(
        'Não foi possível autorizar este dispositivo com o arquivo .evkey.',
      );
    }
  }

  Future<String> _proofHex({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(
        'EVRYLUX_BRAIN_RECOVERY_FILE_PROOF_V1|'
        '$vaultId|$keyVersion',
      ),
      secretKey: SecretKey(masterKeyBytes),
    );

    return mac.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  void _validateKey({
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) {
    if (keyVersion <= 0 || masterKeyBytes.length != 32) {
      throw ArgumentError('Master Key inválida para recuperação.');
    }
  }

  String _required(String value, String name) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('$name não pode ser vazio.');
    }

    return clean;
  }

  void _requireAuth() {
    if (_client.auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
  }
}
