import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'sync_item.dart';

class SyncQueue {
  SyncQueue({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  final AppDatabase _database;

  Future<
    SyncItem
  >
  enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<
          String,
          dynamic
        >
        payload =
        const <
          String,
          dynamic
        >{},
  }) async {
    final normalizedEntityType = entityType.trim();

    final normalizedEntityId = entityId.trim();

    _validateEntity(
      normalizedEntityType,
      normalizedEntityId,
    );

    final now = DateTime.now().toUtc();

    final existing = await findByEntity(
      entityType: normalizedEntityType,
      entityId: normalizedEntityId,
    );

    final resolvedOperation = _resolveOperation(
      existing: existing,
      incoming: operation,
    );

    if (resolvedOperation ==
        null) {
      if (existing !=
          null) {
        await remove(
          existing.id,
        );

        debugPrint(
          '[SYNC QUEUE] '
          '${existing.entityType}/${existing.entityId}: '
          'CREATE + DELETE cancelados.',
        );
      }

      return SyncItem(
        id:
            existing?.id ??
            _newId(),
        entityType: normalizedEntityType,
        entityId: normalizedEntityId,
        operation: operation,
        payload:
            Map<
              String,
              dynamic
            >.from(
              payload,
            ),
        createdAt:
            existing?.createdAt ??
            now,
        updatedAt: now,
      );
    }

    final resolvedPayload =
        <
          String,
          dynamic
        >{
          if (existing !=
              null)
            ...existing.payload,
          ...payload,
        };

    final item = SyncItem(
      id:
          existing?.id ??
          _newId(),
      entityType: normalizedEntityType,
      entityId: normalizedEntityId,
      operation: resolvedOperation,
      payload: resolvedPayload,
      createdAt:
          existing?.createdAt ??
          now,
      updatedAt: now,
      attempts: 0,
      lastError: null,
      nextAttemptAt: null,
    );

    final map = item.toDatabaseMap();

    _database.db.execute(
      '''
      INSERT INTO sync_queue (
        id,
        entity_type,
        entity_id,
        operation,
        payload,
        created_at,
        updated_at,
        attempts,
        last_error,
        next_attempt_at
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id)
      DO UPDATE SET
        entity_type = excluded.entity_type,
        entity_id = excluded.entity_id,
        operation = excluded.operation,
        payload = excluded.payload,
        updated_at = excluded.updated_at,
        attempts = excluded.attempts,
        last_error = excluded.last_error,
        next_attempt_at = excluded.next_attempt_at
      ''',
      [
        map['id'],
        map['entity_type'],
        map['entity_id'],
        map['operation'],
        map['payload'],
        map['created_at'],
        map['updated_at'],
        map['attempts'],
        map['last_error'],
        map['next_attempt_at'],
      ],
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Enfileirado: '
      '$normalizedEntityType/'
      '$normalizedEntityId '
      '(${resolvedOperation.name})',
    );

    return item;
  }

