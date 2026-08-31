import 'dart:convert';

import '../app_database.dart';
import '../tables/training_activity_plan_table.dart';
import '../../sync/sync_status.dart';

// ============================================================
// TRAINING ACTIVITY PLAN DAO
// ============================================================
//
// DAO SQLite do planejamento semanal de atividades.
//
// Responsabilidades:
//
// - criar/garantir a tabela local;
// - salvar uma atividade;
// - carregar plano do usuário;
// - consultar atividade;
// - marcar soft delete;
// - remover definitivamente após sync;
// - controlar sync_status.
//
// ============================================================

class TrainingActivityPlanDao {
  TrainingActivityPlanDao({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  // ============================================================
  // DATABASE
  // ============================================================

  final AppDatabase _database;

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() {
    return _ensureInitialized();
  }

  Future<
    void
  >
  _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _database.initialize();

    final db = _database.db;

    for (final statement in TrainingActivityPlanTable.createStatements) {
      db.execute(
        statement,
      );
    }

    _initialized = true;
  }

  // ============================================================
  // UPSERT
  // ============================================================

  Future<
    String
  >
  upsert({
    String? id,
    required String userId,
    required String activity,
    required Iterable<
      int
    >
    weekdays,
    SyncStatus syncStatus = SyncStatus.pendingUpdate,
    bool deleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    final normalizedWeekdays = _normalizeWeekdays(
      weekdays,
    );

    final localId =
        id?.trim().isNotEmpty ==
            true
        ? id!.trim()
        : TrainingActivityPlanTable.buildLocalId(
            userId: normalizedUserId,
            activity: normalizedActivity,
          );

    final now = DateTime.now().toUtc();

    final created =
        (createdAt ??
                now)
            .toUtc()
            .toIso8601String();

    final updated =
        (updatedAt ??
                now)
            .toUtc()
            .toIso8601String();

    _database.db.execute(
      '''
INSERT INTO ${TrainingActivityPlanTable.name} (
  ${TrainingActivityPlanTable.id},
  ${TrainingActivityPlanTable.userId},
  ${TrainingActivityPlanTable.activity},
  ${TrainingActivityPlanTable.weekdaysJson},
  ${TrainingActivityPlanTable.syncStatus},
  ${TrainingActivityPlanTable.deleted},
  ${TrainingActivityPlanTable.createdAt},
  ${TrainingActivityPlanTable.updatedAt}
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT (
  ${TrainingActivityPlanTable.userId},
  ${TrainingActivityPlanTable.activity}
)
DO UPDATE SET
  ${TrainingActivityPlanTable.weekdaysJson}
    = excluded.${TrainingActivityPlanTable.weekdaysJson},
  ${TrainingActivityPlanTable.syncStatus}
    = excluded.${TrainingActivityPlanTable.syncStatus},
  ${TrainingActivityPlanTable.deleted}
    = excluded.${TrainingActivityPlanTable.deleted},
  ${TrainingActivityPlanTable.updatedAt}
    = excluded.${TrainingActivityPlanTable.updatedAt}
''',
      <
        Object?
      >[
        localId,
        normalizedUserId,
        normalizedActivity,
        jsonEncode(
          normalizedWeekdays,
        ),
        syncStatus.value,
        deleted
            ? 1
            : 0,
        created,
        updated,
      ],
    );

    final existing = await getByActivity(
      userId: normalizedUserId,
      activity: normalizedActivity,
      includeDeleted: true,
    );

    return existing?[TrainingActivityPlanTable.id]?.toString() ??
        localId;
  }

  // ============================================================
  // GET ALL
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getAll({
    required String userId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final sql = includeDeleted
        ? '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
ORDER BY ${TrainingActivityPlanTable.activity} ASC
'''
        : '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.deleted} = 0
ORDER BY ${TrainingActivityPlanTable.activity} ASC
''';

    final result = _database.db.select(
      sql,
      <
        Object?
      >[
        normalizedUserId,
      ],
    );

    return result
        .map(
          _rowToMap,
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET BY ACTIVITY
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getByActivity({
    required String userId,
    required String activity,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    final sql = includeDeleted
        ? '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
LIMIT 1
'''
        : '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
  AND ${TrainingActivityPlanTable.deleted} = 0
LIMIT 1
''';

    final result = _database.db.select(
      sql,
      <
        Object?
      >[
        normalizedUserId,
        normalizedActivity,
      ],
    );

    if (result.isEmpty) {
      return null;
    }

    return _rowToMap(
      result.first,
    );
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    final sql = includeDeleted
        ? '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.id} = ?
LIMIT 1
'''
        : '''
SELECT *
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.id} = ?
  AND ${TrainingActivityPlanTable.deleted} = 0
LIMIT 1
''';

    final result = _database.db.select(
      sql,
      <
        Object?
      >[
        normalizedId,
      ],
    );

    if (result.isEmpty) {
      return null;
    }

    return _rowToMap(
      result.first,
    );
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  exists({
    required String userId,
    required String activity,
  }) async {
    return await getByActivity(
          userId: userId,
          activity: activity,
        ) !=
        null;
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count({
    required String userId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final sql = includeDeleted
        ? '''
SELECT COUNT(*) AS total
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
'''
        : '''
SELECT COUNT(*) AS total
FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.deleted} = 0
''';

    final result = _database.db.select(
      sql,
      <
        Object?
      >[
        normalizedUserId,
      ],
    );

    if (result.isEmpty) {
      return 0;
    }

    final raw = result.first['total'];

    if (raw
        is int) {
      return raw;
    }

    return int.tryParse(
          raw?.toString() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // LOAD FOR WEEKDAY
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  getForWeekday({
    required String userId,
    required int weekday,
  }) async {
    _validateWeekday(
      weekday,
    );

    final rows = await getAll(
      userId: userId,
    );

    return rows
        .where(
          (
            row,
          ) {
            final weekdays = decodeWeekdays(
              row[TrainingActivityPlanTable.weekdaysJson],
            );

            return weekdays.contains(
              weekday,
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // MARK DELETED
  // ============================================================

  Future<
    void
  >
  markDeleted({
    required String userId,
    required String activity,
    SyncStatus syncStatus = SyncStatus.pendingDelete,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    _database.db.execute(
      '''
UPDATE ${TrainingActivityPlanTable.name}
SET
  ${TrainingActivityPlanTable.deleted} = 1,
  ${TrainingActivityPlanTable.syncStatus} = ?,
  ${TrainingActivityPlanTable.updatedAt} = ?
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
''',
      <
        Object?
      >[
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedActivity,
      ],
    );
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<
    void
  >
  restore({
    required String userId,
    required String activity,
    SyncStatus syncStatus = SyncStatus.pendingUpdate,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    _database.db.execute(
      '''
UPDATE ${TrainingActivityPlanTable.name}
SET
  ${TrainingActivityPlanTable.deleted} = 0,
  ${TrainingActivityPlanTable.syncStatus} = ?,
  ${TrainingActivityPlanTable.updatedAt} = ?
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
''',
      <
        Object?
      >[
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedActivity,
      ],
    );
  }

  // ============================================================
  // SET SYNC STATUS BY ID
  // ============================================================

  Future<
    void
  >
  setSyncStatus(
    String id,
    SyncStatus syncStatus,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _database.db.execute(
      '''
UPDATE ${TrainingActivityPlanTable.name}
SET
  ${TrainingActivityPlanTable.syncStatus} = ?,
  ${TrainingActivityPlanTable.updatedAt} = ?
WHERE ${TrainingActivityPlanTable.id} = ?
''',
      <
        Object?
      >[
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedId,
      ],
    );
  }

  // ============================================================
  // SET SYNC STATUS BY ACTIVITY
  // ============================================================

  Future<
    void
  >
  setActivitySyncStatus({
    required String userId,
    required String activity,
    required SyncStatus syncStatus,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    _database.db.execute(
      '''
UPDATE ${TrainingActivityPlanTable.name}
SET
  ${TrainingActivityPlanTable.syncStatus} = ?,
  ${TrainingActivityPlanTable.updatedAt} = ?
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
''',
      <
        Object?
      >[
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedActivity,
      ],
    );
  }

  // ============================================================
  // DELETE PERMANENTLY BY ID
  // ============================================================

  Future<
    void
  >
  deletePermanently(
    String id,
  ) async {
    await _ensureInitialized();

    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    _database.db.execute(
      '''
DELETE FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.id} = ?
''',
      <
        Object?
      >[
        normalizedId,
      ],
    );
  }

  // ============================================================
  // DELETE PERMANENTLY BY ACTIVITY
  // ============================================================

  Future<
    void
  >
  deleteActivityPermanently({
    required String userId,
    required String activity,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    final normalizedActivity = _normalizeActivity(
      activity,
    );

    _database.db.execute(
      '''
DELETE FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
  AND ${TrainingActivityPlanTable.activity} = ?
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedActivity,
      ],
    );
  }

  // ============================================================
  // CLEAR USER PERMANENTLY
  // ============================================================

  Future<
    void
  >
  clearUserPermanently(
    String userId,
  ) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeUserId(
      userId,
    );

    _database.db.execute(
      '''
DELETE FROM ${TrainingActivityPlanTable.name}
WHERE ${TrainingActivityPlanTable.userId} = ?
''',
      <
        Object?
      >[
        normalizedUserId,
      ],
    );
  }

