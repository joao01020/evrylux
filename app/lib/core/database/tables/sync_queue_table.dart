class SyncQueueTable {
  const SyncQueueTable._();

  // ============================================================
  // TABLE
  // ============================================================

  static const String tableName = 'sync_queue';

  // ============================================================
  // COLUMNS
  // ============================================================

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

  // ============================================================
  // CREATE TABLE
  // ============================================================

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

      $nextAttemptAt TEXT,

      UNIQUE (
        $entityType,
        $entityId
      )
    );
  ''';

  // ============================================================
  // NEXT ATTEMPT INDEX
  // ============================================================
  //
  // Usado para buscar rapidamente operações que:
  //
  // - nunca falharam;
  // - ou já chegaram ao horário de retry.
  //
  // ============================================================

  static const String createNextAttemptIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_sync_queue_next_attempt
    ON $tableName (
      $nextAttemptAt
    );
  ''';

  // ============================================================
  // ENTITY INDEX
  // ============================================================
  //
  // Mesmo existindo UNIQUE(entity_type, entity_id), mantemos
  // explicitamente este índice por clareza da intenção da tabela.
  //
  // Em bancos novos o UNIQUE já cria um índice interno.
  //
  // ============================================================

  static const String createEntityIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_sync_queue_entity
    ON $tableName (
      $entityType,
      $entityId
    );
  ''';

  // ============================================================
  // READY INDEX
  // ============================================================
  //
  // Ajuda consultas que filtram por retry e ordenam por criação.
  //
  // ============================================================

  static const String createReadyIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_sync_queue_ready
    ON $tableName (
      $nextAttemptAt,
      $createdAt
    );
  ''';

  // ============================================================
  // CREATE STATEMENTS
  // ============================================================

  static const List<
    String
  >
  createStatements =
      <
        String
      >[
        createSql,
        createNextAttemptIndexSql,
        createEntityIndexSql,
        createReadyIndexSql,
      ];
}
