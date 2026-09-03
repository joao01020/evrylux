import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/daos/training_activity_plan_dao.dart';
import '../../../core/database/tables/training_activity_plan_table.dart';
import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_status.dart';

import '../../models/training_activity_type.dart';
import '../models/body_region.dart';
import '../models/body_region_schedule.dart';

// ============================================================
// BODY MAP REPOSITORY
// ============================================================
//
// Repository offline-first do planejamento corporal.
//
// Fluxo:
//
// BodyMapController
//        ↓
// BodyMapService
//        ↓
// BodyMapRepository
//        ↓
// TrainingActivityPlanDao
//        ↓
// SQLite
//        ↓
// SyncQueue
//        ↓
// SyncService
//        ↓
// Supabase
//
// Fonte de verdade funcional:
//
// TrainingActivityType
//
// O BodyRegion continua existindo somente para representar
// regiões visuais do boneco.
//
// ============================================================

class BodyMapRepository {
  BodyMapRepository({
    SupabaseClient? client,
    TrainingActivityPlanDao? localDao,
    required SyncQueue syncQueue,
    SyncService? syncService,
    Iterable<
          BodyRegionSchedule
        >
        initialSchedules =
        const <
          BodyRegionSchedule
        >[],
  }) : _client =
           client ??
           Supabase.instance.client,
       _localDao =
           localDao ??
           TrainingActivityPlanDao(),
       _syncQueue = syncQueue,
       _syncService = syncService,
       _initialSchedules =
           List<
             BodyRegionSchedule
           >.unmodifiable(
             initialSchedules,
           );

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final TrainingActivityPlanDao _localDao;

  final SyncQueue _syncQueue;

  final SyncService? _syncService;

  final List<
    BodyRegionSchedule
  >
  _initialSchedules;

  // ============================================================
  // CONFIG
  // ============================================================

  static const String entityType = 'training_activity_plan';

  static const String remoteTable = 'training_activity_plans';

  // ============================================================
  // SEED STATE
  // ============================================================

  final Set<
    String
  >
  _seededUsers =
      <
        String
      >{};

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
  //
  // Sempre lê primeiro do SQLite.
  //
  // Portanto o plano continua disponível sem internet.
  //
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadAll() async {
    final user = _requireUser();

    await _ensureInitialSeed(
      user.id,
    );

    final rows = await _localDao.getAll(
      userId: user.id,
    );

    return _rowsToSchedules(
      rows,
    );
  }

  // ============================================================
  // REFRESH FROM REMOTE
  // ============================================================
  //
  // Atualiza o cache local com dados do Supabase.
  //
  // IMPORTANTE:
  //
  // Se a atividade possui uma alteração pendente na SyncQueue,
  // o dado remoto NÃO sobrescreve a alteração local.
  //
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  refreshFromRemote() async {
    final user = _requireUser();

    final response = await _client
        .from(
          remoteTable,
        )
        .select(
          'activity, weekdays, created_at, updated_at',
        )
        .eq(
          'user_id',
          user.id,
        );

    final remoteRows =
        response
            is List
        ? response
        : const <
            dynamic
          >[];

    final remoteActivities =
        <
          String
        >{};

    for (final raw in remoteRows) {
      if (raw
          is! Map) {
        continue;
      }

      final map =
          Map<
            String,
            dynamic
          >.from(
            raw,
          );

      final activity = TrainingActivityTypeExtension.fromAny(
        map['activity']?.toString(),
      );

      if (activity ==
          null) {
        continue;
      }

      remoteActivities.add(
        activity.id,
      );

      final entityId = TrainingActivityPlanTable.buildLocalId(
        userId: user.id,
        activity: activity.id,
      );

      final pending = await _syncQueue.findByEntity(
        entityType: entityType,
        entityId: entityId,
      );

      if (pending !=
          null) {
        continue;
      }

      final weekdays = _parseWeekdays(
        map['weekdays'],
      );

      await _localDao.upsert(
        id: entityId,
        userId: user.id,
        activity: activity.id,
        weekdays: weekdays,
        syncStatus: SyncStatus.synced,
        deleted: false,
        createdAt: _tryParseDate(
          map['created_at'],
        ),
        updatedAt: _tryParseDate(
          map['updated_at'],
        ),
      );
    }

    // ==========================================================
    // REMOTE DELETIONS
    // ==========================================================
    //
    // Linhas locais sincronizadas que não existem mais no remoto
    // são removidas definitivamente.
    //
    // Linhas pendentes nunca são apagadas aqui.
    //
    // ==========================================================

    final localRows = await _localDao.getAll(
      userId: user.id,
      includeDeleted: true,
    );

    for (final row in localRows) {
      final activityId = row[TrainingActivityPlanTable.activity]?.toString().trim().toLowerCase();

      final localId = row[TrainingActivityPlanTable.id]?.toString();

      if (activityId ==
              null ||
          activityId.isEmpty ||
          localId ==
              null ||
          localId.isEmpty) {
        continue;
      }

      if (remoteActivities.contains(
        activityId,
      )) {
        continue;
      }

      final status = SyncStatus.fromValue(
        row[TrainingActivityPlanTable.syncStatus]?.toString(),
      );

      if (status !=
          SyncStatus.synced) {
        continue;
      }

      final pending = await _syncQueue.findByEntity(
        entityType: entityType,
        entityId: localId,
      );

      if (pending !=
          null) {
        continue;
      }

      await _localDao.deletePermanently(
        localId,
      );
    }

    return loadAll();
  }

