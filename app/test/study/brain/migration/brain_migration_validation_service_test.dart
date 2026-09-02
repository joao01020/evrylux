import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/models/brain_file.dart';
import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/migration/services/brain_migration_validation_service.dart';

import 'package:EVRYLUX/study/brain/vault/mappers/brain_file_vault_mapper.dart';
import 'package:EVRYLUX/study/brain/vault/mappers/brain_review_vault_mapper.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void
main() {
  group(
    'BrainMigrationValidationService',
    () {
      late Directory tempDirectory;

      late BrainVaultService vaultService;

      late BrainMigrationValidationService validationService;

      const fileMapper = BrainFileVaultMapper();

      const reviewMapper = BrainReviewVaultMapper();

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_migration_validation_test_',
          );

          final keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          final storage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: storage,
          );

          validationService = BrainMigrationValidationService(
            vaultService: vaultService,
          );

          await vaultService.createVault();
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

      // ============================================================
      // BRAIN FILE
      // ============================================================

      test(
        'valida BrainFile migrado corretamente',
        () async {
          final file = BrainFile(
            topic: 'Vendas',
            title: 'Perguntas abertas',
            path: '/tmp/perguntas-abertas.md',
            content: 'Perguntas abertas ajudam a descobrir necessidades.',
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

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: fileMapper.toVaultData(
              file,
            ),
          );

          final result = await validationService.validateBrainFile(
            objectId: object.header.objectId,
            source: file,
          );

          expect(
            result.valid,
            true,
          );

          expect(
            result.reason,
            isNull,
          );
        },
      );

      test(
        'detecta BrainFile diferente da origem',
        () async {
          final original = BrainFile(
            topic: 'Vendas',
            title: 'Original',
            path: '/tmp/original.md',
            content: 'Conteúdo original',
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

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.note,
            data: fileMapper.toVaultData(
              original,
            ),
          );

          final changed = BrainFile(
            topic: original.topic,
            title: original.title,
            path: original.path,
            content: 'CONTEÚDO ALTERADO',
            concepts: const [],
            createdAt: original.createdAt,
            updatedAt: original.updatedAt,
          );

          final result = await validationService.validateBrainFile(
            objectId: object.header.objectId,
            source: changed,
          );

          expect(
            result.valid,
            false,
          );
        },
      );

      // ============================================================
      // REVIEW
      // ============================================================

      test(
        'valida BrainReviewItem migrado corretamente',
        () async {
          final review = BrainReviewItem(
            id: 'review-validation-001',
            conceptId: 'concept-validation-001',
            question: 'O que é margem?',
            answer: 'Diferença entre receita e determinados custos.',
            sourceNotePath: '/tmp/margem.md',
            sourceNoteTitle: 'Margem',
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

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.review,
            data: reviewMapper.toVaultData(
              review,
            ),
          );

          final result = await validationService.validateBrainReview(
            objectId: object.header.objectId,
            source: review,
          );

          expect(
            result.valid,
            true,
          );

          expect(
            result.reason,
            isNull,
          );
        },
      );

      test(
        'detecta review diferente da origem',
        () async {
          final original = BrainReviewItem(
            id: 'review-validation-002',
            conceptId: 'concept-validation-002',
            question: 'Pergunta original?',
            answer: 'Resposta original.',
            sourceNotePath: '/tmp/review.md',
            sourceNoteTitle: 'Review',
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

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.review,
            data: reviewMapper.toVaultData(
              original,
            ),
          );

          final changed = BrainReviewItem(
            id: original.id,
            conceptId: original.conceptId,
            question: original.question,
            answer: 'RESPOSTA ALTERADA',
            sourceNotePath: original.sourceNotePath,
            sourceNoteTitle: original.sourceNoteTitle,
            createdAt: original.createdAt,
            nextReviewAt: original.nextReviewAt,
            lastReviewedAt: original.lastReviewedAt,
            archivedAt: original.archivedAt,
            reviewCount: original.reviewCount,
            correctCount: original.correctCount,
            wrongCount: original.wrongCount,
            streak: original.streak,
            archived: original.archived,
          );

          final result = await validationService.validateBrainReview(
            objectId: object.header.objectId,
            source: changed,
          );

          expect(
            result.valid,
            false,
          );
        },
      );

      // ============================================================
      // NOT FOUND
      // ============================================================

      test(
        'retorna inválido para objeto inexistente',
        () async {
          final file = BrainFile(
            topic: '',
            title: 'Teste',
            path: '/tmp/teste.md',
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

          final result = await validationService.validateBrainFile(
            objectId: 'obj_AAAAAAAAAAAAAAAAAAAAAA',
            source: file,
          );

          expect(
            result.valid,
            false,
          );

          expect(
            result.reason,
            isNotNull,
          );
        },
      );

      // ============================================================
      // WRONG TYPE
      // ============================================================

      test(
        'detecta tipo de objeto incorreto',
        () async {
          final file = BrainFile(
            topic: '',
            title: 'Teste',
            path: '/tmp/wrong-type.md',
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

          final object = await vaultService.createObject(
            type: BrainVaultObjectType.review,
            data: {
              'question': 'Teste?',
              'answer': 'Teste.',
            },
          );

          final result = await validationService.validateBrainFile(
            objectId: object.header.objectId,
            source: file,
          );

          expect(
            result.valid,
            false,
          );
        },
      );
    },
  );
}
