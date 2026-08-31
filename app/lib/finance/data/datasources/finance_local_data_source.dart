import 'dart:convert';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_status.dart';

class FinanceLocalDataSource {
  FinanceLocalDataSource({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  final AppDatabase _database;

  static const String _table = 'local_finance';

  bool _initialized = false;

  Future<
    void
  >
  _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _database.initialize();

    _database.db.execute(
      '''
      CREATE TABLE IF NOT EXISTS $_table (
        user_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        deleted_at TEXT
      );
      ''',
    );

    _database.db.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_local_finance_sync
      ON $_table (sync_status);
      ''',
    );

    _initialized = true;
  }

  Future<
    void
  >
  save({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
    SyncStatus syncStatus = SyncStatus.pendingUpdate,
  }) async {
    await _ensureInitialized();

    if (userId.trim().isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
      INSERT INTO $_table (
        user_id,
        payload,
        created_at,
        updated_at,
        sync_status,
        deleted_at
      )
      VALUES (?, ?, ?, ?, ?, NULL)
      ON CONFLICT(user_id)
      DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at,
        sync_status = excluded.sync_status,
        deleted_at = NULL
      ''',
      [
        userId,
        jsonEncode(
          data,
        ),
        now,
        now,
        syncStatus.value,
      ],
    );
  }

  Future<
    Map<
      String,
      dynamic
    >?
  >
  load(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT payload
      FROM $_table
      WHERE
        user_id = ?
        AND deleted_at IS NULL
      LIMIT 1
      ''',
      [
        userId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    final raw = rows.first['payload']?.toString();

    if (raw ==
            null ||
        raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(
      raw,
    );

    if (decoded
        is! Map) {
      return null;
    }

    return Map<
      String,
      dynamic
    >.from(
      decoded,
    );
  }

  Future<
    bool
  >
  exists(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT 1
      FROM $_table
      WHERE
        user_id = ?
        AND deleted_at IS NULL
      LIMIT 1
      ''',
      [
        userId,
      ],
    );

    return rows.isNotEmpty;
  }

  Future<
    SyncStatus?
  >
  getSyncStatus(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT sync_status
      FROM $_table
      WHERE user_id = ?
      LIMIT 1
      ''',
      [
        userId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return SyncStatus.fromValue(
      rows.first['sync_status']?.toString(),
    );
  }

  Future<
    void
  >
  setSyncStatus(
    String userId,
    SyncStatus status,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      UPDATE $_table
      SET
        sync_status = ?,
        updated_at = ?
      WHERE user_id = ?
      ''',
      [
        status.value,
        DateTime.now().toUtc().toIso8601String(),
        userId,
      ],
    );
  }

  Future<
    void
  >
  markDeleted(
    String userId,
  ) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
      UPDATE $_table
      SET
        deleted_at = ?,
        updated_at = ?,
        sync_status = ?
      WHERE user_id = ?
      ''',
      [
        now,
        now,
        SyncStatus.pendingDelete.value,
        userId,
      ],
    );
  }

  Future<
    void
  >
  deletePermanently(
    String userId,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      DELETE FROM $_table
      WHERE user_id = ?
      ''',
      [
        userId,
      ],
    );
  }

  Future<
    void
  >
  clear() async {
    await _ensureInitialized();

    _database.db.execute(
      'DELETE FROM $_table',
    );
  }
}
