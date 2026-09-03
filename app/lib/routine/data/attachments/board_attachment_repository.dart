import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_status.dart';

import '../../models/attachments/board_attachment.dart';
import '../../services/attachments/board_attachment_service.dart';

import 'board_attachment_dao.dart';

// ============================================================
// BOARD ATTACHMENT REPOSITORY
// ============================================================
//
// Repository offline-first dos documentos anexados à lousa.
//
// Fluxo:
//
// UI
//   ↓
// BoardAttachmentController
//   ↓
// BoardAttachmentRepository
//   ↓
// BoardAttachmentService
//   ↓
// arquivo físico local
//
// e
//
// BoardAttachmentDao
//   ↓
// SQLite
//
// depois:
//
// SyncQueue
//   ↓
// SyncService
//   ↓
// Supabase / Storage
//
// O SQLite + arquivo local são a fonte de verdade imediata.
//
// ============================================================

class BoardAttachmentRepository {
  BoardAttachmentRepository({
    required SupabaseClient client,
    required BoardAttachmentDao localDao,
    required BoardAttachmentService service,
    required SyncQueue syncQueue,
    SyncService? syncService,
  }) : _client = client,
       _localDao = localDao,
       _service = service,
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // CONFIG
  // ============================================================

  static const String entityType = 'board_attachment';

  static const String remoteTable = 'board_attachments';

  static const String storageBucket = 'board-files';

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final BoardAttachmentDao _localDao;

  final BoardAttachmentService _service;

