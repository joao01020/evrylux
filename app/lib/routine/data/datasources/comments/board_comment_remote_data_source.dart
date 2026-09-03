import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/comments/board_comment.dart';

class BoardCommentRemoteDataSource {
  BoardCommentRemoteDataSource({
    required SupabaseClient client,
  }) : _client = client;

  // ============================================================
  // CLIENT
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // TABLE
  // ============================================================

  static const String _table = 'routine_comments';

  // ============================================================
  // USER
  // ============================================================

  String get _userId {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return user.id;
  }

  // ============================================================
  // BUSCAR COMENTÁRIOS DO DIA
  // ============================================================

  Future<
    List<
      BoardComment
    >
  >
  fetchByDay({
    required String dayId,
    bool includeResolved = false,
  }) async {
    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      return [];
    }

    var query = _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          _userId,
        )
        .eq(
          'day_id',
          normalizedDayId,
        );

    if (!includeResolved) {
      query = query.eq(
        'resolved',
        false,
      );
    }

    final response = await query.order(
      'created_at',
      ascending: true,
    );

    return response.map<
      BoardComment
    >(
      (
        map,
      ) {
        return BoardComment.fromMap(
          map,
        );
      },
    ).toList();
  }

  // ============================================================
  // BUSCAR TODOS
  // ============================================================

  Future<
    List<
      BoardComment
    >
  >
  fetchAll({
    bool includeResolved = false,
  }) async {
    var query = _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          _userId,
        );

    if (!includeResolved) {
      query = query.eq(
        'resolved',
        false,
      );
    }

    final response = await query.order(
      'created_at',
      ascending: true,
    );

    return response.map<
      BoardComment
    >(
      (
        map,
      ) {
        return BoardComment.fromMap(
          map,
        );
      },
    ).toList();
  }

  // ============================================================
  // CRIAR
  // ============================================================
  //
  // O comentário já chega com UUID definitivo criado localmente.
  // Não trocamos o ID durante a sincronização.
  //
  // ============================================================

  Future<BoardComment> create(
    BoardComment comment,
  ) async {
    final data = Map<String, dynamic>.from(
      comment.toMap(),
    );

    data['id'] = comment.id;
    data['user_id'] = _userId;

    final response = await _client
        .from(
          _table,
        )
        .upsert(
          data,
          onConflict: 'id',
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // SYNC QUEUE
  // ============================================================

  Future<void> upsertQueued({
    required String userId,
    required String commentId,
    required Map<String, dynamic> payload,
  }) async {
    _ensureUser(userId);

    final normalizedId = commentId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError('commentId não pode estar vazio.');
    }

    await _client.from(_table).upsert(
      <String, dynamic>{
        'id': normalizedId,
        'user_id': userId,
        'day_id': payload['day_id'],
        'message': payload['message'],
        'position_x': payload['position_x'] ?? 0,
        'position_y': payload['position_y'] ?? 0,
        'author_name': payload['author_name'] ?? 'Você',
        'resolved': payload['resolved'] ?? false,
        'created_at': payload['created_at'] ??
            DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  Future<void> deleteQueued({
    required String userId,
    required String commentId,
  }) async {
    _ensureUser(userId);

    final normalizedId = commentId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    await _client
        .from(_table)
        .delete()
        .eq('id', normalizedId)
        .eq('user_id', userId);
  }

  void _ensureUser(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty || normalized != _userId) {
      throw StateError(
        'Operação de comentário pertence a outro usuário.',
      );
    }
  }

  // ============================================================
  // ATUALIZAR COMPLETO
  // ============================================================

  Future<
    BoardComment
  >
  update(
    BoardComment comment,
  ) async {
    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'message': comment.message,

            'position_x': comment.position.dx,

            'position_y': comment.position.dy,

            'author_name': comment.authorName,

            'resolved': comment.resolved,
          },
        )
        .eq(
          'id',
          comment.id,
        )
        .eq(
          'user_id',
          _userId,
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // ATUALIZAR MENSAGEM
  // ============================================================

  Future<
    BoardComment
  >
  updateMessage({
    required String commentId,
    required String message,
  }) async {
    final normalizedId = commentId.trim();

    final normalizedMessage = message.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'O ID do comentário não pode estar vazio.',
      );
    }

    if (normalizedMessage.isEmpty) {
      throw ArgumentError(
        'A mensagem não pode estar vazia.',
      );
    }

    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'message': normalizedMessage,
          },
        )
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          _userId,
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // MOVER
  // ============================================================

  Future<
    BoardComment
  >
  updatePosition({
    required String commentId,
    required double x,
    required double y,
  }) async {
    final normalizedId = commentId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'O ID do comentário não pode estar vazio.',
      );
    }

    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'position_x': x,
            'position_y': y,
          },
        )
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          _userId,
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // RESOLVER
  // ============================================================

  Future<
    BoardComment
  >
  resolve(
    String commentId,
  ) async {
    final normalizedId = commentId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'O ID do comentário não pode estar vazio.',
      );
    }

    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'resolved': true,
          },
        )
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          _userId,
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // REABRIR
  // ============================================================

  Future<
    BoardComment
  >
  reopen(
    String commentId,
  ) async {
    final normalizedId = commentId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'O ID do comentário não pode estar vazio.',
      );
    }

    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'resolved': false,
          },
        )
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          _userId,
        )
        .select()
        .single();

    return BoardComment.fromMap(
      response,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  delete(
    String commentId,
  ) async {
    final normalizedId = commentId.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'id',
          normalizedId,
        )
        .eq(
          'user_id',
          _userId,
        );
  }

  // ============================================================
  // EXCLUIR TODOS DO DIA
  // ============================================================

  Future<
    void
  >
  deleteByDay(
    String dayId,
  ) async {
    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      return;
    }

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'user_id',
          _userId,
        )
        .eq(
          'day_id',
          normalizedDayId,
        );
  }
}
