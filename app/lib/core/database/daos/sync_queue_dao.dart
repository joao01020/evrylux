import '../../sync/sync_item.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

class SyncQueueDao {
  SyncQueueDao({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  final AppDatabase _database;

  bool _initialized = false;

  Future<
    void
  >
  _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _database.initialize();

    for (final sql in SyncQueueTable.createStatements) {
      _database.db.execute(
        sql,
      );
    }

    _initialized = true;
  }

  Future<
    void
  >
  upsert(
    SyncItem item,
  ) async {
    await _ensureInitialized();

    final map = item.toDatabaseMap();

    _database.db.execute(
      '''
      INSERT INTO ${SyncQueueTable.tableName} (
        ${SyncQueueTable.id},
        ${SyncQueueTable.entityType},
        ${SyncQueueTable.entityId},
        ${SyncQueueTable.operation},
        ${SyncQueueTable.payload},
        ${SyncQueueTable.createdAt},
        ${SyncQueueTable.updatedAt},
        ${SyncQueueTable.attempts},
        ${SyncQueueTable.lastError},
        ${SyncQueueTable.nextAttemptAt}
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(${SyncQueueTable.id})
      DO UPDATE SET
        ${SyncQueueTable.entityType} = excluded.${SyncQueueTable.entityType},
        ${SyncQueueTable.entityId} = excluded.${SyncQueueTable.entityId},
        ${SyncQueueTable.operation} = excluded.${SyncQueueTable.operation},
        ${SyncQueueTable.payload} = excluded.${SyncQueueTable.payload},
        ${SyncQueueTable.updatedAt} = excluded.${SyncQueueTable.updatedAt},
        ${SyncQueueTable.attempts} = excluded.${SyncQueueTable.attempts},
        ${SyncQueueTable.lastError} = excluded.${SyncQueueTable.lastError},
        ${SyncQueueTable.nextAttemptAt} = excluded.${SyncQueueTable.nextAttemptAt}
      ''',
      [
        map[SyncQueueTable.id],
        map[SyncQueueTable.entityType],
        map[SyncQueueTable.entityId],
        map[SyncQueueTable.operation],
        map[SyncQueueTable.payload],
        map[SyncQueueTable.createdAt],
        map[SyncQueueTable.updatedAt],
        map[SyncQueueTable.attempts],
        map[SyncQueueTable.lastError],
        map[SyncQueueTable.nextAttemptAt],
      ],
    );
  }

  Future<
    List<
      SyncItem
    >
  >
  getAll() async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      ORDER BY ${SyncQueueTable.createdAt} ASC
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
    List<
      SyncItem
    >
  >
  getReady({
    int limit = 100,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.nextAttemptAt} IS NULL
        OR ${SyncQueueTable.nextAttemptAt} <= ?
      ORDER BY ${SyncQueueTable.createdAt} ASC
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
    SyncItem?
  >
  findById(
    String id,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      WHERE ${SyncQueueTable.id} = ?
      LIMIT 1
      ''',
      [
        id,
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
    SyncItem?
  >
  findByEntity({
    required String entityType,
    required String entityId,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.entityType} = ?
        AND ${SyncQueueTable.entityId} = ?
      LIMIT 1
      ''',
      [
        entityType,
        entityId,
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
  markFailed({
    required String id,
    required int attempts,
    required Object error,
    required DateTime nextAttemptAt,
  }) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      UPDATE ${SyncQueueTable.tableName}
      SET
        ${SyncQueueTable.attempts} = ?,
        ${SyncQueueTable.lastError} = ?,
        ${SyncQueueTable.nextAttemptAt} = ?,
        ${SyncQueueTable.updatedAt} = ?
      WHERE ${SyncQueueTable.id} = ?
      ''',
      [
        attempts,
        error.toString(),
        nextAttemptAt.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
        id,
      ],
    );
  }

  Future<
    void
  >
  delete(
    String id,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      DELETE FROM ${SyncQueueTable.tableName}
      WHERE ${SyncQueueTable.id} = ?
      ''',
      [
        id,
      ],
    );
  }

  Future<
    void
  >
  deleteByEntity({
    required String entityType,
    required String entityId,
  }) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      DELETE FROM ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.entityType} = ?
        AND ${SyncQueueTable.entityId} = ?
      ''',
      [
        entityType,
        entityId,
      ],
    );
  }

  Future<
    void
  >
  clear() async {
    await _ensureInitialized();

    _database.db.execute(
      'DELETE FROM ${SyncQueueTable.tableName}',
    );
  }

  Future<
    int
  >
  count() async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT COUNT(*) AS total
      FROM ${SyncQueueTable.tableName}
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
          value.toString(),
        ) ??
        0;
  }
}
