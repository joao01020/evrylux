import '../../../reminders/models/reminder_model.dart';
import '../../sync/sync_status.dart';
import '../app_database.dart';
import '../tables/reminder_table.dart';

class ReminderDao {
  ReminderDao({
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

    for (final sql in ReminderTable.createStatements) {
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
    ReminderModel reminder, {
    SyncStatus syncStatus = SyncStatus.synced,
    DateTime? deletedAt,
  }) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
      INSERT INTO ${ReminderTable.tableName} (
        ${ReminderTable.id},
        ${ReminderTable.userId},
        ${ReminderTable.title},
        ${ReminderTable.message},
        ${ReminderTable.remindAt},
        ${ReminderTable.sourceType},
        ${ReminderTable.sourceId},
        ${ReminderTable.notifyInApp},
        ${ReminderTable.notifyTelegram},
        ${ReminderTable.sentInApp},
        ${ReminderTable.sentTelegram},
        ${ReminderTable.completed},
        ${ReminderTable.createdAt},
        ${ReminderTable.updatedAt},
        ${ReminderTable.syncStatus},
        ${ReminderTable.deletedAt}
      )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(${ReminderTable.id})
      DO UPDATE SET
        ${ReminderTable.userId} = excluded.${ReminderTable.userId},
        ${ReminderTable.title} = excluded.${ReminderTable.title},
        ${ReminderTable.message} = excluded.${ReminderTable.message},
        ${ReminderTable.remindAt} = excluded.${ReminderTable.remindAt},
        ${ReminderTable.sourceType} = excluded.${ReminderTable.sourceType},
        ${ReminderTable.sourceId} = excluded.${ReminderTable.sourceId},
        ${ReminderTable.notifyInApp} = excluded.${ReminderTable.notifyInApp},
        ${ReminderTable.notifyTelegram} = excluded.${ReminderTable.notifyTelegram},
        ${ReminderTable.sentInApp} = excluded.${ReminderTable.sentInApp},
        ${ReminderTable.sentTelegram} = excluded.${ReminderTable.sentTelegram},
        ${ReminderTable.completed} = excluded.${ReminderTable.completed},
        ${ReminderTable.updatedAt} = excluded.${ReminderTable.updatedAt},
        ${ReminderTable.syncStatus} = excluded.${ReminderTable.syncStatus},
        ${ReminderTable.deletedAt} = excluded.${ReminderTable.deletedAt}
      ''',
      [
        reminder.id,
        reminder.userId,
        reminder.title,
        reminder.message,
        reminder.remindAt.toUtc().toIso8601String(),
        reminder.sourceType,
        reminder.sourceId,
        reminder.notifyInApp
            ? 1
            : 0,
        reminder.notifyTelegram
            ? 1
            : 0,
        reminder.sentInApp
            ? 1
            : 0,
        reminder.sentTelegram
            ? 1
            : 0,
        reminder.completed
            ? 1
            : 0,
        reminder.createdAt?.toUtc().toIso8601String(),
        (reminder.updatedAt ??
                DateTime.now())
            .toUtc()
            .toIso8601String(),
        syncStatus.value,
        deletedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  Future<
    List<
      ReminderModel
    >
  >
  getAllForUser(
    String userId, {
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${ReminderTable.tableName}
      WHERE
        ${ReminderTable.userId} = ?
        ${includeDeleted ? '' : 'AND ${ReminderTable.deletedAt} IS NULL'}
      ORDER BY ${ReminderTable.remindAt} ASC
      ''',
      [
        userId,
      ],
    );

    return rows
        .map(
          _mapReminder,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    List<
      ReminderModel
    >
  >
  getPendingForUser(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${ReminderTable.tableName}
      WHERE
        ${ReminderTable.userId} = ?
        AND ${ReminderTable.completed} = 0
        AND ${ReminderTable.deletedAt} IS NULL
      ORDER BY ${ReminderTable.remindAt} ASC
      ''',
      [
        userId,
      ],
    );

    return rows
        .map(
          _mapReminder,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    List<
      ReminderModel
    >
  >
  getDueForUser(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${ReminderTable.tableName}
      WHERE
        ${ReminderTable.userId} = ?
        AND ${ReminderTable.completed} = 0
        AND ${ReminderTable.notifyInApp} = 1
        AND ${ReminderTable.sentInApp} = 0
        AND ${ReminderTable.deletedAt} IS NULL
        AND ${ReminderTable.remindAt} <= ?
      ORDER BY ${ReminderTable.remindAt} ASC
      ''',
      [
        userId,
        DateTime.now().toUtc().toIso8601String(),
      ],
    );

    return rows
        .map(
          _mapReminder,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    ReminderModel?
  >
  getById(
    String id,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT *
      FROM ${ReminderTable.tableName}
      WHERE ${ReminderTable.id} = ?
      LIMIT 1
      ''',
      [
        id,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapReminder(
      rows.first,
    );
  }

  Future<
    SyncStatus?
  >
  getSyncStatus(
    String id,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
      SELECT ${ReminderTable.syncStatus}
      FROM ${ReminderTable.tableName}
      WHERE ${ReminderTable.id} = ?
      LIMIT 1
      ''',
      [
        id,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return SyncStatus.fromValue(
      rows.first[ReminderTable.syncStatus]?.toString(),
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
      UPDATE ${ReminderTable.tableName}
      SET
        ${ReminderTable.syncStatus} = ?,
        ${ReminderTable.updatedAt} = ?
      WHERE ${ReminderTable.id} = ?
      ''',
      [
        status.value,
        DateTime.now().toUtc().toIso8601String(),
        id,
      ],
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
      UPDATE ${ReminderTable.tableName}
      SET
        ${ReminderTable.deletedAt} = ?,
        ${ReminderTable.syncStatus} = ?,
        ${ReminderTable.updatedAt} = ?
      WHERE ${ReminderTable.id} = ?
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
      DELETE FROM ${ReminderTable.tableName}
      WHERE ${ReminderTable.id} = ?
      ''',
      [
        id,
      ],
    );
  }

  ReminderModel _mapReminder(
    Map<
      String,
      Object?
    >
    row,
  ) {
    bool asBool(
      String key,
    ) {
      final value = row[key];

      if (value
          is bool) {
        return value;
      }

      if (value
          is int) {
        return value ==
            1;
      }

      return value.toString() ==
          '1';
    }

    return ReminderModel.fromJson(
      {
        'id': row[ReminderTable.id],
        'user_id': row[ReminderTable.userId],
        'title': row[ReminderTable.title],
        'message': row[ReminderTable.message],
        'remind_at': row[ReminderTable.remindAt],
        'source_type': row[ReminderTable.sourceType],
        'source_id': row[ReminderTable.sourceId],
        'notify_in_app': asBool(
          ReminderTable.notifyInApp,
        ),
        'notify_telegram': asBool(
          ReminderTable.notifyTelegram,
        ),
        'sent_in_app': asBool(
          ReminderTable.sentInApp,
        ),
        'sent_telegram': asBool(
          ReminderTable.sentTelegram,
        ),
        'completed': asBool(
          ReminderTable.completed,
        ),
        'created_at': row[ReminderTable.createdAt],
        'updated_at': row[ReminderTable.updatedAt],
      },
    );
  }
}