  // ============================================================
  // ROW TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  _rowToMap(
    dynamic row,
  ) {
    return <
      String,
      dynamic
    >{
      TrainingActivityPlanTable.id: row[TrainingActivityPlanTable.id]?.toString(),

      TrainingActivityPlanTable.userId: row[TrainingActivityPlanTable.userId]?.toString(),

      TrainingActivityPlanTable.activity: row[TrainingActivityPlanTable.activity]?.toString(),

      TrainingActivityPlanTable.weekdaysJson:
          row[TrainingActivityPlanTable.weekdaysJson]?.toString() ??
          '[]',

      'weekdays': decodeWeekdays(
        row[TrainingActivityPlanTable.weekdaysJson],
      ),

      TrainingActivityPlanTable.syncStatus:
          row[TrainingActivityPlanTable.syncStatus]?.toString() ??
          SyncStatus.synced.value,

      TrainingActivityPlanTable.deleted: _asBool(
        row[TrainingActivityPlanTable.deleted],
      ),

      TrainingActivityPlanTable.createdAt: row[TrainingActivityPlanTable.createdAt]?.toString(),

      TrainingActivityPlanTable.updatedAt: row[TrainingActivityPlanTable.updatedAt]?.toString(),
    };
  }

  // ============================================================
  // DECODE WEEKDAYS
  // ============================================================

  static Set<
    int
  >
  decodeWeekdays(
    dynamic raw,
  ) {
    if (raw ==
        null) {
      return <
        int
      >{};
    }

    dynamic decoded = raw;

    if (raw
        is String) {
      try {
        decoded = jsonDecode(
          raw,
        );
      } catch (
        _
      ) {
        return <
          int
        >{};
      }
    }

    if (decoded
        is! Iterable) {
      return <
        int
      >{};
    }

    final result =
        <
          int
        >{};

    for (final value in decoded) {
      final weekday =
          value
              is int
          ? value
          : int.tryParse(
              value.toString(),
            );

      if (weekday ==
          null) {
        continue;
      }

      if (weekday <
              DateTime.monday ||
          weekday >
              DateTime.sunday) {
        continue;
      }

      result.add(
        weekday,
      );
    }

    return result;
  }

  // ============================================================
  // NORMALIZE USER ID
  // ============================================================

  String _normalizeUserId(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZE ACTIVITY
  // ============================================================

  String _normalizeActivity(
    String value,
  ) {
    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'activity não pode ser vazia.',
      );
    }

    return normalized;
  }

  // ============================================================
  // NORMALIZE WEEKDAYS
  // ============================================================

  List<
    int
  >
  _normalizeWeekdays(
    Iterable<
      int
    >
    values,
  ) {
    final weekdays =
        <
          int
        >{};

    for (final weekday in values) {
      if (weekday <
              DateTime.monday ||
          weekday >
              DateTime.sunday) {
        continue;
      }

      weekdays.add(
        weekday,
      );
    }

    final result = weekdays.toList();

    result.sort();

    return result;
  }

  // ============================================================
  // BOOL
  // ============================================================

  bool _asBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is int) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            '1' ||
        normalized ==
            'true';
  }

  // ============================================================
  // VALIDATE WEEKDAY
  // ============================================================

  void _validateWeekday(
    int weekday,
  ) {
    if (weekday <
            DateTime.monday ||
        weekday >
            DateTime.sunday) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'O dia da semana deve estar entre '
            '${DateTime.monday} e '
            '${DateTime.sunday}.',
      );
    }
  }
}
