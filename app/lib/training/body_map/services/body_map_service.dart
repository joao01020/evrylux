import '../../models/training_activity_type.dart';
import '../data/body_map_repository.dart';
import '../models/body_region.dart';
import '../models/body_region_schedule.dart';

// ============================================================
// BODY MAP SERVICE
// ============================================================
//
// Responsável pelas regras de negócio do planejamento corporal.
//
// Fluxo:
//
// UI
//   ↓
// BodyMapController
//   ↓
// BodyMapService
//   ↓
// BodyMapRepository
//
// A fonte principal agora é:
//
// TrainingActivityType
//
// Isso permite trabalhar com:
//
// - Peito
// - Pernas
// - Braço
// - Costas
// - Ombro
// - Core
// - Corrida
// - Caminhada
//
// BodyRegion continua existindo somente como camada visual do
// boneco frontal.
//
// ============================================================

class BodyMapService {
  BodyMapService({
    required BodyMapRepository repository,
  }) : _repository = repository;

  // ============================================================
  // DEPENDENCY
  // ============================================================

  final BodyMapRepository _repository;

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadAll() async {
    final schedules = await _repository.loadAll();

    return _normalizeSchedules(
      schedules,
    );
  }

  // ============================================================
  // LOAD ACTIVITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  loadActivity(
    TrainingActivityType activity,
  ) async {
    final schedule = await _repository.getByActivity(
      activity,
    );

    if (schedule ==
        null) {
      return null;
    }

    return _normalizeSchedule(
      schedule,
    );
  }

  // ============================================================
  // LOAD REGION - COMPATIBILITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  loadRegion(
    BodyRegion region,
  ) {
    return loadActivity(
      region.activity,
    );
  }

  // ============================================================
  // SAVE ACTIVITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  saveActivity({
    required TrainingActivityType activity,
    required Iterable<
      int
    >
    weekdays,
  }) async {
    final normalizedDays = _normalizeWeekdays(
      weekdays,
    );

    if (normalizedDays.isEmpty) {
      await _repository.deleteActivity(
        activity,
      );

      return null;
    }

    final schedule = BodyRegionSchedule(
      activity: activity,
      weekdays: normalizedDays,
    );

    final saved = await _repository.save(
      schedule,
    );

    if (saved ==
        null) {
      return null;
    }

    return _normalizeSchedule(
      saved,
    );
  }

  // ============================================================
  // SAVE REGION - COMPATIBILITY
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  saveRegion({
    required BodyRegion region,
    required Iterable<
      int
    >
    weekdays,
  }) {
    return saveActivity(
      activity: region.activity,
      weekdays: weekdays,
    );
  }

  // ============================================================
  // SAVE SCHEDULE
  // ============================================================

  Future<
    BodyRegionSchedule?
  >
  saveSchedule(
    BodyRegionSchedule schedule,
  ) {
    return saveActivity(
      activity: schedule.activity,
      weekdays: schedule.weekdays,
    );
  }

  // ============================================================
  // SAVE ALL
  // ============================================================
  //
  // Atualiza somente as atividades recebidas.
  //
  // Não apaga as outras já existentes.
  //
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
    final normalized = _normalizeSchedules(
      schedules,
    );

    await _repository.saveAll(
      normalized,
    );

    return loadAll();
  }

  // ============================================================
  // REPLACE PLAN
  // ============================================================
  //
  // Substitui todo o plano semanal.
  //
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  replacePlan(
    Iterable<
      BodyRegionSchedule
    >
    schedules,
  ) async {
    final normalized = _normalizeSchedules(
      schedules,
    );

    await _repository.replaceAll(
      normalized,
    );

    return loadAll();
  }

  // ============================================================
  // REMOVE ACTIVITY
  // ============================================================

  Future<
    bool
  >
  removeActivity(
    TrainingActivityType activity,
  ) {
    return _repository.deleteActivity(
      activity,
    );
  }

  // ============================================================
  // REMOVE REGION - COMPATIBILITY
  // ============================================================

  Future<
    bool
  >
  removeRegion(
    BodyRegion region,
  ) {
    return removeActivity(
      region.activity,
    );
  }

  // ============================================================
  // CLEAR PLAN
  // ============================================================

  Future<
    void
  >
  clearPlan() {
    return _repository.clear();
  }

  // ============================================================
  // HAS ACTIVITY
  // ============================================================

  Future<
    bool
  >
  hasActivity(
    TrainingActivityType activity,
  ) {
    return _repository.existsActivity(
      activity,
    );
  }

  // ============================================================
  // HAS REGION - COMPATIBILITY
  // ============================================================

  Future<
    bool
  >
  hasRegion(
    BodyRegion region,
  ) {
    return hasActivity(
      region.activity,
    );
  }

  // ============================================================
  // CONFIGURED COUNT
  // ============================================================

  Future<
    int
  >
  configuredCount() {
    return _repository.count();
  }

  // ============================================================
  // HAS DATA
  // ============================================================

  Future<
    bool
  >
  get hasData => _repository.hasData;

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

    final schedules = await _repository.loadForWeekday(
      weekday,
    );

    return _normalizeSchedules(
      schedules,
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
  //
  // Este método será usado no modal "Registrar treino".
  //
  // Exemplo:
  //
  // segunda-feira
  //
  // ->
  //
  // {
  //   chest,
  //   arms,
  //   core
  // }
  //
  // ============================================================

  Future<
    Set<
      TrainingActivityType
    >
  >
  activitiesForWeekday(
    int weekday,
  ) async {
    _validateWeekday(
      weekday,
    );

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
  // ACTIVITIES FOR TODAY
  // ============================================================

  Future<
    Set<
      TrainingActivityType
    >
  >
  activitiesForToday() {
    return activitiesForWeekday(
      DateTime.now().weekday,
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

    final schedule = await _repository.addWeekdayToActivity(
      activity: activity,
      weekday: weekday,
    );

    return _normalizeSchedule(
      schedule,
    );
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

    final schedule = await _repository.removeWeekdayFromActivity(
      activity: activity,
      weekday: weekday,
    );

    if (schedule ==
        null) {
      return null;
    }

    return _normalizeSchedule(
      schedule,
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
  // BODY ACTIVITIES
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadBodyActivities() async {
    final schedules = await _repository.loadBodyActivities();

    return _normalizeSchedules(
      schedules,
    );
  }

  // ============================================================
  // CARDIO ACTIVITIES
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadCardioActivities() async {
    final schedules = await _repository.loadCardioActivities();

    return _normalizeSchedules(
      schedules,
    );
  }

  // ============================================================
  // EXPORT PLAN
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  exportPlan() async {
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
  // IMPORT PLAN
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  importPlan(
    Iterable<
      dynamic
    >
    values,
  ) async {
    final schedules =
        <
          BodyRegionSchedule
        >[];

    for (final raw in values) {
      if (raw
          is! Map) {
        continue;
      }

      try {
        final map =
            Map<
              String,
              dynamic
            >.from(
              raw,
            );

        final schedule = BodyRegionSchedule.fromMap(
          map,
        );

        final normalized = _normalizeSchedule(
          schedule,
        );

        if (normalized.weekdays.isEmpty) {
          continue;
        }

        schedules.add(
          normalized,
        );
      } catch (
        _
      ) {
        // Registro inválido é ignorado.
      }
    }

    return replacePlan(
      schedules,
    );
  }

  // ============================================================
  // LOAD FOR MULTIPLE WEEKDAYS
  // ============================================================

  Future<
    List<
      BodyRegionSchedule
    >
  >
  loadForWeekdays(
    Iterable<
      int
    >
    weekdays,
  ) async {
    final normalizedDays = _normalizeWeekdays(
      weekdays,
    );

    if (normalizedDays.isEmpty) {
      return const <
        BodyRegionSchedule
      >[];
    }

    final all = await loadAll();

    final result = all.where(
      (
        schedule,
      ) {
        for (final weekday in normalizedDays) {
          if (schedule.weekdays.contains(
            weekday,
          )) {
            return true;
          }
        }

        return false;
      },
    ).toList();

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
  // WEEK SUMMARY
  // ============================================================
  //
  // Retorna:
  //
  // 1 -> [chest, arms]
  // 2 -> [legs]
  // ...
  //
  // ============================================================

  Future<
    Map<
      int,
      List<
        TrainingActivityType
      >
    >
  >
  buildWeekSummary() async {
    final schedules = await loadAll();

    final result =
        <
          int,
          List<
            TrainingActivityType
          >
        >{
          DateTime.monday:
              <
                TrainingActivityType
              >[],
          DateTime.tuesday:
              <
                TrainingActivityType
              >[],
          DateTime.wednesday:
              <
                TrainingActivityType
              >[],
          DateTime.thursday:
              <
                TrainingActivityType
              >[],
          DateTime.friday:
              <
                TrainingActivityType
              >[],
          DateTime.saturday:
              <
                TrainingActivityType
              >[],
          DateTime.sunday:
              <
                TrainingActivityType
              >[],
        };

    for (final schedule in schedules) {
      for (final weekday in schedule.weekdays) {
        result[weekday]?.add(
          schedule.activity,
        );
      }
    }

    for (final activities in result.values) {
      activities.sort(
        (
          first,
          second,
        ) {
          return first.order.compareTo(
            second.order,
          );
        },
      );
    }

    return Map<
      int,
      List<
        TrainingActivityType
      >
    >.unmodifiable(
      result.map(
        (
          key,
          value,
        ) {
          return MapEntry(
            key,
            List<
              TrainingActivityType
            >.unmodifiable(
              value,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // WEEK SUMMARY LABELS
  // ============================================================

  Future<
    Map<
      int,
      List<
        String
      >
    >
  >
  buildWeekSummaryLabels() async {
    final summary = await buildWeekSummary();

    return Map<
      int,
      List<
        String
      >
    >.unmodifiable(
      summary.map(
        (
          weekday,
          activities,
        ) {
          return MapEntry(
            weekday,
            List<
              String
            >.unmodifiable(
              activities.map(
                (
                  activity,
                ) => activity.label,
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // NORMALIZE SCHEDULES
  // ============================================================

  List<
    BodyRegionSchedule
  >
  _normalizeSchedules(
    Iterable<
      BodyRegionSchedule
    >
    schedules,
  ) {
    final byActivity =
        <
          TrainingActivityType,
          BodyRegionSchedule
        >{};

    for (final schedule in schedules) {
      final normalized = _normalizeSchedule(
        schedule,
      );

      if (normalized.weekdays.isEmpty) {
        continue;
      }

      byActivity[normalized.activity] = normalized;
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
  // NORMALIZE SCHEDULE
  // ============================================================

  BodyRegionSchedule _normalizeSchedule(
    BodyRegionSchedule schedule,
  ) {
    return BodyRegionSchedule(
      activity: schedule.activity,
      weekdays: _normalizeWeekdays(
        schedule.weekdays,
      ),
    );
  }

  // ============================================================
  // NORMALIZE WEEKDAYS
  // ============================================================

  Set<
    int
  >
  _normalizeWeekdays(
    Iterable<
      int
    >
    weekdays,
  ) {
    final normalized =
        <
          int
        >{};

    for (final weekday in weekdays) {
      if (weekday <
              DateTime.monday ||
          weekday >
              DateTime.sunday) {
        continue;
      }

      normalized.add(
        weekday,
      );
    }

    return normalized;
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
            '${DateTime.monday} e ${DateTime.sunday}.',
      );
    }
  }
}
