import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_review_item.dart';

class SupabaseReviewService {
  SupabaseReviewService({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // TABLE
  // ============================================================

  static const String reviewsTable = 'brain_reviews';

  // ============================================================
  // AUTH
  // ============================================================

  String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  bool get isAuthenticated {
    return currentUserId !=
        null;
  }

  String _requireUserId() {
    final userId = _requireUserId();

    if (userId ==
            null ||
        userId.trim().isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) async {
    final userId = _requireUserId();

    final now = DateTime.now().toUtc();

    final data = _toDatabaseJson(
      review,
    );

    data['updated_at'] = now.toIso8601String();

    data['user_id'] = userId;

    try {
      final existing = await getReview(
        review.id,
      );

      // ========================================================
      // INSERT
      // ========================================================

      if (existing ==
          null) {
        data['created_at'] = review.createdAt.toUtc().toIso8601String();

        final response = await _client
            .from(
              reviewsTable,
            )
            .insert(
              data,
            )
            .select()
            .single();

        return _fromDatabaseJson(
          Map<
            String,
            dynamic
          >.from(
            response,
          ),
        );
      }

      // ========================================================
      // UPDATE
      // ========================================================

      final updateData =
          Map<
            String,
            dynamic
          >.from(
            data,
          );

      updateData.remove(
        'id',
      );

      updateData.remove(
        'created_at',
      );

      var query = _client
          .from(
            reviewsTable,
          )
          .update(
            updateData,
          )
          .eq(
            'id',
            review.id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.select().single();

      return _fromDatabaseJson(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao salvar revisão.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // SALVAR VÁRIAS
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
  // CARREGAR TODAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select();

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.order(
        'next_review_at',
        ascending: true,
      );

      return _mapList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao carregar revisões.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReview(
    String id,
  ) async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return _fromDatabaseJson(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao buscar revisão.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR PELO CONCEITO
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReviewByConceptId(
    String conceptId,
  ) async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'concept_id',
            conceptId,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return _fromDatabaseJson(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao buscar revisão pelo conceito.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
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
        (now ??
                DateTime.now())
            .toUtc();

    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'archived',
            false,
          )
          .lte(
            'next_review_at',
            current.toIso8601String(),
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.order(
        'next_review_at',
        ascending: true,
      );

      return _mapList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao carregar revisões vencidas.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // PRÓXIMAS
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
        (now ??
                DateTime.now())
            .toUtc();

    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'archived',
            false,
          )
          .gt(
            'next_review_at',
            current.toIso8601String(),
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.order(
        'next_review_at',
        ascending: true,
      );

      return _mapList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao carregar próximas revisões.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // ATIVAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'archived',
            false,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.order(
        'next_review_at',
        ascending: true,
      );

      return _mapList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao carregar revisões ativas.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // ARQUIVADAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .select()
          .eq(
            'archived',
            true,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      final response = await query.order(
        'archived_at',
        ascending: false,
      );

      return _mapList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao carregar revisões arquivadas.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .delete()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      await query;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao excluir revisão.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR PELO CONCEITO
  // ============================================================

  Future<
    void
  >
  deleteReviewByConceptId(
    String conceptId,
  ) async {
    try {
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            reviewsTable,
          )
          .delete()
          .eq(
            'concept_id',
            conceptId,
          );

      query = query.eq(
        'user_id',
        userId,
      );

      await query;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseReviewService: erro ao excluir revisão do conceito.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // JSON → DATABASE
  // ============================================================

  Map<
    String,
    dynamic
  >
  _toDatabaseJson(
    BrainReviewItem review,
  ) {
    return {
      'id': review.id,

      'concept_id': review.conceptId,

      'question': review.question,

      'answer': review.answer,

      'source_note_path': review.sourceNotePath,

      'source_note_title': review.sourceNoteTitle,

      'next_review_at': review.nextReviewAt.toUtc().toIso8601String(),

      'last_reviewed_at': review.lastReviewedAt?.toUtc().toIso8601String(),

      'review_count': review.reviewCount,

      'correct_count': review.correctCount,

      'wrong_count': review.wrongCount,

      'streak': review.streak,

      'archived': review.archived,

      'archived_at': review.archivedAt?.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // DATABASE → MODEL
  // ============================================================

  BrainReviewItem _fromDatabaseJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return BrainReviewItem(
      id:
          json['id']?.toString() ??
          '',

      conceptId:
          json['concept_id']?.toString() ??
          '',

      question:
          json['question']?.toString() ??
          '',

      answer:
          json['answer']?.toString() ??
          '',

      sourceNotePath:
          json['source_note_path']?.toString() ??
          '',

      sourceNoteTitle:
          json['source_note_title']?.toString() ??
          '',

      createdAt:
          _parseDate(
            json['created_at'],
          ) ??
          DateTime.now(),

      nextReviewAt:
          _parseDate(
            json['next_review_at'],
          ) ??
          DateTime.now(),

      lastReviewedAt: _parseDate(
        json['last_reviewed_at'],
      ),

      archivedAt: _parseDate(
        json['archived_at'],
      ),

      reviewCount: _parseInt(
        json['review_count'],
      ),

      correctCount: _parseInt(
        json['correct_count'],
      ),

      wrongCount: _parseInt(
        json['wrong_count'],
      ),

      streak: _parseInt(
        json['streak'],
      ),

      archived: _parseBool(
        json['archived'],
      ),
    );
  }

  // ============================================================
  // MAP LIST
  // ============================================================

  List<
    BrainReviewItem
  >
  _mapList(
    dynamic response,
  ) {
    if (response
        is! List) {
      return [];
    }

    return response.map(
      (
        item,
      ) {
        return _fromDatabaseJson(
          Map<
            String,
            dynamic
          >.from(
            item,
          ),
        );
      },
    ).toList();
  }

  // ============================================================
  // PARSE
  // ============================================================

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toLocal();
  }

  int _parseInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  bool _parseBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    final normalized = value?.toString().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }
}
