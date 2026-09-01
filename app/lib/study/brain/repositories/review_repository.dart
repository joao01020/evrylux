import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

import '../models/brain_review_item.dart';
import '../services/review_storage.dart';
import '../services/supabase_review_service.dart';

// ============================================================
// REVIEW REPOSITORY
// ============================================================
//
// Arquitetura OFFLINE-FIRST:
//
// UI
//  ↓
// ReviewController
//  ↓
// ReviewRepository
//  ↓
// ReviewStorage local
//  ↓
// SyncQueue
//  ↓
// SyncService
//  ↓
// SupabaseReviewService
//  ↓
// brain_reviews
//
// REGRA:
//
// - leitura principal: local;
// - escrita: local primeiro;
// - Supabase: sincronização posterior;
// - sem internet: revisão continua funcionando.
//
// ============================================================

class ReviewRepository {
  ReviewRepository({
    SupabaseReviewService? remote,
    ReviewStorage? local,
    SyncQueue? syncQueue,
    SyncService? syncService,
  }) : _remote =
           remote ??
           SupabaseReviewService(),
       _local =
           local ??
           const ReviewStorage(),
       _syncQueue =
           syncQueue ??
           SyncQueue(),
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseReviewService _remote;

  final ReviewStorage _local;

  final SyncQueue _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // SYNC ENTITY TYPE
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
  // LOAD ALL
  // ============================================================
  //
  // Sempre lê primeiro do armazenamento local.
  //
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() async {
    final reviews = await _local.loadReviews();

    _sort(
      reviews,
    );

    return reviews;
  }

  // ============================================================
  // REFRESH FROM REMOTE
  // ============================================================
  //
  // Atualiza o cache local com o Supabase.
  //
  // Só deve ser chamado quando quisermos explicitamente trazer
  // os dados remotos para este dispositivo.
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

    final pendingLocal = await _local.loadReviews();

    // ========================================================
    // NÃO SOBRESCREVER ITEM COM ALTERAÇÃO PENDENTE
    // ========================================================

    final merged =
        <
          String,
          BrainReviewItem
        >{
          for (final review in remoteReviews) review.id: review,
        };

    for (final localReview in pendingLocal) {
      final pending = await _syncQueue.findByEntity(
        entityType: entityType,
        entityId: localReview.id,
      );

      if (pending !=
          null) {
        merged[localReview.id] = localReview;
      }
    }

    final result = merged.values.toList();

    _sort(
      result,
    );

    await _local.saveReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // SAVE ONE
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) async {
    final userId = _requireUserId();

    final normalized = _normalizeReview(
      review,
    );

    final reviews = await _local.loadReviews();

    final index = reviews.indexWhere(
      (
        item,
      ) {
        return item.id ==
            normalized.id;
      },
    );

    final operation =
        index >=
            0
        ? SyncOperation.update
        : SyncOperation.create;

    if (index >=
        0) {
      reviews[index] = normalized;
    } else {
      reviews.add(
        normalized,
      );
    }

    _sort(
      reviews,
    );

    // ========================================================
    // LOCAL FIRST
    // ========================================================

    await _local.saveReviews(
      reviews,
    );

    debugPrint(
      '[REVIEW REPOSITORY] '
      '${normalized.id} salvo localmente.',
    );

    // ========================================================
    // SYNC QUEUE
    // ========================================================

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: normalized.id,
      operation: operation,
      payload: _toSyncPayload(
        normalized,
        userId: userId,
      ),
    );

    _syncService?.requestSync();

    return normalized;
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

    final reviews = await _local.loadReviews();

    for (final review in reviews) {
      if (review.id ==
          cleanId) {
        return review;
      }
    }

    return null;
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

    final reviews = await _local.loadReviews();

    for (final review in reviews) {
      if (review.conceptId ==
          cleanConceptId) {
        return review;
      }
    }

    return null;
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
    final review = await getReviewByConceptId(
      conceptId,
    );

    return review !=
        null;
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
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return !review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sort(
      result,
    );

    return result;
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
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sort(
      result,
    );

    return result;
  }

  // ============================================================
  // ACTIVE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() async {
    final reviews = await loadReviews();

    return reviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();
  }

  // ============================================================
  // ARCHIVED
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() async {
    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        return review.archived;
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        final firstDate =
            first.archivedAt ??
            first.createdAt;

        final secondDate =
            second.archivedAt ??
            second.createdAt;

        return secondDate.compareTo(
          firstDate,
        );
      },
    );

    return result;
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

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    final userId = _requireUserId();

    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    final reviews = await _local.loadReviews();

    reviews.removeWhere(
      (
        review,
      ) {
        return review.id ==
            cleanId;
      },
    );

    // ========================================================
    // LOCAL FIRST
    // ========================================================

    await _local.saveReviews(
      reviews,
    );

    debugPrint(
      '[REVIEW REPOSITORY] '
      '$cleanId excluído localmente.',
    );

    // ========================================================
    // SYNC QUEUE
    // ========================================================

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: cleanId,
      operation: SyncOperation.delete,
      payload: {
        'id': cleanId,
        'user_id': userId,
      },
    );

    _syncService?.requestSync();
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

    final reviews = await _local.loadReviews();

    final matches = reviews.where(
      (
        review,
      ) {
        return review.conceptId ==
            cleanConceptId;
      },
    ).toList();

    for (final review in matches) {
      await deleteReview(
        review.id,
      );
    }
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

    final reviews = await _local.loadReviews();

    final matches = reviews.where(
      (
        review,
      ) {
        return review.sourceNotePath.trim() ==
            cleanPath;
      },
    ).toList();

    for (final review in matches) {
      await deleteReview(
        review.id,
      );
    }
  }

  // ============================================================
  // SYNC PAYLOAD
  // ============================================================

  Map<
    String,
    dynamic
  >
  _toSyncPayload(
    BrainReviewItem review, {
    required String userId,
  }) {
    return {
      'id': review.id,
      'user_id': userId,

      'concept_id': review.conceptId,

      'question': review.question,
      'answer': review.answer,

      'source_note_path': review.sourceNotePath,
      'source_note_title': review.sourceNoteTitle,

      'created_at': review.createdAt.toUtc().toIso8601String(),

      'next_review_at': review.nextReviewAt.toUtc().toIso8601String(),

      'last_reviewed_at': review.lastReviewedAt?.toUtc().toIso8601String(),

      'archived_at': review.archivedAt?.toUtc().toIso8601String(),

      'review_count': review.reviewCount,
      'correct_count': review.correctCount,
      'wrong_count': review.wrongCount,
      'streak': review.streak,

      'archived': review.archived,

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
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
