import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/models/brain_file.dart';
import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_legacy_migration_service.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_migration_validation_service.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_object_link_service.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void
main() {
  group(
    'BrainLegacyMigrationService',
    () {
      late Directory tempDirectory;

      late BrainVaultService vaultService;

      late BrainObjectLinkService linkService;

      late BrainMigrationValidationService validationService;

      late BrainLegacyMigrationService migrationService;

      late DateTime currentTime;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_legacy_migration_test_',
          );

          final keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          final storage = BrainVaultStorage(
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
          );

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: storage,
          );

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          linkService = BrainObjectLinkService(
            store: InMemoryBrainMigrationLinkStore(),
            now: () => currentTime,
          );

          validationService = BrainMigrationValidationService(
            vaultService: vaultService,
          );

          migrationService = BrainLegacyMigrationService(
            vaultService: vaultService,
            objectLinkService: linkService,
            validationService: validationService,
            now: () => currentTime,
          );

          await vaultService.createVault();
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
      // BRAIN FILE
      // ============================================================

      test(
        'migra BrainFile para Vault e valida',
        () async {
          final file = BrainFile(
            topic: 'Vendas',
            title: 'Perguntas abertas',
            path: '/tmp/legacy/perguntas-abertas.md',
            content: 'Perguntas abertas ajudam a compreender necessidades.',
            concepts: const [],
            createdAt: DateTime(
              2026,
              8,
              20,
            ),
            updatedAt: DateTime(
              2026,
              9,
              1,
            ),
          );

          final record = await migrationService.migrateBrainFile(
            file,
          );

          expect(
            record.status,
            BrainMigrationStatus.validated,
          );

          expect(
            record.objectId,
            isNotNull,
          );

          expect(
            record.attempts,
            1,
          );

          final decoded = await vaultService.readObject(
            record.objectId!,
          );

          expect(
            decoded,
            isNotNull,
          );

          expect(
            decoded!.data['title'],
            file.title,
          );

          expect(
            decoded.data['content'],
            file.content,
          );
        },
      );

      // ============================================================
      // FILE IDEMPOTENCE
      // ============================================================

      test(
        'migrar mesmo BrainFile novamente não cria outro objeto',
        () async {
          final file = BrainFile(
            topic: 'Hábitos',
            title: 'Ambiente',
            path: '/tmp/legacy/ambiente.md',
            content: 'O ambiente influencia hábitos.',
            concepts: const [],
            createdAt: DateTime(
              2026,
              8,
              1,
            ),
            updatedAt: DateTime(
              2026,
              9,
              1,
            ),
          );

          final first = await migrationService.migrateBrainFile(
            file,
          );

          final second = await migrationService.migrateBrainFile(
            file,
          );

          expect(
            first.status,
            BrainMigrationStatus.validated,
          );

          expect(
            second.status,
            BrainMigrationStatus.validated,
          );

          expect(
            second.objectId,
            first.objectId,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // REVIEW
      // ============================================================

      test(
        'migra BrainReviewItem para Vault e valida',
        () async {
          final review = BrainReviewItem(
            id: 'review-migration-001',
            conceptId: 'concept-migration-001',
            question: 'O que é custo de oportunidade?',
            answer: 'É o valor da melhor alternativa abandonada.',
            sourceNotePath: '/tmp/legacy/economia.md',
            sourceNoteTitle: 'Economia',
            createdAt: DateTime(
              2026,
              8,
              20,
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

          final record = await migrationService.migrateBrainReview(
            review,
          );

          expect(
            record.status,
            BrainMigrationStatus.validated,
          );

          expect(
            record.objectId,
            isNotNull,
          );

          final decoded = await vaultService.readObject(
            record.objectId!,
          );

          expect(
            decoded,
            isNotNull,
          );

          expect(
            decoded!.data['question'],
            review.question,
          );

          expect(
            decoded.data['answer'],
            review.answer,
          );
        },
      );

      // ============================================================
      // REVIEW IDEMPOTENCE
      // ============================================================

      test(
        'migrar mesma review novamente não duplica objeto',
        () async {
          final review = BrainReviewItem(
            id: 'review-idempotent-001',
            conceptId: 'concept-idempotent-001',
            question: 'Pergunta?',
            answer: 'Resposta.',
            sourceNotePath: '/tmp/legacy/idempotent.md',
            sourceNoteTitle: 'Idempotente',
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

          final first = await migrationService.migrateBrainReview(
            review,
          );

          final second = await migrationService.migrateBrainReview(
            review,
          );

          expect(
            second.objectId,
            first.objectId,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // MIGRATE ALL
      // ============================================================

      test(
        'migrateAll migra files e reviews',
        () async {
          final file = BrainFile(
            topic: 'Programação',
            title: 'Ponteiros',
            path: '/tmp/legacy/ponteiros.md',
            content: 'Ponteiros armazenam endereços.',
            concepts: const [],
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            updatedAt: DateTime(
              2026,
              9,
              2,
            ),
          );

          final review = BrainReviewItem(
            id: 'review-all-001',
            conceptId: 'concept-all-001',
            question: 'O que um ponteiro armazena?',
            answer: 'Um endereço de memória.',
            sourceNotePath: file.path,
            sourceNoteTitle: file.title,
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

          final result = await migrationService.migrateAll(
            files: [
              file,
            ],
            reviews: [
              review,
            ],
          );

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
            result.hasFailures,
            false,
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
        },
      );

      // ============================================================
      // DIFFERENT LEGACY IDS
      // ============================================================

      test(
        'arquivos diferentes recebem objectIds diferentes',
        () async {
          final firstFile = BrainFile(
            topic: '',
            title: 'Primeiro',
            path: '/tmp/legacy/primeiro.md',
            content: 'A',
            concepts: const [],
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            updatedAt: DateTime(
              2026,
              9,
              2,
            ),
          );

          final secondFile = BrainFile(
            topic: '',
            title: 'Segundo',
            path: '/tmp/legacy/segundo.md',
            content: 'B',
            concepts: const [],
            createdAt: DateTime(
              2026,
              9,
              1,
            ),
            updatedAt: DateTime(
              2026,
              9,
              2,
            ),
          );

          final first = await migrationService.migrateBrainFile(
            firstFile,
          );

          final second = await migrationService.migrateBrainFile(
            secondFile,
          );

          expect(
            first.objectId,
            isNot(
              second.objectId,
            ),
          );
        },
      );

      // ============================================================
      // EMPTY PATH
      // ============================================================

      test(
        'rejeita BrainFile sem legacy path',
        () async {
          final file = BrainFile(
            topic: '',
            title: 'Sem path',
            path: '',
            content: 'Teste',
            concepts: const [],
            createdAt: DateTime(
              2026,
              9,
              2,
            ),
            updatedAt: DateTime(
              2026,
              9,
              2,
            ),
          );

          expect(
            () async {
              await migrationService.migrateBrainFile(
                file,
              );
            },
            throwsArgumentError,
          );
        },
      );
    },
  );
}
