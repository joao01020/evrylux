import 'package:flutter/material.dart';

import '../../../models/comments/board_comment.dart';
import '../../datasources/comments/board_comment_remote_data_source.dart';

class BoardCommentRepository {
  BoardCommentRepository({
    required BoardCommentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  // ============================================================
  // REMOTE
  // ============================================================

  final BoardCommentRemoteDataSource _remoteDataSource;

  // ============================================================
  // BUSCAR POR DIA
  // ============================================================

  Future<
    List<
      BoardComment
    >
  >
  fetchByDay({
    required String dayId,
    bool includeResolved = false,
  }) {
    return _remoteDataSource.fetchByDay(
      dayId: dayId,
      includeResolved: includeResolved,
    );
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
  }) {
    return _remoteDataSource.fetchAll(
      includeResolved: includeResolved,
    );
  }

  // ============================================================
  // CRIAR
  // ============================================================

  Future<
    BoardComment
  >
  create(
    BoardComment comment,
  ) {
    return _remoteDataSource.create(
      comment,
    );
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<
    BoardComment
  >
  update(
    BoardComment comment,
  ) {
    return _remoteDataSource.update(
      comment,
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
  }) {
    return _remoteDataSource.updateMessage(
      commentId: commentId,
      message: message,
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
    required Offset position,
  }) {
    return _remoteDataSource.updatePosition(
      commentId: commentId,
      x: position.dx,
      y: position.dy,
    );
  }

  // ============================================================
  // RESOLVER
  // ============================================================

  Future<
    BoardComment
  >
  resolve(
    BoardComment comment,
  ) {
    return _remoteDataSource.resolve(
      comment.id,
    );
  }

  // ============================================================
  // REABRIR
  // ============================================================

  Future<
    BoardComment
  >
  reopen(
    BoardComment comment,
  ) {
    return _remoteDataSource.reopen(
      comment.id,
    );
  }

  // ============================================================
  // ALTERNAR RESOLVIDO
  // ============================================================

  Future<
    BoardComment
  >
  toggleResolved(
    BoardComment comment,
  ) {
    if (comment.resolved) {
      return reopen(
        comment,
      );
    }

    return resolve(
      comment,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  delete(
    BoardComment comment,
  ) {
    return _remoteDataSource.delete(
      comment.id,
    );
  }

  // ============================================================
  // EXCLUIR POR ID
  // ============================================================

  Future<
    void
  >
  deleteById(
    String commentId,
  ) {
    return _remoteDataSource.delete(
      commentId,
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
  ) {
    return _remoteDataSource.deleteByDay(
      dayId,
    );
  }
}
