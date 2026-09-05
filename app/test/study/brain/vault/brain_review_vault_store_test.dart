import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';
import 'package:EVRYLUX/study/brain/vault/stores/brain_review_vault_store.dart';

// ============================================================
// BRAIN REVIEW VAULT STORE TEST
// ============================================================
//
// Aqui usamos InMemoryBrainKeyStorage porque:
//
// - este é um UNIT TEST;
// - persistência real da Master Key já possui integration test;
// - queremos testar isoladamente a lógica do Review Vault Store.
//
// ============================================================

void
main() {
  group(
    'BrainReviewVaultStore',
    () {
      late Directory tempDirectory;

      late InMemoryBrainKeyStorage keyStorage;

      late BrainKeyService keyService;

      late BrainVaultStorage vaultStorage;

      late BrainVaultService vaultService;

      late BrainReviewVaultStore store;

      // ============================================================
      // TEST DATA
      // ============================================================

      BrainReviewItem createReview({
        String id = 'review_001',
        String conceptId = 'concept_001',
        String question = 'O que é encapsulamento?',
        String answer = 'Proteção do estado interno.',
        String sourceNotePath = '/legacy/oop.md',
        String sourceNoteTitle = 'Orientação a Objetos',
        DateTime? createdAt,
        DateTime? nextReviewAt,
        DateTime? lastReviewedAt,
        DateTime? archivedAt,
        int reviewCount = 0,
        int correctCount = 0,
        int wrongCount = 0,
        int streak = 0,
        bool archived = false,
      }) {
        final created =
            createdAt ??
            DateTime(
              2026,
              9,
              2,
              12,
            );

        return BrainReviewItem(
          id: id,
          conceptId: conceptId,
          question: question,
          answer: answer,
          sourceNotePath: sourceNotePath,
          sourceNoteTitle: sourceNoteTitle,
          createdAt: created,
          nextReviewAt:
              nextReviewAt ??
              created.add(
                const Duration(
                  days: 1,
                ),
              ),
          lastReviewedAt: lastReviewedAt,
          archivedAt: archivedAt,
          reviewCount: reviewCount,
          correctCount: correctCount,
          wrongCount: wrongCount,
          streak: streak,
          archived: archived,
        );
      }

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_review_vault_store_',
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

          store = BrainReviewVaultStore(
            vaultService: vaultService,
          );

          await store.initialize();
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
      // EMPTY
      // ============================================================

      test(
        'começa vazio',
        () async {
          final reviews = await store.loadReviews();

          expect(
            reviews,
            isEmpty,
          );

          expect(
            await store.count(),
            0,
          );
        },
      );

      // ============================================================
      // CREATE
      // ============================================================

      test(
        'salva revisão no Vault',
        () async {
          final review = createReview();

          final saved = await store.saveReview(
            review,
          );

          expect(
            saved.id,
            review.id,
          );

          final reviews = await store.loadReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.single.id,
            review.id,
          );

          expect(
            reviews.single.question,
            review.question,
          );

          expect(
            reviews.single.answer,
            review.answer,
          );
        },
      );

      // ============================================================
      // OBJECT TYPE
      // ============================================================

      test(
        'salva revisão como objeto criptografado do Vault',
        () async {
          final review = createReview();

          await store.saveReview(
            review,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );

          expect(
            objects.single.isDeleted,
            false,
          );

          expect(
            objects.single.encryptedPayload,
            isNotNull,
          );
        },
      );

      // ============================================================
      // NO PLAINTEXT MODEL IN RAW OBJECT
      // ============================================================

      test(
        'conteúdo sensível não aparece no objeto criptografado',
        () async {
          final review = createReview(
            question: 'PERGUNTA_SUPER_SECRETA_123',
            answer: 'RESPOSTA_SUPER_SECRETA_456',
          );

          await store.saveReview(
            review,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );

          final raw = objects.single.toString();

          expect(
            raw.contains(
              'PERGUNTA_SUPER_SECRETA_123',
            ),
            false,
          );

          expect(
            raw.contains(
              'RESPOSTA_SUPER_SECRETA_456',
            ),
            false,
          );
        },
      );

      // ============================================================
      // GET
      // ============================================================

      test(
        'busca revisão pelo id',
        () async {
          await store.saveReview(
            createReview(
              id: 'review_find',
            ),
          );

          final result = await store.getReview(
            'review_find',
          );

          expect(
            result,
            isNotNull,
          );

          expect(
            result!.id,
            'review_find',
          );
        },
      );

      // ============================================================
      // GET NOT FOUND
      // ============================================================

      test(
        'retorna null para revisão inexistente',
        () async {
          final result = await store.getReview(
            'review_missing',
          );

          expect(
            result,
            isNull,
          );
        },
      );

      // ============================================================
      // GET ENTRY
      // ============================================================

      test(
        'expõe relação entre review id e object id',
        () async {
          await store.saveReview(
            createReview(
              id: 'review_entry',
            ),
          );

          final entry = await store.getEntry(
            'review_entry',
          );

          expect(
            entry,
            isNotNull,
          );

          expect(
            entry!.review.id,
            'review_entry',
          );

          expect(
            entry.objectId,
            isNotEmpty,
          );

          expect(
            entry.isValid,
            true,
          );
        },
      );

      // ============================================================
      // CONCEPT
      // ============================================================

      test(
        'busca revisão pelo conceptId',
        () async {
          await store.saveReview(
            createReview(
              conceptId: 'concept_find',
            ),
          );

          final review = await store.getReviewByConceptId(
            'concept_find',
          );

          expect(
            review,
            isNotNull,
          );

          expect(
            review!.conceptId,
            'concept_find',
          );

          expect(
            await store.hasReviewForConcept(
              'concept_find',
            ),
            true,
          );
        },
      );

      // ============================================================
      // UPDATE
      // ============================================================

      test(
        'atualiza revisão sem criar segundo objeto',
        () async {
          final original = createReview(
            id: 'review_update',
            question: 'Pergunta original?',
          );

          await store.saveReview(
            original,
          );

          final originalEntry = await store.getEntry(
            'review_update',
          );

          expect(
            originalEntry,
            isNotNull,
          );

          final updated = original.copyWith(
            question: 'Pergunta atualizada?',
            answer: 'Resposta atualizada.',
            reviewCount: 3,
            correctCount: 2,
            wrongCount: 1,
            streak: 2,
          );

          await store.saveReview(
            updated,
          );

          final updatedEntry = await store.getEntry(
            'review_update',
          );

          expect(
            updatedEntry,
            isNotNull,
          );

          // ========================================================
          // SAME VAULT OBJECT
          // ========================================================

          expect(
            updatedEntry!.objectId,
            originalEntry!.objectId,
          );

          expect(
            updatedEntry.review.question,
            'Pergunta atualizada?',
          );

          expect(
            updatedEntry.review.answer,
            'Resposta atualizada.',
          );

          expect(
            updatedEntry.review.reviewCount,
            3,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );

          expect(
            objects.single.header.objectVersion.value,
            2,
          );
        },
      );

      // ============================================================
      // NO DUPLICATE
      // ============================================================

      test(
        'salvar a mesma revisão duas vezes não duplica objeto',
        () async {
          final review = createReview(
            id: 'review_idempotent',
          );

          await store.saveReview(
            review,
          );

          await store.saveReview(
            review,
          );

          final reviews = await store.loadReviews();

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            reviews.length,
            1,
          );

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // MULTIPLE
      // ============================================================

      test(
        'salva múltiplas revisões',
        () async {
          await store.saveReviews(
            [
              createReview(
                id: 'review_1',
                conceptId: 'concept_1',
              ),
              createReview(
                id: 'review_2',
                conceptId: 'concept_2',
              ),
              createReview(
                id: 'review_3',
                conceptId: 'concept_3',
              ),
            ],
          );

          expect(
            await store.count(),
            3,
          );
        },
      );

      // ============================================================
      // IGNORE OTHER OBJECT TYPES
      // ============================================================

      test(
        'ignora objetos que não são reviews',
        () async {
          await vaultService.createObject(
            type: BrainVaultObjectType.generic,
            data: const {
              'model': 'generic_test',
              'value': 'não é review',
            },
          );

          await store.saveReview(
            createReview(),
          );

          final reviews = await store.loadReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.single.id,
            'review_001',
          );

          final allObjects = await vaultService.loadAllEncryptedObjects();

          expect(
            allObjects.length,
            2,
          );
        },
      );

      // ============================================================
      // DELETE
      // ============================================================

      test(
        'delete cria tombstone e remove revisão da leitura',
        () async {
          await store.saveReview(
            createReview(
              id: 'review_delete',
            ),
          );

          final entry = await store.getEntry(
            'review_delete',
          );

          expect(
            entry,
            isNotNull,
          );

          await store.deleteReview(
            'review_delete',
          );

          final review = await store.getReview(
            'review_delete',
          );

          expect(
            review,
            isNull,
          );

          final raw = await vaultService.loadEncryptedObject(
            entry!.objectId,
          );

          expect(
            raw,
            isNotNull,
          );

          expect(
            raw!.isDeleted,
            true,
          );

          expect(
            raw.tombstone,
            isNotNull,
          );
        },
      );

      // ============================================================
      // DELETE MISSING
      // ============================================================

      test(
        'delete de revisão inexistente é idempotente',
        () async {
          await store.deleteReview(
            'missing_review',
          );

          expect(
            await store.count(),
            0,
          );
        },
      );

      // ============================================================
      // DELETE BY CONCEPT
      // ============================================================

      test(
        'exclui revisão pelo conceptId',
        () async {
          await store.saveReview(
            createReview(
              id: 'review_concept_delete',
              conceptId: 'concept_delete',
            ),
          );

          await store.deleteReviewByConceptId(
            'concept_delete',
          );

          expect(
            await store.getReview(
              'review_concept_delete',
            ),
            isNull,
          );
        },
      );

      // ============================================================
      // DELETE BY SOURCE
      // ============================================================

      test(
        'exclui revisões pela nota de origem',
        () async {
          await store.saveReviews(
            [
              createReview(
                id: 'review_source_1',
                conceptId: 'concept_source_1',
                sourceNotePath: '/notes/source.md',
              ),
              createReview(
                id: 'review_source_2',
                conceptId: 'concept_source_2',
                sourceNotePath: '/notes/source.md',
              ),
              createReview(
                id: 'review_other',
                conceptId: 'concept_other',
                sourceNotePath: '/notes/other.md',
              ),
            ],
          );

          await store.deleteReviewsBySourceNotePath(
            '/notes/source.md',
          );

          final reviews = await store.loadReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.single.id,
            'review_other',
          );
        },
      );

      // ============================================================
      // DUE / UPCOMING
      // ============================================================

      test(
        'separa revisões vencidas e futuras',
        () async {
          final now = DateTime(
            2026,
            9,
            2,
            12,
          );

          await store.saveReviews(
            [
              createReview(
                id: 'review_due',
                conceptId: 'concept_due',
                nextReviewAt: now.subtract(
                  const Duration(
                    hours: 1,
                  ),
                ),
              ),
              createReview(
                id: 'review_upcoming',
                conceptId: 'concept_upcoming',
                nextReviewAt: now.add(
                  const Duration(
                    days: 1,
                  ),
                ),
              ),
            ],
          );

          final due = await store.loadDueReviews(
            now: now,
          );

          final upcoming = await store.loadUpcomingReviews(
            now: now,
          );

          expect(
            due.length,
            1,
          );

          expect(
            due.single.id,
            'review_due',
          );

          expect(
            upcoming.length,
            1,
          );

          expect(
            upcoming.single.id,
            'review_upcoming',
          );
        },
      );

      // ============================================================
      // ARCHIVED
      // ============================================================

      test(
        'separa revisões ativas e arquivadas',
        () async {
          final archivedAt = DateTime(
            2026,
            9,
            2,
            14,
          );

          await store.saveReviews(
            [
              createReview(
                id: 'review_active',
                conceptId: 'concept_active',
              ),
              createReview(
                id: 'review_archived',
                conceptId: 'concept_archived',
                archived: true,
                archivedAt: archivedAt,
              ),
            ],
          );

          final active = await store.loadActiveReviews();

          final archived = await store.loadArchivedReviews();

          expect(
            active.length,
            1,
          );

          expect(
            active.single.id,
            'review_active',
          );

          expect(
            archived.length,
            1,
          );

          expect(
            archived.single.id,
            'review_archived',
          );
        },
      );

      // ============================================================
      // NORMALIZE
      // ============================================================

      test(
        'normaliza campos antes de salvar',
        () async {
          final review = createReview(
            id: '  review_trim  ',
            conceptId: '  concept_trim  ',
            question: '  Pergunta?  ',
            answer: '  Resposta.  ',
            sourceNotePath: '  /note.md  ',
            sourceNoteTitle: '  Nota  ',
          );

          final saved = await store.saveReview(
            review,
          );

          expect(
            saved.id,
            'review_trim',
          );

          expect(
            saved.conceptId,
            'concept_trim',
          );

          expect(
            saved.question,
            'Pergunta?',
          );

          expect(
            saved.answer,
            'Resposta.',
          );

          expect(
            saved.sourceNotePath,
            '/note.md',
          );

          expect(
            saved.sourceNoteTitle,
            'Nota',
          );
        },
      );

      // ============================================================
      // INVALID
      // ============================================================

      test(
        'não salva revisão sem pergunta',
        () async {
          final review = createReview(
            question: '   ',
          );

          expect(
            () async {
              await store.saveReview(
                review,
              );
            },
            throwsStateError,
          );

          expect(
            await store.count(),
            0,
          );
        },
      );
    },
  );
}
