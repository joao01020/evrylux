import 'dart:io';

import '../../security/crypto/brain_crypto_service.dart';
import '../../security/keys/brain_key_service.dart';
import '../../security/models/brain_crypto_version.dart';

import '../../vault/models/brain_vault_object.dart';
import '../../vault/models/brain_vault_object_header.dart';
import '../../vault/models/brain_vault_object_version.dart';
import '../../vault/services/brain_vault_id_service.dart';
import '../../vault/services/brain_vault_serializer.dart';
import '../../vault/services/brain_vault_service.dart';
import '../../vault/storage/brain_vault_storage.dart';

import '../exceptions/brain_backup_exception.dart';
import '../models/brain_backup_header.dart';
import '../models/brain_backup_package.dart';
import '../models/brain_backup_restore_result.dart';
import 'brain_backup_compression_service.dart';
import 'brain_backup_serializer.dart';

// ============================================================
// BRAIN BACKUP SERVICE
// ============================================================
//
// FASE 04 — .evbrain
//
// Fluxo de export:
//
// Vault (.evobj já criptografados)
//        ↓
// serializar objetos físicos
//        ↓
// archive JSON
//        ↓
// GZIP
//        ↓
// criptografar novamente com a Master Key do Vault
//        ↓
// .evbrain
//
// A Master Key NÃO entra no .evbrain.
//
// Consequência importante:
//
// nesta Fase 04, o backup pode ser transportado como arquivo,
// mas só pode ser restaurado onde a MESMA Master Key já esteja
// disponível de forma autorizada.
//
// Transferência segura da chave entre dispositivos pertence às
// fases:
//
// 7. Dispositivos autorizados
// 16. Recovery Device
//
// ============================================================

class BrainBackupService {
  BrainBackupService({
    required BrainVaultService vaultService,
    required BrainVaultStorage vaultStorage,
    required BrainKeyService keyService,
    BrainCryptoService? cryptoService,
    BrainVaultSerializer? vaultSerializer,
    BrainBackupSerializer? backupSerializer,
    BrainBackupCompressionService? compressionService,
    BrainVaultIdService? idService,
  }) : _vaultService = vaultService,
       _vaultStorage = vaultStorage,
       _keyService = keyService,
       _cryptoService = cryptoService ?? BrainCryptoService(),
       _vaultSerializer = vaultSerializer ?? const BrainVaultSerializer(),
       _backupSerializer = backupSerializer ?? const BrainBackupSerializer(),
       _compressionService =
           compressionService ?? const BrainBackupCompressionService(),
       _idService = idService ?? BrainVaultIdService();

  final BrainVaultService _vaultService;
  final BrainVaultStorage _vaultStorage;
  final BrainKeyService _keyService;
  final BrainCryptoService _cryptoService;
  final BrainVaultSerializer _vaultSerializer;
  final BrainBackupSerializer _backupSerializer;
  final BrainBackupCompressionService _compressionService;
  final BrainVaultIdService _idService;

  // ============================================================
  // EXPORT TO STRING
  // ============================================================

  Future<String> exportToString() async {
    try {
      final manifest = await _vaultService.openVault();

      final key = await _keyService.requireKeyBundle(vaultId: manifest.vaultId);

      final objects = await _vaultService.loadAllEncryptedObjects();

      final serializedObjects = <String>[];

      for (final object in objects) {
        serializedObjects.add(_vaultSerializer.serializeObject(object));
      }

      final archive = _backupSerializer.serializeArchive(
        vaultId: manifest.vaultId,
        objects: serializedObjects,
      );

      final compressedArchive = _compressionService.compressString(archive);

      final encrypted = await _cryptoService.encryptString(
        plaintext: compressedArchive,
        keyBundle: key,
      );

      final now = DateTime.now().toUtc();

      final wrapperHeader = BrainVaultObjectHeader(
        objectId: _idService.generateObjectId(),
        vaultId: manifest.vaultId,
        objectVersion: BrainVaultObjectVersion.initial,
        cryptoVersion: BrainCryptoVersion.current,
        keyVersion: key.keyVersion,
        createdAt: now,
        updatedAt: now,
      );

      final wrapperObject = BrainVaultObject.active(
        header: wrapperHeader,
        encryptedPayload: encrypted,
      );

      final serializedWrapper = _vaultSerializer.serializeObject(wrapperObject);

      final header = BrainBackupHeader.create(
        vaultId: manifest.vaultId,
        cryptoVersion: manifest.cryptoVersion.value,
        keyVersion: manifest.keyVersion,
        objectCount: objects.length,
        createdAt: now,
      );

      final package = BrainBackupPackage(
        header: header,
        encryptedPayloadObject: serializedWrapper,
      );

      return _backupSerializer.serializePackage(package);
    } catch (error) {
      if (error is BrainBackupException) {
        rethrow;
      }

      throw BrainBackupException(
        'Não foi possível criar o backup .evbrain.',
        cause: error,
      );
    }
  }

  // ============================================================
  // EXPORT TO FILE
  // ============================================================