  final SyncQueue _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() {
    return _localDao.initialize();
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User _requireUser() {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return user;
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  loadAll() async {
    final user = _requireUser();

    return _localDao.getAll(
      userId: user.id,
    );
  }

  // ============================================================
  // LOAD BOARD
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  loadByBoardId(
    String boardId,
  ) async {
    final user = _requireUser();

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    return _localDao.getByBoardId(
      userId: user.id,
      boardId: normalizedBoardId,
    );
  }

  // ============================================================
  // LOAD BLOCK
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  loadByBlockId({
    required String boardId,
    required String blockId,
  }) async {
    final user = _requireUser();

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    final normalizedBlockId = _normalizeRequired(
      blockId,
      fieldName: 'blockId',
    );

    return _localDao.getByBlockId(
      userId: user.id,
      boardId: normalizedBoardId,
      blockId: normalizedBlockId,
    );
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    BoardAttachment?
  >
  getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final user = _requireUser();

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    return _localDao.getById(
      userId: user.id,
      id: normalizedId,
      includeDeleted: includeDeleted,
    );
  }

  // ============================================================
  // IMPORT
  // ============================================================
  //
  // Ordem:
  //
  // 1. copia o arquivo;
  // 2. cria BoardAttachment;
  // 3. salva no SQLite;
  // 4. adiciona na SyncQueue;
  // 5. solicita sync.
  //
  // Se o SQLite falhar depois da cópia, removemos o arquivo
  // físico para não deixar lixo local.
  //
  // ============================================================

  Future<
    BoardAttachment
  >
  importAttachment({
    required String boardId,
    required String blockId,
    required String sourcePath,
  }) async {
    final user = _requireUser();

    final attachment = await _service.importAttachment(
      boardId: boardId,
      blockId: blockId,
      sourcePath: sourcePath,
    );

    _assertOwner(
      attachment,
      user.id,
    );

    try {
      await _localDao.upsert(
        attachment,
        syncStatus: SyncStatus.pendingCreate,
      );
    } catch (
      _
    ) {
      try {
        await _service.deleteLocal(
          attachment,
        );
      } catch (
        _
      ) {
        // Ignora erro de limpeza.
      }

      rethrow;
    }

    await _enqueue(
      attachment: attachment,
      operation: SyncOperation.create,
    );

    return attachment;
  }

  // ============================================================
  // READ TEXT
  // ============================================================

  Future<
    String
  >
  readText(
    BoardAttachment attachment,
  ) async {
    final user = _requireUser();

    _assertOwner(
      attachment,
      user.id,
    );

    return _service.readText(
      attachment,
    );
  }

  // ============================================================
  // SAVE TEXT
  // ============================================================

  Future<
    BoardAttachment
  >
  saveText({
    required BoardAttachment attachment,
    required String content,
  }) async {
    final user = _requireUser();

    _assertOwner(
      attachment,
      user.id,
    );

    final updated = await _service.writeText(
      attachment: attachment,
      content: content,
    );

    await _localDao.upsert(
      updated,
      syncStatus: SyncStatus.pendingUpdate,
    );

    await _enqueue(
      attachment: updated,
      operation: SyncOperation.update,
    );

    return updated;
  }

  // ============================================================
  // SAVE METADATA
  // ============================================================

  Future<
    BoardAttachment
  >
  saveMetadata(
    BoardAttachment attachment,
  ) async {
    final user = _requireUser();

    _assertOwner(
      attachment,
      user.id,
    );

    final existing = await _localDao.getById(
      userId: user.id,
      id: attachment.id,
      includeDeleted: true,
    );

    final operation =
        existing ==
            null
        ? SyncOperation.create
        : SyncOperation.update;

    final status =
        existing ==
            null
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    final updated = attachment.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isDeleted: false,
    );

    await _localDao.upsert(
      updated,
      syncStatus: status,
    );

    await _enqueue(
      attachment: updated,
      operation: operation,
    );

    return updated;
  }

  // ============================================================
  // EXISTS LOCAL FILE
  // ============================================================

  Future<
    bool
  >
  localFileExists(
    BoardAttachment attachment,
  ) async {
    final user = _requireUser();

    _assertOwner(
      attachment,
      user.id,
    );

    return _service.exists(
      attachment,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================
  //
  // Soft delete no SQLite primeiro.
  //
  // O arquivo físico local é removido depois que a intenção de
  // exclusão já foi persistida.
  //
  // A SyncQueue recebe user_id/remote_path para a futura camada
  // de Supabase Storage conseguir remover o objeto remoto.
  //
  // ============================================================

  Future<
    void
  >
  delete(
    BoardAttachment attachment,
  ) async {
    final user = _requireUser();

    _assertOwner(
      attachment,
      user.id,
    );

    await _localDao.markDeleted(
      userId: user.id,
      id: attachment.id,
      syncStatus: SyncStatus.pendingDelete,
    );

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: attachment.id,
      operation: SyncOperation.delete,
      payload:
          <
            String,
            dynamic
          >{
            'id': attachment.id,
            'user_id': user.id,
            'board_id': attachment.boardId,
            'block_id': attachment.blockId,
            'file_name': attachment.fileName,
            'remote_path': attachment.remotePath,
            'storage_bucket': storageBucket,
          },
    );

    try {
      await _service.deleteLocal(
        attachment,
      );
    } catch (
      _
    ) {
      // O registro já está marcado para exclusão.
      //
      // Falha ao apagar o arquivo físico não deve desfazer
      // a intenção de exclusão persistida.
    }

    _syncService?.requestSync();
  }

  // ============================================================
  // DELETE BY ID
  // ============================================================

  Future<
    void
  >
  deleteById(
    String id,
  ) async {
    final attachment = await getById(
      id,
    );

    if (attachment ==
        null) {
      return;
    }

    await delete(
      attachment,
    );
  }

  // ============================================================
  // RESTORE
  // ============================================================
  //
  // Restaura somente os metadados locais.
  //
  // Se o arquivo físico já tiver sido apagado, o documento
  // precisará ser baixado novamente do Storage futuramente.
  //
  // ============================================================

  Future<
    BoardAttachment?
  >
  restore(
    String id,
  ) async {
    final user = _requireUser();

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    final attachment = await _localDao.getById(
      userId: user.id,
      id: normalizedId,
      includeDeleted: true,
    );

    if (attachment ==
        null) {
      return null;
    }

    await _localDao.restore(
      userId: user.id,
      id: attachment.id,
      syncStatus: SyncStatus.pendingUpdate,
    );

    final restored = attachment.copyWith(
      isDeleted: false,
      updatedAt: DateTime.now().toUtc(),
    );

    await _enqueue(
      attachment: restored,
      operation: SyncOperation.update,
    );

    return restored;
  }

  // ============================================================
  // MARK SYNCED
  // ============================================================
  //
  // Usado pelo futuro handler do SyncService depois que metadata
  // e arquivo forem confirmados no Supabase.
  //
  // ============================================================

  Future<
    void
  >
  markSynced({
    required String id,
    String? remotePath,
  }) async {
    final user = _requireUser();

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    if (remotePath !=
        null) {
      await _localDao.updateRemotePath(
        userId: user.id,
        id: normalizedId,
        remotePath: remotePath,
        syncStatus: SyncStatus.synced,
      );

      return;
    }

    await _localDao.setSyncStatus(
      userId: user.id,
      id: normalizedId,
      status: SyncStatus.synced,
    );
  }

  // ============================================================
  // DELETE PERMANENTLY
  // ============================================================
  //
  // Deve ser usado pelo handler remoto somente DEPOIS da
  // exclusão no Supabase/Storage ter sido confirmada.
  //
  // ============================================================

  Future<
    void
  >
  deletePermanently(
    String id,
  ) async {
    final user = _requireUser();

    final normalizedId = _normalizeRequired(
      id,
      fieldName: 'id',
    );

    await _localDao.deletePermanently(
      userId: user.id,
      id: normalizedId,
    );
  }

  // ============================================================
  // COUNT BOARD
  // ============================================================

  Future<
    int
  >
  countByBoard(
    String boardId,
  ) async {
    final user = _requireUser();

    final normalizedBoardId = _normalizeRequired(
      boardId,
      fieldName: 'boardId',
    );

    return _localDao.countByBoard(
      userId: user.id,
      boardId: normalizedBoardId,
    );
  }

  // ============================================================
  // QUEUE
  // ============================================================

  Future<
    void
  >
  _enqueue({
    required BoardAttachment attachment,
    required SyncOperation operation,
  }) async {
    final payload =
        <
          String,
          dynamic
        >{
          ...attachment.toRemoteMap(),

          // Este caminho NÃO deve ser salvo no Supabase.
          //
          // Ele existe apenas na fila local para que o futuro
          // handler consiga localizar o arquivo e fazer upload.
          'local_path': attachment.localPath,

          'storage_bucket': storageBucket,
        };

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: attachment.id,
      operation: operation,
      payload: payload,
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // OWNER
  // ============================================================

  void _assertOwner(
    BoardAttachment attachment,
    String currentUserId,
  ) {
    if (attachment.userId !=
        currentUserId) {
      throw StateError(
        'O anexo não pertence ao usuário autenticado.',
      );
    }
  }

  // ============================================================
  // NORMALIZE
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
