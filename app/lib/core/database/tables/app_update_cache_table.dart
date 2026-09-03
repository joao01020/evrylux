class AppUpdateCacheTable {
  const AppUpdateCacheTable._();

  static const String tableName = 'app_update_cache';

  static const String id = 'id';
  static const String version = 'version';
  static const String title = 'title';
  static const String message = 'message';
  static const String publishedAt = 'published_at';
  static const String downloadUrl = 'download_url';
  static const String isRead = 'is_read';
  static const String cachedAt = 'cached_at';

  static const List<String> createStatements = <String>[
    '''
CREATE TABLE IF NOT EXISTS $tableName (
  $id TEXT PRIMARY KEY NOT NULL,
  $version TEXT NOT NULL,
  $title TEXT NOT NULL,
  $message TEXT NOT NULL,
  $publishedAt TEXT NOT NULL,
  $downloadUrl TEXT,
  $isRead INTEGER NOT NULL DEFAULT 0,
  $cachedAt TEXT NOT NULL
);
''',
    '''
CREATE INDEX IF NOT EXISTS
idx_app_update_cache_cached_at
ON $tableName ($cachedAt DESC);
''',
  ];
}
