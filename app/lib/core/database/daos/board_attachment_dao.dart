import '../../../routine/models/attachments/board_attachment.dart';
import '../../../routine/models/attachments/board_attachment_type.dart';
import '../../sync/sync_status.dart';
import '../app_database.dart';
import '../tables/board_attachment_table.dart';

class BoardAttachmentDao {
  BoardAttachmentDao({
    AppDatabase? database,
  }) : _database =
           database ??
           AppDatabase.instance;

  // ============================================================
  // DATABASE
  // ============================================================

  final AppDatabase _database;

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() {
    return _ensureInitialized();
  }

  Future<
    void
  >
  _ensureInitialized() async {
    if (_initialized) {
      return;
    }

    await _database.initialize();

    for (final statement in BoardAttachmentTable.createStatements) {
      _database.db.execute(
        statement,
      );
    }

    _initialized = true;
  }

  // ============================================================
  // UPSERT
  // ============================================================

  Future<
    void
  >
  upsert(
    BoardAttachment attachment, {
    SyncStatus syncStatus = SyncStatus.synced,
    DateTime? deletedAt,
  }) async {
    await _ensureInitialized();

    final normalized = _normalizeAttachment(
      attachment,
    );

    _database.db.execute(
      '''
INSERT INTO ${BoardAttachmentTable.tableName} (
  ${BoardAttachmentTable.id},
  ${BoardAttachmentTable.userId},
  ${BoardAttachmentTable.boardId},
  ${BoardAttachmentTable.blockId},
  ${BoardAttachmentTable.fileName},
  ${BoardAttachmentTable.type},
  ${BoardAttachmentTable.localPath},
  ${BoardAttachmentTable.remotePath},
  ${BoardAttachmentTable.mimeType},
  ${BoardAttachmentTable.sizeBytes},
  ${BoardAttachmentTable.isDeleted},
  ${BoardAttachmentTable.createdAt},
  ${BoardAttachmentTable.updatedAt},
  ${BoardAttachmentTable.syncStatus},
  ${BoardAttachmentTable.deletedAt}
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(${BoardAttachmentTable.id})
DO UPDATE SET
  ${BoardAttachmentTable.userId}
    = excluded.${BoardAttachmentTable.userId},
  ${BoardAttachmentTable.boardId}
    = excluded.${BoardAttachmentTable.boardId},
  ${BoardAttachmentTable.blockId}
    = excluded.${BoardAttachmentTable.blockId},
  ${BoardAttachmentTable.fileName}
    = excluded.${BoardAttachmentTable.fileName},
  ${BoardAttachmentTable.type}
    = excluded.${BoardAttachmentTable.type},
  ${BoardAttachmentTable.localPath}
    = excluded.${BoardAttachmentTable.localPath},
  ${BoardAttachmentTable.remotePath}
    = excluded.${BoardAttachmentTable.remotePath},
  ${BoardAttachmentTable.mimeType}
    = excluded.${BoardAttachmentTable.mimeType},
  ${BoardAttachmentTable.sizeBytes}
    = excluded.${BoardAttachmentTable.sizeBytes},
  ${BoardAttachmentTable.isDeleted}
    = excluded.${BoardAttachmentTable.isDeleted},
  ${BoardAttachmentTable.updatedAt}
    = excluded.${BoardAttachmentTable.updatedAt},
  ${BoardAttachmentTable.syncStatus}
    = excluded.${BoardAttachmentTable.syncStatus},
  ${BoardAttachmentTable.deletedAt}
    = excluded.${BoardAttachmentTable.deletedAt}
''',
      <
        Object?
      >[
        normalized.id,
        normalized.userId,
        normalized.boardId,
        normalized.blockId,
        normalized.fileName,
        normalized.type.name,
        normalized.localPath,
        normalized.remotePath,
        normalized.mimeType ??
            normalized.type.mimeType,
        normalized.sizeBytes,
        normalized.isDeleted
            ? 1
            : 0,
        normalized.createdAt.toUtc().toIso8601String(),
        normalized.updatedAt.toUtc().toIso8601String(),
        syncStatus.value,
        deletedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    BoardAttachment?
  >
  getById({
    required String userId,
    required String id,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    final rows = _database.db.select(
      '''
SELECT *
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
  ${includeDeleted ? '' : 'AND ${BoardAttachmentTable.isDeleted} = 0'}
LIMIT 1
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedId,
      ],
    );

    if (rows.isEmpty) {
      return null;
    }

    return _mapAttachment(
      Map<
        String,
        Object?
      >.from(
        rows.first,
      ),
    );
  }

  // ============================================================
  // GET BY BOARD
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  getByBoardId({
    required String userId,
    required String boardId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    final rows = _database.db.select(
      '''
SELECT *
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.boardId} = ?
  ${includeDeleted ? '' : 'AND ${BoardAttachmentTable.isDeleted} = 0'}
ORDER BY ${BoardAttachmentTable.createdAt} DESC
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedBoardId,
      ],
    );

    return rows
        .map(
          (
            row,
          ) => _mapAttachment(
            Map<
              String,
              Object?
            >.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET BY BLOCK
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  getByBlockId({
    required String userId,
    required String boardId,
    required String blockId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    final normalizedBlockId = _normalizeRequired(
      blockId,
      fieldName: 'blockId',
    );

    final rows = _database.db.select(
      '''
SELECT *
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.boardId} = ?
  AND ${BoardAttachmentTable.blockId} = ?
  ${includeDeleted ? '' : 'AND ${BoardAttachmentTable.isDeleted} = 0'}
ORDER BY ${BoardAttachmentTable.createdAt} DESC
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedBoardId,
        normalizedBlockId,
      ],
    );

    return rows
        .map(
          (
            row,
          ) => _mapAttachment(
            Map<
              String,
              Object?
            >.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET ALL
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  getAll({
    required String userId,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final rows = _database.db.select(
      '''
SELECT *
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  ${includeDeleted ? '' : 'AND ${BoardAttachmentTable.isDeleted} = 0'}
ORDER BY ${BoardAttachmentTable.createdAt} DESC
''',
      <
        Object?
      >[
        normalizedUserId,
      ],
    );

    return rows
        .map(
          (
            row,
          ) => _mapAttachment(
            Map<
              String,
              Object?
            >.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET UNSYNCED
  // ============================================================

  Future<
    List<
      Map<
        String,
        Object?
      >
    >
  >
  getUnsynced({
    required String userId,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final rows = _database.db.select(
      '''
SELECT *
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.syncStatus} != ?
ORDER BY ${BoardAttachmentTable.updatedAt} ASC
''',
      <
        Object?
      >[
        normalizedUserId,
        SyncStatus.synced.value,
      ],
    );

    return rows
        .map(
          (
            row,
          ) =>
              Map<
                String,
                Object?
              >.from(
                row,
              ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // SET SYNC STATUS
  // ============================================================

  Future<
    void
  >
  setSyncStatus({
    required String userId,
    required String id,
    required SyncStatus status,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    _database.db.execute(
      '''
UPDATE ${BoardAttachmentTable.tableName}
SET
  ${BoardAttachmentTable.syncStatus} = ?,
  ${BoardAttachmentTable.updatedAt} = ?
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
''',
      <
        Object?
      >[
        status.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedId,
      ],
    );
  }

  // ============================================================
  // UPDATE REMOTE PATH
  // ============================================================

  Future<
    void
  >
  updateRemotePath({
    required String userId,
    required String id,
    required String? remotePath,
    SyncStatus syncStatus = SyncStatus.synced,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    final normalizedRemotePath =
        remotePath?.trim().isNotEmpty ==
            true
        ? remotePath!.trim()
        : null;

    _database.db.execute(
      '''
UPDATE ${BoardAttachmentTable.tableName}
SET
  ${BoardAttachmentTable.remotePath} = ?,
  ${BoardAttachmentTable.syncStatus} = ?,
  ${BoardAttachmentTable.updatedAt} = ?
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
''',
      <
        Object?
      >[
        normalizedRemotePath,
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedId,
      ],
    );
  }

  // ============================================================
  // MARK DELETED
  // ============================================================

  Future<
    void
  >
  markDeleted({
    required String userId,
    required String id,
    SyncStatus syncStatus = SyncStatus.pendingDelete,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
UPDATE ${BoardAttachmentTable.tableName}
SET
  ${BoardAttachmentTable.isDeleted} = 1,
  ${BoardAttachmentTable.deletedAt} = ?,
  ${BoardAttachmentTable.syncStatus} = ?,
  ${BoardAttachmentTable.updatedAt} = ?
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
''',
      <
        Object?
      >[
        now,
        syncStatus.value,
        now,
        normalizedUserId,
        normalizedId,
      ],
    );
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<
    void
  >
  restore({
    required String userId,
    required String id,
    SyncStatus syncStatus = SyncStatus.pendingUpdate,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    _database.db.execute(
      '''
UPDATE ${BoardAttachmentTable.tableName}
SET
  ${BoardAttachmentTable.isDeleted} = 0,
  ${BoardAttachmentTable.deletedAt} = NULL,
  ${BoardAttachmentTable.syncStatus} = ?,
  ${BoardAttachmentTable.updatedAt} = ?
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
''',
      <
        Object?
      >[
        syncStatus.value,
        DateTime.now().toUtc().toIso8601String(),
        normalizedUserId,
        normalizedId,
      ],
    );
  }

  // ============================================================
  // DELETE PERMANENTLY
  // ============================================================

  Future<
    void
  >
  deletePermanently({
    required String userId,
    required String id,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    _database.db.execute(
      '''
DELETE FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.id} = ?
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedId,
      ],
    );
  }

  // ============================================================
  // DELETE BOARD PERMANENTLY
  // ============================================================

  Future<
    void
  >
  deleteBoardPermanently({
    required String userId,
    required String boardId,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    _database.db.execute(
      '''
DELETE FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.boardId} = ?
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedBoardId,
      ],
    );
  }

  // ============================================================
  // COUNT BY BOARD
  // ============================================================

  Future<
    int
  >
  countByBoard({
    required String userId,
    required String boardId,
  }) async {
    await _ensureInitialized();

    final normalizedUserId = _normalizeRequired(
      userId,
      fieldName: 'userId',
    );

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    final rows = _database.db.select(
      '''
SELECT COUNT(*) AS total
FROM ${BoardAttachmentTable.tableName}
WHERE
  ${BoardAttachmentTable.userId} = ?
  AND ${BoardAttachmentTable.boardId} = ?
  AND ${BoardAttachmentTable.isDeleted} = 0
''',
      <
        Object?
      >[
        normalizedUserId,
        normalizedBoardId,
      ],
    );

    if (rows.isEmpty) {
      return 0;
    }

    final raw = rows.first['total'];

    if (raw
        is int) {
      return raw;
    }

    return int.tryParse(
          raw?.toString() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // MAP ATTACHMENT
  // ============================================================

  BoardAttachment _mapAttachment(
    Map<
      String,
      Object?
    >
    row,
  ) {
    return BoardAttachment.fromMap(
      <
        String,
        dynamic
      >{
        BoardAttachmentTable.id: row[BoardAttachmentTable.id],
        BoardAttachmentTable.userId: row[BoardAttachmentTable.userId],
        BoardAttachmentTable.boardId: row[BoardAttachmentTable.boardId],
        BoardAttachmentTable.blockId: row[BoardAttachmentTable.blockId],
        BoardAttachmentTable.fileName: row[BoardAttachmentTable.fileName],
        BoardAttachmentTable.type: row[BoardAttachmentTable.type],
        BoardAttachmentTable.localPath: row[BoardAttachmentTable.localPath],
        BoardAttachmentTable.remotePath: row[BoardAttachmentTable.remotePath],
        BoardAttachmentTable.mimeType: row[BoardAttachmentTable.mimeType],
        BoardAttachmentTable.sizeBytes: row[BoardAttachmentTable.sizeBytes],
        BoardAttachmentTable.isDeleted: row[BoardAttachmentTable.isDeleted],
        BoardAttachmentTable.createdAt: row[BoardAttachmentTable.createdAt],
        BoardAttachmentTable.updatedAt: row[BoardAttachmentTable.updatedAt],
      },
    );
  }

  // ============================================================
  // NORMALIZE ATTACHMENT
  // ============================================================

  BoardAttachment _normalizeAttachment(
    BoardAttachment attachment,
  ) {
    final id = _normalizeRequired(
      attachment.id,
      fieldName: 'attachment.id',
    );

    final userId = _normalizeRequired(
      attachment.userId,
      fieldName: 'attachment.userId',
    );

    final boardId = _normalizeRequired(
      attachment.boardId,
      fieldName: 'attachment.boardId',
    );

    final blockId = _normalizeRequired(
      attachment.blockId,
      fieldName: 'attachment.blockId',
    );

    final fileName = _normalizeRequired(
      attachment.fileName,
      fieldName: 'attachment.fileName',
    );

    final localPath = _normalizeRequired(
      attachment.localPath,
      fieldName: 'attachment.localPath',
    );

    final remotePath =
        attachment.remotePath?.trim().isNotEmpty ==
            true
        ? attachment.remotePath!.trim()
        : null;

    final mimeType =
        attachment.mimeType?.trim().isNotEmpty ==
            true
        ? attachment.mimeType!.trim()
        : attachment.type.mimeType;

    final sizeBytes =
        attachment.sizeBytes <
            0
        ? 0
        : attachment.sizeBytes;

    return attachment.copyWith(
      id: id,
      userId: userId,
      boardId: boardId,
      blockId: blockId,
      fileName: fileName,
      localPath: localPath,
      remotePath: remotePath,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: attachment.createdAt.toUtc(),
      updatedAt: attachment.updatedAt.toUtc(),
    );
  }

  // ============================================================
  // NORMALIZE REQUIRED
  // ============================================================

  String _normalizeRequired(
    String value, {
    required String fieldName,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName não pode estar vazio.',
      );
    }

    return normalized;
  }
}
