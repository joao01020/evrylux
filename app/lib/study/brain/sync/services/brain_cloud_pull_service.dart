import '../../security/crypto/brain_crypto_service.dart';
import '../../security/keys/brain_key_service.dart';

import '../../vault/models/brain_vault_object.dart';
import '../../vault/services/brain_vault_serializer.dart';
import '../../vault/services/brain_vault_service.dart';
import '../../vault/storage/brain_vault_storage.dart';

import '../models/brain_cloud_pull_result.dart';
import '../ports/brain_remote_object_source.dart';

// ============================================================
// BRAIN CLOUD PULL SERVICE
// ============================================================
//
// Faz download de .evobj criptografados.
//
// Antes de substituir o arquivo local:
//
// 1. valida estrutura;
// 2. compara versão;
// 3. valida AEAD/binding com a Master Key local;
// 4. somente então persiste.
//
// Isso evita gravar ciphertext remoto corrompido no Vault.
//
// ============================================================

class BrainCloudPullService {
  BrainCloudPullService({
    required BrainRemoteObjectSource remote,
    required BrainVaultService vaultService,
    required BrainVaultStorage vaultStorage,
    required BrainKeyService keyService,
    BrainCryptoService? cryptoService,
    BrainVaultSerializer? serializer,
  }) : _remote = remote,
       _vaultService = vaultService,
       _vaultStorage = vaultStorage,
       _keyService = keyService,
       _cryptoService = cryptoService ?? BrainCryptoService(),
       _serializer = serializer ?? const BrainVaultSerializer();

  final BrainRemoteObjectSource _remote;
  final BrainVaultService _vaultService;
  final BrainVaultStorage _vaultStorage;
  final BrainKeyService _keyService;
  final BrainCryptoService _cryptoService;
  final BrainVaultSerializer _serializer;

  // ============================================================
  // PULL CURRENT VAULT
  // ============================================================

  Future<BrainCloudPullResult> pullCurrentVault() async {
    final manifest = await _vaultService.openVault();

    final remoteObjects = await _remote.loadVaultObjects(
      vaultId: manifest.vaultId,
    );

    var applied = 0;
    var skippedSameVersion = 0;
    var skippedNewerLocal = 0;

    for (final remotePayload in remoteObjects) {
      if (remotePayload.vaultId != manifest.vaultId) {
        throw const FormatException('Objeto remoto pertence a outro Vault.');
      }

      final remoteObject = remotePayload.toVaultObject(serializer: _serializer);

      final localObject = await _vaultStorage.loadObject(
        remoteObject.header.objectId,
      );

      if (localObject != null) {
        final localVersion = localObject.header.objectVersion.value;

        final remoteVersion = remoteObject.header.objectVersion.value;

        if (localVersion > remoteVersion) {
          skippedNewerLocal++;
          continue;
        }

        if (localVersion == remoteVersion) {
          skippedSameVersion++;
          continue;
        }
      }

      await _validateRemoteObjectAuthenticity(remoteObject);

      await _vaultStorage.saveObject(remoteObject);

      applied++;
    }

    if (applied > 0) {
      final currentManifest = await _vaultStorage.loadManifest();

      if (currentManifest == null) {
        throw StateError('Manifest não encontrado após pull.');
      }

      await _vaultStorage.saveManifest(currentManifest.touch());
    }

    return BrainCloudPullResult(
      vaultId: manifest.vaultId,
      remoteCount: remoteObjects.length,
      applied: applied,
      skippedSameVersion: skippedSameVersion,
      skippedNewerLocal: skippedNewerLocal,
    );
  }

  // ============================================================
  // AUTHENTICATE REMOTE OBJECT
  // ============================================================

  Future<void> _validateRemoteObjectAuthenticity(
    BrainVaultObject object,
  ) async {
    object.header.validate();

    if (object.isDeleted) {
      final tombstone = object.tombstone;

      if (tombstone == null) {
        throw const FormatException('Objeto remoto excluído sem tombstone.');
      }

      if (tombstone.objectId != object.header.objectId ||
          tombstone.vaultId != object.header.vaultId ||
          tombstone.objectVersion.value != object.header.objectVersion.value) {
        throw const FormatException(
          'Tombstone remoto não corresponde ao header.',
        );
      }

      return;
    }

    final encryptedPayload = object.encryptedPayload;

    if (encryptedPayload == null) {
      throw const FormatException(
        'Objeto remoto ativo sem payload criptografado.',
      );
    }

    final key = await _keyService.requireKeyBundle(
      vaultId: object.header.vaultId,
    );

    if (key.keyVersion != object.header.keyVersion) {
      throw StateError(
        'A versão da Master Key local não abre '
        'o objeto remoto.',
      );
    }

    final plaintext = await _cryptoService.decryptString(
      payload: encryptedPayload,
      keyBundle: key,
    );

    final decoded = _serializer.deserializeLogicalPayload(plaintext);

    _serializer.verifyBinding(header: object.header, decoded: decoded);
  }
}
