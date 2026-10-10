import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/devices/models/brain_device_record.dart';
import '../../study/brain/devices/security/brain_device_crypto_service.dart';
import '../../study/brain/devices/security/brain_device_local_secrets.dart';
import '../../study/brain/devices/services/brain_device_supabase_service.dart';
import '../../study/brain/security/crypto/brain_secure_random.dart';
import '../../study/brain/security/models/brain_key_bundle.dart';
import '../../study/brain/vault/services/brain_vault_id_service.dart';
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

class WebBrainVaultResolution {
  const WebBrainVaultResolution({
    required this.vaultId,
    required this.canBootstrap,
  });

  final String vaultId;
  final bool canBootstrap;
}

class WebBrainBootstrapResult {
  const WebBrainBootstrapResult({
    required this.state,
    required this.firstDeviceBootstrap,
  });

  final WebBrainDeviceState state;
  final bool firstDeviceBootstrap;

  bool get ready => state.ready;
}

/// Identidade/autorização do Cérebro no navegador.
///
/// Fase 1 multiplataforma:
/// - Web pode ser o primeiro dispositivo;
/// - Vault existente nunca recebe nova Master Key automaticamente;
/// - backend continua sendo a fonte da verdade da autorização;
/// - Master Key é gerada localmente com CSPRNG;
/// - devices seguintes continuam pending + envelope.
class WebBrainDeviceService {
  WebBrainDeviceService({
    SupabaseClient? client,
    WebBrainSecureStorage? storage,
    BrainDeviceCryptoService? crypto,
    BrainSecureRandom? secureRandom,
    BrainVaultIdService? vaultIds,
  }) : _client = client ?? Supabase.instance.client,
       storage = storage ?? WebBrainSecureStorage(),
       _crypto = crypto ?? BrainDeviceCryptoService(),
       _secureRandom = secureRandom ?? BrainSecureRandom(),
       _vaultIds = vaultIds ?? BrainVaultIdService() {
    _remote = BrainDeviceSupabaseService(client: _client);
  }

  final SupabaseClient _client;
  final WebBrainSecureStorage storage;
  final BrainDeviceCryptoService _crypto;
  final BrainSecureRandom _secureRandom;
  final BrainVaultIdService _vaultIds;
  late final BrainDeviceSupabaseService _remote;

  void _requireAuth() {
    if (_client.auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
  }

  Future<String?> discoverVaultId() async {
    _requireAuth();

    final result = await _client.rpc('discover_brain_vault');

    if (result == null) {
      return null;
    }

    final value = result.toString().trim();

    if (value.isEmpty) {
      return null;
    }

    await storage.saveVaultId(value);
    return value;
  }

  Future<WebBrainVaultResolution> _claimVault() async {
    _requireAuth();

    final discovered = await discoverVaultId();
    final locallySaved = await storage.loadVaultId();

    final proposed =
        discovered ??
        locallySaved ??
        _vaultIds.generateVaultId();

    final result = await _client.rpc(
      'claim_brain_vault',
      params: <String, dynamic>{
        'p_proposed_vault_id': proposed,
      },
    );

    if (result is! Map) {
      throw const FormatException(
        'Resposta inválida ao resolver o Vault do Cérebro.',
      );
    }

    final map = Map<String, dynamic>.from(result);
    final vaultId = map['vault_id']?.toString().trim() ?? '';
    final canBootstrap = map['can_bootstrap'] == true;

    if (vaultId.isEmpty) {
      throw const FormatException(
        'O backend não retornou um Vault válido para o Cérebro.',
      );
    }

    await storage.saveVaultId(vaultId);

    return WebBrainVaultResolution(
      vaultId: vaultId,
      canBootstrap: canBootstrap,
    );
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

  Future<WebBrainBootstrapResult> bootstrapAccess() async {
    final resolution = await _claimVault();
    final vaultId = resolution.vaultId;

    var firstDeviceBootstrap = false;

    if (resolution.canBootstrap) {
      final hasKey = await storage.containsKeyBundle(vaultId: vaultId);

      if (!hasKey) {
        final masterKey = _secureRandom.generateMasterKey();

        if (masterKey.length != BrainKeyBundle.masterKeyLengthBytes) {
          throw StateError(
            'O gerador seguro retornou uma Master Key com tamanho inválido.',
          );
        }

        final bundle = BrainKeyBundle(
          masterKeyBytes: List<int>.unmodifiable(masterKey),
          keyVersion: BrainKeyBundle.initialKeyVersion,
          createdAt: DateTime.now().toUtc(),
        );

        bundle.validate();

        await storage.saveKeyBundle(
          vaultId: vaultId,
          bundle: bundle,
        );

        firstDeviceBootstrap = true;
      }
    }

    var state = await registerOrRefresh(vaultId: vaultId);

    if (state.record.isAuthorized && !state.hasMasterKey) {
      final imported = await tryImportApprovedKey(vaultId: vaultId);

      if (imported) {
        state = WebBrainDeviceState(
          vaultId: state.vaultId,
          localSecrets: state.localSecrets,
          record: state.record,
          hasMasterKey: true,
        );
      }
    }

    return WebBrainBootstrapResult(
      state: state,
      firstDeviceBootstrap: firstDeviceBootstrap,
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
