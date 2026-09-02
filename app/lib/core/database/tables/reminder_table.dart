class ReminderTable {
  const ReminderTable._();

  // ============================================================
  // TABLE
  // ============================================================

  static const String tableName = 'local_reminders';

  // ============================================================
  // COLUMNS
  // ============================================================

  static const String id = 'id';

  static const String userId = 'user_id';

  static const String title = 'title';

  static const String message = 'message';

  static const String remindAt = 'remind_at';

  static const String sourceType = 'source_type';

  static const String sourceId = 'source_id';

  static const String notifyInApp = 'notify_in_app';

  static const String notifyTelegram = 'notify_telegram';

  static const String sentInApp = 'sent_in_app';

  static const String sentTelegram = 'sent_telegram';

  static const String completed = 'completed';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String syncStatus = 'sync_status';

  static const String deletedAt = 'deleted_at';

  // ============================================================
  // CREATE TABLE
  // ============================================================
  //
  // DATAS:
  //
  // Todos os timestamps são armazenados como TEXT utilizando
  // ISO-8601 em UTC.
  //
  // Exemplo:
  //
  // 2026-09-02T01:30:00.000Z
  //
  // Isso permite:
  //
  // - comparação cronológica direta no SQLite;
  // - independência do timezone do sistema operacional;
  // - sincronização consistente com Supabase;
  // - mesma representação no modo online e offline.
  //
  // ============================================================

  static const String createSql =
      '''
    CREATE TABLE IF NOT EXISTS $tableName (
      $id TEXT PRIMARY KEY NOT NULL,

      $userId TEXT NOT NULL,

      $title TEXT NOT NULL,

      $message TEXT NOT NULL,

      $remindAt TEXT NOT NULL,

      $sourceType TEXT,

      $sourceId TEXT,

      $notifyInApp INTEGER NOT NULL DEFAULT 1,

      $notifyTelegram INTEGER NOT NULL DEFAULT 0,

      $sentInApp INTEGER NOT NULL DEFAULT 0,

      $sentTelegram INTEGER NOT NULL DEFAULT 0,

      $completed INTEGER NOT NULL DEFAULT 0,

      $createdAt TEXT,

      $updatedAt TEXT,

      $syncStatus TEXT NOT NULL DEFAULT 'synced',

      $deletedAt TEXT
    );
  ''';

  // ============================================================
  // INDEX — USER
  // ============================================================
  //
  // Usado principalmente por:
  //
  // getAllForUser()
  // getPendingForUser()
  //
  // ============================================================

  static const String createUserIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_local_reminders_user
    ON $tableName (
      $userId
    );
  ''';

  // ============================================================
  // INDEX — DUE
  // ============================================================
  //
  // Otimizado para a consulta:
  //
  // user_id = ?
  // completed = 0
  // notify_in_app = 1
  // sent_in_app = 0
  // deleted_at IS NULL
  // remind_at <= agora
  //
  // remindAt fica no final porque é utilizado como range.
  //
  // ============================================================

  static const String createDueIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_local_reminders_due
    ON $tableName (
      $userId,
      $completed,
      $notifyInApp,
      $sentInApp,
      $deletedAt,
      $remindAt
    );
  ''';

  // ============================================================
  // INDEX — SYNC
  // ============================================================
  //
  // Usado pelo mecanismo offline-first para localizar registros
  // que ainda precisam ser sincronizados.
  //
  // ============================================================

  static const String createSyncIndexSql =
      '''
    CREATE INDEX IF NOT EXISTS
    idx_local_reminders_sync
    ON $tableName (
      $syncStatus
    );
  ''';

  // ============================================================
  // CREATE STATEMENTS
  // ============================================================

  static const List<
    String
  >
  createStatements = [
    createSql,
    createUserIndexSql,
    createDueIndexSql,
    createSyncIndexSql,
  ];
}
