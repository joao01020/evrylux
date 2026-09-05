import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_migration_factory.dart';

import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/services/brain_storage.dart';
import 'package:EVRYLUX/study/brain/services/review_storage.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

// ============================================================
// FAKE PATH PROVIDER
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
    'BrainMigration ReviewStorage integration',
    () {
      late Directory tempDirectory;

      late PathProviderPlatform originalPathProvider;

      late BrainStorage brainStorage;

      late ReviewStorage reviewStorage;

      late BrainVaultService vaultService;

      late DateTime currentTime;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_review_storage_migration_test_',
          );

          originalPathProvider = PathProviderPlatform.instance;

          PathProviderPlatform.instance = _FakePathProviderPlatform(
            tempDirectory.path,
          );

          brainStorage = BrainStorage(
            storageScope: UserStorageScope.fixed(userId: 'test-user'),
          );

          reviewStorage = ReviewStorage(
            storageScope: UserStorageScope.fixed(userId: 'test-user'),
          );

          final keyStorage = InMemoryBrainKeyStorage();

          final keyService = BrainKeyService(
            storage: keyStorage,
          );

          final vaultStorage = BrainVaultStorage(
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

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

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
      // REVIEW STORAGE LOAD
      // ============================================================

      test(
        'factory carrega reviews reais pelo ReviewStorage',
        () async {
          final review = BrainReviewItem(
            id: 'review-storage-001',
            conceptId: 'concept-storage-001',
            question: 'O que é encapsulamento?',
            answer: 'É esconder detalhes internos atrás de uma interface.',
            sourceNotePath: '/tmp/orientacao-objetos.md',
            sourceNoteTitle: 'Orientação a objetos',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              review,
            ],
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final reviews = await runtime.coordinator.loadLegacyReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.first.id,
            review.id,
          );

          expect(
            reviews.first.question,
            review.question,
          );

          expect(
            reviews.first.answer,
            review.answer,
          );
        },
      );

      // ============================================================
      // MIGRATE REVIEW
      // ============================================================

      test(
        'Coordinator migra review salva no ReviewStorage',
        () async {
          final review = BrainReviewItem(
            id: 'review-storage-002',
            conceptId: 'concept-storage-002',
            question: 'O que é polimorfismo?',
            answer: 'É a capacidade de tratar diferentes implementações por uma interface comum.',
            sourceNotePath: '/tmp/polimorfismo.md',
            sourceNoteTitle: 'Polimorfismo',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              review,
            ],
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final result = await runtime.coordinator.runReviewsOnly();

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

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );

          final recordList = await runtime.registry.loadAll();

          expect(
            recordList.length,
            1,
          );

          expect(
            recordList.single.status,
            BrainMigrationStatus.validated,
          );

          expect(
            recordList.single.objectId,
            isNotNull,
          );
        },
      );

      // ============================================================
      // REVIEWS.JSON SURVIVES
      // ============================================================

      test(
        'migração não remove review legada do ReviewStorage',
        () async {
          final review = BrainReviewItem(
            id: 'review-storage-003',
            conceptId: 'concept-storage-003',
            question: 'O que é composição?',
            answer: 'É construir objetos a partir de outros objetos.',
            sourceNotePath: '/tmp/composicao.md',
            sourceNoteTitle: 'Composição',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              review,
            ],
          );

          final before = await reviewStorage.loadReviews();

          expect(
            before.length,
            1,
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final result = await runtime.coordinator.runReviewsOnly();

          expect(
            result.validated,
            1,
          );

          final after = await reviewStorage.loadReviews();

          expect(
            after.length,
            1,
          );

          expect(
            after.single.id,
            review.id,
          );
        },
      );

      // ============================================================
      // RESTART / PERSISTENCE
      // ============================================================

      test(
        'novo runtime não duplica review já migrada',
        () async {
          final review = BrainReviewItem(
            id: 'review-storage-004',
            conceptId: 'concept-storage-004',
            question: 'O que é herança?',
            answer: 'É um mecanismo de especialização entre tipos.',
            sourceNotePath: '/tmp/heranca.md',
            sourceNoteTitle: 'Herança',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              review,
            ],
          );

          // ========================================================
          // FIRST RUNTIME
          // ========================================================

          final firstRuntime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final firstResult = await firstRuntime.coordinator.runReviewsOnly();

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
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final secondResult = await secondRuntime.coordinator.runReviewsOnly();

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
      // FILE + REVIEW
      // ============================================================

      test(
        'factory migra nota e review reais juntas',
        () async {
          final savedNote = await brainStorage.saveNote(
            topic: 'Arquitetura',
            title: 'Dependency Injection',
            content: 'Dependências são fornecidas externamente ao componente.',
            concepts: const [],
          );

          final review = BrainReviewItem(
            id: 'review-storage-005',
            conceptId: 'concept-storage-005',
            question: 'O que é dependency injection?',
            answer: 'É fornecer dependências de fora do componente.',
            sourceNotePath: savedNote.path,
            sourceNoteTitle: savedNote.title,
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              review,
            ],
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final result = await runtime.coordinator.run();

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

          expect(
            result.allValidated,
            true,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            2,
          );

          // ========================================================
          // LEGADO CONTINUA PRESENTE
          // ========================================================

          expect(
            await File(
              savedNote.path,
            ).exists(),
            true,
          );

          final legacyReviews = await reviewStorage.loadReviews();

          expect(
            legacyReviews.length,
            1,
          );

          expect(
            legacyReviews.single.id,
            review.id,
          );
        },
      );

      // ============================================================
      // MULTIPLE REVIEWS
      // ============================================================

      test(
        'migra múltiplas reviews reais sem duplicar vínculos',
        () async {
          final first = BrainReviewItem(
            id: 'review-storage-multi-001',
            conceptId: 'concept-storage-multi-001',
            question: 'Pergunta 1?',
            answer: 'Resposta 1.',
            sourceNotePath: '/tmp/multi-1.md',
            sourceNoteTitle: 'Multi 1',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          final second = BrainReviewItem(
            id: 'review-storage-multi-002',
            conceptId: 'concept-storage-multi-002',
            question: 'Pergunta 2?',
            answer: 'Resposta 2.',
            sourceNotePath: '/tmp/multi-2.md',
            sourceNoteTitle: 'Multi 2',
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              6,
            ),
            lastReviewedAt: null,
            archivedAt: null,
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          await reviewStorage.saveReviews(
            [
              first,
              second,
            ],
          );

          final runtime = await BrainMigrationFactory.create(
            vaultService: vaultService,
            brainStorage: brainStorage,
            reviewStorage: reviewStorage,
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
            now: () => currentTime,
          );

          final result = await runtime.coordinator.runReviewsOnly();

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

          final records = await runtime.registry.loadAll();

          expect(
            records.length,
            2,
          );

          expect(
            records[0].objectId,
            isNotNull,
          );

          expect(
            records[1].objectId,
            isNotNull,
          );

          expect(
            records[0].objectId,
            isNot(
              records[1].objectId,
            ),
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            2,
          );
        },
      );
    },
  );
}
