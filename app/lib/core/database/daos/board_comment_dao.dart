import '../../../routine/models/comments/board_comment.dart';
import '../../sync/sync_status.dart';
import '../app_database.dart';
import '../tables/board_comment_table.dart';

class BoardCommentDao {
  BoardCommentDao({
    AppDatabase? database,
  }) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;
  bool _initialized = false;

  Future<void> initialize() => _ensureInitialized();

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _database.initialize();
    for (final statement in BoardCommentTable.createStatements) {
      _database.db.execute(statement);
    }
    _initialized = true;
  }

  Future<void> upsert(
    BoardComment comment, {
    required String userId,
    SyncStatus syncStatus = SyncStatus.synced,
    DateTime? deletedAt,
  }) async {
    await _ensureInitialized();
    final uid = _required(userId, 'userId');
    final id = _required(comment.id, 'comment.id');
    final dayId = _required(comment.dayId, 'comment.dayId');
    final now = DateTime.now().toUtc().toIso8601String();

    _database.db.execute(
      '''
INSERT INTO ${BoardCommentTable.tableName} (
  ${BoardCommentTable.id}, ${BoardCommentTable.userId},
  ${BoardCommentTable.dayId}, ${BoardCommentTable.message},
  ${BoardCommentTable.positionX}, ${BoardCommentTable.positionY},
  ${BoardCommentTable.authorName}, ${BoardCommentTable.resolved},
  ${BoardCommentTable.createdAt}, ${BoardCommentTable.updatedAt},
  ${BoardCommentTable.syncStatus}, ${BoardCommentTable.deletedAt}
)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
ON CONFLICT(${BoardCommentTable.id}) DO UPDATE SET
  ${BoardCommentTable.userId} = excluded.${BoardCommentTable.userId},
  ${BoardCommentTable.dayId} = excluded.${BoardCommentTable.dayId},
  ${BoardCommentTable.message} = excluded.${BoardCommentTable.message},
  ${BoardCommentTable.positionX} = excluded.${BoardCommentTable.positionX},
  ${BoardCommentTable.positionY} = excluded.${BoardCommentTable.positionY},
  ${BoardCommentTable.authorName} = excluded.${BoardCommentTable.authorName},
  ${BoardCommentTable.resolved} = excluded.${BoardCommentTable.resolved},
  ${BoardCommentTable.updatedAt} = excluded.${BoardCommentTable.updatedAt},
  ${BoardCommentTable.syncStatus} = excluded.${BoardCommentTable.syncStatus},
  ${BoardCommentTable.deletedAt} = excluded.${BoardCommentTable.deletedAt}
''',
      <Object?>[
        id,
        uid,
        dayId,
        comment.message,
        comment.position.dx,
        comment.position.dy,
        comment.authorName.trim().isEmpty ? 'Você' : comment.authorName.trim(),
        comment.resolved ? 1 : 0,
        comment.createdAt.toUtc().toIso8601String(),
        now,
        syncStatus.value,
        deletedAt?.toUtc().toIso8601String(),
      ],
    );
  }

  Future<BoardComment?> getById({
    required String userId,
    required String id,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();
    final rows = _database.db.select(
      '''
SELECT * FROM ${BoardCommentTable.tableName}
WHERE ${BoardCommentTable.userId} = ?
  AND ${BoardCommentTable.id} = ?
  ${includeDeleted ? '' : 'AND ${BoardCommentTable.deletedAt} IS NULL'}
LIMIT 1
''',
      <Object?>[_required(userId, 'userId'), _required(id, 'id')],
    );
    return rows.isEmpty ? null : _mapComment(rows.first);
  }

  Future<List<BoardComment>> getByDay({
    required String userId,
    required String dayId,
    bool includeResolved = false,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();
    final rows = _database.db.select(
      '''
SELECT * FROM ${BoardCommentTable.tableName}
WHERE ${BoardCommentTable.userId} = ?
  AND ${BoardCommentTable.dayId} = ?
  ${includeResolved ? '' : 'AND ${BoardCommentTable.resolved} = 0'}
  ${includeDeleted ? '' : 'AND ${BoardCommentTable.deletedAt} IS NULL'}
ORDER BY ${BoardCommentTable.createdAt} ASC
''',
      <Object?>[_required(userId, 'userId'), _required(dayId, 'dayId')],
    );
    return rows.map(_mapComment).toList(growable: false);
  }

  Future<List<BoardComment>> getAll({
    required String userId,
    bool includeResolved = false,
    bool includeDeleted = false,
  }) async {
    await _ensureInitialized();
    final rows = _database.db.select(
      '''
SELECT * FROM ${BoardCommentTable.tableName}
WHERE ${BoardCommentTable.userId} = ?
  ${includeResolved ? '' : 'AND ${BoardCommentTable.resolved} = 0'}
  ${includeDeleted ? '' : 'AND ${BoardCommentTable.deletedAt} IS NULL'}
ORDER BY ${BoardCommentTable.createdAt} ASC
''',
      <Object?>[_required(userId, 'userId')],
    );
    return rows.map(_mapComment).toList(growable: false);
  }

  Future<SyncStatus?> getSyncStatus({
    required String userId,
    required String id,
  }) async {
    await _ensureInitialized();
    final rows = _database.db.select(
      '''
SELECT ${BoardCommentTable.syncStatus}
FROM ${BoardCommentTable.tableName}
WHERE ${BoardCommentTable.userId} = ? AND ${BoardCommentTable.id} = ?
LIMIT 1
''',
      <Object?>[_required(userId, 'userId'), _required(id, 'id')],
    );
    if (rows.isEmpty) return null;
    return SyncStatus.fromValue(rows.first[BoardCommentTable.syncStatus]?.toString());
  }

  Future<void> setSyncStatus(String id, SyncStatus status) async {
    await _ensureInitialized();
    _database.db.execute(
      '''
UPDATE ${BoardCommentTable.tableName}
SET ${BoardCommentTable.syncStatus} = ?, ${BoardCommentTable.updatedAt} = ?
WHERE ${BoardCommentTable.id} = ?
''',
      <Object?>[
        status.value,
        DateTime.now().toUtc().toIso8601String(),
        _required(id, 'id'),
      ],
    );
  }

  Future<void> markDeleted({
    required String userId,
    required String id,
    SyncStatus syncStatus = SyncStatus.pendingDelete,
  }) async {
    await _ensureInitialized();
    final now = DateTime.now().toUtc().toIso8601String();
    _database.db.execute(
      '''
UPDATE ${BoardCommentTable.tableName}
SET ${BoardCommentTable.deletedAt} = ?,
    ${BoardCommentTable.syncStatus} = ?,
    ${BoardCommentTable.updatedAt} = ?
WHERE ${BoardCommentTable.userId} = ? AND ${BoardCommentTable.id} = ?
''',
      <Object?>[now, syncStatus.value, now, _required(userId, 'userId'), _required(id, 'id')],
    );
  }

  Future<void> deletePermanently(String id) async {
    await _ensureInitialized();
    _database.db.execute(
      'DELETE FROM ${BoardCommentTable.tableName} WHERE ${BoardCommentTable.id} = ?',
      <Object?>[_required(id, 'id')],
    );
  }

  Future<bool> isDayInitialized({required String userId, required String dayId}) =>
      _isScopeInitialized(userId: userId, scopeKey: _dayScope(dayId));

  Future<void> markDayInitialized({required String userId, required String dayId}) =>
      _markScopeInitialized(userId: userId, scopeKey: _dayScope(dayId));

  Future<bool> isAllInitialized({required String userId}) =>
      _isScopeInitialized(userId: userId, scopeKey: 'all');

  Future<void> markAllInitialized({required String userId}) =>
      _markScopeInitialized(userId: userId, scopeKey: 'all');

  Future<bool> _isScopeInitialized({
    required String userId,
    required String scopeKey,
  }) async {
    await _ensureInitialized();
    final rows = _database.db.select(
      '''
SELECT 1 FROM ${BoardCommentTable.scopeTableName}
WHERE ${BoardCommentTable.userId} = ? AND ${BoardCommentTable.scopeKey} = ?
LIMIT 1
''',
      <Object?>[_required(userId, 'userId'), _required(scopeKey, 'scopeKey')],
    );
    return rows.isNotEmpty;
  }

  Future<void> _markScopeInitialized({
    required String userId,
    required String scopeKey,
  }) async {
    await _ensureInitialized();
    _database.db.execute(
      '''
INSERT INTO ${BoardCommentTable.scopeTableName} (
  ${BoardCommentTable.userId}, ${BoardCommentTable.scopeKey}, ${BoardCommentTable.initializedAt}
)
VALUES (?, ?, ?)
ON CONFLICT(${BoardCommentTable.userId}, ${BoardCommentTable.scopeKey}) DO UPDATE SET
  ${BoardCommentTable.initializedAt} = excluded.${BoardCommentTable.initializedAt}
''',
      <Object?>[
        _required(userId, 'userId'),
        _required(scopeKey, 'scopeKey'),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  String _dayScope(String dayId) => 'day:${_required(dayId, 'dayId')}';

  BoardComment _mapComment(Map<String, Object?> row) {
    return BoardComment.fromMap(<String, dynamic>{
      'id': row[BoardCommentTable.id],
      'day_id': row[BoardCommentTable.dayId],
      'message': row[BoardCommentTable.message],
      'position_x': row[BoardCommentTable.positionX],
      'position_y': row[BoardCommentTable.positionY],
      'created_at': row[BoardCommentTable.createdAt],
      'author_name': row[BoardCommentTable.authorName],
      'resolved': row[BoardCommentTable.resolved],
    });
  }

  String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field, '$field não pode estar vazio.');
    }
    return normalized;
  }
}
