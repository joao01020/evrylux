import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void
main() {
  group(
    'BrainVaultStorage',
    () {
      late Directory tempDirectory;

      late BrainVaultStorage storage;

      late BrainKeyService keyService;

      late BrainVaultService vaultService;

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_storage_test_',
          );

          storage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: storage,
          );
        },
      );

      tearDown(
        () async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      test(
        'initialize cria estrutura do Vault',
        () async {
          await storage.initialize();

          final root = Directory(
            '${tempDirectory.path}/evrylux_brain/vault',
          );

          final objects = Directory(
            '${root.path}/objects',
          );

          expect(
            await root.exists(),
            true,
          );

          expect(
            await objects.exists(),
            true,
          );
        },
      );

      test(
        'Vault recém inicializado não possui manifest',
        () async {
          await storage.initialize();

          expect(
            await storage.hasManifest(),
            false,
          );
        },
      );

      test(
        'createVault salva manifest',
        () async {
          final manifest = await vaultService.createVault();

          expect(
            await storage.hasManifest(),
            true,
          );

          final loaded = await storage.loadManifest();

          expect(
            loaded,
            isNotNull,
          );

          expect(
            loaded!.vaultId,
            manifest.vaultId,
          );
        },
      );

      test(
        'objectFile gera arquivo .evobj',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Teste',
              'content': 'Conteúdo',
            },
          );

          final file = storage.objectFile(
            object.header.objectId,
          );

          expect(
            file.path.endsWith(
              '${object.header.objectId}.evobj',
            ),
            true,
          );

          expect(
            await file.exists(),
            true,
          );
        },
      );

      test(
        'containsObject detecta objeto existente',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste',
            },
          );

          expect(
            await storage.containsObject(
              object.header.objectId,
            ),
            true,
          );
        },
      );

      test(
        'containsObject retorna false para inexistente',
        () async {
          await vaultService.createVault();

          expect(
            await storage.containsObject(
              'obj_AAAAAAAAAAAAAAAAAAAAAA',
            ),
            false,
          );
        },
      );

      test(
        'loadObject recupera objeto salvo',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Persistência',
            },
          );

          final loaded = await storage.loadObject(
            original.header.objectId,
          );

          expect(
            loaded,
            isNotNull,
          );

          expect(
            loaded!.header.objectId,
            original.header.objectId,
          );

          expect(
            loaded.header.vaultId,
            original.header.vaultId,
          );
        },
      );

      test(
        'loadObject retorna null para inexistente',
        () async {
          await vaultService.createVault();

          final loaded = await storage.loadObject(
            'obj_AAAAAAAAAAAAAAAAAAAAAA',
          );

          expect(
            loaded,
            isNull,
          );
        },
      );

      test(
        'loadAllObjects recupera múltiplos objetos',
        () async {
          await vaultService.createVault();

          await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Primeiro',
            },
          );

          await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Segundo',
            },
          );

          await vaultService.createObject(
            type: BrainVaultObjectType.review,
            data: {
              'question': 'Pergunta?',
              'answer': 'Resposta.',
            },
          );

          final objects = await storage.loadAllObjects();

          expect(
            objects.length,
            3,
          );
        },
      );

      test(
        'arquivo salvo não contém plaintext',
        () async {
          await vaultService.createVault();

          const secret = 'SEGREDO_QUE_NAO_PODE_APARECER';

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Privado',
              'content': secret,
            },
          );

          final file = storage.objectFile(
            object.header.objectId,
          );

          final raw = await file.readAsString();

          expect(
            raw.contains(
              secret,
            ),
            false,
          );

          expect(
            raw.contains(
              'Privado',
            ),
            false,
          );
        },
      );

      test(
        'update sobrescreve mesmo arquivo físico',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'V1',
            },
          );

          final originalFile = storage.objectFile(
            original.header.objectId,
          );

          final originalPath = originalFile.path;

          await vaultService.updateObject(
            objectId: original.header.objectId,
            type: BrainVaultObjectType.note,
            data: {
              'content': 'V2',
            },
          );

          final updatedFile = storage.objectFile(
            original.header.objectId,
          );

          expect(
            updatedFile.path,
            originalPath,
          );

          expect(
            await updatedFile.exists(),
            true,
          );

          final loaded = await storage.loadObject(
            original.header.objectId,
          );

          expect(
            loaded!.header.objectVersion.value,
            2,
          );
        },
      );

      test(
        'delete lógico mantém arquivo físico como tombstone',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Será excluído',
            },
          );

          final file = storage.objectFile(
            object.header.objectId,
          );

          expect(
            await file.exists(),
            true,
          );

          await vaultService.deleteObject(
            object.header.objectId,
          );

          expect(
            await file.exists(),
            true,
          );

          final stored = await storage.loadObject(
            object.header.objectId,
          );

          expect(
            stored,
            isNotNull,
          );

          expect(
            stored!.isDeleted,
            true,
          );
        },
      );

      test(
        'não deixa arquivos temporários após gravação normal',
        () async {
          await vaultService.createVault();

          await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste atomic write',
            },
          );

          final root = Directory(
            '${tempDirectory.path}/evrylux_brain/vault',
          );

          final entities = await root
              .list(
                recursive: true,
              )
              .toList();

          final tempFiles = entities
              .whereType<
                File
              >()
              .where(
                (
                  file,
                ) => file.path.endsWith(
                  '.tmp',
                ),
              )
              .toList();

          expect(
            tempFiles,
            isEmpty,
          );
        },
      );
    },
  );
}