  Future<
    List<
      SyncItem
    >
  >
  getPending({
    int limit = 100,
  }) async {
    if (limit <=
        0) {
      return const <
        SyncItem
      >[];
    }

    final now = DateTime.now().toUtc().toIso8601String();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM sync_queue
      WHERE (
        next_attempt_at IS NULL
        OR next_attempt_at <= ?
      )
      ORDER BY created_at ASC
      LIMIT ?
      ''',
      [
        now,
        limit,
      ],
    );

    return rows
        .map(
          (
            row,
          ) => SyncItem.fromDatabaseRow(
            Map<
              String,
              Object?
            >.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  Future<
    List<
      SyncItem
    >
  >
  getAll() async {
    final rows = _database.db.select(
      '''
      SELECT *
      FROM sync_queue
      ORDER BY created_at ASC
      ''',
    );

    return rows
        .map(
          (
            row,
          ) => SyncItem.fromDatabaseRow(
            Map<
              String,
              Object?
            >.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  Future<
    SyncItem?
  >
  findByEntity({
    required String entityType,
    required String entityId,
  }) async {
    final rows = _database.db.select(
      '''
      SELECT *
      FROM sync_queue
      WHERE
        entity_type = ?
        AND entity_id = ?
      ORDER BY created_at ASC
      LIMIT 1
      ''',
      [
        entityType.trim(),
        entityId.trim(),
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return SyncItem.fromDatabaseRow(
      Map<
        String,
        Object?
      >.from(
        rows.first,
      ),
    );
  }

  Future<
    void
  >
  markSuccess(
    String id,
  ) async {
    await remove(
      id,
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Sincronização concluída: $id',
    );
  }

  Future<
    void
  >
  markFailed({
    required String id,
    required Object error,
  }) async {
    final rows = _database.db.select(
      '''
      SELECT attempts
      FROM sync_queue
      WHERE id = ?
      LIMIT 1
      ''',
      [
        id,
      ],
    );

    if (rows.isEmpty) {
      return;
    }

    final rawAttempts = rows.first['attempts'];

    final currentAttempts =
        rawAttempts
            is int
        ? rawAttempts
        : int.tryParse(
                rawAttempts?.toString() ??
                    '',
              ) ??
              0;

    final attempts =
        currentAttempts +
        1;

    final retryDelay = _retryDelay(
      attempts,
    );

    final nextAttemptAt = DateTime.now().toUtc().add(
      retryDelay,
    );

    _database.db.execute(
      '''
      UPDATE sync_queue
      SET
        attempts = ?,
        last_error = ?,
        next_attempt_at = ?,
        updated_at = ?
      WHERE id = ?
      ''',
      [
        attempts,
        error.toString(),
        nextAttemptAt.toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
        id,
      ],
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Falha em $id. '
      'Tentativa $attempts. '
      'Nova tentativa em ${retryDelay.inSeconds}s. '
      'Erro: $error',
    );
  }

  Duration _retryDelay(
    int attempts,
  ) {
    final safeAttempts = attempts.clamp(
      1,
      8,
    );

    final seconds = pow(
      2,
      safeAttempts,
    ).toInt();

    return Duration(
      seconds: seconds.clamp(
        2,
        300,
      ),
    );
  }

  Future<
    void
  >
  remove(
    String id,
  ) async {
    _database.db.execute(
      '''
      DELETE FROM sync_queue
      WHERE id = ?
      ''',
      [
        id,
      ],
    );
  }

  Future<
    void
  >
  clear() async {
    _database.db.execute(
      'DELETE FROM sync_queue;',
    );

    debugPrint(
      '[SYNC QUEUE] Fila limpa.',
    );
  }

  Future<
    int
  >
  count() async {
    final rows = _database.db.select(
      '''
      SELECT COUNT(*) AS total
      FROM sync_queue
      ''',
    );

    if (rows.isEmpty) {
      return 0;
    }

    final value = rows.first['total'];

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

  Future<
    int
  >
  countReady() async {
    final now = DateTime.now().toUtc().toIso8601String();

    final rows = _database.db.select(
      '''
      SELECT COUNT(*) AS total
      FROM sync_queue
      WHERE (
        next_attempt_at IS NULL
        OR next_attempt_at <= ?
      )
      ''',
      [
        now,
      ],
    );

    if (rows.isEmpty) {
      return 0;
    }

    final value = rows.first['total'];

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

  Future<
    bool
  >
  get hasPending async {
    return await count() >
        0;
  }

  SyncOperation? _resolveOperation({
    required SyncItem? existing,
    required SyncOperation incoming,
  }) {
    if (existing ==
        null) {
      return incoming;
    }

    switch (existing.operation) {
      case SyncOperation.create:
        switch (incoming) {
          case SyncOperation.create:
          case SyncOperation.update:
            return SyncOperation.create;

          case SyncOperation.delete:
            return null;
        }

      case SyncOperation.update:
        switch (incoming) {
          case SyncOperation.create:
          case SyncOperation.update:
            return SyncOperation.update;

          case SyncOperation.delete:
            return SyncOperation.delete;
        }

      case SyncOperation.delete:
        switch (incoming) {
          case SyncOperation.create:
            return SyncOperation.update;

          case SyncOperation.update:
          case SyncOperation.delete:
            return SyncOperation.delete;
        }
    }
  }

  void _validateEntity(
    String entityType,
    String entityId,
  ) {
    if (entityType.isEmpty) {
      throw ArgumentError(
        'entityType não pode ser vazio.',
      );
    }

    if (entityId.isEmpty) {
      throw ArgumentError(
        'entityId não pode ser vazio.',
      );
    }
  }

  String _newId() {
    final random = Random.secure();

    final time = DateTime.now().microsecondsSinceEpoch;

    final entropy =
        List<
          int
        >.generate(
          8,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    final suffix =
        base64UrlEncode(
          entropy,
        ).replaceAll(
          '=',
          '',
        );

    return 'sync_${time}_$suffix';
  }
}
