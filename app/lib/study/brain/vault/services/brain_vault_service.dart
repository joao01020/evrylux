import '../../security/crypto/brain_crypto_service.dart';
import '../../security/keys/brain_key_service.dart';
import '../../security/models/brain_crypto_version.dart';
import '../../security/models/brain_key_bundle.dart';
import '../models/brain_vault_manifest.dart';
import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_header.dart';
import '../models/brain_vault_object_type.dart';
import '../models/brain_vault_object_version.dart';
import '../models/brain_vault_tombstone.dart';
import '../storage/brain_vault_storage.dart';
import 'brain_vault_id_service.dart';
import 'brain_vault_serializer.dart';

// ============================================================
// BRAIN VAULT SERVICE
// ============================================================
//
// Orquestrador principal do Vault local criptografado.
//
// Fluxo:
//
// data
// ↓
// serializer
// ↓
// BrainCryptoService
// ↓
// BrainVaultObject
// ↓
// BrainVaultStorage
//
// IMPORTANTE:
//
// Este service:
//
// - não conhece UI;
// - não conhece Supabase;
// - não conhece SyncQueue;
// - não conhece BrainStorage legado.
//
// ============================================================

class BrainVaultService {
  BrainVaultService({
    required BrainKeyService keyService,
    BrainCryptoService? cryptoService,
    BrainVaultStorage? storage,
    BrainVaultIdService? idService,
    BrainVaultSerializer? serializer,
  }) : _keyService =
           keyService,
       _cryptoService =
           cryptoService ??
           BrainCryptoService(),
       _idService =
           idService ??
           BrainVaultIdService(),
       _serializer =
           serializer ??
           const BrainVaultSerializer(),
       _storage =
           storage ??
           BrainVaultStorage();

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainKeyService _keyService;

  final BrainCryptoService _cryptoService;

  final BrainVaultStorage _storage;

  final BrainVaultIdService _idService;

  final BrainVaultSerializer _serializer;

  // ============================================================
  // INITIALIZE / CREATE VAULT
  // ============================================================

  Future<
    BrainVaultManifest
  >
  createVault({
    String? vaultId,
  }) async {
    await _storage.initialize();

    final existing = await _storage.loadManifest();

    if (existing !=
        null) {
      throw StateError(
        'Já existe um Vault inicializado neste armazenamento.',
      );
    }

    final resolvedVaultId =
        vaultId?.trim().isNotEmpty ==
            true
        ? vaultId!.trim()
        : _idService.generateVaultId();

    if (!_idService.isValidVaultId(
      resolvedVaultId,
    )) {
      throw ArgumentError(
        'vaultId inválido.',
      );
    }

    BrainKeyBundle? createdKey;

    try {
      createdKey = await _keyService.getOrCreateKeyBundle(
        vaultId: resolvedVaultId,
      );

      final manifest = BrainVaultManifest.create(
        vaultId: resolvedVaultId,
        keyVersion: createdKey.keyVersion,
      );

      await _storage.saveManifest(
        manifest,
      );

      return manifest;
    } catch (
      error
    ) {
      // Se o manifest não chegou a ser criado, evitamos deixar
      // uma chave órfã criada especificamente nesta operação.
      if (createdKey !=
          null) {
        final manifestExists = await _storage.hasManifest();

        if (!manifestExists) {
          try {
            await _keyService.deleteKeyBundle(
              vaultId: resolvedVaultId,
            );
          } catch (
            _
          ) {
            // Não mascarar o erro original.
          }
        }
      }

      rethrow;
    }
  }

  // ============================================================
  // LOAD LOCAL MANIFEST
  // ============================================================
  //
  // Lê somente a identidade local do Vault.
  //
  // Diferente de openVault(), este método NÃO exige que a
  // Master Key já esteja presente. Isso é necessário durante
  // Recovery Device: o manifest pode existir antes da importação
  // da chave, ou ainda não existir no novo computador.
  //
  // ============================================================

  Future<BrainVaultManifest?> loadLocalManifest() async {
    await _storage.initialize();

    final manifest = await _storage.loadManifest();

    if (manifest != null) {
      manifest.validate();
    }

    return manifest;
  }

