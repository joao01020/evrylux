import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_queue.dart';

import '../models/brain_review_item.dart';
import '../services/review_storage.dart';
import '../services/supabase_review_service.dart';

import '../vault/stores/brain_review_vault_store.dart';

// ============================================================
// REVIEW REPOSITORY
// ============================================================
//
// Arquitetura atual:
//
// UI
//  ↓
// ReviewController
//  ↓
// ReviewRepository
//  ↓
// BrainReviewVaultStore
//  ↓
// BrainVaultService
//  ↓
// Vault criptografado
//
// ============================================================
//
// ReviewStorage:
//
// continua existindo temporariamente como armazenamento legado.
//
// Ele NÃO é mais a fonte principal.
//
// ============================================================
//
// SupabaseReviewService:
//
// continua existindo apenas para compatibilidade/importação
// explícita do backend legado.
//
// Novas alterações locais NÃO são enviadas para brain_reviews.
//
// ============================================================
//
// SyncQueue:
//
// nesta etapa NÃO recebe novos payloads de review.
//
// Motivo:
//
// o formato antigo colocava:
//
// - question;
// - answer;
// - source_note_path;
// - source_note_title;
//
// em plaintext.
//
// A sincronização será reativada quando existir:
//
// brain_objects
// +
// payload criptografado
// +
// SyncQueue E2EE.
//
// ============================================================
//
// REGRA:
//
// - Vault é a fonte local principal;
// - save/delete funcionam sem login;
// - autenticação só é necessária para operações remotas explícitas;
// - nenhum plaintext novo de review entra na SyncQueue.
//
// ============================================================

class ReviewRepository {
  ReviewRepository({
    required BrainReviewVaultStore vaultStore,
    SupabaseReviewService? remote,
    ReviewStorage? local,
    SyncQueue? syncQueue,
  }) : _vaultStore =
           vaultStore,
       _remote =
           remote ??
           SupabaseReviewService(),
       _legacyLocal =
           local ??
           const ReviewStorage(),
       _legacySyncQueue =
           syncQueue ??
           SyncQueue();

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainReviewVaultStore _vaultStore;

  final SupabaseReviewService _remote;

  final ReviewStorage _legacyLocal;

  final SyncQueue _legacySyncQueue;

  // ============================================================
  // LEGACY ENTITY TYPE
  // ============================================================
  //
  // Mantido porque refreshFromRemote() ainda precisa reconhecer
  // alterações antigas já existentes na SyncQueue.
  //
  // Novas alterações NÃO são enfileiradas por este repository.
  //
  // ============================================================

  static const String entityType = 'brain_review';

  // ============================================================
  // AUTH
  // ============================================================

  bool get isAuthenticated {
    return _remote.isAuthenticated;
  }

  String? get currentUserId {
    return _remote.currentUserId;
  }

  String _requireUserId() {
    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    await _vaultStore.initialize();
  }

  // ============================================================
  // LOAD ALL
  // ============================================================
  //
  // Fonte principal:
  //
  // Vault criptografado.
  //
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() async {
    await initialize();

    final reviews = await _vaultStore.loadReviews();

    _sort(
      reviews,
    );

    return reviews;
  }

  // ============================================================
  // LEGACY FALLBACK LOAD
  // ============================================================
  //
  // Método separado para compatibilidade/migração.
  //
  // Não é usado como leitura principal.
  //
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadLegacyReviews() async {
    final reviews = await _legacyLocal.loadReviews();

    _sort(
      reviews,
    );

    return reviews;
  }

  // ============================================================
  // REFRESH FROM REMOTE
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Isto NÃO é a nova sincronização E2EE.
  //
  // É apenas uma ponte explícita para importar dados existentes
  // da tabela legada brain_reviews.
  //
  // Requer autenticação porque acessa Supabase.
  //
  // Depois de carregados, os itens são gravados no Vault.
  //
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  refreshFromRemote() async {
    _requireUserId();

    final remoteReviews = await _remote.loadReviews();

    final vaultReviews = await _vaultStore.loadReviews();

    final merged =
        <
          String,
          BrainReviewItem
        >{
          for (final review in vaultReviews) review.id: review,
        };

    // ========================================================
    // LEGACY PENDING PROTECTION
    // ========================================================
    //
    // Se existir uma operação antiga pendente na SyncQueue,
    // mantemos a versão local do Vault.
    //
    // Isso evita que um refresh do backend antigo sobrescreva
    // uma alteração que ainda estava pendente antes da migração.
    //
    // ========================================================

    for (final remoteReview in remoteReviews) {
      final localReview = merged[remoteReview.id];

      if (localReview ==
          null) {
        merged[remoteReview.id] = remoteReview;

        continue;
      }

      final pending = await _legacySyncQueue.findByEntity(
        entityType: entityType,
        entityId: remoteReview.id,
      );

      if (pending ==
          null) {
        merged[remoteReview.id] = remoteReview;
      }
    }

    final result = merged.values.toList();

    _sort(
      result,
    );

    // ========================================================
    // IMPORT INTO VAULT
    // ========================================================

    for (final review in result) {
      await _vaultStore.saveReview(
        review,
      );
    }

    return result;
  }

  // ============================================================
  // IMPORT LEGACY LOCAL
  // ============================================================
  //
  // Permite importar explicitamente reviews.json legado para o
  // Vault.
  //
  // É idempotente porque BrainReviewVaultStore faz upsert por
  // review.id.
  //
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  importLegacyLocalReviews() async {
    final legacyReviews = await _legacyLocal.loadReviews();

    for (final review in legacyReviews) {
      await _vaultStore.saveReview(
        review,
      );
    }

    final result = await _vaultStore.loadReviews();

    _sort(
      result,
    );

    return result;
  }

