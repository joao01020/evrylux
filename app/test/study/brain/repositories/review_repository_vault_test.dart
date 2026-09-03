import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:EVRYLUX/core/sync/sync_queue.dart';

import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/repositories/review_repository.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/services/supabase_review_service.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';
import 'package:EVRYLUX/study/brain/vault/stores/brain_review_vault_store.dart';

// ============================================================
// REVIEW REPOSITORY VAULT TEST
// ============================================================
//
// Objetivos:
//
// 1. provar que ReviewRepository funciona sem login;
// 2. provar que Vault é a fonte principal;
// 3. provar create/update;
// 4. provar leitura;
// 5. provar delete por tombstone;
// 6. provar consultas por conceptId;
// 7. provar due/upcoming;
// 8. provar persistência após recriar repository/service graph.
//
// ============================================================
//
// IMPORTANTE:
//
// Este teste usa:
//
// InMemoryBrainKeyStorage
//
// porque persistência real da Master Key já foi validada pelos
// integration tests Linux.
//
// Aqui queremos testar especificamente:
//
// ReviewRepository
//        ↓
// BrainReviewVaultStore
//        ↓
// BrainVaultService
//
// ============================================================

void
main() {
  group(
    'ReviewRepository Vault-first',
    () {
      late Directory tempDirectory;

      late InMemoryBrainKeyStorage keyStorage;

      late BrainKeyService keyService;

      late BrainVaultStorage vaultStorage;

      late BrainVaultService vaultService;

      late BrainReviewVaultStore vaultStore;

      late SupabaseReviewService remote;

      late ReviewRepository repository;

      // ============================================================
      // REVIEW FACTORY
      // ============================================================

      BrainReviewItem createReview({
        String id = 'review_001',
        String conceptId = 'concept_001',
        String question = 'O que é encapsulamento?',
        String answer = 'Proteção do estado interno.',
        String sourceNotePath = '/notes/oop.md',
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
      // CREATE REPOSITORY
      // ============================================================

      ReviewRepository createRepository() {
        keyService = BrainKeyService(
          storage: keyStorage,
        );

        vaultStorage = BrainVaultStorage(
          documentsDirectoryProvider: () async => tempDirectory,
        );

        vaultService = BrainVaultService(
          keyService: keyService,
          storage: vaultStorage,
        );

        vaultStore = BrainReviewVaultStore(
          vaultService: vaultService,
        );

        // ==========================================================
        // SUPABASE CLIENT SEM LOGIN
        // ==========================================================
        //
        // Nenhuma chamada de rede será feita nesses testes.
        //
        // Queremos apenas um SupabaseReviewService válido cujo
        // currentUser seja null.
        //
        // Isso permite provar que save/delete locais não dependem
        // de autenticação.
        //
        // ==========================================================

        final client = SupabaseClient(
          'http://localhost:54321',
          'test-anon-key',
        );

        remote = SupabaseReviewService(
          client: client,
        );

        return ReviewRepository(
          vaultStore: vaultStore,
          remote: remote,

          // Dependência explícita do teste.
          //
          // O repository não cria mais uma SyncQueue escondida em
          // produção. Aqui a fila é criada pelo próprio test graph.
          syncQueue: SyncQueue(),
        );
      }

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_review_repository_vault_',
          );

          keyStorage = InMemoryBrainKeyStorage();

          repository = createRepository();

          await repository.initialize();
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

          keyStorage.clear();
        },
      );

      // ============================================================
      // EMPTY
      // ============================================================

      test(
        'inicia com Vault vazio',
        () async {
          final reviews = await repository.loadReviews();

          expect(
            reviews,
            isEmpty,
          );

          expect(
            await repository.count(),
            0,
          );
        },
      );

      // ============================================================
      // SAVE WITHOUT AUTH
      // ============================================================

      test(
        'salva revisão sem usuário autenticado',
        () async {
          expect(
            repository.isAuthenticated,
            false,
          );

          expect(
            repository.currentUserId,
            isNull,
          );

          final review = createReview();

          final saved = await repository.saveReview(
            review,
          );

          expect(
            saved.id,
            review.id,
          );

          expect(
            saved.question,
            review.question,
          );

          expect(
            saved.answer,
            review.answer,
          );

          final loaded = await repository.loadReviews();

          expect(
            loaded.length,
            1,
          );

          expect(
            loaded.single.id,
            review.id,
          );
        },
      );

      // ============================================================
      // NORMALIZE
      // ============================================================

      test(
        'normaliza revisão antes de salvar',
        () async {
          final review = createReview(
            id: '  review_trim  ',
            conceptId: '  concept_trim  ',
            question: '  Pergunta?  ',
            answer: '  Resposta.  ',
            sourceNotePath: '  /notes/teste.md  ',
            sourceNoteTitle: '  Teste  ',
          );

          final saved = await repository.saveReview(
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
            '/notes/teste.md',
          );

          expect(
            saved.sourceNoteTitle,
            'Teste',
          );
        },
      );

      // ============================================================
      // GET
      // ============================================================

      test(
        'busca revisão pelo ID',
        () async {
          await repository.saveReview(
            createReview(
              id: 'review_find',
            ),
          );

          final result = await repository.getReview(
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
      // GET BY CONCEPT
      // ============================================================

      test(
        'busca revisão pelo conceptId',
        () async {
          await repository.saveReview(
            createReview(
              id: 'review_concept',
              conceptId: 'concept_find',
            ),
          );

          final result = await repository.getReviewByConceptId(
            'concept_find',
          );

          expect(
            result,
            isNotNull,
          );

          expect(
            result!.conceptId,
            'concept_find',
          );

          expect(
            await repository.hasReviewForConcept(
              'concept_find',
            ),
            true,
          );

          expect(
            await repository.hasReviewForConcept(
              'concept_missing',
            ),
            false,
          );
        },
      );

      // ============================================================
      // UPDATE
      // ============================================================

      test(
        'atualiza revisão mantendo o mesmo objeto do Vault',
        () async {
          final original = createReview(
            id: 'review_update',
            question: 'Pergunta original?',
          );

          await repository.saveReview(
            original,
          );

          final entryBefore = await vaultStore.getEntry(
            'review_update',
          );

          expect(
            entryBefore,
            isNotNull,
          );

          final updated = original.copyWith(
            question: 'Pergunta atualizada?',
            answer: 'Resposta atualizada.',
            reviewCount: 4,
            correctCount: 3,
            wrongCount: 1,
            streak: 2,
          );

          final saved = await repository.saveReview(
            updated,
          );

          final entryAfter = await vaultStore.getEntry(
            'review_update',
          );

          expect(
            entryAfter,
            isNotNull,
          );

          // ========================================================
          // MESMO OBJECT ID
          // ========================================================

          expect(
            entryAfter!.objectId,
            entryBefore!.objectId,
          );

          expect(
            saved.question,
            'Pergunta atualizada?',
          );

          expect(
            saved.answer,
            'Resposta atualizada.',
          );

          expect(
            saved.reviewCount,
            4,
          );

          expect(
            saved.correctCount,
            3,
          );

          expect(
            saved.wrongCount,
            1,
          );

          expect(
            saved.streak,
            2,
          );

          // ========================================================
          // OBJECT VERSION
          // ========================================================

          final raw = await vaultService.loadEncryptedObject(
            entryAfter.objectId,
          );

          expect(
            raw,
            isNotNull,
          );

          expect(
            raw!.header.objectVersion.value,
            2,
          );
        },
      );

      // ============================================================
      // NO DUPLICATE
      // ============================================================

      test(
        'salvar mesma revisão duas vezes não duplica objeto',
        () async {
          final review = createReview(
            id: 'review_same',
          );

          await repository.saveReview(
            review,
          );

          await repository.saveReview(
            review,
          );

          final reviews = await repository.loadReviews();

          final rawObjects = await vaultService.loadAllEncryptedObjects();

          expect(
            reviews.length,
            1,
          );

          expect(
            rawObjects.length,
            1,
          );
        },
      );

      // ============================================================
      // DELETE WITHOUT AUTH
      // ============================================================

      test(
        'delete funciona sem login e cria tombstone',
        () async {
          expect(
            repository.isAuthenticated,
            false,
          );

          await repository.saveReview(
            createReview(
              id: 'review_delete',
            ),
          );

          final entry = await vaultStore.getEntry(
            'review_delete',
          );

          expect(
            entry,
            isNotNull,
          );

          await repository.deleteReview(
            'review_delete',
          );

          final loaded = await repository.getReview(
            'review_delete',
          );

          expect(
            loaded,
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
          await repository.deleteReview(
            'review_missing',
          );

          expect(
            await repository.count(),
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
          await repository.saveReview(
            createReview(
              id: 'review_delete_concept',
              conceptId: 'concept_delete',
            ),
          );

          await repository.deleteReviewByConceptId(
            'concept_delete',
          );

          expect(
            await repository.getReview(
              'review_delete_concept',
            ),
            isNull,
          );
        },
      );

      // ============================================================
      // DELETE BY SOURCE NOTE
      // ============================================================

      test(
        'exclui revisões pela nota de origem',
        () async {
          await repository.saveReviews(
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

          await repository.deleteReviewsBySourceNotePath(
            '/notes/source.md',
          );

          final reviews = await repository.loadReviews();

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

          await repository.saveReviews(
            [
              createReview(
                id: 'review_due',
                conceptId: 'concept_due',
                nextReviewAt: now.subtract(
                  const Duration(
                    minutes: 10,
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

          final due = await repository.loadDueReviews(
            now: now,
          );

          final upcoming = await repository.loadUpcomingReviews(
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
      // ARCHIVE / RESTORE
      // ============================================================

      test(
        'arquiva e restaura revisão',
        () async {
          final review = createReview(
            id: 'review_archive',
          );

          await repository.saveReview(
            review,
          );

          final archived = await repository.archiveReview(
            review,
          );

          expect(
            archived.archived,
            true,
          );

          expect(
            archived.archivedAt,
            isNotNull,
          );

          final archivedList = await repository.loadArchivedReviews();

          expect(
            archivedList.length,
            1,
          );

          final restored = await repository.restoreReview(
            archived,
          );

          expect(
            restored.archived,
            false,
          );

          expect(
            restored.archivedAt,
            isNull,
          );

          final active = await repository.loadActiveReviews();

          expect(
            active.length,
            1,
          );
        },
      );

      // ============================================================
      // RECREATE REPOSITORY GRAPH
      // ============================================================
      //
      // Prova que ReviewRepository não depende da lista em memória.
      //
      // O segundo repository aponta para:
      //
      // - mesmo diretório do Vault;
      // - mesmo KeyStorage deste unit test.
      //
      // ============================================================

      test(
        'recria repository e continua lendo a revisão do Vault',
        () async {
          await repository.saveReview(
            createReview(
              id: 'review_restart',
              conceptId: 'concept_restart',
              question: 'Persistiu?',
              answer: 'Sim.',
            ),
          );

          // ========================================================
          // DESCARTA GRAFO LÓGICO
          // ========================================================

          final secondRepository = createRepository();

          final reviews = await secondRepository.loadReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.single.id,
            'review_restart',
          );

          expect(
            reviews.single.question,
            'Persistiu?',
          );

          expect(
            reviews.single.answer,
            'Sim.',
          );
        },
      );

      // ============================================================
      // INVALID QUESTION
      // ============================================================

      test(
        'não salva revisão sem pergunta',
        () async {
          final review = createReview(
            question: '   ',
          );

          expect(
            () async {
              await repository.saveReview(
                review,
              );
            },
            throwsStateError,
          );

          expect(
            await repository.count(),
            0,
          );
        },
      );

      // ============================================================
      // INVALID ANSWER
      // ============================================================

      test(
        'não salva revisão sem resposta',
        () async {
          final review = createReview(
            answer: '   ',
          );

          expect(
            () async {
              await repository.saveReview(
                review,
              );
            },
            throwsStateError,
          );

          expect(
            await repository.count(),
            0,
          );
        },
      );
    },
  );
}
