import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/devices/models/brain_device_record.dart';
import '../../study/brain/devices/security/brain_device_crypto_service.dart';
import '../../study/brain/devices/security/brain_device_local_secrets.dart';
import '../../study/brain/devices/services/brain_device_supabase_service.dart';
import '../../study/brain/security/models/brain_key_bundle.dart';
import 'web_brain_secure_storage.dart';

class WebBrainDeviceState {
  const WebBrainDeviceState({
    required this.vaultId,
    required this.localSecrets,
    required this.record,
    required this.hasMasterKey,
  });

  final String vaultId;
  final BrainDeviceLocalSecrets localSecrets;
  final BrainDeviceRecord record;
  final bool hasMasterKey;

  bool get ready => record.isAuthorized && hasMasterKey;
}

/// Identidade/autorização do Cérebro no navegador.
///
/// Regra final:
/// - autorização NÃO expira localmente por tempo;
/// - em toda entrada, consulta o backend;
/// - se o device continuar autorizado, reutiliza a mesma identidade e chave;
/// - se estiver pending, mantém o mesmo fingerprint;
/// - se estiver revogado, descarta a identidade revogada e cria uma nova.
class WebBrainDeviceService {
  WebBrainDeviceService({
    SupabaseClient? client,
    WebBrainSecureStorage? storage,
    BrainDeviceCryptoService? crypto,
  })  : _client = client ?? Supabase.instance.client,
        storage = storage ?? WebBrainSecureStorage(),
        _crypto = crypto ?? BrainDeviceCryptoService() {
    _remote = BrainDeviceSupabaseService(client: _client);
  }

  final SupabaseClient _client;
  final WebBrainSecureStorage storage;
  final BrainDeviceCryptoService _crypto;
  late final BrainDeviceSupabaseService _remote;

  Future<String?> discoverVaultId() async {
    final saved = await storage.loadVaultId();
    if (saved != null) {
      return saved;
    }

    final rows = await _client
        .from('brain_objects')
        .select('vault_id')
        .order('updated_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first['vault_id']?.toString().trim() ?? '';
    if (value.isEmpty) {
      return null;
    }

    await storage.saveVaultId(value);
    return value;
  }

  Future<BrainDeviceLocalSecrets> getOrCreateLocalDevice() async {
    final existing = await storage.loadDevice();
    if (existing != null) {
      return existing;
    }

    final created = await _crypto.generateLocalSecrets(
      deviceName: 'EVRYLUX Web',
    );

    await storage.saveDevice(created);
    return created;
  }

  Future<bool> hasLocalMasterKey({
    required String vaultId,
  }) {
    return storage.containsKeyBundle(vaultId: vaultId);
  }

  /// Apenas verifica o estado remoto.
  ///
  /// Não altera identidade/chaves locais em caso de erro de rede.
  Future<bool> isAuthorized({
    required String vaultId,
  }) async {
    final local = await storage.loadDevice();
    if (local == null) {
      return false;
    }

    return _remote.isAuthorized(
      vaultId: vaultId,
      deviceId: local.deviceId,
      authorizationSecretBase64: local.authorizationSecretBase64,
    );
  }

  /// Garante uma solicitação válida para um dispositivo ainda não autorizado.
  ///
  /// Pending existente é reutilizado. Revogado gera nova identidade.
  Future<WebBrainDeviceState> registerOrRefresh({
    required String vaultId,
  }) async {
    final cleanVaultId = vaultId.trim();
    if (cleanVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    await storage.saveVaultId(cleanVaultId);

    var local = await getOrCreateLocalDevice();
    BrainDeviceRecord record;

    try {
      record = await _remote.registerDevice(
        vaultId: cleanVaultId,
        localSecrets: local,
      );
    } on PostgrestException catch (error) {
      final message = error.message.toLowerCase();

      if (!message.contains('device_revoked')) {
        rethrow;
      }

      // Revogação é a única situação em que o navegador perde a identidade
      // autorizada e deve apresentar um novo fingerprint.
      await storage.deleteKeyBundle(vaultId: cleanVaultId);
      await storage.clearTrustedAccess(vaultId: cleanVaultId);
      await storage.clearDevice();

      local = await _crypto.generateLocalSecrets(
        deviceName: 'EVRYLUX Web',
      );

      await storage.saveDevice(local);
      await storage.saveVaultId(cleanVaultId);

      record = await _remote.registerDevice(
        vaultId: cleanVaultId,
        localSecrets: local,
      );
    }

    final hasMasterKey = await storage.containsKeyBundle(
      vaultId: cleanVaultId,
    );

    return WebBrainDeviceState(
      vaultId: cleanVaultId,
      localSecrets: local,
      record: record,
      hasMasterKey: hasMasterKey,
    );
  }

  Future<bool> tryImportApprovedKey({
    required String vaultId,
  }) async {
    final local = await storage.loadDevice();
    if (local == null) {
      throw StateError('Identidade Web inexistente.');
    }

    final envelope = await _remote.claimPendingEnvelope(
      vaultId: vaultId,
      targetDeviceId: local.deviceId,
      targetAuthorizationSecretBase64:
          local.authorizationSecretBase64,
    );

    if (envelope == null) {
      return false;
    }

    final masterKey = await _crypto.unwrapMasterKey(
      target: local,
      envelope: envelope,
    );

    await storage.saveKeyBundle(
      vaultId: vaultId,
      bundle: BrainKeyBundle(
        masterKeyBytes: masterKey,
        keyVersion: envelope.keyVersion,
        createdAt: DateTime.now().toUtc(),
      ),
    );

    return true;
  }
}
