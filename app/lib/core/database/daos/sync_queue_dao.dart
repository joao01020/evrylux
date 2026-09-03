import '../../sync/sync_item.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

class SyncQueueDao {
  SyncQueueDao({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  // ============================================================
  // DATABASE
  // ============================================================

  final AppDatabase _database;

  // ============================================================
  // INITIALIZATION
  // ============================================================

  bool _initialized = false;

  Future<
    void
  >
  initialize() async {
    await _ensureInitialized();
  }

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

  // ============================================================
  // UPSERT
  // ============================================================

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
        ${SyncQueueTable.entityType} =
          excluded.${SyncQueueTable.entityType},

        ${SyncQueueTable.entityId} =
          excluded.${SyncQueueTable.entityId},

        ${SyncQueueTable.operation} =
          excluded.${SyncQueueTable.operation},

        ${SyncQueueTable.payload} =
          excluded.${SyncQueueTable.payload},

        ${SyncQueueTable.updatedAt} =
          excluded.${SyncQueueTable.updatedAt},

        ${SyncQueueTable.attempts} =
          excluded.${SyncQueueTable.attempts},

        ${SyncQueueTable.lastError} =
          excluded.${SyncQueueTable.lastError},

        ${SyncQueueTable.nextAttemptAt} =
          excluded.${SyncQueueTable.nextAttemptAt}
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

  // ============================================================
  // GET ALL
  // ============================================================

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
      ORDER BY
        ${SyncQueueTable.createdAt} ASC
      ''',
    );

    return _mapRows(
      rows,
    );
  }

  // ============================================================
  // GET READY
  // ============================================================
  //
  // Retorna somente operações que:
  //
  // - nunca falharam;
  // - OU já chegaram ao horário de retry.
  //
  // ============================================================

  Future<
    List<
      SyncItem
    >
  >
  getReady({
    int limit = 100,
  }) async {
    await _ensureInitialized();

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
      FROM ${SyncQueueTable.tableName}
      WHERE (
        ${SyncQueueTable.nextAttemptAt} IS NULL
        OR
        ${SyncQueueTable.nextAttemptAt} <= ?
      )
      ORDER BY
        ${SyncQueueTable.createdAt} ASC
      LIMIT ?
      ''',
      [
        now,
        limit,
      ],
    );

    return _mapRows(
      rows,
    );
  }

  // ============================================================
  // FIND BY ID
  // ============================================================

  Future<
    SyncItem?
  >
  findById(
    String id,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.id} = ?
      LIMIT 1
      ''',
      [
        normalizedId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRow(
      rows.first,
    );
  }

  // ============================================================
  // FIND BY ENTITY
  // ============================================================

  Future<
    SyncItem?
  >
  findByEntity({
    required String entityType,
    required String entityId,
  }) async {
    await _ensureInitialized();

    final normalizedEntityType = entityType.trim();

    final normalizedEntityId = entityId.trim();

    if (normalizedEntityType.isEmpty ||
        normalizedEntityId.isEmpty) {
      return null;
    }

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.entityType} = ?
        AND
        ${SyncQueueTable.entityId} = ?
      ORDER BY
        ${SyncQueueTable.createdAt} ASC
      LIMIT 1
      ''',
      [
        normalizedEntityType,
        normalizedEntityId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRow(
      rows.first,
    );
  }

  // ============================================================
  // GET ATTEMPTS
  // ============================================================
  //
  // Utilizado pela SyncQueue para calcular exponential backoff.
  //
  // ============================================================

