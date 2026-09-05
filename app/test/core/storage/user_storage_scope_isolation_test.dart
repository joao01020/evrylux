import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/services/brain_storage.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void main() {
  group('UserStorageScope account isolation', () {
    late Directory tempDirectory;
    late String activeUserId;
    late UserStorageScope scope;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'evrylux_user_scope_isolation_',
      );

      activeUserId = 'account-a';

      scope = UserStorageScope(
        userIdProvider: () => activeUserId,
        documentsDirectoryProvider: () async => tempDirectory,
        supportDirectoryProvider: () async => tempDirectory,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('BrainStorage não mistura notas entre contas', () async {
      final storage = BrainStorage(storageScope: scope);

      await storage.saveNote(
        topic: '',
        title: 'Nota A',
        content: 'Conteúdo A',
        concepts: const [],
      );

      expect((await storage.loadNotes()).length, 1);

      activeUserId = 'account-b';

      expect(await storage.loadNotes(), isEmpty);

      await storage.saveNote(
        topic: '',
        title: 'Nota B',
        content: 'Conteúdo B',
        concepts: const [],
      );

      expect((await storage.loadNotes()).single.title, 'Nota B');

      activeUserId = 'account-a';

      expect((await storage.loadNotes()).single.title, 'Nota A');
    });

    test('BrainVaultStorage troca o Vault físico junto com a conta', () async {
      final storage = BrainVaultStorage(storageScope: scope);
      final keyService = BrainKeyService(storage: InMemoryBrainKeyStorage());
      final vaultService = BrainVaultService(
        keyService: keyService,
        storage: storage,
      );

      final manifestA = await vaultService.createVault();

      activeUserId = 'account-b';

      expect(await storage.hasManifest(), false);

      final manifestB = await vaultService.createVault();

      expect(manifestB.vaultId, isNot(manifestA.vaultId));

      activeUserId = 'account-a';

      final loadedA = await storage.loadManifest();
      expect(loadedA?.vaultId, manifestA.vaultId);
    });
  });
}
