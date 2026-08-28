import '../models/brain_review_item.dart';
import '../services/supabase_review_service.dart';

class ReviewRepository {
  ReviewRepository({
    SupabaseReviewService? remote,
  }) : _remote =
           remote ??
           SupabaseReviewService();

  final SupabaseReviewService _remote;

  // ============================================================
  // AUTH
  // ============================================================

  bool get isAuthenticated {
    return _remote.isAuthenticated;
  }

  String? get currentUserId {
    return _remote.currentUserId;
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() {
    return _remote.loadReviews();
  }

  // ============================================================
  // SAVE ONE
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) {
    return _remote.saveReview(
      review,
    );
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
  ) {
    return _remote.saveReviews(
      reviews,
    );
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReview(
    String id,
  ) {
    return _remote.getReview(
      id,
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
  ) {
    return _remote.getReviewByConceptId(
      conceptId,
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
  }) {
    return _remote.loadDueReviews(
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
    return _remote.loadUpcomingReviews(
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
    return _remote.loadActiveReviews();
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
    return _remote.loadArchivedReviews();
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
  ) {
    return _remote.deleteReview(
      id,
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
  ) {
    return _remote.deleteReviewByConceptId(
      conceptId,
    );
  }
}
