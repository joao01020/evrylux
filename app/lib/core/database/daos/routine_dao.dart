import 'dart:convert';

import '../../sync/sync_status.dart';
import '../app_database.dart';
import '../tables/routine_table.dart';

class RoutineLocalRecord {
  const RoutineLocalRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    required this.syncStatus,
    this.deletedAt,
  });

  final String id;
  final String userId;
  final DateTime date;
  final Map<
    String,
    dynamic
  >
  payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final DateTime? deletedAt;
}

class RoutineDao {
  RoutineDao({
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

    for (final sql in RoutineTable.createStatements) {
      _database.db.execute(
        sql,
      );
    }

    _initialized = true;
  }

  Future<
    void
  >
  upsert({
    required String id,
    required String userId,
    required DateTime date,
    required Map<
      String,
      dynamic
    >
    payload,
    SyncStatus syncStatus = SyncStatus.synced,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc();

    _database.db.execute(
      '''
      INSERT INTO ${RoutineTable.tableName} (
        ${RoutineTable.id},
        ${RoutineTable.userId},
        ${RoutineTable.date},
        ${RoutineTable.payload},
        ${RoutineTable.createdAt},
        ${RoutineTable.updatedAt},
        ${RoutineTable.syncStatus},
        ${RoutineTable.deletedAt}
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(${RoutineTable.id})
      DO UPDATE SET
        ${RoutineTable.userId} = excluded.${RoutineTable.userId},
        ${RoutineTable.date} = excluded.${RoutineTable.date},
        ${RoutineTable.payload} = excluded.${RoutineTable.payload},
        ${RoutineTable.updatedAt} = excluded.${RoutineTable.updatedAt},
        ${RoutineTable.syncStatus} = excluded.${RoutineTable.syncStatus},
        ${RoutineTable.deletedAt} = excluded.${RoutineTable.deletedAt}
      ''',
      [
        id,
        userId,
        _normalizeDate(
          date,
        ),
        jsonEncode(
          payload,
        ),
        (createdAt ??
                now)
            .toUtc()
            .toIso8601String(),
        (updatedAt ??
                now)
            .toUtc()
            .toIso8601String(),
        syncStatus.value,
        deletedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  Future<
    RoutineLocalRecord?
  >
  getByDate({
    required String userId,
    required DateTime date,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${RoutineTable.tableName}
      WHERE
        ${RoutineTable.userId} = ?
        AND ${RoutineTable.date} = ?
        ${includeDeleted ? '' : 'AND ${RoutineTable.deletedAt} IS NULL'}
      LIMIT 1
      ''',
      [
        userId,
        _normalizeDate(
          date,
        ),
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapRecord(
      rows.first,
    );
  }

  Future<
    List<
      RoutineLocalRecord
    >
  >
  getRange({
    required String userId,
    required DateTime start,
    required DateTime end,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${RoutineTable.tableName}
      WHERE
        ${RoutineTable.userId} = ?
        AND ${RoutineTable.date} >= ?
        AND ${RoutineTable.date} <= ?
        ${includeDeleted ? '' : 'AND ${RoutineTable.deletedAt} IS NULL'}
      ORDER BY ${RoutineTable.date} ASC
      ''',
      [
        userId,
        _normalizeDate(
          start,
        ),
        _normalizeDate(
          end,
        ),
      ],
    );

    return rows
        .map(
          _mapRecord,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    List<
      RoutineLocalRecord
    >
  >
  getAll({
    required String userId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${RoutineTable.tableName}
      WHERE
        ${RoutineTable.userId} = ?
        ${includeDeleted ? '' : 'AND ${RoutineTable.deletedAt} IS NULL'}
      ORDER BY ${RoutineTable.date} ASC
      ''',
      [
        userId,
      ],
    );

    return rows
        .map(
          _mapRecord,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    void
  >
  setSyncStatus(
    String id,
    SyncStatus status,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      UPDATE ${RoutineTable.tableName}
      SET
        ${RoutineTable.syncStatus} = ?,
        ${RoutineTable.updatedAt} = ?
      WHERE ${RoutineTable.id} = ?
      ''',
      [
        status.value,
        DateTime.now().toUtc().toIso8601String(),
        id,
      ],
    );
  }

  Future<
    List<
      RoutineLocalRecord
    >
  >
  getUnsynced({
    required String userId,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${RoutineTable.tableName}
      WHERE
        ${RoutineTable.userId} = ?
        AND ${RoutineTable.syncStatus} != ?
      ORDER BY ${RoutineTable.updatedAt} ASC
      ''',
      [
        userId,
        SyncStatus.synced.value,
      ],
    );

    return rows
        .map(
          _mapRecord,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    void
  >
  markDeleted(
    String id, {
    SyncStatus syncStatus = SyncStatus.pendingDelete,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
      UPDATE ${RoutineTable.tableName}
      SET
        ${RoutineTable.deletedAt} = ?,
        ${RoutineTable.syncStatus} = ?,
        ${RoutineTable.updatedAt} = ?
      WHERE ${RoutineTable.id} = ?
      ''',
      [
        now,
        syncStatus.value,
        now,
        id,
      ],
    );
  }

  Future<
    void
  >
  deletePermanently(
    String id,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      DELETE FROM ${RoutineTable.tableName}
      WHERE ${RoutineTable.id} = ?
      ''',
      [
        id,
      ],
    );
  }

  String _normalizeDate(
    DateTime value,
  ) {
    final year = value.year.toString().padLeft(
      4,
      '0',
    );
    final month = value.month.toString().padLeft(
      2,
      '0',
    );
    final day = value.day.toString().padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
  }

  RoutineLocalRecord _mapRecord(
    Map<
      String,
      Object?
    >
    row,
  ) {
    final decoded = jsonDecode(
      row[RoutineTable.payload]?.toString() ??
          '{}',
    );

    return RoutineLocalRecord(
      id:
          row[RoutineTable.id]?.toString() ??
          '',
      userId:
          row[RoutineTable.userId]?.toString() ??
          '',
      date: DateTime.parse(
        row[RoutineTable.date]?.toString() ??
            '',
      ),
      payload:
          decoded
              is Map
          ? Map<
              String,
              dynamic
            >.from(
              decoded,
            )
          : <
              String,
              dynamic
            >{},
      createdAt: DateTime.parse(
        row[RoutineTable.createdAt]?.toString() ??
            '',
      ).toLocal(),
      updatedAt: DateTime.parse(
        row[RoutineTable.updatedAt]?.toString() ??
            '',
      ).toLocal(),
      syncStatus: SyncStatus.fromValue(
        row[RoutineTable.syncStatus]?.toString(),
      ),
      deletedAt:
          row[RoutineTable.deletedAt] ==
              null
          ? null
          : DateTime.tryParse(
              row[RoutineTable.deletedAt].toString(),
            )?.toLocal(),
    );
  }
}
