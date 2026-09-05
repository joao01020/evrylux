import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/models/brain_file.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';
import 'package:EVRYLUX/study/brain/vault/stores/brain_note_vault_store.dart';

void
main() {
  group(
    'BrainNoteVaultStore',
    () {
      late Directory directory;
      late BrainVaultService vaultService;
      late BrainNoteVaultStore store;

      setUp(
        () async {
          directory = await Directory.systemTemp.createTemp(
            'evrylux_note_vault_',
          );

          vaultService = BrainVaultService(
            keyService: BrainKeyService(
              storage: InMemoryBrainKeyStorage(),
            ),
            storage: BrainVaultStorage(
              storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => directory,
              supportDirectoryProvider: () async => directory,
            ),
            ),
          );

          await vaultService.createVault();

          store = BrainNoteVaultStore(
            vaultService: vaultService,
          );
        },
      );

      tearDown(
        () async {
          if (await directory.exists()) {
            await directory.delete(
              recursive: true,
            );
          }
        },
      );

      test(
        'save cria nota criptografada e load recupera',
        () async {
          final now = DateTime.now();

          final note = BrainFile(
            topic: 'programacao',
            title: 'Future',
            path: '/tmp/future.md',
            content: 'Conteúdo secreto Dart.',
            concepts: const [],
            createdAt: now,
            updatedAt: now,
          );

          final object = await store.saveNote(
            note,
          );

          expect(
            object.isDeleted,
            false,
          );

          final loaded = await store.loadNotes();

          expect(
            loaded.length,
            1,
          );

          expect(
            loaded.single.title,
            'Future',
          );

          expect(
            loaded.single.content,
            'Conteúdo secreto Dart.',
          );
        },
      );

      test(
        'delete cria tombstone',
        () async {
          final now = DateTime.now();

          await store.saveNote(
            BrainFile(
              topic: 'dart',
              title: 'Delete',
              path: '/tmp/delete.md',
              content: 'Excluir.',
              concepts: const [],
              createdAt: now,
              updatedAt: now,
            ),
          );

          final tombstone = await store.deleteNoteByPath(
            '/tmp/delete.md',
          );

          expect(
            tombstone,
            isNotNull,
          );

          expect(
            tombstone!.isDeleted,
            true,
          );
        },
      );
    },
  );
}
