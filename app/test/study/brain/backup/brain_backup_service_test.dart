import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/backup/services/brain_backup_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void main() {
  group('BrainBackupService', () {
    late Directory sourceDirectory;
    late Directory restoreDirectory;

    late InMemoryBrainKeyStorage keyStorage;
    late BrainKeyService keyService;

    setUp(() async {
      sourceDirectory = await Directory.systemTemp.createTemp(
        'evrylux_backup_source_',
      );

      restoreDirectory = await Directory.systemTemp.createTemp(
        'evrylux_backup_restore_',
      );

      keyStorage = InMemoryBrainKeyStorage();

      keyService = BrainKeyService(storage: keyStorage);
    });

    tearDown(() async {
      if (await sourceDirectory.exists()) {
        await sourceDirectory.delete(recursive: true);
      }

      if (await restoreDirectory.exists()) {
        await restoreDirectory.delete(recursive: true);
      }

      keyStorage.clear();
    });

    test('exporta e restaura objetos sem plaintext no .evbrain', () async {
      // ====================================================
      // SOURCE VAULT
      // ====================================================

      final sourceStorage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => sourceDirectory,
              supportDirectoryProvider: () async => sourceDirectory,
            ),
      );

      final sourceVaultService = BrainVaultService(
        keyService: keyService,
        storage: sourceStorage,
      );

      final manifest = await sourceVaultService.createVault();

      const secretQuestion = 'O que é um ponteiro secreto em C++?';

      const secretAnswer = 'Um ponteiro guarda um endereço de memória.';

      final reviewObject = await sourceVaultService.createObject(
        type: BrainVaultObjectType.review,
        data: const <String, dynamic>{
          'question': secretQuestion,
          'answer': secretAnswer,
        },
      );

      final deletedObject = await sourceVaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{
          'content': 'Esse objeto será tombstonado.',
        },
      );

      await sourceVaultService.deleteObject(deletedObject.header.objectId);

      final sourceBackupService = BrainBackupService(
        vaultService: sourceVaultService,
        vaultStorage: sourceStorage,
        keyService: keyService,
      );

      // ====================================================
      // EXPORT
      // ====================================================

      final backupRaw = await sourceBackupService.exportToString();

      expect(backupRaw, isNotEmpty);

      // O arquivo externo não pode revelar conteúdo.
      expect(backupRaw.contains(secretQuestion), false);

      expect(backupRaw.contains(secretAnswer), false);

      // A Master Key também não pode aparecer em nenhum campo
      // textual do package.
      final bundle = await keyService.requireKeyBundle(
        vaultId: manifest.vaultId,
      );

      expect(backupRaw.contains(bundle.masterKeyBytes.toString()), false);

      // ====================================================
      // RESTORE VAULT
      // ====================================================
      //
      // Usa a MESMA key storage para representar um ambiente
      // autorizado que já possui a Master Key do Vault.
      //
      // ====================================================

      final restoreStorage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => restoreDirectory,
              supportDirectoryProvider: () async => restoreDirectory,
            ),
      );

      final restoreVaultService = BrainVaultService(
        keyService: keyService,
        storage: restoreStorage,
      );

      final restoreBackupService = BrainBackupService(
        vaultService: restoreVaultService,
        vaultStorage: restoreStorage,
        keyService: keyService,
      );

      final result = await restoreBackupService.importFromString(backupRaw);

      expect(result.vaultId, manifest.vaultId);

      expect(result.totalInBackup, 2);

      expect(result.restored, 2);

      // ====================================================
      // ACTIVE OBJECT
      // ====================================================

      final restoredReview = await restoreVaultService.readObject(
        reviewObject.header.objectId,
      );

      expect(restoredReview, isNotNull);

      expect(restoredReview!.data['question'], secretQuestion);

      expect(restoredReview.data['answer'], secretAnswer);

      // ====================================================
      // TOMBSTONE
      // ====================================================

      final restoredDeleted = await restoreVaultService.loadEncryptedObject(
        deletedObject.header.objectId,
      );

      expect(restoredDeleted, isNotNull);

      expect(restoredDeleted!.isDeleted, true);

      expect(restoredDeleted.tombstone, isNotNull);
    });

    test('não sobrescreve versão local mais nova com backup antigo', () async {
      final sourceStorage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => sourceDirectory,
              supportDirectoryProvider: () async => sourceDirectory,
            ),
      );

      final sourceVaultService = BrainVaultService(
        keyService: keyService,
        storage: sourceStorage,
      );

      final manifest = await sourceVaultService.createVault();

      final original = await sourceVaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'V1'},
      );

      final backupService = BrainBackupService(
        vaultService: sourceVaultService,
        vaultStorage: sourceStorage,
        keyService: keyService,
      );

      final oldBackup = await backupService.exportToString();

      // Cria no destino o mesmo Vault a partir do backup.
      final restoreStorage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => restoreDirectory,
              supportDirectoryProvider: () async => restoreDirectory,
            ),
      );

      final restoreVaultService = BrainVaultService(
        keyService: keyService,
        storage: restoreStorage,
      );

      final restoreBackupService = BrainBackupService(
        vaultService: restoreVaultService,
        vaultStorage: restoreStorage,
        keyService: keyService,
      );

      await restoreBackupService.importFromString(oldBackup);

      await restoreVaultService.updateObject(
        objectId: original.header.objectId,
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'V2 local'},
      );

      final result = await restoreBackupService.importFromString(oldBackup);

      expect(result.skippedNewerLocal, 1);

      final decoded = await restoreVaultService.readObject(
        original.header.objectId,
      );

      expect(decoded!.data['content'], 'V2 local');

      expect(manifest.vaultId, result.vaultId);
    });
  });
}
