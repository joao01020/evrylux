import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_serializer.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void
main() {
  group(
    'BrainVaultService',
    () {
      late Directory tempDirectory;

      late InMemoryBrainKeyStorage keyStorage;

      late BrainKeyService keyService;

      late BrainVaultStorage vaultStorage;

      late BrainVaultService vaultService;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_vault_test_',
          );

          keyStorage = InMemoryBrainKeyStorage();

          keyService = BrainKeyService(
            storage: keyStorage,
          );

          vaultStorage = BrainVaultStorage(
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
          );

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: vaultStorage,
          );
        },
      );

      // ============================================================
      // TEARDOWN
      // ============================================================

      tearDown(
        () async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      // ============================================================
      // CREATE VAULT
      // ============================================================

      test(
        'cria Vault e salva manifest',
        () async {
          final manifest = await vaultService.createVault();

          expect(
            manifest.vaultId,
            isNotEmpty,
          );

          expect(
            manifest.formatVersion,
            1,
          );

          expect(
            manifest.cryptoVersion.value,
            1,
          );

          expect(
            manifest.keyVersion,
            1,
          );

          expect(
            await vaultStorage.hasManifest(),
            true,
          );

          final loaded = await vaultStorage.loadManifest();

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

      // ============================================================
      // DUPLICATE VAULT
      // ============================================================

      test(
        'não permite criar segundo Vault no mesmo storage',
        () async {
          await vaultService.createVault();

          expect(
            () async {
              await vaultService.createVault();
            },
            throwsStateError,
          );
        },
      );

      // ============================================================
      // OPEN VAULT
      // ============================================================

      test(
        'abre Vault existente com a mesma Master Key',
        () async {
          final created = await vaultService.createVault();

          final opened = await vaultService.openVault();

          expect(
            opened.vaultId,
            created.vaultId,
          );

          expect(
            opened.keyVersion,
            created.keyVersion,
          );
        },
      );

      // ============================================================
      // CREATE OBJECT
      // ============================================================

      test(
        'cria objeto criptografado',
        () async {
          final manifest = await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Negociação',
              'content': 'Perguntas abertas ajudam a entender a outra pessoa.',
            },
          );

          expect(
            object.header.vaultId,
            manifest.vaultId,
          );

          expect(
            object.header.objectVersion.value,
            1,
          );

          expect(
            object.header.cryptoVersion.value,
            1,
          );

          expect(
            object.header.keyVersion,
            1,
          );

          expect(
            object.isActive,
            true,
          );

          expect(
            object.isDeleted,
            false,
          );

          expect(
            object.encryptedPayload,
            isNotNull,
          );

          expect(
            object.tombstone,
            isNull,
          );
        },
      );

      // ============================================================
      // .EVOBJ EXISTS
      // ============================================================

      test(
        'cria arquivo .evobj no disco',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Teste',
              'content': 'Conteúdo',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          expect(
            await file.exists(),
            true,
          );

          expect(
            file.path.endsWith(
              '.evobj',
            ),
            true,
          );
        },
      );

      // ============================================================
      // NO PLAINTEXT
      // ============================================================

      test(
        '.evobj não contém título nem conteúdo em plaintext',
        () async {
          await vaultService.createVault();

          const title = 'Minha anotação extremamente secreta';

          const content = 'Este conteúdo jamais deve aparecer em texto puro no arquivo.';

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': title,
              'content': content,
              'question': 'Uma pergunta também secreta?',
              'answer': 'Uma resposta igualmente secreta.',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          final raw = await file.readAsString();

          expect(
            raw.contains(
              title,
            ),
            false,
          );

          expect(
            raw.contains(
              content,
            ),
            false,
          );

          expect(
            raw.contains(
              'Uma pergunta também secreta?',
            ),
            false,
          );

          expect(
            raw.contains(
              'Uma resposta igualmente secreta.',
            ),
            false,
          );
        },
      );

      // ============================================================
      // ROUND TRIP
      // ============================================================

      test(
        'grava no disco e recupera os dados originais',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Hábitos',
              'content': 'O ambiente influencia o comportamento.',
              'tags': [
                'hábitos',
                'comportamento',
              ],
              'nested': {
                'value': 123,
                'enabled': true,
              },
            },
          );

          final decoded = await vaultService.readObject(
            object.header.objectId,
          );

          expect(
            decoded,
            isNotNull,
          );

          expect(
            decoded!.type,
            BrainVaultObjectType.note,
          );

          expect(
            decoded.objectId,
            object.header.objectId,
          );

          expect(
            decoded.vaultId,
            object.header.vaultId,
          );

          expect(
            decoded.objectVersion,
            1,
          );

          expect(
            decoded.data['title'],
            'Hábitos',
          );

          expect(
            decoded.data['content'],
            'O ambiente influencia o comportamento.',
          );

          expect(
            decoded.data['tags'],
            [
              'hábitos',
              'comportamento',
            ],
          );

          final nested = decoded.data['nested'];

          expect(
            nested,
            isA<
              Map
            >(),
          );

          expect(
            nested['value'],
            123,
          );

          expect(
            nested['enabled'],
            true,
          );
        },
      );

      // ============================================================
      // UNICODE
      // ============================================================

      test(
        'preserva Unicode após encrypt disco decrypt',
        () async {
          await vaultService.createVault();

          const original = 'Olá çãõ — Привет — 日本語 — 🧠🔐';

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': original,
            },
          );

          final decoded = await vaultService.readObject(
            object.header.objectId,
          );

          expect(
            decoded!.data['content'],
            original,
          );
        },
      );

      // ============================================================
      // DIFFERENT IDS
      // ============================================================

      test(
        'objetos diferentes recebem objectIds diferentes',
        () async {
          await vaultService.createVault();

          final first = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'A',
            },
          );

          final second = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'B',
            },
          );

          expect(
            first.header.objectId,
            isNot(
              second.header.objectId,
            ),
          );
        },
      );

      // ============================================================
      // UPDATE
      // ============================================================

      test(
        'update mantém objectId e incrementa objectVersion',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Versão 1',
              'content': 'Conteúdo original',
            },
          );

          final updated = await vaultService.updateObject(
            objectId: original.header.objectId,
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Versão 2',
              'content': 'Conteúdo atualizado',
            },
          );

          expect(
            updated.header.objectId,
            original.header.objectId,
          );

          expect(
            original.header.objectVersion.value,
            1,
          );

          expect(
            updated.header.objectVersion.value,
            2,
          );

          final decoded = await vaultService.readObject(
            original.header.objectId,
          );

          expect(
            decoded,
            isNotNull,
          );

          expect(
            decoded!.objectVersion,
            2,
          );

          expect(
            decoded.data['title'],
            'Versão 2',
          );

          expect(
            decoded.data['content'],
            'Conteúdo atualizado',
          );
        },
      );

      // ============================================================
      // MULTIPLE UPDATES
      // ============================================================

      test(
        'múltiplas atualizações incrementam versão sequencialmente',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'V1',
            },
          );

          final second = await vaultService.updateObject(
            objectId: original.header.objectId,
            type: BrainVaultObjectType.note,
            data: {
              'content': 'V2',
            },
          );

          final third = await vaultService.updateObject(
            objectId: original.header.objectId,
            type: BrainVaultObjectType.note,
            data: {
              'content': 'V3',
            },
          );

          expect(
            original.header.objectVersion.value,
            1,
          );

          expect(
            second.header.objectVersion.value,
            2,
          );

          expect(
            third.header.objectVersion.value,
            3,
          );
        },
      );

      // ============================================================
      // DELETE / TOMBSTONE
      // ============================================================

      test(
        'delete substitui payload por tombstone',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Excluir',
              'content': 'Este objeto será apagado.',
            },
          );

          final deleted = await vaultService.deleteObject(
            original.header.objectId,
          );

          expect(
            deleted.isDeleted,
            true,
          );

          expect(
            deleted.isActive,
            false,
          );

          expect(
            deleted.encryptedPayload,
            isNull,
          );

          expect(
            deleted.tombstone,
            isNotNull,
          );

          expect(
            deleted.header.objectVersion.value,
            2,
          );

          expect(
            deleted.tombstone!.objectVersion.value,
            2,
          );

          expect(
            deleted.tombstone!.objectId,
            original.header.objectId,
          );
        },
      );

      // ============================================================
      // READ TOMBSTONE
      // ============================================================

      test(
        'readObject retorna null para tombstone',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste',
            },
          );

          await vaultService.deleteObject(
            original.header.objectId,
          );

          final decoded = await vaultService.readObject(
            original.header.objectId,
          );

          expect(
            decoded,
            isNull,
          );
        },
      );

      // ============================================================
      // TOMBSTONE PERSISTS
      // ============================================================

      test(
        'tombstone continua armazenado fisicamente',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste',
            },
          );

          await vaultService.deleteObject(
            original.header.objectId,
          );

          final rawObject = await vaultService.loadEncryptedObject(
            original.header.objectId,
          );

          expect(
            rawObject,
            isNotNull,
          );

          expect(
            rawObject!.isDeleted,
            true,
          );

          expect(
            rawObject.tombstone,
            isNotNull,
          );
        },
      );

      // ============================================================
      // DELETE TWICE
      // ============================================================

      test(
        'delete repetido mantém o tombstone existente',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste',
            },
          );

          final firstDelete = await vaultService.deleteObject(
            original.header.objectId,
          );

          final secondDelete = await vaultService.deleteObject(
            original.header.objectId,
          );

          expect(
            secondDelete.header.objectVersion,
            firstDelete.header.objectVersion,
          );

          expect(
            secondDelete.tombstone!.deletedAt,
            firstDelete.tombstone!.deletedAt,
          );
        },
      );

      // ============================================================
      // UPDATE DELETED
      // ============================================================

      test(
        'não permite atualizar objeto já excluído',
        () async {
          await vaultService.createVault();

          final original = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Original',
            },
          );

          await vaultService.deleteObject(
            original.header.objectId,
          );

          expect(
            () async {
              await vaultService.updateObject(
                objectId: original.header.objectId,
                type: BrainVaultObjectType.note,
                data: {
                  'content': 'Tentativa',
                },
              );
            },
            throwsStateError,
          );
        },
      );

      // ============================================================
      // LOAD ALL
      // ============================================================

      test(
        'loadAllEncryptedObjects retorna todos os objetos',
        () async {
          await vaultService.createVault();

          await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Nota',
            },
          );

          await vaultService.createObject(
            type: BrainVaultObjectType.review,
            data: {
              'question': 'Pergunta?',
              'answer': 'Resposta.',
            },
          );

          await vaultService.createObject(
            type: BrainVaultObjectType.concept,
            data: {
              'title': 'Conceito',
            },
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            3,
          );
        },
      );

      // ============================================================
      // OBJECT NOT FOUND
      // ============================================================

      test(
        'readObject retorna null para objeto inexistente',
        () async {
          await vaultService.createVault();

          final result = await vaultService.readObject(
            'obj_AAAAAAAAAAAAAAAAAAAAAA',
          );

          expect(
            result,
            isNull,
          );
        },
      );

      // ============================================================
      // UPDATE NOT FOUND
      // ============================================================

      test(
        'update falha para objeto inexistente',
        () async {
          await vaultService.createVault();

          expect(
            () async {
              await vaultService.updateObject(
                objectId: 'obj_AAAAAAAAAAAAAAAAAAAAAA',
                type: BrainVaultObjectType.note,
                data: {
                  'content': 'Teste',
                },
              );
            },
            throwsStateError,
          );
        },
      );

      // ============================================================
      // DELETE NOT FOUND
      // ============================================================

      test(
        'delete falha para objeto inexistente',
        () async {
          await vaultService.createVault();

          expect(
            () async {
              await vaultService.deleteObject(
                'obj_AAAAAAAAAAAAAAAAAAAAAA',
              );
            },
            throwsStateError,
          );
        },
      );

      // ============================================================
      // CIPHERTEXT TAMPERING
      // ============================================================

      test(
        'ciphertext adulterado causa falha ao descriptografar',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Conteúdo protegido',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          final raw = await file.readAsString();

          final decoded =
              jsonDecode(
                    raw,
                  )
                  as Map<
                    String,
                    dynamic
                  >;

          final payload =
              decoded['encrypted_payload']
                  as Map<
                    String,
                    dynamic
                  >;

          final cipherTextBase64 =
              payload['ciphertext']
                  as String;

          final cipherBytes = base64Decode(
            cipherTextBase64,
          );

          expect(
            cipherBytes,
            isNotEmpty,
          );

          cipherBytes[0] =
              cipherBytes[0] ^
              1;

          payload['ciphertext'] = base64Encode(
            cipherBytes,
          );

          await file.writeAsString(
            jsonEncode(
              decoded,
            ),
          );

          expect(
            () async {
              await vaultService.readObject(
                object.header.objectId,
              );
            },
            throwsException,
          );
        },
      );

      // ============================================================
      // NONCE TAMPERING
      // ============================================================

      test(
        'nonce adulterado causa falha ao descriptografar',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Conteúdo protegido',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          final decoded =
              jsonDecode(
                    await file.readAsString(),
                  )
                  as Map<
                    String,
                    dynamic
                  >;

          final payload =
              decoded['encrypted_payload']
                  as Map<
                    String,
                    dynamic
                  >;

          final nonce = base64Decode(
            payload['nonce']
                as String,
          );

          nonce[0] =
              nonce[0] ^
              1;

          payload['nonce'] = base64Encode(
            nonce,
          );

          await file.writeAsString(
            jsonEncode(
              decoded,
            ),
          );

          expect(
            () async {
              await vaultService.readObject(
                object.header.objectId,
              );
            },
            throwsException,
          );
        },
      );

      // ============================================================
      // MAC TAMPERING
      // ============================================================

      test(
        'MAC adulterado causa falha ao descriptografar',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Conteúdo protegido',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          final decoded =
              jsonDecode(
                    await file.readAsString(),
                  )
                  as Map<
                    String,
                    dynamic
                  >;

          final payload =
              decoded['encrypted_payload']
                  as Map<
                    String,
                    dynamic
                  >;

          final mac = base64Decode(
            payload['mac']
                as String,
          );

          mac[0] =
              mac[0] ^
              1;

          payload['mac'] = base64Encode(
            mac,
          );

          await file.writeAsString(
            jsonEncode(
              decoded,
            ),
          );

          expect(
            () async {
              await vaultService.readObject(
                object.header.objectId,
              );
            },
            throwsException,
          );
        },
      );

      // ============================================================
      // HEADER TAMPERING
      // ============================================================

      test(
        'header adulterado é detectado pelo binding autenticado',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Conteúdo protegido',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          final decoded =
              jsonDecode(
                    await file.readAsString(),
                  )
                  as Map<
                    String,
                    dynamic
                  >;

          final header =
              decoded['header']
                  as Map<
                    String,
                    dynamic
                  >;

          header['object_version'] = 99;

          await file.writeAsString(
            jsonEncode(
              decoded,
            ),
          );

          expect(
            () async {
              await vaultService.readObject(
                object.header.objectId,
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      // ============================================================
      // WRONG KEY
      // ============================================================

      test(
        'Master Key errada impede leitura do objeto',
        () async {
          final manifest = await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Conteúdo protegido',
            },
          );

          final otherKeyStorage = InMemoryBrainKeyStorage();

          final otherKeyService = BrainKeyService(
            storage: otherKeyStorage,
          );

          final wrongBundle = otherKeyService.createKeyBundle();

          await otherKeyStorage.saveKeyBundle(
            vaultId: manifest.vaultId,
            bundle: wrongBundle,
          );

          final secondStorage = BrainVaultStorage(
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
          );

          final secondService = BrainVaultService(
            keyService: otherKeyService,
            storage: secondStorage,
          );

          expect(
            () async {
              await secondService.readObject(
                object.header.objectId,
              );
            },
            throwsException,
          );
        },
      );

      // ============================================================
      // REOPEN SAME STORAGE
      // ============================================================

      test(
        'outro BrainVaultService consegue abrir o Vault com a mesma key storage',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'title': 'Persistência',
              'content': 'O serviço foi recriado.',
            },
          );

          final secondStorage = BrainVaultStorage(
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
          );

          final secondService = BrainVaultService(
            keyService: keyService,
            storage: secondStorage,
          );

          final opened = await secondService.openVault();

          expect(
            opened.vaultId,
            object.header.vaultId,
          );

          final decoded = await secondService.readObject(
            object.header.objectId,
          );

          expect(
            decoded,
            isNotNull,
          );

          expect(
            decoded!.data['title'],
            'Persistência',
          );

          expect(
            decoded.data['content'],
            'O serviço foi recriado.',
          );
        },
      );

      // ============================================================
      // RAW SERIALIZATION
      // ============================================================

      test(
        'arquivo .evobj pode ser desserializado como BrainVaultObject',
        () async {
          await vaultService.createVault();

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: {
              'content': 'Teste',
            },
          );

          final file = vaultStorage.objectFile(
            object.header.objectId,
          );

          const serializer = BrainVaultSerializer();

          final restored = serializer.deserializeObject(
            await file.readAsString(),
          );

          expect(
            restored,
            isA<
              BrainVaultObject
            >(),
          );

          expect(
            restored.header.objectId,
            object.header.objectId,
          );

          expect(
            restored.header.vaultId,
            object.header.vaultId,
          );
        },
      );
    },
  );
}
