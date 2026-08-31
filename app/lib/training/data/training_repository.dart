import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/storage/storage_service.dart';

import '../../core/sync/sync_item.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_service.dart';

class TrainingRepository {
  TrainingRepository({
    SupabaseClient? client,
    SyncQueue? syncQueue,
    SyncService? syncService,
  }) : _client =
           client ??
           Supabase.instance.client,
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final SyncQueue? _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // SYNC ENTITIES
  // ============================================================

  static const String _trainingEntityType = 'training_day';

  static const String _planEntityType = 'training_plan';

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
  // CARREGAR TREINOS
  // ============================================================
  //
  // StorageService continua sendo a fonte local.
  //
  // Isso garante que a tela abra normalmente sem internet.
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    final data = await StorageService.getTraining();

    return Map<
      String,
      dynamic
    >.from(
      data,
    );
  }

  // ============================================================
  // SALVAR TREINO
  // ============================================================
  //
  // Fluxo offline-first:
  //
  // 1. salva no StorageService;
  // 2. registra na SyncQueue;
  // 3. solicita SyncService;
  // 4. Supabase é atualizado quando houver conexão.
  //
  // ============================================================

  Future<
    void
  >
  save({
    required String day,
    required String training,
    required int minutes,
    required DateTime date,
  }) async {
    final user = _requireUser();

    final normalizedDay = _normalizeRequired(
      day,
      fieldName: 'day',
      message: 'O dia do treino não pode estar vazio.',
    );

    final normalizedTraining = training.trim();

    if (minutes <
        0) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Os minutos de treino não podem ser negativos.',
      );
    }

    final normalizedDate = date.toLocal();

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await StorageService.saveTraining(
      normalizedDay,
      normalizedTraining,
      minutes,
      date: normalizedDate,
    );

    debugPrint(
      '[TRAINING REPOSITORY] '
      '$normalizedDay salvo localmente.',
    );

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _trainingEntityId(
      userId: user.id,
      day: normalizedDay,
      training: normalizedTraining,
      date: normalizedDate,
    );

    await queue.enqueue(
      entityType: _trainingEntityType,
      entityId: entityId,
      operation: SyncOperation.update,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'day': normalizedDay,
        'training': normalizedTraining,
        'minutes': minutes,
        'date': normalizedDate.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // ATUALIZAR TREINO
  // ============================================================
  //
  // O registro antigo é identificado por:
  //
  // day + training + date
  //
  // Fluxo:
  //
  // 1. reescreve o StorageService localmente;
  // 2. enfileira DELETE do registro antigo;
  // 3. enfileira UPDATE do registro novo;
  // 4. solicita sincronização.
  //
  // ============================================================

  Future<
    void
  >
  updateTraining({
    required String oldDay,
    required String oldTraining,
    required DateTime oldDate,
    required String newDay,
    required String newTraining,
    required int newMinutes,
    required DateTime newDate,
  }) async {
    final user = _requireUser();

    final normalizedOldDay = _normalizeRequired(
      oldDay,
      fieldName: 'oldDay',
      message: 'O dia antigo não pode estar vazio.',
    );

    final normalizedOldTraining = _normalizeRequired(
      oldTraining,
      fieldName: 'oldTraining',
      message: 'O treino antigo não pode estar vazio.',
    );

    final normalizedNewDay = _normalizeRequired(
      newDay,
      fieldName: 'newDay',
      message: 'O novo dia não pode estar vazio.',
    );

    final normalizedNewTraining = _normalizeRequired(
      newTraining,
      fieldName: 'newTraining',
      message: 'A nova atividade não pode estar vazia.',
    );

    if (newMinutes <
        0) {
      throw ArgumentError.value(
        newMinutes,
        'newMinutes',
        'Os minutos não podem ser negativos.',
      );
    }

    final oldLocalDate = oldDate.toLocal();

    final newLocalDate = newDate.toLocal();

    final records = await _loadLocalRecords();

    var replaced = false;

    final updatedRecords =
        <
          _StoredTrainingRecord
        >[];

    for (final record in records) {
      if (!replaced &&
          _matchesRecord(
            record: record,
            day: normalizedOldDay,
            training: normalizedOldTraining,
            date: oldLocalDate,
          )) {
        updatedRecords.add(
          _StoredTrainingRecord(
            day: normalizedNewDay,
            training: normalizedNewTraining,
            minutes: newMinutes,
            date: newLocalDate,
          ),
        );

        replaced = true;

        continue;
      }

      updatedRecords.add(
        record,
      );
    }

    if (!replaced) {
      throw StateError(
        'Treino que seria editado não foi encontrado no armazenamento local.',
      );
    }

    await _rewriteLocalRecords(
      updatedRecords,
    );

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final oldEntityId = _trainingEntityId(
      userId: user.id,
      day: normalizedOldDay,
      training: normalizedOldTraining,
      date: oldLocalDate,
    );

    final newEntityId = _trainingEntityId(
      userId: user.id,
      day: normalizedNewDay,
      training: normalizedNewTraining,
      date: newLocalDate,
    );

    // Se a identidade mudou, removemos o registro antigo.
    //
    // Se somente os minutos mudaram, oldEntityId == newEntityId
    // e basta um UPDATE. Isso evita delete + update no mesmo
    // item da SyncQueue.
    if (oldEntityId !=
        newEntityId) {
      await queue.enqueue(
        entityType: _trainingEntityType,
        entityId: oldEntityId,
        operation: SyncOperation.delete,
        payload: {
          'id': oldEntityId,
          'user_id': user.id,
          'day': normalizedOldDay,
          'training': normalizedOldTraining,
          'date': oldLocalDate.toUtc().toIso8601String(),
          'delete_scope': 'one',
        },
      );
    }

    // Salva a identidade nova ou atualiza a existente.
    await queue.enqueue(
      entityType: _trainingEntityType,
      entityId: newEntityId,
      operation: SyncOperation.update,
      payload: {
        'id': newEntityId,
        'user_id': user.id,
        'day': normalizedNewDay,
        'training': normalizedNewTraining,
        'minutes': newMinutes,
        'date': newLocalDate.toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // APAGAR UM TREINO
  // ============================================================

  Future<
    void
  >
  deleteTraining({
    required String day,
    required String training,
    required DateTime date,
  }) async {
    final user = _requireUser();

    final normalizedDay = _normalizeRequired(
      day,
      fieldName: 'day',
      message: 'O dia não pode estar vazio.',
    );

    final normalizedTraining = _normalizeRequired(
      training,
      fieldName: 'training',
      message: 'A atividade não pode estar vazia.',
    );

    final normalizedDate = date.toLocal();

    final records = await _loadLocalRecords();

    var removed = false;

    final remaining =
        <
          _StoredTrainingRecord
        >[];

    for (final record in records) {
      if (!removed &&
          _matchesRecord(
            record: record,
            day: normalizedDay,
            training: normalizedTraining,
            date: normalizedDate,
          )) {
        removed = true;

        continue;
      }

      remaining.add(
        record,
      );
    }

    if (!removed) {
      throw StateError(
        'Treino que seria apagado não foi encontrado.',
      );
    }

    await _rewriteLocalRecords(
      remaining,
    );

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _trainingEntityId(
      userId: user.id,
      day: normalizedDay,
      training: normalizedTraining,
      date: normalizedDate,
    );

    await queue.enqueue(
      entityType: _trainingEntityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'day': normalizedDay,
        'training': normalizedTraining,
        'date': normalizedDate.toUtc().toIso8601String(),
        'delete_scope': 'one',
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // CARREGAR REGISTROS LOCAIS NORMALIZADOS
  // ============================================================

  Future<
    List<
      _StoredTrainingRecord
    >
  >
  _loadLocalRecords() async {
    final raw = await StorageService.getTraining();

    final records =
        <
          _StoredTrainingRecord
        >[];

    for (final entry in raw.entries) {
      final day = entry.key.toString().trim();

      if (_isConfigurationKey(
        day,
      )) {
        continue;
      }

      final value = entry.value;

      if (value
          is List) {
        for (final item in value) {
          final record = _recordFromRaw(
            day: day,
            raw: item,
          );

          if (record !=
              null) {
            records.add(
              record,
            );
          }
        }

        continue;
      }

      final record = _recordFromRaw(
        day: day,
        raw: value,
      );

      if (record !=
          null) {
        records.add(
          record,
        );
      }
    }

    return records;
  }

  // ============================================================
  // RAW -> LOCAL RECORD
  // ============================================================

  _StoredTrainingRecord? _recordFromRaw({
    required String day,
    required dynamic raw,
  }) {
    if (raw
        is! Map) {
      return null;
    }

    final training = raw['training']?.toString().trim();

    if (training ==
            null ||
        training.isEmpty) {
      return null;
    }

    final minutes =
        int.tryParse(
          raw['minutes']?.toString() ??
              '',
        ) ??
        0;

    final date = DateTime.tryParse(
      raw['date']?.toString() ??
          '',
    )?.toLocal();

    if (date ==
        null) {
      return null;
    }

    return _StoredTrainingRecord(
      day: day,
      training: training,
      minutes: minutes,
      date: date,
    );
  }

  // ============================================================
  // REESCREVER LOCAL
  // ============================================================

  Future<
    void
  >
  _rewriteLocalRecords(
    Iterable<
      _StoredTrainingRecord
    >
    records,
  ) async {
    await StorageService.clearTraining();

    for (final record in records) {
      await StorageService.saveTraining(
        record.day,
        record.training,
        record.minutes,
        date: record.date,
      );
    }
  }

  // ============================================================
  // COMPARAR REGISTRO
  // ============================================================

  bool _matchesRecord({
    required _StoredTrainingRecord record,
    required String day,
    required String training,
    required DateTime date,
  }) {
    return record.day ==
            day &&
        record.training ==
            training &&
        _sameMomentOrSecond(
          record.date,
          date,
        );
  }

  bool _sameMomentOrSecond(
    DateTime first,
    DateTime second,
  ) {
    final a = first.toUtc();

    final b = second.toUtc();

    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day &&
        a.hour ==
            b.hour &&
        a.minute ==
            b.minute &&
        a.second ==
            b.second;
  }

  // ============================================================
  // CONFIG KEY
  // ============================================================

  bool _isConfigurationKey(
    String key,
  ) {
    return key ==
            'trainingPlan' ||
        key ==
            'weeklyGoal' ||
        key ==
            'plannedWeekdays' ||
        key.startsWith(
          '_',
        );
  }

  // ============================================================
  // CARREGAR PLANO SEMANAL
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  loadTrainingPlan() async {
    final data = await StorageService.getTrainingPlan();

    if (data.isEmpty) {
      return null;
    }

    return Map<
      String,
      dynamic
    >.from(
      data,
    );
  }

  // ============================================================
  // SALVAR PLANO SEMANAL
  // ============================================================

  Future<
    void
  >
  saveTrainingPlan({
    required int weeklyGoal,
    required List<
      int
    >
    plannedWeekdays,
  }) async {
    final user = _requireUser();

    final normalizedWeekdays =
        plannedWeekdays
            .where(
              (
                weekday,
              ) {
                return weekday >=
                        DateTime.monday &&
                    weekday <=
                        DateTime.sunday;
              },
            )
            .toSet()
            .toList()
          ..sort();

    if (normalizedWeekdays.isEmpty) {
      throw ArgumentError(
        'Selecione pelo menos um dia da semana.',
      );
    }

    if (weeklyGoal <=
        0) {
      throw ArgumentError.value(
        weeklyGoal,
        'weeklyGoal',
        'A meta semanal deve ser maior que zero.',
      );
    }

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================
    //
    // Mantemos o weeklyGoal informado pelo usuário.
    //
    // No código antigo ele era ignorado e substituído por:
    //
    // normalizedWeekdays.length
    //
    // ==========================================================

    await StorageService.saveTrainingPlan(
      weeklyGoal: weeklyGoal,
      plannedWeekdays: normalizedWeekdays,
    );

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _trainingPlanEntityId(
      user.id,
    );

    await queue.enqueue(
      entityType: _planEntityType,
      entityId: entityId,
      operation: SyncOperation.update,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'weekly_goal': weeklyGoal,
        'planned_weekdays': normalizedWeekdays,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // LIMPAR PLANO SEMANAL
  // ============================================================

  Future<
    void
  >
  clearTrainingPlan() async {
    final user = _requireUser();

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await StorageService.clearTrainingPlan();

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _trainingPlanEntityId(
      user.id,
    );

    await queue.enqueue(
      entityType: _planEntityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      payload: {
        'id': entityId,
        'user_id': user.id,
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // LIMPAR TREINOS
  // ============================================================
  //
  // StorageService é limpo imediatamente.
  //
  // Para sincronização remota usamos uma operação especial por
  // usuário, pois clear() representa exclusão em lote.
  //
  // ============================================================

  Future<
    void
  >
  clear() async {
    final user = _requireUser();

    await StorageService.clearTraining();

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _trainingClearEntityId(
      user.id,
    );

    await queue.enqueue(
      entityType: _trainingEntityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'delete_scope': 'all',
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // RESET COMPLETO
  // ============================================================

  Future<
    void
  >
  clearAll() async {
    final user = _requireUser();

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await StorageService.clearTraining();

    await StorageService.clearTrainingPlan();

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    await queue.enqueue(
      entityType: _trainingEntityType,
      entityId: _trainingClearEntityId(
        user.id,
      ),
      operation: SyncOperation.delete,
      payload: {
        'user_id': user.id,
        'delete_scope': 'all',
      },
    );

    await queue.enqueue(
      entityType: _planEntityType,
      entityId: _trainingPlanEntityId(
        user.id,
      ),
      operation: SyncOperation.delete,
      payload: {
        'user_id': user.id,
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // HAS TRAINING DATA
  // ============================================================

  Future<
    bool
  >
  hasTrainingData() async {
    final data = await load();

    return data.isNotEmpty;
  }

  // ============================================================
  // HAS TRAINING PLAN
  // ============================================================

  Future<
    bool
  >
  hasTrainingPlan() async {
    final plan = await loadTrainingPlan();

    return plan !=
        null;
  }

  // ============================================================
  // NORMALIZE REQUIRED
  // ============================================================

  String _normalizeRequired(
    String value, {
    required String fieldName,
    required String message,
  }) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        message,
      );
    }

    return normalized;
  }

  // ============================================================
  // TRAINING ENTITY ID
  // ============================================================
  //
  // Um treino precisa de um ID local determinístico.
  //
  // Incluímos a data para não misturar duas semanas que usem o
  // mesmo nome de dia.
  //
  // ============================================================

  String _trainingEntityId({
    required String userId,
    required String day,
    required String training,
    required DateTime date,
  }) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    return 'training_'
        '${_safeId(userId)}_'
        '${_safeId(day)}_'
        '${_safeId(training)}_'
        '$dateKey';
  }

  // ============================================================
  // TRAINING PLAN ENTITY ID
  // ============================================================

  String _trainingPlanEntityId(
    String userId,
  ) {
    return 'training_plan_'
        '${_safeId(userId)}';
  }

  // ============================================================
  // TRAINING CLEAR ENTITY ID
  // ============================================================

  String _trainingClearEntityId(
    String userId,
  ) {
    return 'training_clear_'
        '${_safeId(userId)}';
  }

  // ============================================================
  // SAFE ID
  // ============================================================

  String _safeId(
    String value,
  ) {
    return value.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );
  }
}

// ============================================================
// STORED TRAINING RECORD
// ============================================================

class _StoredTrainingRecord {
  const _StoredTrainingRecord({
    required this.day,
    required this.training,
    required this.minutes,
    required this.date,
  });

  final String day;

  final String training;

  final int minutes;

  final DateTime date;
}
