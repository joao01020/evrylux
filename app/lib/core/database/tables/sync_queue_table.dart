class SyncQueueTable {
  const SyncQueueTable._();

  static const String tableName = 'sync_queue';

  static const String id = 'id';
  static const String entityType = 'entity_type';
  static const String entityId = 'entity_id';
  static const String operation = 'operation';
  static const String payload = 'payload';
  static const String createdAt = 'created_at';
  static const String updatedAt = 'updated_at';
  static const String attempts = 'attempts';
  static const String lastError = 'last_error';
  static const String nextAttemptAt = 'next_attempt_at';

  static const String createSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $id TEXT PRIMARY KEY NOT NULL,
      $entityType TEXT NOT NULL,
      $entityId TEXT NOT NULL,
      $operation TEXT NOT NULL,
      $payload TEXT NOT NULL,
      $createdAt TEXT NOT NULL,
      $updatedAt TEXT NOT NULL,
      $attempts INTEGER NOT NULL DEFAULT 0,
      $lastError TEXT,
      $nextAttemptAt TEXT
    );
  ''';

  static const String createNextAttemptIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_sync_queue_next_attempt
    ON $tableName ($nextAttemptAt);
  ''';

  static const String createEntityIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_sync_queue_entity
    ON $tableName ($entityType, $entityId);
  ''';

  static const List<
    String
  >
  createStatements = [
    createSql,
    createNextAttemptIndexSql,
    createEntityIndexSql,
  ];
}
