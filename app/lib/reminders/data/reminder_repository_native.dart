import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/daos/reminder_dao.dart';
import '../../core/sync/sync_item.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_status.dart';

import '../models/reminder_model.dart';

// ============================================================
// REMINDER REPOSITORY
// ============================================================
//
// Estratégia OFFLINE-FIRST:
//
// CREATE / UPDATE
//   1. salva primeiro no SQLite;
//   2. adiciona a alteração à SyncQueue;
//   3. devolve o resultado imediatamente para a interface;
//   4. SyncService envia ao Supabase quando houver conexão.
//
// DELETE
//   1. marca o registro local como removido;
//   2. registra DELETE na SyncQueue;
//   3. remove definitivamente do SQLite somente após o
//      Supabase confirmar a exclusão.
//
// LOAD
//   1. carrega SQLite primeiro;
//   2. se houver alteração pendente, o local vence;
//   3. se não houver pendência, tenta atualizar pelo Supabase;
//   4. se estiver offline, continua usando o SQLite.
//
// ============================================================

class ReminderRepository {
  ReminderRepository({
    SupabaseClient? client,
    ReminderDao? localDao,
    SyncQueue? syncQueue,
    SyncService? syncService,
  }) : _client =
           client ??
           Supabase.instance.client,
       _localDao =
           localDao ??
           ReminderDao(),
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final ReminderDao _localDao;

  final SyncQueue? _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // TABLE / ENTITY
  // ============================================================

  static const String _table = 'reminders';

  static const String _entityType = 'reminder';

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
  // GET ALL
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getAll() async {
    final user = _requireUser();

    // ----------------------------------------------------------
    // LOCAL FIRST
    // ----------------------------------------------------------

    final local = await _localDao.getAllForUser(
      user.id,
    );

    // ----------------------------------------------------------
    // PENDING LOCAL
    // ----------------------------------------------------------
    //
    // Se existe qualquer alteração de lembrete na fila,
    // não permitimos que um snapshot remoto antigo a
    // sobrescreva.
    //
    // ----------------------------------------------------------

    if (await _hasPendingReminderSync()) {
      _log(
        'GET ALL',
        'Existem alterações locais pendentes. '
            'Usando SQLite.',
      );

      _syncService?.requestSync();

      return local;
    }

    // ----------------------------------------------------------
    // REMOTE REFRESH
    // ----------------------------------------------------------

    try {
      final response = await _client
          .from(
            _table,
          )
          .select()
          .eq(
            'user_id',
            user.id,
          )
          .order(
            'remind_at',
            ascending: true,
          );

      final remote =
          (response
                  as List)
              .map(
                (
                  item,
                ) => ReminderModel.fromJson(
                  Map<
                    String,
                    dynamic
                  >.from(
                    item
                        as Map,
                  ),
                ),
              )
              .toList(
                growable: false,
              );

      await _replaceLocalSnapshot(
        userId: user.id,
        remote: remote,
      );

      return remote;
    } on PostgrestException catch (
      error
    ) {
      _log(
        'GET ALL',
        'Supabase indisponível. '
            'Usando SQLite. ${error.message}',
      );

      return local;
    } catch (
      error
    ) {
      _log(
        'GET ALL',
        'Falha remota. Usando SQLite. $error',
      );

      return local;
    }
  }

  // ============================================================
  // GET PENDING
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getPending() async {
    final all = await getAll();

    final result = all
        .where(
          (
            reminder,
          ) => !reminder.completed,
        )
        .toList(
          growable: false,
        );

    result.sort(
      (
        first,
        second,
      ) => first.remindAt.compareTo(
        second.remindAt,
      ),
    );

    return result;
  }

