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

  Future<
    BoardComment
  >
  create(
    BoardComment comment,
  ) async {
    // ==========================================================
    // MAP DO MODEL
    // ==========================================================

    final data =
        Map<
          String,
          dynamic
        >.from(
          comment.toMap(),
        );

    // ==========================================================
    // ID
    // ==========================================================
    //
    // O BoardCommentController usa um ID temporário local.
    //
    // A coluna "id" do Supabase é UUID:
    //
    // id uuid primary key default gen_random_uuid()
    //
    // Portanto NÃO enviamos o ID temporário.
    //
    // O próprio PostgreSQL cria o UUID real.
    //
    // ==========================================================

    data.remove(
      'id',
    );

    // ==========================================================
    // USER
    // ==========================================================

    data['user_id'] = _userId;

    // ==========================================================
    // INSERT
    // ==========================================================

    final response = await _client
        .from(
          _table,
        )
        .insert(
          data,
        )
        .select()
        .single();

    // ==========================================================
    // RETORNO
    // ==========================================================
    //
    // Aqui já recebemos o UUID real criado pelo Supabase.
    //
    // ==========================================================

    return BoardComment.fromMap(
      response,
    );
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
