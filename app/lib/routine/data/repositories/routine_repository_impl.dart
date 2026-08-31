import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

import '../../models/routine_day.dart';
import '../datasources/routine_local_datasource.dart';
import '../datasources/routine_memory_datasource.dart';
import '../datasources/routine_remote_data_source.dart';
import '../dtos/routine_day_dto.dart';
import '../mappers/routine_day_mapper.dart';
import 'routine_repository.dart';

// ============================================================
// ROUTINE REPOSITORY IMPLEMENTATION
// ============================================================
//
// Estratégia OFFLINE-FIRST:
//
// SAVE
//   1. converte Model -> DTO -> Map;
//   2. garante um ID estável;
//   3. salva PRIMEIRO no SQLite;
//   4. adiciona operação à SyncQueue;
//   5. atualiza a UI imediatamente;
//   6. SyncService envia ao Supabase quando houver internet.
//
// LOAD
//   1. tenta carregar o SQLite primeiro;
//   2. se houver alterações locais pendentes, elas vencem;
//   3. se não houver pendências, tenta atualizar pelo Supabase;
//   4. se estiver offline, continua usando o SQLite.
//
// DELETE
//   1. registra a exclusão localmente;
//   2. adiciona DELETE à SyncQueue;
//   3. SyncService remove do Supabase quando houver internet.
//
// ============================================================