  // ============================================================
  // GET DUE
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getDue() async {
    final user = _requireUser();

    // Para notificações dentro do app priorizamos diretamente
    // o SQLite. Isso permite disparar lembretes mesmo quando o
    // computador está sem internet.
    final local = await _localDao.getDueForUser(
      user.id,
    );

    local.sort(
      (
        first,
        second,
      ) => first.remindAt.compareTo(
        second.remindAt,
      ),
    );

    return local;
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    ReminderModel?
  >
  getById(
    String id,
  ) async {
    final user = _requireUser();

    final normalizedId = _validateId(
      id,
    );

    // ----------------------------------------------------------
    // LOCAL FIRST
    // ----------------------------------------------------------

    final local = await _localDao.getById(
      normalizedId,
    );

    final pending = await _syncQueue?.findByEntity(
      entityType: _entityType,
      entityId: normalizedId,
    );

    if (pending !=
        null) {
      return local;
    }

    // ----------------------------------------------------------
    // REMOTE REFRESH
    // ----------------------------------------------------------

    try {
      final response = await _client
          .from(
            _table,
          )
          .select()
          .eq(
            'id',
            normalizedId,
          )
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (response ==
          null) {
        return local;
      }

      final remote = ReminderModel.fromJson(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      await _localDao.upsert(
        remote,
        syncStatus: SyncStatus.synced,
      );

      return remote;
    } catch (
      error
    ) {
      _log(
        'GET BY ID',
        'Falha remota. Retornando local. $error',
      );

      return local;
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<
    ReminderModel
  >
  create({
    required String title,
    required String message,
    required DateTime remindAt,
    String? sourceType,
    String? sourceId,
    bool notifyInApp = true,
    bool notifyTelegram = false,
  }) async {
    final user = _requireUser();

    final normalizedTitle = title.trim();

    final normalizedMessage = message.trim();

    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(
        title,
        'title',
        'O título do lembrete não pode estar vazio.',
      );
    }

    if (normalizedMessage.isEmpty) {
      throw ArgumentError.value(
        message,
        'message',
        'A mensagem do lembrete não pode estar vazia.',
      );
    }

    final now = DateTime.now().toUtc();

    final reminder = ReminderModel(
      id: _uuidV4(),
      userId: user.id,
      title: normalizedTitle,
      message: normalizedMessage,
      remindAt: remindAt.toUtc(),
      sourceType: _nullIfEmpty(
        sourceType,
      ),
      sourceId: _nullIfEmpty(
        sourceId,
      ),
      notifyInApp: notifyInApp,
      notifyTelegram: notifyTelegram,
      sentInApp: false,
      sentTelegram: false,
      completed: false,
      createdAt: now,
      updatedAt: now,
    );

    // ----------------------------------------------------------
    // LOCAL FIRST
    // ----------------------------------------------------------

    await _localDao.upsert(
      reminder,
      syncStatus: SyncStatus.pendingCreate,
    );

    // ----------------------------------------------------------
    // QUEUE
    // ----------------------------------------------------------

    await _enqueue(
      reminder: reminder,
      operation: SyncOperation.create,
    );

    _log(
      'CREATE',
      'Lembrete ${reminder.id} salvo localmente.',
    );

    return reminder;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<
    ReminderModel
  >
  update(
    ReminderModel reminder,
  ) async {
    final user = _requireUser();

    if (reminder.userId !=
        user.id) {
      throw StateError(
        'O lembrete não pertence ao usuário autenticado.',
      );
    }

    final updated = _copyReminder(
      reminder,
      title: reminder.title.trim(),
      message: reminder.message.trim(),
      remindAt: reminder.remindAt.toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );

    final currentStatus = await _localDao.getSyncStatus(
      reminder.id,
    );

    final nextStatus =
        currentStatus ==
            SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    // ----------------------------------------------------------
    // LOCAL FIRST
    // ----------------------------------------------------------

    await _localDao.upsert(
      updated,
      syncStatus: nextStatus,
    );

    // ----------------------------------------------------------
    // QUEUE
    // ----------------------------------------------------------

    await _enqueue(
      reminder: updated,
      operation: SyncOperation.update,
    );

    return updated;
  }

  // ============================================================
  // MARK IN APP AS SENT
  // ============================================================

  Future<
    void
  >
  markInAppAsSent(
    String id,
  ) async {
    await _patch(
      id: id,
      transform:
          (
            reminder,
          ) => _copyReminder(
            reminder,
            sentInApp: true,
            updatedAt: DateTime.now().toUtc(),
          ),
    );
  }

  // ============================================================
  // MARK TELEGRAM AS SENT
  // ============================================================

  Future<
    void
  >
  markTelegramAsSent(
    String id,
  ) async {
    await _patch(
      id: id,
      transform:
          (
            reminder,
          ) => _copyReminder(
            reminder,
            sentTelegram: true,
            updatedAt: DateTime.now().toUtc(),
          ),
    );
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<
    void
  >
  complete(
    String id,
  ) async {
    await _patch(
      id: id,
      transform:
          (
            reminder,
          ) => _copyReminder(
            reminder,
            completed: true,
            updatedAt: DateTime.now().toUtc(),
          ),
    );
  }

  // ============================================================
  // REOPEN
  // ============================================================

  Future<
    void
  >
  reopen(
    String id,
  ) async {
    await _patch(
      id: id,
      transform:
          (
            reminder,
          ) => _copyReminder(
            reminder,
            completed: false,
            sentInApp: false,
            sentTelegram: false,
            updatedAt: DateTime.now().toUtc(),
          ),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  delete(
    String id,
  ) async {
    _requireUser();

    final normalizedId = _validateId(
      id,
    );

    final local = await _localDao.getById(
      normalizedId,
    );

    final queue = _syncQueue;

    final existingQueueItem = await queue?.findByEntity(
      entityType: _entityType,
      entityId: normalizedId,
    );

    final localStatus = await _localDao.getSyncStatus(
      normalizedId,
    );

    // ----------------------------------------------------------
    // CREATE + DELETE BEFORE FIRST SYNC
    // ----------------------------------------------------------
    //
    // O servidor nunca recebeu esse registro.
    // Não há motivo para manter tombstone.
    //
    // SyncQueue também reduz create -> delete para nenhuma
    // operação.
    //
    // ----------------------------------------------------------

    final neverSynced =
        localStatus ==
            SyncStatus.pendingCreate ||
        existingQueueItem?.operation ==
            SyncOperation.create;

    if (neverSynced) {
      if (queue !=
          null) {
        await queue.enqueue(
          entityType: _entityType,
          entityId: normalizedId,
          operation: SyncOperation.delete,
        );
      }

      await _localDao.deletePermanently(
        normalizedId,
      );

      _syncService?.requestSync();

      return;
    }

    // ----------------------------------------------------------
    // NORMAL DELETE
    // ----------------------------------------------------------

    if (local !=
        null) {
      await _localDao.markDeleted(
        normalizedId,
        syncStatus: SyncStatus.pendingDelete,
      );
    }

    if (queue !=
        null) {
      await queue.enqueue(
        entityType: _entityType,
        entityId: normalizedId,
        operation: SyncOperation.delete,
        payload: {
          'id': normalizedId,
          'user_id':
              local?.userId ??
              _client.auth.currentUser?.id,
        },
      );

      _syncService?.requestSync();

      return;
    }

    // ----------------------------------------------------------
    // COMPATIBILITY FALLBACK
    // ----------------------------------------------------------
    //
    // Se SyncQueue ainda não foi injetada, tentamos o Supabase
    // diretamente.
    //
    // ----------------------------------------------------------

    await _deleteRemoteDirect(
      normalizedId,
    );

    await _localDao.deletePermanently(
      normalizedId,
    );
  }

  // ============================================================
  // PATCH
  // ============================================================

  Future<
    void
  >
  _patch({
    required String id,
    required ReminderModel Function(
      ReminderModel reminder,
    )
    transform,
  }) async {
    final normalizedId = _validateId(
      id,
    );

    var current = await _localDao.getById(
      normalizedId,
    );

    current ??= await _loadRemoteByIdDirect(
      normalizedId,
    );

    if (current ==
        null) {
      throw StateError(
        'Lembrete não encontrado: $normalizedId',
      );
    }

    final updated = transform(
      current,
    );

    final currentStatus = await _localDao.getSyncStatus(
      normalizedId,
    );

    final nextStatus =
        currentStatus ==
            SyncStatus.pendingCreate
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    await _localDao.upsert(
      updated,
      syncStatus: nextStatus,
    );

    await _enqueue(
      reminder: updated,
      operation: SyncOperation.update,
    );
  }

  // ============================================================
  // ENQUEUE
  // ============================================================

  Future<
    void
  >
  _enqueue({
    required ReminderModel reminder,
    required SyncOperation operation,
  }) async {
    final queue = _syncQueue;

    if (queue !=
        null) {
      await queue.enqueue(
        entityType: _entityType,
        entityId: reminder.id,
        operation: operation,
        payload: _toRemotePayload(
          reminder,
        ),
      );

      _syncService?.requestSync();

      return;
    }

    // ----------------------------------------------------------
    // COMPATIBILITY FALLBACK
    // ----------------------------------------------------------

    try {
      await _upsertRemoteDirect(
        reminder,
      );

      await _localDao.setSyncStatus(
        reminder.id,
        SyncStatus.synced,
      );
    } catch (
      error
    ) {
      _log(
        'DIRECT REMOTE',
        'Falha; dado continua salvo localmente. $error',
      );
    }
  }

  // ============================================================
  // REMOTE UPSERT DIRECT
  // ============================================================

  Future<
    void
  >
  _upsertRemoteDirect(
    ReminderModel reminder,
  ) async {
    await _client
        .from(
          _table,
        )
        .upsert(
          _toRemotePayload(
            reminder,
          ),
          onConflict: 'id',
        );
  }

  // ============================================================
  // REMOTE DELETE DIRECT
  // ============================================================

  Future<
    void
  >
  _deleteRemoteDirect(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // ============================================================
  // LOAD REMOTE BY ID DIRECT
  // ============================================================

  Future<
    ReminderModel?
  >
  _loadRemoteByIdDirect(
    String id,
  ) async {
    final user = _requireUser();

    try {
      final response = await _client
          .from(
            _table,
          )
          .select()
          .eq(
            'id',
            id,
          )
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (response ==
          null) {
        return null;
      }

      final reminder = ReminderModel.fromJson(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );

      await _localDao.upsert(
        reminder,
        syncStatus: SyncStatus.synced,
      );

      return reminder;
    } catch (
      _
    ) {
      return null;
    }
  }

  // ============================================================
  // REPLACE LOCAL SNAPSHOT
  // ============================================================

  Future<
    void
  >
  _replaceLocalSnapshot({
    required String userId,
    required List<
      ReminderModel
    >
    remote,
  }) async {
    final local = await _localDao.getAllForUser(
      userId,
    );

    final queued = await _pendingReminderItems();

    final pendingIds = queued
        .map(
          (
            item,
          ) => item.entityId,
        )
        .toSet();

    final remoteIds = remote
        .map(
          (
            reminder,
          ) => reminder.id,
        )
        .toSet();

    // ----------------------------------------------------------
    // REMOVE STALE SYNCED LOCAL ROWS
    // ----------------------------------------------------------

    for (final reminder in local) {
      if (pendingIds.contains(
        reminder.id,
      )) {
        continue;
      }

      if (!remoteIds.contains(
        reminder.id,
      )) {
        await _localDao.deletePermanently(
          reminder.id,
        );
      }
    }

    // ----------------------------------------------------------
    // UPSERT REMOTE
    // ----------------------------------------------------------

    for (final reminder in remote) {
      if (pendingIds.contains(
        reminder.id,
      )) {
        continue;
      }

      await _localDao.upsert(
        reminder,
        syncStatus: SyncStatus.synced,
      );
    }
  }

  // ============================================================
  // PENDING REMINDER ITEMS
  // ============================================================

  Future<
    List<
      SyncItem
    >
  >
  _pendingReminderItems() async {
    final queue = _syncQueue;

    if (queue ==
        null) {
      return const [];
    }

    final items = await queue.getAll();

    return items
        .where(
          (
            item,
          ) =>
              item.entityType ==
              _entityType,
        )
        .toList(
          growable: false,
        );
  }

  Future<
    bool
  >
  _hasPendingReminderSync() async {
    final items = await _pendingReminderItems();

    return items.isNotEmpty;
  }

  // ============================================================
  // REMOTE PAYLOAD
  // ============================================================

  Map<
    String,
    dynamic
  >
  _toRemotePayload(
    ReminderModel reminder,
  ) {
    return {
      'id': reminder.id,

      'user_id': reminder.userId,

      'title': reminder.title.trim(),

      'message': reminder.message.trim(),

      'remind_at': reminder.remindAt.toUtc().toIso8601String(),

      'source_type': reminder.sourceType,

      'source_id': reminder.sourceId,

      'notify_in_app': reminder.notifyInApp,

      'notify_telegram': reminder.notifyTelegram,

      'sent_in_app': reminder.sentInApp,

      'sent_telegram': reminder.sentTelegram,

      'completed': reminder.completed,

      'created_at': reminder.createdAt?.toUtc().toIso8601String(),

      'updated_at':
          (reminder.updatedAt ??
                  DateTime.now())
              .toUtc()
              .toIso8601String(),
    };
  }

  // ============================================================
  // COPY REMINDER
  // ============================================================

  ReminderModel _copyReminder(
    ReminderModel source, {
    String? title,
    String? message,
    DateTime? remindAt,
    String? sourceType,
    String? sourceId,
    bool? notifyInApp,
    bool? notifyTelegram,
    bool? sentInApp,
    bool? sentTelegram,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: source.id,

      userId: source.userId,

      title:
          title ??
          source.title,

      message:
          message ??
          source.message,

      remindAt:
          remindAt ??
          source.remindAt,

      sourceType:
          sourceType ??
          source.sourceType,

      sourceId:
          sourceId ??
          source.sourceId,

      notifyInApp:
          notifyInApp ??
          source.notifyInApp,

      notifyTelegram:
          notifyTelegram ??
          source.notifyTelegram,

      sentInApp:
          sentInApp ??
          source.sentInApp,

      sentTelegram:
          sentTelegram ??
          source.sentTelegram,

      completed:
          completed ??
          source.completed,

      createdAt:
          createdAt ??
          source.createdAt,

      updatedAt:
          updatedAt ??
          source.updatedAt,
    );
  }

  // ============================================================
  // VALIDATE ID
  // ============================================================

  String _validateId(
    String id,
  ) {
    final normalized = id.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        id,
        'id',
        'O id não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // NULL IF EMPTY
  // ============================================================

  String? _nullIfEmpty(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim();

    return normalized.isEmpty
        ? null
        : normalized;
  }

  // ============================================================
  // UUID V4
  // ============================================================
  //
  // UUID gerado localmente para permitir criação offline.
  //
  // Formato compatível com PostgreSQL uuid.
  //
  // ============================================================

  String _uuidV4() {
    final random = Random.secure();

    final bytes =
        List<
          int
        >.generate(
          16,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    bytes[6] =
        (bytes[6] &
            0x0F) |
        0x40;

    bytes[8] =
        (bytes[8] &
            0x3F) |
        0x80;

    String hex(
      int value,
    ) {
      return value
          .toRadixString(
            16,
          )
          .padLeft(
            2,
            '0',
          );
    }

    final value = bytes
        .map(
          hex,
        )
        .join();

    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20, 32)}';
  }

  // ============================================================
  // LOG
  // ============================================================

  void _log(
    String operation,
    String message,
  ) {
    debugPrint(
      '[REMINDER][$operation] $message',
    );
  }
}