  // ============================================================
  // GET BY ACTIVITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  getByActivity(
    TrainingActivityType activity,
  ) async {
    final user = _requireUser();

    final row = await _localDao.getByActivity(
      userId: user.id,
      activity: activity.id,
    );

    if (row ==
        null) {
      return null;
    }

    return _rowToSchedule(
      row,
    );
  }

  // ============================================================
  // GET BY REGION - COMPATIBILITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  getByRegion(
    BodyRegion region,
  ) {
    return getByActivity(
      region.activity,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================
  //
  // OFFLINE-FIRST:
  //
  // 1. salva primeiro no SQLite;
  // 2. adiciona operação na SyncQueue;
  // 3. pede sincronização;
  // 4. retorna imediatamente o valor local.
  //
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  save(
    BodyRegionSchedule schedule,
  ) async {
    final user = _requireUser();

    final normalized = _normalizeSchedule(
      schedule,
    );

    if (normalized.weekdays.isEmpty) {
      await deleteActivity(
        normalized.activity,
      );

      return null;
    }

    final existing = await _localDao.getByActivity(
      userId: user.id,
      activity: normalized.activity.id,
      includeDeleted: true,
    );

    final operation =
        existing ==
            null
        ? SyncOperation.create
        : SyncOperation.update;

    final syncStatus =
        operation ==
            SyncOperation.create
        ? SyncStatus.pendingCreate
        : SyncStatus.pendingUpdate;

    final now = DateTime.now().toUtc();

    final localId = await _localDao.upsert(
      id: existing?[TrainingActivityPlanTable.id]?.toString(),
      userId: user.id,
      activity: normalized.activity.id,
      weekdays: normalized.weekdays,
      syncStatus: syncStatus,
      deleted: false,
      createdAt: _tryParseDate(
        existing?[TrainingActivityPlanTable.createdAt],
      ),
      updatedAt: now,
    );

    final payload =
        <
          String,
          dynamic
        >{
          'user_id': user.id,
          'activity': normalized.activity.id,
          'weekdays': normalized.orderedWeekdays,
          'updated_at': now.toIso8601String(),
        };

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: localId,
      operation: operation,
      payload: payload,
    );

    _syncService?.requestSync();

    debugPrint(
      '[BODY MAP] '
      '${normalized.activity.id} salvo localmente '
      '(${operation.value}).',
    );

    return BodyRegionSchedule(
      activity: normalized.activity,
      weekdays:
          Set<
            int
          >.from(
            normalized.weekdays,
          ),
    );
  }

  // ============================================================
  // SAVE MANY
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  saveAll(
    Iterable<
      BodyRegionSchedule
    >
    schedules,
  ) async {
    for (final schedule in schedules) {
      await save(
        schedule,
      );
    }

    return loadAll();
  }

  // ============================================================
  // REPLACE ALL
  // ============================================================
  //
  // Faz diff entre o plano atual e o novo.
  //
  // Atividades removidas entram como DELETE.
  // Atividades novas/alteradas entram como CREATE/UPDATE.
  //
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  replaceAll(
    Iterable<
      BodyRegionSchedule
    >
    schedules,
  ) async {
    final normalized =
        <
          TrainingActivityType,
          BodyRegionSchedule
        >{};

    for (final schedule in schedules) {
      final value = _normalizeSchedule(
        schedule,
      );

      if (value.weekdays.isEmpty) {
        continue;
      }

      normalized[value.activity] = value;
    }

    final current = await loadAll();

    final currentActivities = current
        .map(
          (
            schedule,
          ) => schedule.activity,
        )
        .toSet();

    final nextActivities = normalized.keys.toSet();

    final removed = currentActivities.difference(
      nextActivities,
    );

    for (final activity in removed) {
      await deleteActivity(
        activity,
      );
    }

    for (final schedule in normalized.values) {
      final existing = current.where(
        (
          item,
        ) =>
            item.activity ==
            schedule.activity,
      );

      if (existing.isNotEmpty &&
          _sameWeekdays(
            existing.first.weekdays,
            schedule.weekdays,
          )) {
        continue;
      }

      await save(
        schedule,
      );
    }

    return loadAll();
  }

  // ============================================================
  // DELETE ACTIVITY
  // ============================================================

  Future<
    bool
  >
  deleteActivity(
    TrainingActivityType activity,
  ) async {
    final user = _requireUser();

    final existing = await _localDao.getByActivity(
      userId: user.id,
      activity: activity.id,
      includeDeleted: true,
    );

    if (existing ==
        null) {
      return false;
    }

    final localId = existing[TrainingActivityPlanTable.id]?.toString();

    if (localId ==
            null ||
        localId.isEmpty) {
      return false;
    }

    final currentStatus = SyncStatus.fromValue(
      existing[TrainingActivityPlanTable.syncStatus]?.toString(),
    );

    final payload =
        <
          String,
          dynamic
        >{
          'user_id': user.id,
          'activity': activity.id,
          'delete_scope': 'activity',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        };

    // ==========================================================
    // LOCAL-ONLY CREATE
    // ==========================================================
    //
    // Se nunca chegou ao Supabase, create + delete se cancelam.
    //
    // ==========================================================

    if (currentStatus ==
        SyncStatus.pendingCreate) {
      await _syncQueue.enqueue(
        entityType: entityType,
        entityId: localId,
        operation: SyncOperation.delete,
        payload: payload,
      );

      await _localDao.deletePermanently(
        localId,
      );

      _syncService?.requestSync();

      return true;
    }

    // ==========================================================
    // SOFT DELETE
    // ==========================================================

    await _localDao.markDeleted(
      userId: user.id,
      activity: activity.id,
      syncStatus: SyncStatus.pendingDelete,
    );

    await _syncQueue.enqueue(
      entityType: entityType,
      entityId: localId,
      operation: SyncOperation.delete,
      payload: payload,
    );

    _syncService?.requestSync();

    return true;
  }

  // ============================================================
  // DELETE REGION - COMPATIBILITY
  // ============================================================

  Future<
    bool
  >
  delete(
    BodyRegion region,
  ) {
    return deleteActivity(
      region.activity,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    final schedules = await loadAll();

    for (final schedule in schedules) {
      await deleteActivity(
        schedule.activity,
      );
    }
  }

  // ============================================================
  // EXISTS ACTIVITY
  // ============================================================

  Future<
    bool
  >
  existsActivity(
    TrainingActivityType activity,
  ) async {
    final user = _requireUser();

    return _localDao.exists(
      userId: user.id,
      activity: activity.id,
    );
  }

  // ============================================================
  // EXISTS REGION - COMPATIBILITY
  // ============================================================

  Future<
    bool
  >
  exists(
    BodyRegion region,
  ) {
    return existsActivity(
      region.activity,
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    final user = _requireUser();

    return _localDao.count(
      userId: user.id,
    );
  }

  // ============================================================
  // HAS DATA
  // ============================================================

  Future<
    bool
  >
  get hasData async {
    return await count() >
        0;
  }

  // ============================================================
  // LOAD FOR WEEKDAY
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadForWeekday(
    int weekday,
  ) async {
    _validateWeekday(
      weekday,
    );

    final user = _requireUser();

    final rows = await _localDao.getForWeekday(
      userId: user.id,
      weekday: weekday,
    );

    return _rowsToSchedules(
      rows,
    );
  }

  // ============================================================
  // LOAD FOR TODAY
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadForToday() {
    return loadForWeekday(
      DateTime.now().weekday,
    );
  }

  // ============================================================
  // ACTIVITIES FOR WEEKDAY
  // ============================================================

  Future<
    Set<
      TrainingActivityType
    >
  >
  activitiesForWeekday(
    int weekday,
  ) async {
    final schedules = await loadForWeekday(
      weekday,
    );

    return Set<
      TrainingActivityType
    >.unmodifiable(
      schedules.map(
        (
          schedule,
        ) => schedule.activity,
      ),
    );
  }

  // ============================================================
  // ADD WEEKDAY TO ACTIVITY
  // ============================================================

  Future<
    BodyRegionSchedule
  >
  addWeekdayToActivity({
    required TrainingActivityType activity,
    required int weekday,
  }) async {
    _validateWeekday(
      weekday,
    );

    final existing = await getByActivity(
      activity,
    );

    final weekdays =
        <
          int
        >{
          ...?existing?.weekdays,
          weekday,
        };

    final saved = await save(
      BodyRegionSchedule(
        activity: activity,
        weekdays: weekdays,
      ),
    );

    if (saved ==
        null) {
      throw StateError(
        'Não foi possível salvar a atividade ${activity.id}.',
      );
    }

    return saved;
  }

  // ============================================================
  // ADD WEEKDAY - REGION COMPATIBILITY
  // ============================================================

  Future<
    BodyRegionSchedule
  >
  addWeekday({
    required BodyRegion region,
    required int weekday,
  }) {
    return addWeekdayToActivity(
      activity: region.activity,
      weekday: weekday,
    );
  }

  // ============================================================
  // REMOVE WEEKDAY FROM ACTIVITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  removeWeekdayFromActivity({
    required TrainingActivityType activity,
    required int weekday,
  }) async {
    _validateWeekday(
      weekday,
    );

    final existing = await getByActivity(
      activity,
    );

    if (existing ==
        null) {
      return null;
    }

    final weekdays =
        Set<
          int
        >.from(
          existing.weekdays,
        );

    weekdays.remove(
      weekday,
    );

    if (weekdays.isEmpty) {
      await deleteActivity(
        activity,
      );

      return null;
    }

    return save(
      BodyRegionSchedule(
        activity: activity,
        weekdays: weekdays,
      ),
    );
  }

  // ============================================================
  // REMOVE WEEKDAY - REGION COMPATIBILITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  removeWeekday({
    required BodyRegion region,
    required int weekday,
  }) {
    return removeWeekdayFromActivity(
      activity: region.activity,
      weekday: weekday,
    );
  }

  // ============================================================
  // LOAD BODY ACTIVITIES
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadBodyActivities() async {
    final all = await loadAll();

    return List<
      BodyRegionSchedule
    >.unmodifiable(
      all.where(
        (
          schedule,
        ) => schedule.activity.isBodyRegion,
      ),
    );
  }

  // ============================================================
  // LOAD CARDIO ACTIVITIES
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadCardioActivities() async {
    final all = await loadAll();

    return List<
      BodyRegionSchedule
    >.unmodifiable(
      all.where(
        (
          schedule,
        ) => schedule.activity.isCardio,
      ),
    );
  }

  // ============================================================
  // TO MAP LIST
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  toMapList() async {
    final schedules = await loadAll();

    return schedules
        .map(
          (
            schedule,
          ) => schedule.toMap(),
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // IMPORT MAP LIST
  // ============================================================

  Future<
    void
  >
  loadFromMapList(
    Iterable<
      dynamic
    >
    rawValues,
  ) async {
    final schedules =
        <
          BodyRegionSchedule
        >[];

    for (final raw in rawValues) {
      if (raw
          is! Map) {
        continue;
      }

      try {
        final schedule = BodyRegionSchedule.fromMap(
          Map<
            String,
            dynamic
          >.from(
            raw,
          ),
        );

        if (schedule.weekdays.isEmpty) {
          continue;
        }

        schedules.add(
          schedule,
        );
      } catch (
        _
      ) {
        // Registro inválido é ignorado.
      }
    }

    await replaceAll(
      schedules,
    );
  }

  // ============================================================
  // MARK SYNCED
  // ============================================================
  //
  // Chamado pelo SyncHandler depois do sucesso remoto.
  //
  // ============================================================

  Future<
    void
  >
  markSynced(
    String entityId,
  ) {
    return _localDao.setSyncStatus(
      entityId,
      SyncStatus.synced,
    );
  }

  // ============================================================
  // DELETE LOCAL PERMANENTLY
  // ============================================================
  //
  // Chamado pelo SyncHandler depois do DELETE remoto.
  //
  // ============================================================

  Future<
    void
  >
  deleteLocalPermanently(
    String entityId,
  ) {
    return _localDao.deletePermanently(
      entityId,
    );
  }

  // ============================================================
  // INITIAL SEED
  // ============================================================

  Future<
    void
  >
  _ensureInitialSeed(
    String userId,
  ) async {
    if (_seededUsers.contains(
      userId,
    )) {
      return;
    }

    _seededUsers.add(
      userId,
    );

    if (_initialSchedules.isEmpty) {
      return;
    }

    final currentCount = await _localDao.count(
      userId: userId,
    );

    if (currentCount >
        0) {
      return;
    }

    for (final schedule in _initialSchedules) {
      if (schedule.weekdays.isEmpty) {
        continue;
      }

      await save(
        schedule,
      );
    }
  }

  // ============================================================
  // ROWS TO SCHEDULES
  // ============================================================

  List<
    BodyRegionSchedule
  >
  _rowsToSchedules(
    Iterable<
      Map<
        String,
        dynamic
      >
    >
    rows,
  ) {
    final byActivity =
        <
          TrainingActivityType,
          BodyRegionSchedule
        >{};

    for (final row in rows) {
      final schedule = _rowToSchedule(
        row,
      );

      if (schedule ==
              null ||
          schedule.weekdays.isEmpty) {
        continue;
      }

      byActivity[schedule.activity] = schedule;
    }

    final result = byActivity.values.toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.activity.order.compareTo(
          second.activity.order,
        );
      },
    );

    return List<
      BodyRegionSchedule
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // ROW TO SCHEDULE
  // ============================================================

  BodyRegionSchedule? _rowToSchedule(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    final activity = TrainingActivityTypeExtension.fromAny(
      row[TrainingActivityPlanTable.activity]?.toString(),
    );

    if (activity ==
        null) {
      return null;
    }

    final weekdays = _parseWeekdays(
      row['weekdays'] ??
          row[TrainingActivityPlanTable.weekdaysJson],
    );

    return BodyRegionSchedule(
      activity: activity,
      weekdays: weekdays,
    );
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  BodyRegionSchedule _normalizeSchedule(
    BodyRegionSchedule schedule,
  ) {
    final weekdays =
        <
          int
        >{};

    for (final weekday in schedule.weekdays) {
      if (weekday <
              DateTime.monday ||
          weekday >
              DateTime.sunday) {
        continue;
      }

      weekdays.add(
        weekday,
      );
    }

    return BodyRegionSchedule(
      activity: schedule.activity,
      weekdays: weekdays,
    );
  }

  // ============================================================
  // PARSE WEEKDAYS
  // ============================================================

  Set<
    int
  >
  _parseWeekdays(
    dynamic raw,
  ) {
    if (raw
        is Set<
          int
        >) {
      return Set<
        int
      >.from(
        raw.where(
          (
            day,
          ) =>
              day >=
                  DateTime.monday &&
              day <=
                  DateTime.sunday,
        ),
      );
    }

    if (raw
        is Iterable) {
      final result =
          <
            int
          >{};

      for (final value in raw) {
        final day =
            value
                is int
            ? value
            : int.tryParse(
                value.toString(),
              );

        if (day ==
                null ||
            day <
                DateTime.monday ||
            day >
                DateTime.sunday) {
          continue;
        }

        result.add(
          day,
        );
      }

      return result;
    }

    return TrainingActivityPlanDao.decodeWeekdays(
      raw,
    );
  }

  // ============================================================
  // SAME WEEKDAYS
  // ============================================================

  bool _sameWeekdays(
    Set<
      int
    >
    first,
    Set<
      int
    >
    second,
  ) {
    if (first.length !=
        second.length) {
      return false;
    }

    for (final value in first) {
      if (!second.contains(
        value,
      )) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime? _tryParseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    )?.toUtc();
  }

  // ============================================================
  // VALIDATE WEEKDAY
  // ============================================================

  void _validateWeekday(
    int weekday,
  ) {
    if (weekday <
            DateTime.monday ||
        weekday >
            DateTime.sunday) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'O dia da semana deve estar entre '
            '${DateTime.monday} e '
            '${DateTime.sunday}.',
      );
    }
  }
}
