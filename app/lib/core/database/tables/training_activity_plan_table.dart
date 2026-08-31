// ============================================================
// TRAINING ACTIVITY PLAN TABLE
// ============================================================
//
// Tabela SQLite local do planejamento semanal de treino.
//
// Cada registro representa uma atividade configurada:
//
// - chest
// - legs
// - arms
// - back
// - shoulders
// - core
// - running
// - walking
//
// Exemplo:
//
// activity = chest
// weekdays_json = [1,4]
//
// O banco local é a fonte imediata do offline-first.
//
// ============================================================

class TrainingActivityPlanTable {
  TrainingActivityPlanTable._();

  // ============================================================
  // TABLE
  // ============================================================

  static const String name = 'training_activity_plans';

  // ============================================================
  // COLUMNS
  // ============================================================

  static const String id = 'id';

  static const String userId = 'user_id';

  static const String activity = 'activity';

  static const String weekdaysJson = 'weekdays_json';

  static const String syncStatus = 'sync_status';

  static const String deleted = 'deleted';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  // ============================================================
  // CREATE TABLE
  // ============================================================

  static const String createTableSql =
      '''
CREATE TABLE IF NOT EXISTS $name (
  $id TEXT PRIMARY KEY,
  $userId TEXT NOT NULL,
  $activity TEXT NOT NULL,
  $weekdaysJson TEXT NOT NULL DEFAULT '[]',
  $syncStatus TEXT NOT NULL DEFAULT 'synced',
  $deleted INTEGER NOT NULL DEFAULT 0,
  $createdAt TEXT NOT NULL,
  $updatedAt TEXT NOT NULL,
  UNIQUE ($userId, $activity)
)
''';

  // ============================================================
  // INDEXES
  // ============================================================

  static const String createUserIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_training_activity_plans_user
ON $name ($userId)
''';

  static const String createUserActivityIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_training_activity_plans_user_activity
ON $name ($userId, $activity)
''';

  static const String createSyncStatusIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_training_activity_plans_sync_status
ON $name ($syncStatus)
''';

  static const String createDeletedIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_training_activity_plans_deleted
ON $name ($deleted)
''';

  // ============================================================
  // ALL CREATE STATEMENTS
  // ============================================================

  static const List<
    String
  >
  createStatements =
      <
        String
      >[
        createTableSql,
        createUserIndexSql,
        createUserActivityIndexSql,
        createSyncStatusIndexSql,
        createDeletedIndexSql,
      ];

  // ============================================================
  // LOCAL ID
  // ============================================================

  static String buildLocalId({
    required String userId,
    required String activity,
  }) {
    final normalizedUserId = userId.trim();

    final normalizedActivity = activity.trim().toLowerCase();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }

    if (normalizedActivity.isEmpty) {
      throw ArgumentError(
        'activity não pode ser vazia.',
      );
    }

    return '$normalizedUserId::$normalizedActivity';
  }
}