  // ============================================================
  // SAVE ONE
  // ============================================================
  //
  // Não exige autenticação.
  //
  // Fluxo:
  //
  // review
  // ↓
  // normalize
  // ↓
  // Vault
  //
  // Nenhum payload é enviado para SyncQueue nesta etapa.
  //
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) async {
    final normalized = _normalizeReview(
      review,
    );

    final saved = await _vaultStore.saveReview(
      normalized,
    );

    debugPrint(
      '[REVIEW REPOSITORY] '
      '${saved.id} salvo no Vault criptografado.',
    );

    return saved;
  }

  // ============================================================
  // SAVE MANY
  // ============================================================

  Future<
    void
  >
  saveReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) async {
    for (final review in reviews) {
      await saveReview(
        review,
      );
    }
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReview(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    return _vaultStore.getReview(
      cleanId,
    );
  }

  // ============================================================
  // GET BY CONCEPT
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReviewByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return null;
    }

    return _vaultStore.getReviewByConceptId(
      cleanConceptId,
    );
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  hasReviewForConcept(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return false;
    }

    return _vaultStore.hasReviewForConcept(
      cleanConceptId,
    );
  }

  // ============================================================
  // DUE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadDueReviews({
    DateTime? now,
  }) {
    return _vaultStore.loadDueReviews(
      now: now,
    );
  }

  // ============================================================
  // UPCOMING
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadUpcomingReviews({
    DateTime? now,
  }) {
    return _vaultStore.loadUpcomingReviews(
      now: now,
    );
  }

  // ============================================================
  // ACTIVE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() {
    return _vaultStore.loadActiveReviews();
  }

  // ============================================================
  // ARCHIVED
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() {
    return _vaultStore.loadArchivedReviews();
  }

  // ============================================================
  // UPDATE NEXT REVIEW
  // ============================================================

  Future<
    BrainReviewItem
  >
  updateNextReview({
    required BrainReviewItem review,
    required DateTime nextReviewAt,
  }) {
    final updated = review.copyWith(
      nextReviewAt: nextReviewAt,
    );

    return saveReview(
      updated,
    );
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<
    BrainReviewItem
  >
  archiveReview(
    BrainReviewItem review,
  ) {
    final updated = review.copyWith(
      archived: true,
      archivedAt: DateTime.now(),
    );

    return saveReview(
      updated,
    );
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<
    BrainReviewItem
  >
  restoreReview(
    BrainReviewItem review,
  ) {
    final updated = review.copyWith(
      archived: false,
      clearArchivedAt: true,
      nextReviewAt: DateTime.now(),
    );

    return saveReview(
      updated,
    );
  }

  // ============================================================
  // POSTPONE
  // ============================================================

  Future<
    BrainReviewItem
  >
  postponeReview(
    BrainReviewItem review, {
    Duration duration = const Duration(
      days: 1,
    ),
  }) {
    final updated = review.copyWith(
      nextReviewAt: DateTime.now().add(
        duration,
      ),
    );

    return saveReview(
      updated,
    );
  }

  // ============================================================
  // DELETE BY ID
  // ============================================================
  //
  // Não exige autenticação.
  //
  // BrainReviewVaultStore cria tombstone.
  //
  // Nenhum delete novo é colocado na SyncQueue antiga.
  //
  // ============================================================

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    await _vaultStore.deleteReview(
      cleanId,
    );

    debugPrint(
      '[REVIEW REPOSITORY] '
      '$cleanId excluído do Vault por tombstone.',
    );
  }

  // ============================================================
  // DELETE BY CONCEPT
  // ============================================================

  Future<
    void
  >
  deleteReviewByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return;
    }

    await _vaultStore.deleteReviewByConceptId(
      cleanConceptId,
    );
  }

  // ============================================================
  // DELETE BY SOURCE NOTE
  // ============================================================

  Future<
    void
  >
  deleteReviewsBySourceNotePath(
    String sourceNotePath,
  ) async {
    final cleanPath = sourceNotePath.trim();

    if (cleanPath.isEmpty) {
      return;
    }

    await _vaultStore.deleteReviewsBySourceNotePath(
      cleanPath,
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() {
    return _vaultStore.count();
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  BrainReviewItem _normalizeReview(
    BrainReviewItem review,
  ) {
    final id = review.id.trim();

    final conceptId = review.conceptId.trim();

    final question = review.question.trim();

    final answer = review.answer.trim();

    final sourceNotePath = review.sourceNotePath.trim();

    final sourceNoteTitle = review.sourceNoteTitle.trim();

    if (id.isEmpty) {
      throw StateError(
        'Revisão sem ID.',
      );
    }

    if (conceptId.isEmpty) {
      throw StateError(
        'Revisão sem conceptId.',
      );
    }

    if (question.isEmpty) {
      throw StateError(
        'Revisão sem pergunta.',
      );
    }

    if (answer.isEmpty) {
      throw StateError(
        'Revisão sem resposta.',
      );
    }

    if (sourceNotePath.isEmpty) {
      throw StateError(
        'Revisão sem caminho da anotação de origem.',
      );
    }

    return review.copyWith(
      id: id,
      conceptId: conceptId,
      question: question,
      answer: answer,
      sourceNotePath: sourceNotePath,
      sourceNoteTitle: sourceNoteTitle,
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sort(
    List<
      BrainReviewItem
    >
    reviews,
  ) {
    reviews.sort(
      (
        first,
        second,
      ) {
        if (first.archived !=
            second.archived) {
          return first.archived
              ? 1
              : -1;
        }

        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
    );
  }
}
