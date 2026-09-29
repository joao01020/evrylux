import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/comments/board_comment.dart';
import '../../datasources/comments/board_comment_remote_data_source.dart';

class BoardCommentRepository {
  BoardCommentRepository({
    SupabaseClient? client,
    BoardCommentRemoteDataSource? remoteDataSource,
  }) : _client = client ?? Supabase.instance.client,
       _remoteDataSource =
           remoteDataSource ??
           BoardCommentRemoteDataSource(
             client: client ?? Supabase.instance.client,
           );

  static const String entityType = 'board_comment';

  final SupabaseClient _client;
  final BoardCommentRemoteDataSource _remoteDataSource;

  Future<void> initialize() async {}

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user;
  }

  Future<List<BoardComment>> fetchByDay({
    required String dayId,
    bool includeResolved = false,
  }) {
    _requireUser();
    return _remoteDataSource.fetchByDay(
      dayId: dayId,
      includeResolved: includeResolved,
    );
  }

  Future<List<BoardComment>> refreshByDay({
    required String dayId,
    bool includeResolved = false,
  }) {
    return fetchByDay(dayId: dayId, includeResolved: includeResolved);
  }

  Future<List<BoardComment>> fetchAll({bool includeResolved = false}) {
    _requireUser();
    return _remoteDataSource.fetchAll(includeResolved: includeResolved);
  }

  Future<BoardComment> create(BoardComment comment) {
    _requireUser();
    return _remoteDataSource.create(comment);
  }

  Future<BoardComment> update(BoardComment comment) {
    _requireUser();
    return _remoteDataSource.update(comment);
  }

  Future<BoardComment> updateMessage({
    required String commentId,
    required String message,
  }) {
    return _remoteDataSource.updateMessage(
      commentId: commentId,
      message: message,
    );
  }

  Future<BoardComment> updatePosition({
    required String commentId,
    required Offset position,
  }) {
    return _remoteDataSource.updatePosition(
      commentId: commentId,
      x: position.dx,
      y: position.dy,
    );
  }

  Future<BoardComment> resolve(BoardComment comment) {
    return _remoteDataSource.resolve(comment.id);
  }

  Future<BoardComment> reopen(BoardComment comment) {
    return _remoteDataSource.reopen(comment.id);
  }

  Future<BoardComment> toggleResolved(BoardComment comment) {
    return comment.resolved ? reopen(comment) : resolve(comment);
  }

  Future<void> delete(BoardComment comment) {
    return _remoteDataSource.delete(comment.id);
  }

  Future<void> deleteById(String commentId) {
    return _remoteDataSource.delete(commentId);
  }

  Future<void> deleteByDay(String dayId) {
    return _remoteDataSource.deleteByDay(dayId);
  }

  Future<void> markSynced(String id) async {}

  Future<void> deletePermanently(String id) {
    return _remoteDataSource.delete(id);
  }
}
