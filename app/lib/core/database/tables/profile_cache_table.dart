class ProfileCacheTable {
  const ProfileCacheTable._();

  static const String tableName = 'profile_cache';

  static const String userId = 'user_id';
  static const String fullName = 'full_name';
  static const String email = 'email';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String compactMode = 'ui_compact_mode';
  static const String reduceMotion = 'ui_reduce_motion';
  static const String confirmBeforeDelete = 'confirm_before_delete';
  static const String preferencesInitialized = 'preferences_initialized';
  static const String preferencesDirty = 'preferences_dirty';
  static const String cachedAt = 'cached_at';

  static const List<String> createStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS $tableName (
  $userId TEXT PRIMARY KEY NOT NULL,
  $fullName TEXT NOT NULL DEFAULT '',
  $email TEXT NOT NULL DEFAULT '',
  $createdAt TEXT,
  $updatedAt TEXT,
  $compactMode INTEGER NOT NULL DEFAULT 0,
  $reduceMotion INTEGER NOT NULL DEFAULT 0,
  $confirmBeforeDelete INTEGER NOT NULL DEFAULT 1,
  $preferencesInitialized INTEGER NOT NULL DEFAULT 0,
  $preferencesDirty INTEGER NOT NULL DEFAULT 0,
  $cachedAt TEXT NOT NULL
);
''',
    '''
CREATE INDEX IF NOT EXISTS
idx_profile_cache_cached_at
ON $tableName ($cachedAt DESC);
''',
  ];
}
