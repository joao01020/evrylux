import 'package:flutter/foundation.dart';

import '../../models/routine_day.dart';
import '../datasources/routine_local_datasource.dart';
import '../datasources/routine_remote_data_source.dart';
import '../dtos/routine_day_dto.dart';
import '../mappers/routine_day_mapper.dart';
import 'routine_repository.dart';

class RoutineRepositoryImpl
    implements
        RoutineRepository {
  RoutineRepositoryImpl({
    required RoutineLocalDataSource localDataSource,
    RoutineRemoteDataSource? remoteDataSource,

    // ==========================================================
    // IMPORTANTE
    // ==========================================================
    //
    // Enquanto estamos configurando o Supabase, deixe false.
    //
    // Assim qualquer erro remoto aparece de verdade no terminal.
    //
    // Depois que tudo estiver funcionando, se quiser modo offline,
    // você pode voltar para true.
    //
    // ==========================================================
    this.fallbackToLocalOnRemoteError = false,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  // ============================================================
  // DATASOURCES
  // ============================================================

  final RoutineLocalDataSource _localDataSource;

  final RoutineRemoteDataSource? _remoteDataSource;

  // ============================================================
  // CONFIG
  // ============================================================

  final bool fallbackToLocalOnRemoteError;

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

    final remote = _remoteDataSource;

    // ==========================================================
    // REMOTE
    // ==========================================================

    if (remote !=
        null) {
      try {
        _log(
          'LOAD WEEK',
          'Buscando semana no Supabase.',
        );

        _log(
          'LOAD WEEK',
          'userId: $normalizedUserId',
        );

        _log(
          'LOAD WEEK',
          'weekStart: $start',
        );

        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        final remoteRecords = await remote.loadWeek(
          userId: normalizedUserId,
          weekStart: start,
        );

        _log(
          'LOAD WEEK',
          '${remoteRecords.length} dia(s) recebidos do Supabase.',
        );

        // ------------------------------------------------------
        // ATUALIZA CACHE LOCAL
        // ------------------------------------------------------

        for (final record in remoteRecords) {
          try {
            await _localDataSource.saveDay(
              userId: normalizedUserId,
              day: record,
            );
          } catch (
            error,
            stackTrace
          ) {
            _logError(
              operation: 'LOAD WEEK / LOCAL CACHE',
              error: error,
              stackTrace: stackTrace,
            );
          }
        }

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

        if (!fallbackToLocalOnRemoteError) {
          rethrow;
        }
      }
    } else {
      _log(
        'LOAD WEEK',
        'RemoteDataSource não configurado. Usando cache local.',
      );
    }

    // ==========================================================
    // LOCAL FALLBACK
    // ==========================================================

    _log(
      'LOAD WEEK',
      'Carregando dados locais.',
    );

    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: start,
      weekEnd: end,
    );

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

    final remote = _remoteDataSource;

    // ==========================================================
    // REMOTE
    // ==========================================================

    if (remote !=
        null) {
      try {
        _log(
          'LOAD DAY',
          'Buscando dia no Supabase.',
        );

        _log(
          'LOAD DAY',
          'userId: $normalizedUserId',
        );

        _log(
          'LOAD DAY',
          'date: $normalizedDate',
        );

        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        final remoteRecord = await remote.getDay(
          userId: normalizedUserId,
          date: normalizedDate,
        );

        if (remoteRecord ==
            null) {
          _log(
            'LOAD DAY',
            'Nenhum registro encontrado.',
          );

          return null;
        }

        // ------------------------------------------------------
        // CACHE LOCAL
        // ------------------------------------------------------

        try {
          await _localDataSource.saveDay(
            userId: normalizedUserId,
            day: remoteRecord,
          );
        } catch (
          error,
          stackTrace
        ) {
          _logError(
            operation: 'LOAD DAY / LOCAL CACHE',
            error: error,
            stackTrace: stackTrace,
          );
        }

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

        if (!fallbackToLocalOnRemoteError) {
          rethrow;
        }
      }
    }

    // ==========================================================
    // LOCAL FALLBACK
    // ==========================================================

    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: normalizedDate,
      weekEnd: normalizedDate,
    );

    if (localRecords.isEmpty) {
      return null;
    }

    for (final record in localRecords) {
      try {
        final model = _recordToModel(
          record,
        );

        if (_sameDate(
          model.normalizedDate,
          normalizedDate,
        )) {
          return model;
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

    return null;
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

    // ==========================================================
    // MODEL -> DTO
    // ==========================================================

    final dto = RoutineDayMapper.toDto(
      model: day,
      userId: normalizedUserId,
    );

    // ==========================================================
    // DTO -> MAP
    // ==========================================================

    final localRecord = dto.toMap(
      includeBlocks: true,
    );

    final remote = _remoteDataSource;

    // ==========================================================
    // DEBUG
    // ==========================================================

    _log(
      'SAVE DAY',
      'Iniciando salvamento.',
    );

    _log(
      'SAVE DAY',
      'userId: $normalizedUserId',
    );

    _log(
      'SAVE DAY',
      'dayId: ${day.id ?? 'NOVO'}',
    );

    _log(
      'SAVE DAY',
      'date: ${day.normalizedDate}',
    );

    _log(
      'SAVE DAY',
      'focus: "${day.focus}"',
    );

    _log(
      'SAVE DAY',
      'blocks: ${day.blocks.length}',
    );

    // ==========================================================
    // REMOTE
    // ==========================================================

    if (remote !=
        null) {
      try {
        _log(
          'SAVE DAY',
          'Validando usuário autenticado.',
        );

        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        _log(
          'SAVE DAY',
          'Enviando para Supabase...',
        );

        final remoteRecord = await remote.saveDay(
          userId: normalizedUserId,
          data: localRecord,
        );

        _log(
          'SAVE DAY',
          'Salvo com sucesso no Supabase.',
        );

        _log(
          'SAVE DAY',
          'remote id: ${remoteRecord['id']}',
        );

        // ------------------------------------------------------
        // CACHE LOCAL
        // ------------------------------------------------------

        try {
          await _localDataSource.saveDay(
            userId: normalizedUserId,
            day: remoteRecord,
          );

          _log(
            'SAVE DAY',
            'Cache local atualizado.',
          );
        } catch (
          error,
          stackTrace
        ) {
          // Cache local não deve impedir que um save remoto
          // já realizado seja considerado sucesso.
          _logError(
            operation: 'SAVE DAY / LOCAL CACHE',
            error: error,
            stackTrace: stackTrace,
          );
        }

        // ------------------------------------------------------
        // REMOTE -> MODEL
        // ------------------------------------------------------

        final model = _recordToModel(
          remoteRecord,
        );

        _log(
          'SAVE DAY',
          'Save concluído.',
        );

        return model;
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'SAVE DAY / SUPABASE',
          error: error,
          stackTrace: stackTrace,
        );

        if (!fallbackToLocalOnRemoteError) {
          rethrow;
        }
      }
    } else {
      _log(
        'SAVE DAY',
        'ERRO: RemoteDataSource não foi configurado.',
      );

      if (!fallbackToLocalOnRemoteError) {
        throw StateError(
          'RoutineRemoteDataSource não foi configurado. '
          'O dia não pode ser salvo no Supabase.',
        );
      }
    }

    // ==========================================================
    // LOCAL FALLBACK
    // ==========================================================

    _log(
      'SAVE DAY',
      'Usando fallback local.',
    );

    await _localDataSource.saveDay(
      userId: normalizedUserId,
      day: localRecord,
    );

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

    final remote = _remoteDataSource;

    // ==========================================================
    // REMOTE
    // ==========================================================

    if (remote !=
        null) {
      try {
        _log(
          'DELETE DAY',
          'Removendo dia do Supabase.',
        );

        _log(
          'DELETE DAY',
          'dayId: $normalizedDayId',
        );

        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        await remote.deleteDay(
          userId: normalizedUserId,
          dayId: normalizedDayId,
        );

        _log(
          'DELETE DAY',
          'Dia removido do Supabase.',
        );
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'DELETE DAY / SUPABASE',
          error: error,
          stackTrace: stackTrace,
        );

        if (!fallbackToLocalOnRemoteError) {
          rethrow;
        }
      }
    } else if (!fallbackToLocalOnRemoteError) {
      throw StateError(
        'RoutineRemoteDataSource não foi configurado.',
      );
    }

    // ==========================================================
    // LOCAL
    // ==========================================================

    await _localDataSource.deleteDay(
      userId: normalizedUserId,
      dayId: normalizedDayId,
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

    final remote = _remoteDataSource;

    // ==========================================================
    // REMOTE
    // ==========================================================

    if (remote !=
        null) {
      try {
        remote.ensureAuthenticatedUser(
          normalizedUserId,
        );

        final exists = await remote.dayExists(
          userId: normalizedUserId,
          date: normalizedDate,
        );

        _log(
          'DAY EXISTS',
          '$normalizedDate = $exists',
        );

        return exists;
      } catch (
        error,
        stackTrace
      ) {
        _logError(
          operation: 'DAY EXISTS / SUPABASE',
          error: error,
          stackTrace: stackTrace,
        );

        if (!fallbackToLocalOnRemoteError) {
          rethrow;
        }
      }
    }

    // ==========================================================
    // LOCAL FALLBACK
    // ==========================================================

    final localRecords = await _localDataSource.loadWeek(
      userId: normalizedUserId,
      weekStart: normalizedDate,
      weekEnd: normalizedDate,
    );

    if (localRecords.isEmpty) {
      return false;
    }

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

    return false;
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
    //
    // O Supabase devolve width/height dentro de blocks.
    //
    // Mesmo que alguma camada intermediária/mapper antigo ainda
    // descarte esses campos, restauramos os valores diretamente
    // do registro remoto antes de entregar o RoutineDay ao
    // controller.
    //
    // Isso evita o mapa mental voltar para 620x430 depois de um
    // save/reload.
    //
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