class RoutineRepositoryImpl
    implements
        RoutineRepository {
  RoutineRepositoryImpl({
    required RoutineLocalDataSource localDataSource,
    RoutineRemoteDataSource? remoteDataSource,
    required SyncQueue syncQueue,
    required SyncService syncService,

    // Mantido por compatibilidade com o restante do projeto.
    //
    // No modo offline-first, erros remotos de leitura não
    // impedem o uso do cache local.
    this.fallbackToLocalOnRemoteError = true,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // DATASOURCES
  // ============================================================

  final RoutineLocalDataSource _localDataSource;

  final RoutineRemoteDataSource? _remoteDataSource;

  // ============================================================
  // SYNC
  // ============================================================

  final SyncQueue _syncQueue;

  final SyncService _syncService;

  // ============================================================
  // CONFIG
  // ============================================================

  final bool fallbackToLocalOnRemoteError;

  static const String _entityType = 'routine_day';

  // ============================================================
  // LOAD WEEK
  // ============================================================

  @override
  Future<
    List<
      RoutineDay
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final start = _dateOnly(
      weekStart,
    );

    final end = start.add(
      const Duration(
        days: 6,
      ),
    );

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: start,
      weekEnd: end,
    );

    final hasPending = await _hasPendingLocal(
      normalizedUserId,
    );

    // Se existe alteração local pendente, não permitimos que
    // um snapshot remoto mais antigo a sobrescreva.
    if (hasPending) {
      _log(
        'LOAD WEEK',
        'Existem alterações locais pendentes. '
            'Usando SQLite como fonte principal.',
      );

      _syncService.requestSync();

      return _recordsToModels(
        localRecords,
      );
    }

    // ==========================================================
    // REMOTE REFRESH
    // ==========================================================

    final remote = _remoteDataSource;

    if (remote !=
        null) {
      try {
        _log(
          'LOAD WEEK',
          'Atualizando semana pelo Supabase.',
        );

        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        final remoteRecords = await remote.loadWeek(
          userId: normalizedUserId,
          weekStart: start,
        );

        await _replaceLocalSnapshot(
          userId: normalizedUserId,
          remoteRecords: remoteRecords,
          rangeStart: start,
          rangeEnd: end,
        );

        return _recordsToModels(
          remoteRecords,
        );
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'LOAD WEEK / SUPABASE',
          error: error,
          stackTrace: stackTrace,
        );

        if (localRecords.isNotEmpty ||
            fallbackToLocalOnRemoteError) {
          _log(
            'LOAD WEEK',
            'Usando dados locais.',
          );

          return _recordsToModels(
            localRecords,
          );
        }

        rethrow;
      }
    }

    // ==========================================================
    // LOCAL ONLY
    // ==========================================================

    return _recordsToModels(
      localRecords,
    );
  }

  // ============================================================
  // LOAD DAY
  // ============================================================

  @override
  Future<
    RoutineDay?
  >
  loadDay({
    required String userId,
    required DateTime date,
  }) async {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final normalizedDate = _dateOnly(
      date,
    );

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: normalizedDate,
      weekEnd: normalizedDate,
    );

    RoutineDay? localModel;

    for (final record in localRecords) {
      try {
        final model = _recordToModel(
          record,
        );

        if (_sameDate(
          model.normalizedDate,
          normalizedDate,
        )) {
          localModel = model;

          break;
        }
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'LOAD DAY / LOCAL PARSE',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    final hasPending = await _hasPendingLocal(
      normalizedUserId,
    );

    if (hasPending) {
      _syncService.requestSync();

      return localModel;
    }

    // ==========================================================
    // REMOTE REFRESH
    // ==========================================================

    final remote = _remoteDataSource;

    if (remote !=
        null) {
      try {
        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        final remoteRecord = await remote.getDay(
          userId: normalizedUserId,
          date: normalizedDate,
        );

        if (remoteRecord ==
            null) {
          return localModel;
        }

        await _cacheRemoteRecords(
          userId: normalizedUserId,
          records: [
            remoteRecord,
          ],
        );

        return _recordToModel(
          remoteRecord,
        );
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'LOAD DAY / SUPABASE',
          error: error,
          stackTrace: stackTrace,
        );

        if (localModel !=
                null ||
            fallbackToLocalOnRemoteError) {
          return localModel;
        }

        rethrow;
      }
    }

    return localModel;
  }

  // ============================================================
  // SAVE DAY
  // ============================================================

  @override
  Future<
    RoutineDay
  >
  saveDay({
    required String userId,
    required RoutineDay day,
  }) async {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final normalizedDate = _dateOnly(
      day.normalizedDate,
    );

    // ==========================================================
    // MODEL -> DTO -> MAP
    // ==========================================================

    final dto = RoutineDayMapper.toDto(
      model: day,
      userId: normalizedUserId,
    );

    final localRecord =
        Map<
          String,
          dynamic
        >.from(
          dto.toMap(
            includeBlocks: true,
          ),
        );

    // ==========================================================
    // ID ESTÁVEL POR DATA
    // ==========================================================
    //
    // O mesmo dia precisa conservar o mesmo UUID.
    //
    // Se o model vier sem id, procuramos primeiro o registro local
    // já existente para a mesma data. Só geramos UUID quando o dia
    // realmente ainda não existe.
    //
    // Isso evita:
    //
    // - criar IDs novos para a mesma data;
    // - conflito no UNIQUE(user_id, date);
    // - duplicar operações na SyncQueue.
    //
    // ==========================================================

    final rawId = localRecord['id']?.toString().trim();

    final existingLocalId = await _findExistingLocalDayId(
      userId: normalizedUserId,
      date: normalizedDate,
    );

    final hasIncomingId =
        rawId !=
            null &&
        rawId.isNotEmpty;

    final dayId = hasIncomingId
        ? rawId
        : existingLocalId ??
              _uuidV4();

    final existedBeforeSave =
        hasIncomingId ||
        existingLocalId !=
            null;

    localRecord['id'] = dayId;

    localRecord['user_id'] = normalizedUserId;

    localRecord['date'] = _dateKey(
      normalizedDate,
    );

    localRecord['updated_at'] = DateTime.now().toUtc().toIso8601String();

    // ==========================================================
    // DEBUG
    // ==========================================================

    _log(
      'SAVE DAY',
      'Salvando primeiro no SQLite.',
    );

    _log(
      'SAVE DAY',
      'userId: $normalizedUserId',
    );

    _log(
      'SAVE DAY',
      'dayId: $dayId',
    );

    _log(
      'SAVE DAY',
      'date: $normalizedDate',
    );

    _log(
      'SAVE DAY',
      'focus: "${day.focus}"',
    );

    _log(
      'SAVE DAY',
      'blocks: ${day.blocks.length}',
    );

    _log(
      'SAVE DAY',
      'existingLocalId: ${existingLocalId ?? "(nenhum)"}',
    );

    // ==========================================================
    // 1. LOCAL FIRST
    // ==========================================================

    await _localDataSource.saveDay(
      userId: normalizedUserId,
      day: localRecord,
    );

    // ==========================================================
    // 2. SYNC QUEUE
    // ==========================================================
    //
    // Não existe mais fallback silencioso sem fila.
    //
    // Se o SQLite foi marcado como pendente, a operação PRECISA
    // existir também na SyncQueue.
    //
    // ==========================================================

    final operation = existedBeforeSave
        ? SyncOperation.update
        : SyncOperation.create;

    _log(
      'SAVE DAY',
      'Enfileirando $_entityType/$dayId (${operation.value}).',
    );

    try {
      await _syncQueue.enqueue(
        entityType: _entityType,
        entityId: dayId,
        operation: operation,
        payload: localRecord,
      );
    } catch (
      error,
      stackTrace
    ) {
      _logError(
        operation: 'SAVE DAY / SYNC QUEUE',
        error: error,
        stackTrace: stackTrace,
      );

      // O dado já está seguro no SQLite, mas não podemos fingir
      // que a operação foi corretamente preparada para sync.
      rethrow;
    }

    // Atualiza imediatamente o contador exibido pelo card.
    await _syncService.refreshPendingCount();

    _log(
      'SAVE DAY',
      'Fila atualizada. pending=${_syncService.pendingCount}.',
    );

    // ==========================================================
    // 3. AUTO SYNC
    // ==========================================================

    _syncService.requestSync();

    _log(
      'SAVE DAY',
      'Sincronização solicitada.',
    );

    // ==========================================================
    // 4. RETURN LOCAL RESULT
    // ==========================================================

    return _recordToModel(
      localRecord,
    );
  }

  // ============================================================
  // DELETE DAY
  // ============================================================

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      throw ArgumentError.value(
        dayId,
        'dayId',
        'O dayId não pode estar vazio.',
      );
    }

    // ==========================================================
    // 1. LOCAL FIRST
    // ==========================================================

    await _localDataSource.deleteDay(
      userId: normalizedUserId,
      dayId: normalizedDayId,
    );

    // ==========================================================
    // 2. QUEUE
    // ==========================================================
    //
    // user_id é preservado no payload.
    //
    // Isso é necessário para o handler remoto validar qual usuário
    // é dono da operação.
    //
    // ==========================================================

    _log(
      'DELETE DAY',
      'Enfileirando $_entityType/$normalizedDayId (delete).',
    );

    try {
      await _syncQueue.enqueue(
        entityType: _entityType,
        entityId: normalizedDayId,
        operation: SyncOperation.delete,
        payload:
            <
              String,
              dynamic
            >{
              'user_id': normalizedUserId,
            },
      );
    } catch (
      error,
      stackTrace
    ) {
      _logError(
        operation: 'DELETE DAY / SYNC QUEUE',
        error: error,
        stackTrace: stackTrace,
      );

      rethrow;
    }

    await _syncService.refreshPendingCount();

    _syncService.requestSync();

    _log(
      'DELETE DAY',
      'Sincronização solicitada. pending=${_syncService.pendingCount}.',
    );
  }

  // ============================================================
  // DAY EXISTS
  // ============================================================

  @override
  Future<
    bool
  >
  dayExists({
    required String userId,
    required DateTime date,
  }) async {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final normalizedDate = _dateOnly(
      date,
    );

    // Offline-first:
    // existência local é suficiente para responder imediatamente.
    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: normalizedDate,
      weekEnd: normalizedDate,
    );

    for (final record in localRecords) {
      try {
        final model = _recordToModel(
          record,
        );

        if (_sameDate(
          model.normalizedDate,
          normalizedDate,
        )) {
          return true;
        }
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'DAY EXISTS / LOCAL PARSE',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    // Se não existe localmente e há pendência, não consultamos
    // remoto para evitar resurrectar registro excluído offline.
    if (await _hasPendingLocal(
      normalizedUserId,
    )) {
      return false;
    }

    final remote = _remoteDataSource;

    if (remote ==
        null) {
      return false;
    }

    try {
      remote.ensureAuthenticatedUser(
        normalizedUserId,
      );

      return await remote.dayExists(
        userId: normalizedUserId,
        date: normalizedDate,
      );
    } catch (
      error,
      stackTrace
    ) {
      _logError(
        operation: 'DAY EXISTS / SUPABASE',
        error: error,
        stackTrace: stackTrace,
      );

      if (fallbackToLocalOnRemoteError) {
        return false;
      }

      rethrow;
    }
  }

  // ============================================================
  // CLEAR LOCAL DATA
  // ============================================================

  @override
  Future<
    void
  >
  clearLocalData(
    String userId,
  ) {
    final normalizedUserId = _validateUserId(
      userId,
    );

    return _localDataSource.clearUser(
      normalizedUserId,
    );
  }

  // ============================================================
  // DIRECT REMOTE SAVE
  // ============================================================
  //
  // Somente fallback para instalações que ainda não injetaram
  // SyncQueue.
  //
  // ============================================================

  Future<
    void
  >
  _tryDirectRemoteSave({
    required String userId,
    required RoutineRecord localRecord,
  }) async {
    final remote = _remoteDataSource;

    if (remote ==
        null) {
      if (!fallbackToLocalOnRemoteError) {
        throw StateError(
          'RoutineRemoteDataSource não foi configurado.',
        );
      }

      return;
    }

    try {
      remote.ensureAuthenticatedUser(
        userId,
      );

      final remoteRecord = await remote.saveDay(
        userId: userId,
        data: localRecord,
      );

      await _cacheRemoteRecords(
        userId: userId,
        records: [
          remoteRecord,
        ],
      );
    } catch (
      error,
      stackTrace
    ) {
      _logError(
        operation: 'SAVE DAY / DIRECT REMOTE',
        error: error,
        stackTrace: stackTrace,
      );

      if (!fallbackToLocalOnRemoteError) {
        rethrow;
      }
    }
  }

  // ============================================================
  // CACHE REMOTE RECORDS
  // ============================================================

  Future<
    void
  >
  _cacheRemoteRecords({
    required String userId,
    required List<
      RoutineRecord
    >
    records,
  }) async {
    final local = _localDataSource;

    // Nossa implementação SQLite conhece seed() e consegue
    // marcar snapshot remoto como "synced".
    if (local
        is RoutineMemoryDataSource) {
      await local.seed(
        userId: userId,
        days: records,
      );

      return;
    }

    // Compatibilidade com outra implementação da interface.
    for (final record in records) {
      await local.saveDay(
        userId: userId,
        day: record,
      );
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
      RoutineRecord
    >
    remoteRecords,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final local = _localDataSource;

    if (local
        is RoutineMemoryDataSource) {
      await local.seed(
        userId: userId,
        days: remoteRecords,
      );

      return;
    }

    // Interface genérica:
    // apenas atualiza os registros recebidos.
    for (final record in remoteRecords) {
      await local.saveDay(
        userId: userId,
        day: record,
      );
    }
  }

  // ============================================================
  // HAS PENDING LOCAL
  // ============================================================

  Future<
    bool
  >
  _hasPendingLocal(
    String userId,
  ) async {
    final local = _localDataSource;

    if (local
        is RoutineMemoryDataSource) {
      final pending = await local.loadUnsynced(
        userId: userId,
      );

      return pending.isNotEmpty;
    }

    return false;
  }

  // ============================================================
  // FIND EXISTING LOCAL DAY ID
  // ============================================================
  //
  // Procura um registro já persistido para user + date.
  //
  // O objetivo é garantir que salvar novamente o mesmo dia não
  // gere um novo UUID.
  //
  // ============================================================

  Future<
    String?
  >
  _findExistingLocalDayId({
    required String userId,
    required DateTime date,
  }) async {
    final normalizedDate = _dateOnly(
      date,
    );

    final records = await _localDataSource.loadWeek(
      userId: userId,
      weekStart: normalizedDate,
      weekEnd: normalizedDate,
    );

    for (final record in records) {
      try {
        final raw =
            Map<
              String,
              dynamic
            >.from(
              record,
            );

        final rawDate = raw['date'];

        DateTime? recordDate;

        if (rawDate
            is DateTime) {
          recordDate = _dateOnly(
            rawDate,
          );
        } else if (rawDate !=
            null) {
          final parsed = DateTime.tryParse(
            rawDate.toString().trim(),
          );

          if (parsed !=
              null) {
            recordDate = _dateOnly(
              parsed.toLocal(),
            );
          }
        }

        if (recordDate ==
                null ||
            !_sameDate(
              recordDate,
              normalizedDate,
            )) {
          continue;
        }

        final id = raw['id']?.toString().trim();

        if (id !=
                null &&
            id.isNotEmpty) {
          return id;
        }
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'FIND EXISTING LOCAL DAY ID',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return null;
  }

  // ============================================================
  // RECORDS -> MODELS
  // ============================================================

  List<
    RoutineDay
  >
  _recordsToModels(
    List<
      RoutineRecord
    >
    records,
  ) {
    final models =
        <
          RoutineDay
        >[];

    for (final record in records) {
      try {
        models.add(
          _recordToModel(
            record,
          ),
        );
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'RECORD -> MODEL',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    models.sort(
      (
        first,
        second,
      ) => first.normalizedDate.compareTo(
        second.normalizedDate,
      ),
    );

    return models;
  }

  // ============================================================
  // RECORD -> MODEL
  // ============================================================

  RoutineDay _recordToModel(
    RoutineRecord record,
  ) {
    final rawRecord =
        Map<
          String,
          dynamic
        >.from(
          record,
        );

    final dto = RoutineDayDto.fromMap(
      rawRecord,
    );

    final model = RoutineDayMapper.toModel(
      dto,
    );

    // ==========================================================
    // RESTAURAR TAMANHO PERSONALIZADO DOS BLOCOS
    // ==========================================================

    _restoreBlockDimensionsFromRecord(
      model: model,
      record: rawRecord,
    );

    return model;
  }

  // ============================================================
  // RESTAURAR DIMENSÕES DOS BLOCOS
  // ============================================================

  void _restoreBlockDimensionsFromRecord({
    required RoutineDay model,
    required Map<
      String,
      dynamic
    >
    record,
  }) {
    final rawBlocks = record['blocks'];

    if (rawBlocks
        is! List) {
      return;
    }

    final dimensionsById =
        <
          String,
          Map<
            String,
            dynamic
          >
        >{};

    for (final rawBlock in rawBlocks) {
      if (rawBlock
          is! Map) {
        continue;
      }

      final map =
          Map<
            String,
            dynamic
          >.from(
            rawBlock,
          );

      final id = map['id']?.toString().trim();

      if (id ==
              null ||
          id.isEmpty) {
        continue;
      }

      dimensionsById[id] = map;
    }

    for (final block in model.blocks) {
      final raw = dimensionsById[block.id];

      if (raw ==
          null) {
        continue;
      }

      final width = _nullableDouble(
        raw['width'],
      );

      final height = _nullableDouble(
        raw['height'],
      );

      if (width !=
          null) {
        block.width = width;
      }

      if (height !=
          null) {
        block.height = height;
      }
    }
  }

  // ============================================================
  // NULLABLE DOUBLE
  // ============================================================

  double? _nullableDouble(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // VALIDATE USER
  // ============================================================

  String _validateUserId(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O userId não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // DATE ONLY
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

  // ============================================================
  // DATE KEY
  // ============================================================

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
  // SAME DATE
  // ============================================================

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  // ============================================================
  // UUID V4
  // ============================================================
  //
  // Não exige dependência externa.
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

    // UUID version 4.
    bytes[6] =
        (bytes[6] &
            0x0F) |
        0x40;

    // RFC 4122 variant.
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
      '[ROUTINE][$operation] $message',
    );
  }

  // ============================================================
  // ERROR LOG
  // ============================================================

  void _logError({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
  }) {
    debugPrint(
      '',
    );

    debugPrint(
      '============================================================',
    );

    debugPrint(
      '[ROUTINE][$operation] ERRO',
    );

    debugPrint(
      '------------------------------------------------------------',
    );

    debugPrint(
      '$error',
    );

    debugPrint(
      '------------------------------------------------------------',
    );

    debugPrint(
      '$stackTrace',
    );

    debugPrint(
      '============================================================',
    );

    debugPrint(
      '',
    );
  }
}
