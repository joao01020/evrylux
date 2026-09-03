import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/models/brain_concept.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';
import 'package:EVRYLUX/study/brain/vault/stores/brain_concept_vault_store.dart';

void main() {
  group('BrainConceptVaultStore', () {
    late Directory directory;

    late BrainConceptVaultStore store;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'evrylux_concept_vault_',
      );

      final vaultService = BrainVaultService(
        keyService: BrainKeyService(storage: InMemoryBrainKeyStorage()),
        storage: BrainVaultStorage(
          documentsDirectoryProvider: () async => directory,
        ),
      );

      await vaultService.createVault();

      store = BrainConceptVaultStore(vaultService: vaultService);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('save/load preserva conceito', () async {
      final concept = BrainConcept(
        id: 'concept_1',
        title: 'Future',
        description: 'Representa resultado futuro.',
        type: BrainConceptType.concept,
      );

      final object = await store.saveConcept(
        concept: concept,
        sourceNotePath: '/tmp/future.md',
      );

      expect(object.isDeleted, false);

      final loaded = await store.getConcept('concept_1');

      expect(loaded, isNotNull);

      expect(loaded!.title, 'Future');

      expect(loaded.description, 'Representa resultado futuro.');

      expect(loaded.type, BrainConceptType.concept);
    });

    test('delete gera tombstone', () async {
      await store.saveConcept(
        concept: BrainConcept(
          id: 'concept_delete',
          title: 'Delete',
          description: 'Teste',
          type: BrainConceptType.concept,
        ),
      );

      final tombstone = await store.deleteConcept('concept_delete');

      expect(tombstone, isNotNull);

      expect(tombstone!.isDeleted, true);

      expect(tombstone.tombstone, isNotNull);
    });
  });
}
