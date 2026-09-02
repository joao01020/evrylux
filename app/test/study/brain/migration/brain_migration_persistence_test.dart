import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_migration_factory.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/services/brain_storage.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

// ============================================================
// FAKE PATH PROVIDER
// ============================================================
//
// BrainStorage usa getApplicationDocumentsDirectory().
//
// Durante o teste apontamos para:
//
// /tmp/evrylux_migration_persistence_test_...
//
// Nenhum dado real do usuário é utilizado.
//
// ============================================================

class _FakePathProviderPlatform
    extends
        PathProviderPlatform {
  _FakePathProviderPlatform(
    this.documentsPath,
  );

  final String documentsPath;

  @override
  Future<
    String?
  >
  getApplicationDocumentsPath() async {
    return documentsPath;
  }
}

// ============================================================
// TESTS
// ============================================================

void
main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'BrainMigration persistence',
    () {
      late Directory tempDirectory;

      late PathProviderPlatform originalPathProvider;

      late BrainStorage brainStorage;

      late BrainVaultService vaultService;

      late InMemoryBrainKeyStorage keyStorage;

      late DateTime currentTime;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          // ========================================================
          // TEMP DIRECTORY
          // ========================================================

          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_migration_persistence_test_',
          );

          // ========================================================
          // PATH PROVIDER
          // ========================================================

          originalPathProvider = PathProviderPlatform.instance;

          PathProviderPlatform.instance = _FakePathProviderPlatform(
            tempDirectory.path,
          );

          // ========================================================
          // LEGACY STORAGE
          // ========================================================

          brainStorage = const BrainStorage();

          // ========================================================
          // KEY STORAGE
          // ========================================================
          //
          // IMPORTANTE:
          //
          // Aqui usamos memória porque é TESTE.
          //
          // O objetivo deste arquivo é testar persistência do
          // MigrationRegistry, não persistência da Master Key
          // através de um keyring do sistema operacional.
          //
          // ========================================================

          keyStorage = InMemoryBrainKeyStorage();

          final keyService = BrainKeyService(
            storage: keyStorage,
          );

          // ========================================================
          // VAULT STORAGE
          // ========================================================

          final vaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          // ========================================================
          // VAULT SERVICE
          // ========================================================

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: vaultStorage,
          );

          // ========================================================
          // CLOCK
          // ========================================================

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          // ========================================================
          // CREATE VAULT
          // ========================================================

          await vaultService.createVault();
        },
      );

      // ============================================================
      // TEARDOWN
      // ============================================================

      tearDown(
        () async {
          PathProviderPlatform.instance = originalPathProvider;

          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      // ============================================================
      // FACTORY
      // ============================================================

      test(
        'factory monta runtime persistente',
        () async {
          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          expect(
            runtime.isReady,
            true,
          );

          expect(
            await runtime.registry.count(),
            0,
          );

          expect(
            runtime.coordinator.isRunning,
            false,
          );
        },
      );

      // ============================================================
      // REGISTRY FILE
      // ============================================================

      test(
        'factory usa BrainMigrationRegistry persistente',
        () async {
          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final registryFile = await runtime.registry.getRegistryFile();

          // ========================================================
          // SOMENTE INITIALIZE NÃO PRECISA CRIAR O JSON
          // ========================================================

          expect(
            await registryFile.exists(),
            false,
          );

          // ========================================================
          // CRIAR NOTA LEGADA
          // ========================================================

          await brainStorage.saveNote(
            topic: 'Persistência',

            title: 'Registry',

            content: 'Teste de persistência do registry de migração.',

            concepts: const [],
          );

          // ========================================================
          // MIGRAR
          // ========================================================

          final result = await runtime.coordinator.run();

          expect(
            result.total,
            1,
          );

          expect(
            result.validated,
            1,
          );

          expect(
            result.failed,
            0,
          );

          // ========================================================
          // AGORA O REGISTRY DEVE EXISTIR
          // ========================================================

          expect(
            await registryFile.exists(),
            true,
          );

          expect(
            await runtime.registry.count(),
            1,
          );
        },
      );

      // ============================================================
      // RECONSTRUCT MIGRATION RUNTIME
      // ============================================================

      test(
        'novo runtime recupera vínculos persistidos',
        () async {
          final saved = await brainStorage.saveNote(
            topic: 'C++',

            title: 'Ownership',

            content: 'Ownership define responsabilidade sobre recursos.',

            concepts: const [],
          );

          // ========================================================
          // RUNTIME 1
          // ========================================================

          final firstRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final firstResult = await firstRuntime.coordinator.run();

          expect(
            firstResult.total,
            1,
          );

          expect(
            firstResult.validated,
            1,
          );

          // ========================================================
          // RECORD ORIGINAL
          // ========================================================

          final firstRecords = await firstRuntime.registry.loadAll();

          expect(
            firstRecords.length,
            1,
          );

          final firstRecord = firstRecords.single;

          expect(
            firstRecord.status,
            BrainMigrationStatus.validated,
          );

          expect(
            firstRecord.objectId,
            isNotNull,
          );

          final originalObjectId = firstRecord.objectId!;

          // ========================================================
          // LEGACY FILE CONTINUA EXISTINDO
          // ========================================================

          expect(
            await File(
              saved.path,
            ).exists(),
            true,
          );

          // ========================================================
          // RECONSTRUIR TODA A CAMADA DE MIGRAÇÃO
          // ========================================================
          //
          // Não reutilizamos:
          //
          // - registry;
          // - objectLinkService;
          // - validationService;
          // - legacyMigrationService;
          // - coordinator.
          //
          // ========================================================

          final secondRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          // ========================================================
          // NOVO REGISTRY LEU O DISCO
          // ========================================================

          final secondRecords = await secondRuntime.registry.loadAll();

          expect(
            secondRecords.length,
            1,
          );

          final restoredRecord = secondRecords.single;

          expect(
            restoredRecord.legacyFingerprint,
            firstRecord.legacyFingerprint,
          );

          expect(
            restoredRecord.objectId,
            originalObjectId,
          );

          expect(
            restoredRecord.status,
            BrainMigrationStatus.validated,
          );
        },
      );

      // ============================================================
      // RERUN AFTER RECONSTRUCTION
      // ============================================================

      test(
        'novo runtime não duplica objeto já migrado',
        () async {
          await brainStorage.saveNote(
            topic: 'Linux',

            title: 'Processos',

            content: 'Um processo é uma instância de um programa em execução.',

            concepts: const [],
          );

          // ========================================================
          // FIRST RUNTIME
          // ========================================================

          final firstRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final firstResult = await firstRuntime.coordinator.run();

          expect(
            firstResult.validated,
            1,
          );

          final firstObjects = await vaultService.loadAllEncryptedObjects();

          expect(
            firstObjects.length,
            1,
          );

          final firstRecords = await firstRuntime.registry.loadAll();

          expect(
            firstRecords.length,
            1,
          );

          final firstObjectId = firstRecords.single.objectId;

          expect(
            firstObjectId,
            isNotNull,
          );

          // ========================================================
          // SECOND RUNTIME
          // ========================================================

          final secondRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          // ========================================================
          // RUN NOVAMENTE
          // ========================================================

          final secondResult = await secondRuntime.coordinator.run();

          expect(
            secondResult.total,
            1,
          );

          expect(
            secondResult.validated,
            1,
          );

          expect(
            secondResult.failed,
            0,
          );

          // ========================================================
          // CONTINUA EXISTINDO APENAS UM OBJETO
          // ========================================================

          final secondObjects = await vaultService.loadAllEncryptedObjects();

          expect(
            secondObjects.length,
            1,
          );

          final secondRecords = await secondRuntime.registry.loadAll();

          expect(
            secondRecords.length,
            1,
          );

          expect(
            secondRecords.single.objectId,
            firstObjectId,
          );
        },
      );

      // ============================================================
      // RAW REGISTRY
      // ============================================================

      test(
        'registry persistente não contém path título ou conteúdo',
        () async {
          const secretTitle = 'Conhecimento super reservado';

          const secretContent = 'Este conteúdo não pode aparecer no migration registry.';

          final saved = await brainStorage.saveNote(
            topic: 'Privado',

            title: secretTitle,

            content: secretContent,

            concepts: const [],
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final result = await runtime.coordinator.run();

          expect(
            result.validated,
            1,
          );

          final registryFile = await runtime.registry.getRegistryFile();

          expect(
            await registryFile.exists(),
            true,
          );

          final raw = await registryFile.readAsString();

          // ========================================================
          // NÃO DEVE CONTER DADOS DO LEGADO
          // ========================================================

          expect(
            raw.contains(
              saved.path,
            ),
            false,
          );

          expect(
            raw.contains(
              secretTitle,
            ),
            false,
          );

          expect(
            raw.contains(
              secretContent,
            ),
            false,
          );

          // ========================================================
          // DEVE CONTER METADADOS TÉCNICOS
          // ========================================================

          expect(
            raw.contains(
              'legacy_fingerprint',
            ),
            true,
          );

          expect(
            raw.contains(
              'object_id',
            ),
            true,
          );

          expect(
            raw.contains(
              'validated',
            ),
            true,
          );
        },
      );

      // ============================================================
      // DIFFERENT NOTES
      // ============================================================

      test(
        'registry persistente mantém múltiplos vínculos',
        () async {
          await brainStorage.saveNote(
            topic: 'Programação',

            title: 'Primeira',

            content: 'Primeiro conteúdo.',

            concepts: const [],
          );

          await brainStorage.saveNote(
            topic: 'Programação',

            title: 'Segunda',

            content: 'Segundo conteúdo.',

            concepts: const [],
          );

          final firstRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final result = await firstRuntime.coordinator.run();

          expect(
            result.total,
            2,
          );

          expect(
            result.validated,
            2,
          );

          expect(
            result.failed,
            0,
          );

          final firstRecords = await firstRuntime.registry.loadAll();

          expect(
            firstRecords.length,
            2,
          );

          expect(
            firstRecords[0].objectId,
            isNotNull,
          );

          expect(
            firstRecords[1].objectId,
            isNotNull,
          );

          expect(
            firstRecords[0].objectId,
            isNot(
              firstRecords[1].objectId,
            ),
          );

          // ========================================================
          // RECONSTRUCT
          // ========================================================

          final secondRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final restored = await secondRuntime.registry.loadAll();

          expect(
            restored.length,
            2,
          );
        },
      );

      // ============================================================
      // LEGACY SURVIVES PERSISTENT MIGRATION
      // ============================================================

      test(
        'migração persistente continua preservando legado',
        () async {
          final saved = await brainStorage.saveNote(
            topic: 'Memória',

            title: 'Não destruir',

            content: 'O legado precisa permanecer enquanto a migração não for finalizada.',

            concepts: const [],
          );

          final legacyFile = File(
            saved.path,
          );

          expect(
            await legacyFile.exists(),
            true,
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final result = await runtime.coordinator.run();

          expect(
            result.validated,
            1,
          );

          expect(
            await legacyFile.exists(),
            true,
          );

          // ========================================================
          // RECONSTRUCT
          // ========================================================

          final reopenedRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            documentsDirectoryProvider: () async => tempDirectory,
            now: () => currentTime,
          );

          final secondResult = await reopenedRuntime.coordinator.run();

          expect(
            secondResult.validated,
            1,
          );

          expect(
            await legacyFile.exists(),
            true,
          );
        },
      );
    },
  );
}
