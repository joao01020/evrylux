import '../../../profile/models/profile_preferences.dart';
import '../../../profile/models/user_profile.dart';
import '../app_database.dart';
import '../tables/profile_cache_table.dart';

class ProfileCacheDao {
  ProfileCacheDao({
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

    for (final statement in ProfileCacheTable.createStatements) {
      _database.db.execute(statement);
    }

    _initialized = true;
  }

  Future<UserProfile?> loadProfile(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
SELECT *
FROM ${ProfileCacheTable.tableName}
WHERE ${ProfileCacheTable.userId} = ?
LIMIT 1
''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;
    final fullName = row[ProfileCacheTable.fullName]?.toString() ?? '';

    if (fullName.trim().isEmpty) {
      return null;
    }

    return UserProfile.fromMap(
      <String, dynamic>{
        'id': row[ProfileCacheTable.userId],
        'full_name': fullName,
        'created_at': row[ProfileCacheTable.createdAt],
        'updated_at': row[ProfileCacheTable.updatedAt],
      },
    );
  }

  Future<String?> loadEmail(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
SELECT ${ProfileCacheTable.email}
FROM ${ProfileCacheTable.tableName}
WHERE ${ProfileCacheTable.userId} = ?
LIMIT 1
''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final value = rows.first[ProfileCacheTable.email]?.toString().trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  Future<void> saveProfile(
    UserProfile profile, {
    String? email,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
INSERT INTO ${ProfileCacheTable.tableName} (
  ${ProfileCacheTable.userId},
  ${ProfileCacheTable.fullName},
  ${ProfileCacheTable.email},
  ${ProfileCacheTable.createdAt},
  ${ProfileCacheTable.updatedAt},
  ${ProfileCacheTable.cachedAt}
)
VALUES (?, ?, ?, ?, ?, ?)
ON CONFLICT(${ProfileCacheTable.userId})
DO UPDATE SET
  ${ProfileCacheTable.fullName} = excluded.${ProfileCacheTable.fullName},
  ${ProfileCacheTable.email} = CASE
    WHEN excluded.${ProfileCacheTable.email} <> ''
      THEN excluded.${ProfileCacheTable.email}
    ELSE ${ProfileCacheTable.tableName}.${ProfileCacheTable.email}
  END,
  ${ProfileCacheTable.createdAt} = COALESCE(
    excluded.${ProfileCacheTable.createdAt},
    ${ProfileCacheTable.tableName}.${ProfileCacheTable.createdAt}
  ),
  ${ProfileCacheTable.updatedAt} = excluded.${ProfileCacheTable.updatedAt},
  ${ProfileCacheTable.cachedAt} = excluded.${ProfileCacheTable.cachedAt}
''',
      <Object?>[
        profile.id,
        profile.fullName.trim(),
        email?.trim() ?? '',
        profile.createdAt?.toUtc().toIso8601String(),
        profile.updatedAt?.toUtc().toIso8601String(),
        now,
      ],
    );
  }

  Future<ProfilePreferences?> loadPreferences(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
SELECT
  ${ProfileCacheTable.preferencesInitialized},
  ${ProfileCacheTable.compactMode},
  ${ProfileCacheTable.reduceMotion},
  ${ProfileCacheTable.confirmBeforeDelete}
FROM ${ProfileCacheTable.tableName}
WHERE ${ProfileCacheTable.userId} = ?
LIMIT 1
''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final row = rows.first;

    if (!_asBool(row[ProfileCacheTable.preferencesInitialized])) {
      return null;
    }

    return ProfilePreferences(
      compactMode: _asBool(row[ProfileCacheTable.compactMode]),
      reduceMotion: _asBool(row[ProfileCacheTable.reduceMotion]),
      confirmBeforeDelete: _asBool(
        row[ProfileCacheTable.confirmBeforeDelete],
      ),
    );
  }

  Future<void> savePreferences({
    required String userId,
    required ProfilePreferences preferences,
    required bool dirty,
    String? email,
  }) async {
    await _ensureInitialized();

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
INSERT INTO ${ProfileCacheTable.tableName} (
  ${ProfileCacheTable.userId},
  ${ProfileCacheTable.email},
  ${ProfileCacheTable.compactMode},
  ${ProfileCacheTable.reduceMotion},
  ${ProfileCacheTable.confirmBeforeDelete},
  ${ProfileCacheTable.preferencesInitialized},
  ${ProfileCacheTable.preferencesDirty},
  ${ProfileCacheTable.cachedAt}
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(${ProfileCacheTable.userId})
DO UPDATE SET
  ${ProfileCacheTable.email} = CASE
    WHEN excluded.${ProfileCacheTable.email} <> ''
      THEN excluded.${ProfileCacheTable.email}
    ELSE ${ProfileCacheTable.tableName}.${ProfileCacheTable.email}
  END,
  ${ProfileCacheTable.compactMode} = excluded.${ProfileCacheTable.compactMode},
  ${ProfileCacheTable.reduceMotion} = excluded.${ProfileCacheTable.reduceMotion},
  ${ProfileCacheTable.confirmBeforeDelete} = excluded.${ProfileCacheTable.confirmBeforeDelete},
  ${ProfileCacheTable.preferencesInitialized} = 1,
  ${ProfileCacheTable.preferencesDirty} = excluded.${ProfileCacheTable.preferencesDirty},
  ${ProfileCacheTable.cachedAt} = excluded.${ProfileCacheTable.cachedAt}
''',
      <Object?>[
        userId,
        email?.trim() ?? '',
        preferences.compactMode ? 1 : 0,
        preferences.reduceMotion ? 1 : 0,
        preferences.confirmBeforeDelete ? 1 : 0,
        1,
        dirty ? 1 : 0,
        now,
      ],
    );
  }

  Future<bool> hasDirtyPreferences(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = _database.db.select(
      '''
SELECT ${ProfileCacheTable.preferencesDirty}
FROM ${ProfileCacheTable.tableName}
WHERE ${ProfileCacheTable.userId} = ?
LIMIT 1
''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return false;
    }

    return _asBool(rows.first[ProfileCacheTable.preferencesDirty]);
  }

  Future<void> markPreferencesSynced(
    String userId,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
UPDATE ${ProfileCacheTable.tableName}
SET ${ProfileCacheTable.preferencesDirty} = 0,
    ${ProfileCacheTable.cachedAt} = ?
WHERE ${ProfileCacheTable.userId} = ?
''',
      <Object?>[
        DateTime.now().toUtc().toIso8601String(),
        userId,
      ],
    );
  }

  Future<void> deleteUser(
    String userId,
  ) async {
    await _ensureInitialized();

    _database.db.execute(
      '''
DELETE FROM ${ProfileCacheTable.tableName}
WHERE ${ProfileCacheTable.userId} = ?
''',
      <Object?>[userId],
    );
  }

  bool _asBool(
    Object? value,
  ) {
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
