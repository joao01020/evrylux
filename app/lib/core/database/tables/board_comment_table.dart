class BoardCommentTable {
  const BoardCommentTable._();

  static const String tableName = 'local_board_comments';
  static const String scopeTableName = 'local_board_comment_scopes';

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String dayId = 'day_id';
  static const String message = 'message';
  static const String positionX = 'position_x';
  static const String positionY = 'position_y';
  static const String authorName = 'author_name';
  static const String resolved = 'resolved';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String syncStatus = 'sync_status';
  static const String deletedAt = 'deleted_at';

  static const String scopeKey = 'scope_key';
  static const String initializedAt = 'initialized_at';

  static const String createCommentsSql = '''
CREATE TABLE IF NOT EXISTS $tableName (
  $id TEXT PRIMARY KEY NOT NULL,
  $userId TEXT NOT NULL,
  $dayId TEXT NOT NULL,
  $message TEXT NOT NULL,
  $positionX REAL NOT NULL DEFAULT 0,
  $positionY REAL NOT NULL DEFAULT 0,
  $authorName TEXT NOT NULL DEFAULT 'Você',
  $resolved INTEGER NOT NULL DEFAULT 0,
  $createdAt TEXT NOT NULL,
  $updatedAt TEXT NOT NULL,
  $syncStatus TEXT NOT NULL DEFAULT 'synced',
  $deletedAt TEXT
);
''';

  static const String createScopesSql = '''
CREATE TABLE IF NOT EXISTS $scopeTableName (
  $userId TEXT NOT NULL,
  $scopeKey TEXT NOT NULL,
  $initializedAt TEXT NOT NULL,
  PRIMARY KEY ($userId, $scopeKey)
);
''';

  static const String createUserDayIndexSql = '''
CREATE INDEX IF NOT EXISTS
idx_local_board_comments_user_day
ON $tableName ($userId, $dayId, $createdAt);
''';

  static const String createSyncIndexSql = '''
CREATE INDEX IF NOT EXISTS
idx_local_board_comments_sync
ON $tableName ($userId, $syncStatus, $updatedAt);
''';

  static const List<String> createStatements = [
    createCommentsSql,
    createScopesSql,
    createUserDayIndexSql,
    createSyncIndexSql,
  ];
}
