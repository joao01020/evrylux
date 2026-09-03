import '../../../profile/notifications/models/app_update_notification.dart';
import '../app_database.dart';
import '../tables/app_update_cache_table.dart';

class AppUpdateCacheDao {
  AppUpdateCacheDao({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  bool _initialized = false;

  Future<void> initialize() {
    return _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _database.initialize();

    for (final statement in AppUpdateCacheTable.createStatements) {
      _database.db.execute(statement);
    }

    _initialized = true;
  }

  Future<AppUpdateNotification?> loadLatest() async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
SELECT *
FROM ${AppUpdateCacheTable.tableName}
ORDER BY ${AppUpdateCacheTable.cachedAt} DESC
LIMIT 1
''',
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    return AppUpdateNotification.fromMap(
      <String, dynamic>{
        'version': row[AppUpdateCacheTable.version],
        'title': row[AppUpdateCacheTable.title],
        'message': row[AppUpdateCacheTable.message],
        'published_at': row[AppUpdateCacheTable.publishedAt],
        'download_url': row[AppUpdateCacheTable.downloadUrl],
        'is_read': _asBool(row[AppUpdateCacheTable.isRead]),
      },
    );
  }

  Future<void> save(
    AppUpdateNotification notification,
  ) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    _database.transaction(
      () {
        // Mantemos apenas o snapshot útil mais recente.
        _database.db.execute(
          'DELETE FROM ${AppUpdateCacheTable.tableName};',
        );

        _database.db.execute(
          '''
INSERT INTO ${AppUpdateCacheTable.tableName} (
  ${AppUpdateCacheTable.id},
  ${AppUpdateCacheTable.version},
  ${AppUpdateCacheTable.title},
  ${AppUpdateCacheTable.message},
  ${AppUpdateCacheTable.publishedAt},
  ${AppUpdateCacheTable.downloadUrl},
  ${AppUpdateCacheTable.isRead},
  ${AppUpdateCacheTable.cachedAt}
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
''',
          <Object?>[
            notification.id,
            notification.version,
            notification.title,
            notification.message,
            notification.publishedAt.toUtc().toIso8601String(),
            notification.downloadUrl,
            notification.isRead ? 1 : 0,
            now,
          ],
        );
      },
    );
  }

  Future<void> clear() async {
    await _ensureInitialized();

    _database.db.execute(
      'DELETE FROM ${AppUpdateCacheTable.tableName};',
    );
  }

  bool _asBool(Object? value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == '1' || normalized == 'true';
  }
}
