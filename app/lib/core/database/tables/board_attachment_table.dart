class BoardAttachmentTable {
  const BoardAttachmentTable._();

  // ============================================================
  // TABLE
  // ============================================================

  static const String tableName = 'local_board_attachments';

  // ============================================================
  // COLUMNS
  // ============================================================

  static const String id = 'id';

  static const String userId = 'user_id';

  static const String boardId = 'board_id';

  static const String blockId = 'block_id';

  static const String fileName = 'file_name';

  static const String type = 'type';

  static const String localPath = 'local_path';

  static const String remotePath = 'remote_path';

  static const String mimeType = 'mime_type';

  static const String sizeBytes = 'size_bytes';

  static const String isDeleted = 'is_deleted';

  static const String createdAt = 'created_at';

  static const String updatedAt = 'updated_at';

  static const String syncStatus = 'sync_status';

  static const String deletedAt = 'deleted_at';

  // ============================================================
  // CREATE TABLE
  // ============================================================

  static const String createSql =
      '''
CREATE TABLE IF NOT EXISTS $tableName (
  $id TEXT PRIMARY KEY NOT NULL,
  $userId TEXT NOT NULL,
  $boardId TEXT NOT NULL,
  $blockId TEXT NOT NULL,
  $fileName TEXT NOT NULL,
  $type TEXT NOT NULL,
  $localPath TEXT NOT NULL,
  $remotePath TEXT,
  $mimeType TEXT,
  $sizeBytes INTEGER NOT NULL DEFAULT 0,
  $isDeleted INTEGER NOT NULL DEFAULT 0,
  $createdAt TEXT NOT NULL,
  $updatedAt TEXT NOT NULL,
  $syncStatus TEXT NOT NULL DEFAULT 'synced',
  $deletedAt TEXT
);
''';

  // ============================================================
  // INDEX - USER
  // ============================================================

  static const String createUserIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_local_board_attachments_user
ON $tableName (
  $userId
);
''';

  // ============================================================
  // INDEX - BOARD
  // ============================================================

  static const String createBoardIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_local_board_attachments_board
ON $tableName (
  $userId,
  $boardId
);
''';

  // ============================================================
  // INDEX - BLOCK
  // ============================================================

  static const String createBlockIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_local_board_attachments_block
ON $tableName (
  $userId,
  $boardId,
  $blockId
);
''';

  // ============================================================
  // INDEX - SYNC
  // ============================================================

  static const String createSyncIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_local_board_attachments_sync
ON $tableName (
  $userId,
  $syncStatus
);
''';

  // ============================================================
  // INDEX - DELETED
  // ============================================================

  static const String createDeletedIndexSql =
      '''
CREATE INDEX IF NOT EXISTS
idx_local_board_attachments_deleted
ON $tableName (
  $userId,
  $isDeleted,
  $deletedAt
);
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
        createSql,
        createUserIndexSql,
        createBoardIndexSql,
        createBlockIndexSql,
        createSyncIndexSql,
        createDeletedIndexSql,
      ];
}
