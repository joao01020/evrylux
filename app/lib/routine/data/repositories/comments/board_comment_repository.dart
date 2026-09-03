import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/daos/board_comment_dao.dart';
import '../../../../core/sync/sync_item.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../models/comments/board_comment.dart';
import '../../datasources/comments/board_comment_remote_data_source.dart';

class BoardCommentRepository {
  BoardCommentRepository({
    required SupabaseClient client,
    required BoardCommentDao localDao,
    required BoardCommentRemoteDataSource remoteDataSource,
    required SyncQueue syncQueue,
    SyncService? syncService,
  }) : _client = client,
       _localDao = localDao,
       _remoteDataSource = remoteDataSource,
       _syncQueue = syncQueue,
       _syncService = syncService;

  static const String entityType = 'board_comment';

  final SupabaseClient _client;
  final BoardCommentDao _localDao;
  final BoardCommentRemoteDataSource _remoteDataSource;
  final SyncQueue _syncQueue;
  final SyncService? _syncService;

  Future<void> initialize() => _localDao.initialize();

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
  }) async {
    final user = _requireUser();
    final normalizedDayId = _required(dayId, 'dayId');

    final local = await _localDao.getByDay(
      userId: user.id,
      dayId: normalizedDayId,
      includeResolved: includeResolved,
    );

    if (await _localDao.isDayInitialized(
      userId: user.id,
      dayId: normalizedDayId,
    )) {
      return local;
    }

    try {
      final remote = await _remoteDataSource.fetchByDay(
        dayId: normalizedDayId,
        includeResolved: true,
      );

      for (final comment in remote) {
        await _localDao.upsert(
          comment,
          userId: user.id,
          syncStatus: SyncStatus.synced,
        );
      }

      await _localDao.markDayInitialized(
        userId: user.id,
        dayId: normalizedDayId,
      );

      return _localDao.getByDay(
        userId: user.id,
        dayId: normalizedDayId,
        includeResolved: includeResolved,
      );
    } catch (_) {
      return local;
    }
  }

  Future<List<BoardComment>> fetchAll({
    bool includeResolved = false,
  }) async {
    final user = _requireUser();

    final local = await _localDao.getAll(
      userId: user.id,
      includeResolved: includeResolved,
    );

    if (await _localDao.isAllInitialized(userId: user.id)) {
      return local;
    }

    try {
      final remote = await _remoteDataSource.fetchAll(
        includeResolved: true,
      );

      for (final comment in remote) {
        await _localDao.upsert(
          comment,
          userId: user.id,
          syncStatus: SyncStatus.synced,
        );
        await _localDao.markDayInitialized(
          userId: user.id,
          dayId: comment.dayId,
        );
      }

      await _localDao.markAllInitialized(userId: user.id);

      return _localDao.getAll(
        userId: user.id,
        includeResolved: includeResolved,
      );
    } catch (_) {
      return local;
    }
  }

  Future<BoardComment> create(BoardComment comment) async {
    final user = _requireUser();

    await _localDao.upsert(
      comment,
      userId: user.id,
      syncStatus: SyncStatus.pendingCreate,
    );

    await _localDao.markDayInitialized(
      userId: user.id,
      dayId: comment.dayId,
    );
    await _localDao.markAllInitialized(userId: user.id);

    await _queueComment(
      userId: user.id,
      comment: comment,
      operation: SyncOperation.create,
    );

    return comment;
  }

  Future<BoardComment> update(BoardComment comment) async {
    final user = _requireUser();

    await _localDao.upsert(
      comment,
      userId: user.id,
      syncStatus: await _saveStatus(
        userId: user.id,
        id: comment.id,
      ),
    );

    await _queueComment(
      userId: user.id,
      comment: comment,
      operation: SyncOperation.update,
    );

    return comment;
  }

  Future<BoardComment> updateMessage({
    required String commentId,
    required String message,
  }) async {
    final current = await _requireLocalComment(commentId);
    return update(
      current.copyWith(
        message: _required(message, 'message'),
      ),
    );
  }

  Future<BoardComment> updatePosition({
    required String commentId,
    required Offset position,
  }) async {
    final current = await _requireLocalComment(commentId);
    return update(current.copyWith(position: position));
  }

  Future<BoardComment> resolve(BoardComment comment) async {
    final current = await _requireLocalComment(comment.id);
    return update(current.copyWith(resolved: true));
  }

  Future<BoardComment> reopen(BoardComment comment) async {
    final current = await _requireLocalComment(comment.id);
    return update(current.copyWith(resolved: false));
  }

  Future<BoardComment> toggleResolved(BoardComment comment) {
    return comment.resolved ? reopen(comment) : resolve(comment);
  }

  Future<void> delete(BoardComment comment) => deleteById(comment.id);

  Future<void> deleteById(String commentId) async {
    final user = _requireUser();
    final id = _required(commentId, 'commentId');

    final existing = await _localDao.getById(
      userId: user.id,
      id: id,
      includeDeleted: true,
    );
    if (existing == null) return;

    final previousStatus = await _localDao.getSyncStatus(
      userId: user.id,
      id: id,
    );

    if (previousStatus != SyncStatus.pendingCreate) {
      await _localDao.markDeleted(
        userId: user.id,
        id: id,
      );
    }

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: id,
      operation: SyncOperation.delete,
      payload: <String, dynamic>{
        'id': id,
        'user_id': user.id,
        'day_id': existing.dayId,
      },
    );

    if (previousStatus == SyncStatus.pendingCreate) {
      await _localDao.deletePermanently(id);
    }

    _syncService?.requestSync();
  }

  Future<void> deleteByDay(String dayId) async {
    final user = _requireUser();
    final normalizedDayId = _required(dayId, 'dayId');

    await _localDao.markDayInitialized(
      userId: user.id,
      dayId: normalizedDayId,
    );

    final comments = await _localDao.getByDay(
      userId: user.id,
      dayId: normalizedDayId,
      includeResolved: true,
    );

    for (final comment in comments) {
      await deleteById(comment.id);
    }
  }

  Future<void> markSynced(String id) {
    return _localDao.setSyncStatus(id, SyncStatus.synced);
  }

  Future<void> deletePermanently(String id) {
    return _localDao.deletePermanently(id);
  }

  Future<BoardComment> _requireLocalComment(String id) async {
    final user = _requireUser();
    final comment = await _localDao.getById(
      userId: user.id,
      id: _required(id, 'id'),
    );
    if (comment == null) {
      throw StateError('Comentário local não encontrado.');
    }
    return comment;
  }

  Future<SyncStatus> _saveStatus({
    required String userId,
    required String id,
  }) async {
    final current = await _localDao.getSyncStatus(
      userId: userId,
      id: id,
    );
    return current == SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;
  }

  Future<void> _queueComment({
    required String userId,
    required BoardComment comment,
    required SyncOperation operation,
  }) async {
    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: comment.id,
      operation: operation,
      payload: <String, dynamic>{
        ...comment.toMap(),
        'id': comment.id,
        'user_id': userId,
        'created_at': comment.createdAt.toUtc().toIso8601String(),
      },
    );
    _syncService?.requestSync();
  }

  String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field, '$field não pode estar vazio.');
    }
    return normalized;
  }
}