  Future<
    int?
  >
  getAttempts(
    String id,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final rows = _database.db.select(
      '''
      SELECT
        ${SyncQueueTable.attempts}
      FROM
        ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.id} = ?
      LIMIT 1
      ''',
      [
        normalizedId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _toInt(
      rows.first[SyncQueueTable.attempts],
    );
  }

  // ============================================================
  // MARK FAILED
  // ============================================================

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

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    final safeAttempts =
        attempts <
            0
        ? 0
        : attempts;

    _database.db.execute(
      '''
      UPDATE
        ${SyncQueueTable.tableName}
      SET
        ${SyncQueueTable.attempts} = ?,
        ${SyncQueueTable.lastError} = ?,
        ${SyncQueueTable.nextAttemptAt} = ?,
        ${SyncQueueTable.updatedAt} = ?
      WHERE
        ${SyncQueueTable.id} = ?
      ''',
      [
        safeAttempts,
        error.toString(),
        nextAttemptAt.toUtc().toIso8601String(),
        DateTime.now().toUtc().toIso8601String(),
        normalizedId,
      ],
    );
  }

  // ============================================================
  // RESET RETRY
  // ============================================================
  //
  // Útil quando uma nova alteração substitui uma operação
  // que estava aguardando retry.
  //
  // ============================================================

  Future<
    void
  >
  resetRetry(
    String id,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _database.db.execute(
      '''
      UPDATE
        ${SyncQueueTable.tableName}
      SET
        ${SyncQueueTable.attempts} = 0,
        ${SyncQueueTable.lastError} = NULL,
        ${SyncQueueTable.nextAttemptAt} = NULL,
        ${SyncQueueTable.updatedAt} = ?
      WHERE
        ${SyncQueueTable.id} = ?
      ''',
      [
        DateTime.now().toUtc().toIso8601String(),
        normalizedId,
      ],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  delete(
    String id,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _database.db.execute(
      '''
      DELETE FROM
        ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.id} = ?
      ''',
      [
        normalizedId,
      ],
    );
  }

  // ============================================================
  // DELETE BY ENTITY
  // ============================================================

  Future<
    void
  >
  deleteByEntity({
    required String entityType,
    required String entityId,
  }) async {
    await _ensureInitialized();

    final normalizedEntityType = entityType.trim();

    final normalizedEntityId = entityId.trim();

    if (normalizedEntityType.isEmpty ||
        normalizedEntityId.isEmpty) {
      return;
    }

    _database.db.execute(
      '''
      DELETE FROM
        ${SyncQueueTable.tableName}
      WHERE
        ${SyncQueueTable.entityType} = ?
        AND
        ${SyncQueueTable.entityId} = ?
      ''',
      [
        normalizedEntityType,
        normalizedEntityId,
      ],
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      DELETE FROM
        ${SyncQueueTable.tableName}
      ''',
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT
        COUNT(*) AS total
      FROM
        ${SyncQueueTable.tableName}
      ''',
    );

    if (rows.isEmpty) {
      return 0;
    }

    return _toInt(
          rows.first['total'],
        ) ??
        0;
  }

  // ============================================================
  // COUNT READY
  // ============================================================

  Future<
    int
  >
  countReady() async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    final rows = _database.db.select(
      '''
      SELECT
        COUNT(*) AS total
      FROM
        ${SyncQueueTable.tableName}
      WHERE (
        ${SyncQueueTable.nextAttemptAt} IS NULL
        OR
        ${SyncQueueTable.nextAttemptAt} <= ?
      )
      ''',
      [
        now,
      ],
    );

    if (rows.isEmpty) {
      return 0;
    }

    return _toInt(
          rows.first['total'],
        ) ??
        0;
  }

  // ============================================================
  // HAS PENDING
  // ============================================================

  Future<
    bool
  >
  get hasPending async {
    return await count() >
        0;
  }

  // ============================================================
  // HAS READY
  // ============================================================

  Future<
    bool
  >
  get hasReady async {
    return await countReady() >
        0;
  }

  // ============================================================
  // ROW MAPPING
  // ============================================================

  List<
    SyncItem
  >
  _mapRows(
    Iterable<
      dynamic
    >
    rows,
  ) {
    return rows
        .map(
          (
            row,
          ) {
            return _mapRow(
              row,
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  SyncItem _mapRow(
    dynamic row,
  ) {
    return SyncItem.fromDatabaseRow(
      Map<
        String,
        Object?
      >.from(
        row,
      ),
    );
  }

  // ============================================================
  // INT PARSER
  // ============================================================

  int? _toInt(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}
