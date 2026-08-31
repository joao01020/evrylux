import 'dart:convert';

import '../../../core/database/daos/routine_dao.dart';
import '../../../core/sync/sync_status.dart';

import 'routine_local_datasource.dart';

/// Implementação persistente de [RoutineLocalDataSource].
///
/// O nome [RoutineMemoryDataSource] foi mantido apenas por
/// compatibilidade com o restante do projeto.
///
/// Diferente da versão antiga, os dados NÃO ficam mais apenas
/// em memória. Eles são gravados no SQLite através de
/// [RoutineDao].
///
/// Isso significa que:
///
/// - fechar o aplicativo não apaga a rotina;
/// - reiniciar o computador não apaga a rotina;
/// - a rotina pode ser carregada mesmo sem internet.
///
/// A sincronização com Supabase continua sendo responsabilidade
/// do Repository / SyncService.
class RoutineMemoryDataSource
    implements
        RoutineLocalDataSource {
  RoutineMemoryDataSource({
    RoutineDao? dao,
  }) : _dao =
           dao ??
           RoutineDao();

  // ============================================================
  // DAO
  // ============================================================

  final RoutineDao _dao;

  // ============================================================
  // LOAD WEEK
  // ============================================================

  @override
  Future<
    List<
      RoutineRecord
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    _validateUserId(
      userId,
    );

    final records = await _dao.getRange(
      userId: userId,
      start: _dateOnly(
        weekStart,
      ),
      end: _dateOnly(
        weekEnd,
      ),
    );

    return records
        .map(
          (
            record,
          ) => _recordFromLocal(
            record,
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // SAVE DAY
  // ============================================================

  @override
  Future<
    void
  >
  saveDay({
    required String userId,
    required RoutineRecord day,
  }) async {
    _validateUserId(
      userId,
    );

    final id = day['id']?.toString().trim();

    final rawDate = day['date'];

    final date = _parseDate(
      rawDate,
    );

    if (date ==
        null) {
      throw ArgumentError(
        'O registro da rotina precisa conter uma data válida.',
      );
    }

    final resolvedId =
        id !=
                null &&
            id.isNotEmpty
        ? id
        : _localIdForDate(
            userId: userId,
            date: date,
          );

    final record = _copyRecord(
      day,
    );

    record['id'] = resolvedId;

    record['user_id'] = userId;

    record['date'] = _dateKey(
      date,
    );

    final existing = await _dao.getByDate(
      userId: userId,
      date: date,
      includeDeleted: true,
    );

    final status = _resolveSaveStatus(
      existing,
    );

    await _dao.upsert(
      id: resolvedId,
      userId: userId,
      date: date,
      payload: record,
      syncStatus: status,
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
    );
  }

  // ============================================================
  // DELETE DAY
  // ============================================================
  //
  // Mantemos tombstone local quando o registro já foi
  // sincronizado, para que o Repository possa futuramente
  // sincronizar a exclusão.
  //
  // Se o registro nunca chegou ao servidor (pendingCreate),
  // podemos removê-lo definitivamente do SQLite.
  //
  // ============================================================

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    _validateUserId(
      userId,
    );

    final normalizedId = dayId.trim();

    if (normalizedId.isEmpty) {
      throw ArgumentError(
        'dayId não pode ser vazio.',
      );
    }

    final records = await _dao.getAll(
      userId: userId,
      includeDeleted: true,
    );

    RoutineLocalRecord? target;

    for (final record in records) {
      if (record.id ==
          normalizedId) {
        target = record;

        break;
      }
    }

    if (target ==
        null) {
      return;
    }

    if (target.syncStatus ==
        SyncStatus.pendingCreate) {
      await _dao.deletePermanently(
        normalizedId,
      );

      return;
    }

    await _dao.markDeleted(
      normalizedId,
      syncStatus: SyncStatus.pendingDelete,
    );
  }

  // ============================================================
  // CLEAR USER
  // ============================================================
  //
  // Remove somente os dados locais desse usuário.
  //
  // Esse método é útil para:
  //
  // - logout;
  // - reset de cache;
  // - testes.
  //
  // Não remove nada diretamente do Supabase.
  //
  // ============================================================

  @override
  Future<
    void
  >
  clearUser(
    String userId,
  ) async {
    _validateUserId(
      userId,
    );

    final records = await _dao.getAll(
      userId: userId,
      includeDeleted: true,
    );

    for (final record in records) {
      await _dao.deletePermanently(
        record.id,
      );
    }
  }

  // ============================================================
  // SEED
  // ============================================================
  //
  // Substitui o snapshot local do usuário pelos registros
  // recebidos.
  //
  // Normalmente será utilizado depois de carregar dados do
  // Supabase.
  //
  // Os registros recebidos são marcados como sincronizados.
  //
  // ============================================================

  Future<
    void
  >
  seed({
    required String userId,
    required List<
      RoutineRecord
    >
    days,
  }) async {
    _validateUserId(
      userId,
    );

    final current = await _dao.getAll(
      userId: userId,
      includeDeleted: true,
    );

    // ----------------------------------------------------------
    // Não removemos alterações locais pendentes.
    //
    // Isso evita que um refresh remoto apague algo criado ou
    // alterado enquanto o usuário estava offline.
    // ----------------------------------------------------------

    final pendingIds = current
        .where(
          (
            record,
          ) =>
              record.syncStatus !=
              SyncStatus.synced,
        )
        .map(
          (
            record,
          ) => record.id,
        )
        .toSet();

    // ----------------------------------------------------------
    // Remove somente snapshot já sincronizado.
    // ----------------------------------------------------------

    for (final record in current) {
      if (record.syncStatus ==
          SyncStatus.synced) {
        await _dao.deletePermanently(
          record.id,
        );
      }
    }

    // ----------------------------------------------------------
    // Insere snapshot remoto.
    // ----------------------------------------------------------

    for (final day in days) {
      final rawDate = day['date'];

      final date = _parseDate(
        rawDate,
      );

      if (date ==
          null) {
        continue;
      }

      final rawId = day['id']?.toString().trim();

      final id =
          rawId !=
                  null &&
              rawId.isNotEmpty
          ? rawId
          : _localIdForDate(
              userId: userId,
              date: date,
            );

      // Se já existe alteração local pendente para este mesmo
      // ID, ela vence o snapshot remoto.
      if (pendingIds.contains(
        id,
      )) {
        continue;
      }

      final record = _copyRecord(
        day,
      );

      record['id'] = id;

      record['user_id'] = userId;

      record['date'] = _dateKey(
        date,
      );

      await _dao.upsert(
        id: id,
        userId: userId,
        date: date,
        payload: record,
        syncStatus: SyncStatus.synced,
        createdAt: _parseDateTime(
          day['created_at'],
        ),
        updatedAt: _parseDateTime(
          day['updated_at'],
        ),
      );
    }
  }

  // ============================================================
  // GET DAY
  // ============================================================
  //
  // Helper adicional para debug e futuros repositories.
  //
  // ============================================================

  Future<
    RoutineRecord?
  >
  loadDay({
    required String userId,
    required DateTime date,
  }) async {
    _validateUserId(
      userId,
    );

    final record = await _dao.getByDate(
      userId: userId,
      date: _dateOnly(
        date,
      ),
    );

    if (record ==
        null) {
      return null;
    }

    return _recordFromLocal(
      record,
    );
  }

  // ============================================================
  // HAS LOCAL DATA
  // ============================================================

  Future<
    bool
  >
  hasLocalData(
    String userId,
  ) async {
    _validateUserId(
      userId,
    );

    final records = await _dao.getAll(
      userId: userId,
    );

    return records.isNotEmpty;
  }

  // ============================================================
  // UNSYNCED
  // ============================================================

  Future<
    List<
      RoutineRecord
    >
  >
  loadUnsynced({
    required String userId,
  }) async {
    _validateUserId(
      userId,
    );

    final records = await _dao.getUnsynced(
      userId: userId,
    );

    return records
        .map(
          (
            record,
          ) => _recordFromLocal(
            record,
          ),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // MARK SYNCED
  // ============================================================

  Future<
    void
  >
  markSynced(
    String dayId,
  ) async {
    final id = dayId.trim();

    if (id.isEmpty) {
      throw ArgumentError(
        'dayId não pode ser vazio.',
      );
    }

    await _dao.setSyncStatus(
      id,
      SyncStatus.synced,
    );
  }

  // ============================================================
  // SAVE STATUS
  // ============================================================

  SyncStatus _resolveSaveStatus(
    RoutineLocalRecord? existing,
  ) {
    if (existing ==
        null) {
      return SyncStatus.pendingCreate;
    }

    switch (existing.syncStatus) {
      case SyncStatus.pendingCreate:
        return SyncStatus.pendingCreate;

      case SyncStatus.pendingDelete:
        return SyncStatus.pendingUpdate;

      case SyncStatus.synced:
      case SyncStatus.pendingUpdate:
      case SyncStatus.syncing:
      case SyncStatus.error:
        return SyncStatus.pendingUpdate;
    }
  }

  // ============================================================
  // LOCAL -> ROUTINE RECORD
  // ============================================================

  RoutineRecord _recordFromLocal(
    RoutineLocalRecord local,
  ) {
    final record = _copyRecord(
      local.payload,
    );

    record['id'] = local.id;

    record['user_id'] = local.userId;

    record['date'] = _dateKey(
      local.date,
    );

    record['created_at'] ??= local.createdAt.toUtc().toIso8601String();

    record['updated_at'] = local.updatedAt.toUtc().toIso8601String();

    return record;
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  void _validateUserId(
    String userId,
  ) {
    if (userId.trim().isEmpty) {
      throw ArgumentError(
        'userId não pode ser vazio.',
      );
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return _dateOnly(
        value,
      );
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    if (parsed ==
        null) {
      return null;
    }

    return _dateOnly(
      parsed,
    );
  }

  DateTime? _parseDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  String _dateKey(
    DateTime value,
  ) {
    final year = value.year.toString().padLeft(
      4,
      '0',
    );

    final month = value.month.toString().padLeft(
      2,
      '0',
    );

    final day = value.day.toString().padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
  }

  // ============================================================
  // LOCAL ID
  // ============================================================
  //
  // Fallback estável quando o registro ainda não possui ID.
  //
  // Mantemos o mesmo ID para o mesmo usuário + dia.
  //
  // ============================================================

  String _localIdForDate({
    required String userId,
    required DateTime date,
  }) {
    final safeUser = userId.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    return 'routine_${safeUser}_${_dateKey(date)}';
  }

  // ============================================================
  // DEEP COPY
  // ============================================================

  RoutineRecord _copyRecord(
    RoutineRecord source,
  ) {
    final encoded = jsonEncode(
      source,
    );

    final decoded = jsonDecode(
      encoded,
    );

    return Map<
      String,
      dynamic
    >.from(
      decoded
          as Map,
    );
  }
}