  Future<File> exportToFile(File file) async {
    final path = file.path.trim();

    if (path.isEmpty) {
      throw const BrainBackupException('Caminho do backup vazio.');
    }

    if (!path.toLowerCase().endsWith('.evbrain')) {
      throw const BrainBackupException(
        'O arquivo de backup precisa usar a extensão .evbrain.',
      );
    }

    final parent = file.parent;

    if (!await parent.exists()) {
      await parent.create(recursive: true);
    }

    final raw = await exportToString();

    final temp = File('$path.tmp');

    try {
      await temp.writeAsString(raw, flush: true);

      if (await file.exists()) {
        await file.delete();
      }

      await temp.rename(path);

      return file;
    } catch (error) {
      if (await temp.exists()) {
        try {
          await temp.delete();
        } catch (_) {}
      }

      throw BrainBackupException(
        'Não foi possível salvar o arquivo .evbrain.',
        cause: error,
      );
    }
  }

  // ============================================================
  // IMPORT FROM FILE
  // ============================================================

  Future<BrainBackupRestoreResult> importFromFile(File file) async {
    if (!await file.exists()) {
      throw const BrainBackupException('Arquivo .evbrain não encontrado.');
    }

    if (!file.path.toLowerCase().endsWith('.evbrain')) {
      throw const BrainBackupException('Arquivo inválido: esperado .evbrain.');
    }

    final raw = await file.readAsString();

    return importFromString(raw);
  }

  // ============================================================
  // IMPORT FROM STRING
  // ============================================================

  Future<BrainBackupRestoreResult> importFromString(String raw) async {
    try {
      final package = _backupSerializer.deserializePackage(raw);

      final backupHeader = package.header;

      final key = await _keyService.requireKeyBundle(
        vaultId: backupHeader.vaultId,
      );

      if (key.keyVersion != backupHeader.keyVersion) {
        throw StateError(
          'A versão da Master Key disponível não corresponde '
          'à versão exigida pelo backup.',
        );
      }

      final wrapperObject = _vaultSerializer.deserializeObject(
        package.encryptedPayloadObject,
      );

      if (wrapperObject.isDeleted) {
        throw const FormatException(
          'Wrapper criptográfico do .evbrain está excluído.',
        );
      }

      if (wrapperObject.header.vaultId != backupHeader.vaultId) {
        throw const FormatException(
          'vault_id do wrapper não corresponde ao header.',
        );
      }

      final encryptedPayload = wrapperObject.encryptedPayload;

      if (encryptedPayload == null) {
        throw const FormatException(
          'Wrapper do .evbrain não possui payload criptografado.',
        );
      }

      final compressedArchive = await _cryptoService.decryptString(
        payload: encryptedPayload,
        keyBundle: key,
      );

      final archiveRaw = _compressionService.decompressString(
        compressedArchive,
      );

      final archive = _backupSerializer.deserializeArchive(archiveRaw);

      if (archive.vaultId != backupHeader.vaultId) {
        throw const FormatException(
          'vault_id interno não corresponde ao header do backup.',
        );
      }

      if (archive.objects.length != backupHeader.objectCount) {
        throw const FormatException(
          'Quantidade de objetos do backup não confere.',
        );
      }

      await _vaultStorage.initialize();

      final existingManifest = await _vaultStorage.loadManifest();

      if (existingManifest == null) {
        await _vaultService.createVault(vaultId: backupHeader.vaultId);
      } else {
        if (existingManifest.vaultId != backupHeader.vaultId) {
          throw StateError('O destino já contém outro Vault.');
        }

        await _vaultService.openVault();
      }

      var restored = 0;
      var skippedNewerLocal = 0;

      for (final serializedObject in archive.objects) {
        final object = _vaultSerializer.deserializeObject(serializedObject);

        _validateImportedObject(object: object, vaultId: backupHeader.vaultId);

        final existing = await _vaultStorage.loadObject(object.header.objectId);

        if (existing != null &&
            existing.header.objectVersion.value >
                object.header.objectVersion.value) {
          skippedNewerLocal++;

          continue;
        }

        await _vaultStorage.saveObject(object);

        restored++;
      }

      final finalManifest = await _vaultStorage.loadManifest();

      if (finalManifest == null) {
        throw StateError('Manifest desapareceu durante a restauração.');
      }

      await _vaultStorage.saveManifest(finalManifest.touch());

      return BrainBackupRestoreResult(
        vaultId: backupHeader.vaultId,
        totalInBackup: backupHeader.objectCount,
        restored: restored,
        skippedNewerLocal: skippedNewerLocal,
      );
    } catch (error) {
      if (error is BrainBackupException) {
        rethrow;
      }

      throw BrainBackupException(
        'Não foi possível restaurar o backup .evbrain.',
        cause: error,
      );
    }
  }

  // ============================================================
  // VALIDATE IMPORTED OBJECT
  // ============================================================

  void _validateImportedObject({
    required BrainVaultObject object,
    required String vaultId,
  }) {
    object.header.validate();

    if (object.header.vaultId != vaultId) {
      throw const FormatException('Objeto do backup pertence a outro Vault.');
    }

    if (object.isActive && object.encryptedPayload == null) {
      throw const FormatException(
        'Objeto ativo importado sem payload criptografado.',
      );
    }

    if (object.isDeleted && object.tombstone == null) {
      throw const FormatException('Objeto excluído importado sem tombstone.');
    }
  }
}
