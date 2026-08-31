class RoutineTable {
  const RoutineTable._();

  static const String tableName = 'local_routines';

  static const String id = 'id';
  static const String userId = 'user_id';
  static const String date = 'date';
  static const String payload = 'payload';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String syncStatus = 'sync_status';
  static const String deletedAt = 'deleted_at';

  static const String createSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $id TEXT PRIMARY KEY NOT NULL,
      $userId TEXT NOT NULL,
      $date TEXT NOT NULL,
      $payload TEXT NOT NULL,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $syncStatus TEXT NOT NULL DEFAULT 'synced',
      $deletedAt TEXT
    );
  ''';

  static const String createUserDateUniqueIndexSql =
      '''
    CREATE UNIQUE INDEX IF NOT EXISTS
    idx_local_routines_user_date
    ON $tableName ($userId, $date);
  ''';

  static const String createSyncIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_local_routines_sync
    ON $tableName ($syncStatus);
  ''';

  static const List<
    String
  >
  createStatements = [
    createSql,
    createUserDateUniqueIndexSql,
    createSyncIndexSql,
  ];
}
