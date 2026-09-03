import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

import 'package:EVRYLUX/study/brain/sync/models/brain_sync_payload.dart';

void main() {
  group('BrainSyncPayload', () {
    late Directory directory;
    late BrainVaultService vaultService;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'evrylux_brain_sync_payload_',
      );

      final keyStorage = InMemoryBrainKeyStorage();

      final keyService = BrainKeyService(storage: keyStorage);

      vaultService = BrainVaultService(
        keyService: keyService,
        storage: BrainVaultStorage(
          documentsDirectoryProvider: () async => directory,
        ),
      );

      await vaultService.createVault();
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('payload contém somente .evobj criptografado', () async {
      const question = 'Qual é a pergunta super secreta?';

      const answer = 'Esta é a resposta super secreta.';

      final object = await vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: const <String, dynamic>{'question': question, 'answer': answer},
      );

      final payload = BrainSyncPayload.fromVaultObject(object: object);

      final raw = jsonEncode(payload.toQueuePayload());

      expect(raw.contains(question), false);

      expect(raw.contains(answer), false);

      expect(raw.contains('"encrypted_payload"'), true);

      expect(payload.objectId, object.header.objectId);
    });

    test('tombstone também é payload update versionado', () async {
      final object = await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'Será excluído.'},
      );

      final tombstone = await vaultService.deleteObject(object.header.objectId);

      final payload = BrainSyncPayload.fromVaultObject(object: tombstone);

      expect(payload.isDeleted, true);

      expect(payload.objectVersion, 2);

      expect(payload.encryptedObject['tombstone'], isNotNull);
    });

    test('guard rejeita domínio lógico em plaintext', () async {
      final object = await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'Seguro.'},
      );

      final payload = BrainSyncPayload.fromVaultObject(object: object);

      final contaminated = payload.toQueuePayload();

      final encrypted = Map<String, dynamic>.from(
        contaminated['encrypted_object'] as Map,
      );

      encrypted['question'] = 'plaintext indevido';

      contaminated['encrypted_object'] = encrypted;

      expect(() {
        BrainSyncPayload.fromQueuePayload(contaminated);
      }, throwsFormatException);
    });
  });
}