  // ============================================================
  // OPEN VAULT
  // ============================================================

  Future<
    BrainVaultManifest
  >
  openVault() async {
    await _storage.initialize();

    final manifest = await _storage.loadManifest();

    if (manifest ==
        null) {
      throw StateError(
        'Nenhum Vault foi inicializado.',
      );
    }

    manifest.validate();

    final key = await _keyService.requireKeyBundle(
      vaultId: manifest.vaultId,
    );

    _validateKeyAgainstManifest(
      key: key,
      manifest: manifest,
    );

    return manifest;
  }

  // ============================================================
  // GET OR CREATE VAULT
  // ============================================================

  Future<
    BrainVaultManifest
  >
  getOrCreateVault() async {
    await _storage.initialize();

    final existing = await _storage.loadManifest();

    if (existing !=
        null) {
      return openVault();
    }

    return createVault();
  }

  // ============================================================
  // SAVE NEW OBJECT
  // ============================================================

  Future<
    BrainVaultObject
  >
  createObject({
    required BrainVaultObjectType type,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final manifest = await openVault();

    final key = await _keyService.requireKeyBundle(
      vaultId: manifest.vaultId,
    );

    final objectId = _idService.generateObjectId();

    final now = DateTime.now().toUtc();

    final header = BrainVaultObjectHeader(
      objectId: objectId,
      vaultId: manifest.vaultId,
      objectVersion: BrainVaultObjectVersion.initial,
      cryptoVersion: BrainCryptoVersion.current,
      keyVersion: key.keyVersion,
      createdAt: now,
      updatedAt: now,
    );

    final object = await _buildEncryptedObject(
      header: header,
      type: type,
      data: data,
      key: key,
    );

    await _storage.saveObject(
      object,
    );

    await _touchManifest(
      manifest,
    );

    return object;
  }

  // ============================================================
  // UPDATE OBJECT
  // ============================================================

  Future<
    BrainVaultObject
  >
  updateObject({
    required String objectId,
    required BrainVaultObjectType type,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final manifest = await openVault();

    final existing = await _storage.loadObject(
      objectId,
    );

    if (existing ==
        null) {
      throw StateError(
        'Objeto do Vault não encontrado.',
      );
    }

    _validateObjectBelongsToVault(
      object: existing,
      manifest: manifest,
    );

    if (existing.isDeleted) {
      throw StateError(
        'Objeto excluído não pode ser atualizado diretamente.',
      );
    }

    final key = await _keyService.requireKeyBundle(
      vaultId: manifest.vaultId,
    );

    final nextHeader = existing.header.copyWith(
      objectVersion: existing.header.objectVersion.next(),
      cryptoVersion: BrainCryptoVersion.current,
      keyVersion: key.keyVersion,
      updatedAt: DateTime.now().toUtc(),
    );

    final updated = await _buildEncryptedObject(
      header: nextHeader,
      type: type,
      data: data,
      key: key,
    );

    await _storage.saveObject(
      updated,
    );

    await _touchManifest(
      manifest,
    );

    return updated;
  }

  // ============================================================
  // READ OBJECT
  // ============================================================

  Future<
    BrainVaultDecodedPayload?
  >
  readObject(
    String objectId,
  ) async {
    final manifest = await openVault();

    final object = await _storage.loadObject(
      objectId,
    );

    if (object ==
        null) {
      return null;
    }

    _validateObjectBelongsToVault(
      object: object,
      manifest: manifest,
    );

    if (object.isDeleted) {
      return null;
    }

    final payload = object.encryptedPayload;

    if (payload ==
        null) {
      throw const FormatException(
        'Objeto ativo não possui payload criptografado.',
      );
    }

    final key = await _keyService.requireKeyBundle(
      vaultId: manifest.vaultId,
    );

    if (object.header.keyVersion !=
        key.keyVersion) {
      throw StateError(
        'A versão da chave necessária para este objeto '
        'não está disponível.',
      );
    }

    final plaintext = await _cryptoService.decryptString(
      payload: payload,
      keyBundle: key,
    );

    final decoded = _serializer.deserializeLogicalPayload(
      plaintext,
    );

    _serializer.verifyBinding(
      header: object.header,
      decoded: decoded,
    );

    return decoded;
  }

  // ============================================================
  // DELETE OBJECT
  // ============================================================

  Future<
    BrainVaultObject
  >
  deleteObject(
    String objectId,
  ) async {
    final manifest = await openVault();

    final existing = await _storage.loadObject(
      objectId,
    );

    if (existing ==
        null) {
      throw StateError(
        'Objeto do Vault não encontrado.',
      );
    }

    _validateObjectBelongsToVault(
      object: existing,
      manifest: manifest,
    );

    if (existing.isDeleted) {
      return existing;
    }

    final now = DateTime.now().toUtc();

    final nextVersion = existing.header.objectVersion.next();

    final header = existing.header.copyWith(
      objectVersion: nextVersion,
      updatedAt: now,
    );

    final tombstone = BrainVaultTombstone(
      objectId: header.objectId,
      vaultId: header.vaultId,
      objectVersion: header.objectVersion,
      deletedAt: now,
    );

    final deleted = BrainVaultObject.deleted(
      header: header,
      tombstone: tombstone,
    );

    await _storage.saveObject(
      deleted,
    );

    await _touchManifest(
      manifest,
    );

    return deleted;
  }

  // ============================================================
  // LOAD RAW OBJECT
  // ============================================================
  //
  // Útil futuramente para sync sem descriptografar.
  //
  // ============================================================

  Future<
    BrainVaultObject?
  >
  loadEncryptedObject(
    String objectId,
  ) async {
    final manifest = await openVault();

    final object = await _storage.loadObject(
      objectId,
    );

    if (object ==
        null) {
      return null;
    }

    _validateObjectBelongsToVault(
      object: object,
      manifest: manifest,
    );

    return object;
  }

  // ============================================================
  // LOAD ALL RAW OBJECTS
  // ============================================================

  Future<
    List<
      BrainVaultObject
    >
  >
  loadAllEncryptedObjects() async {
    final manifest = await openVault();

    final objects = await _storage.loadAllObjects();

    for (final object in objects) {
      _validateObjectBelongsToVault(
        object: object,
        manifest: manifest,
      );
    }

    return objects;
  }

  // ============================================================
  // BUILD ENCRYPTED OBJECT
  // ============================================================

  Future<
    BrainVaultObject
  >
  _buildEncryptedObject({
    required BrainVaultObjectHeader header,
    required BrainVaultObjectType type,
    required Map<
      String,
      dynamic
    >
    data,
    required BrainKeyBundle key,
  }) async {
    header.validate();

    final serialized = _serializer.serializeLogicalPayload(
      type: type,
      header: header,
      data: data,
    );

    final encrypted = await _cryptoService.encryptString(
      plaintext: serialized,
      keyBundle: key,
    );

    if (encrypted.metadata.version !=
        header.cryptoVersion) {
      throw StateError(
        'Crypto version produzida não corresponde ao header.',
      );
    }

    return BrainVaultObject.active(
      header: header,
      encryptedPayload: encrypted,
    );
  }

  // ============================================================
  // VALIDATE VAULT OWNERSHIP
  // ============================================================

  void _validateObjectBelongsToVault({
    required BrainVaultObject object,
    required BrainVaultManifest manifest,
  }) {
    if (object.header.vaultId !=
        manifest.vaultId) {
      throw const FormatException(
        'Objeto pertence a outro Vault.',
      );
    }
  }

  // ============================================================
  // VALIDATE KEY
  // ============================================================

  void _validateKeyAgainstManifest({
    required BrainKeyBundle key,
    required BrainVaultManifest manifest,
  }) {
    key.validate();

    if (key.keyVersion !=
        manifest.keyVersion) {
      throw StateError(
        'A Master Key disponível não corresponde '
        'à versão esperada pelo Vault.',
      );
    }
  }

  // ============================================================
  // TOUCH MANIFEST
  // ============================================================

  Future<
    void
  >
  _touchManifest(
    BrainVaultManifest manifest,
  ) async {
    final updated = manifest.touch();

    await _storage.saveManifest(
      updated,
    );
  }
}
