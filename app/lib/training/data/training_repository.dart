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
    required DateTime date,
  }) {
    final dateKey =
        '${date.year.toString().padLeft(4, '0')}'
        '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';

    return 'training_'
        '${_safeId(userId)}_'
        '${_safeId(day)}_'
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
