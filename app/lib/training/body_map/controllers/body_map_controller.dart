import 'package:flutter/foundation.dart';

import '../../models/training_activity_type.dart';
import '../models/body_region.dart';
import '../models/body_region_schedule.dart';

// ============================================================
// BODY MAP CONTROLLER
// ============================================================
//
// Controla:
//
// - hover visual no boneco;
// - região visual selecionada;
// - atividade selecionada;
// - dias temporários;
// - múltiplas atividades configuradas;
// - salvar configuração;
// - remover configuração;
// - carregar/importar planejamento.
//
// IMPORTANTE:
//
// O mapa visual continua usando:
//
// BodyRegion
//
// Já o planejamento usa:
//
// TrainingActivityType
//
// Exemplo:
//
// BodyRegion.abdomen
//        ↓
// TrainingActivityType.core
//
// BodyRegion.quadriceps
// BodyRegion.calves
//        ↓
// TrainingActivityType.legs
//
// Isso permite que várias regiões visuais representem a mesma
// atividade de treino.
//
// ============================================================

class BodyMapController
    extends
        ChangeNotifier {
  BodyMapController({
    Iterable<
          BodyRegionSchedule
        >
        initialSchedules =
        const <
          BodyRegionSchedule
        >[],
  }) {
    loadSchedules(
      initialSchedules,
      notify: false,
    );
  }

  // ============================================================
  // STATE - MAPA VISUAL
  // ============================================================

  BodyRegion? _hoveredRegion;

  BodyRegion? _selectedRegion;

  // ============================================================
  // STATE - ATIVIDADE
  // ============================================================

  TrainingActivityType? _selectedActivity;

  final Map<
    TrainingActivityType,
    BodyRegionSchedule
  >
  _schedules =
      <
        TrainingActivityType,
        BodyRegionSchedule
      >{};

  final Set<
    int
  >
  _draftWeekdays =
      <
        int
      >{};

  // ============================================================
  // GETTERS - HOVER
  // ============================================================

  BodyRegion? get hoveredRegion => _hoveredRegion;

  // ============================================================
  // GETTERS - SELEÇÃO
  // ============================================================

  BodyRegion? get selectedRegion => _selectedRegion;

  TrainingActivityType? get selectedActivity => _selectedActivity;

  bool get hasSelection =>
      _selectedActivity !=
      null;

  // ============================================================
  // GETTERS - DRAFT
  // ============================================================

  Set<
    int
  >
  get draftWeekdays =>
      Set<
        int
      >.unmodifiable(
        _draftWeekdays,
      );

  // ============================================================
  // GETTERS - SCHEDULES
  // ============================================================

  List<
    BodyRegionSchedule
  >
  get schedules {
    final values = _schedules.values.toList();

    values.sort(
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
      values,
    );
  }

  // ============================================================
  // CONFIGURED ACTIVITIES
  // ============================================================

  Set<
    TrainingActivityType
  >
  get configuredActivities {
    return Set<
      TrainingActivityType
    >.unmodifiable(
      _schedules.keys,
    );
  }

  // ============================================================
  // CONFIGURED REGIONS
  // ============================================================
  //
  // Converte as atividades salvas novamente para regiões
  // visuais do boneco.
  //
  // Exemplo:
  //
  // legs
  //
  // ->
  //
  // quadriceps + calves
  //
  // ============================================================

  Set<
    BodyRegion
  >
  get configuredRegions {
    return Set<
      BodyRegion
    >.unmodifiable(
      BodyRegionExtension.regionsForActivities(
        _schedules.keys,
      ),
    );
  }

  bool get hasSchedules => _schedules.isNotEmpty;

  int get configuredCount => _schedules.length;

  // ============================================================
  // HOVER
  // ============================================================

  void hoverRegion(
    BodyRegion? region,
  ) {
    if (_hoveredRegion ==
        region) {
      return;
    }

    _hoveredRegion = region;

    notifyListeners();
  }

  void clearHover() {
    hoverRegion(
      null,
    );
  }

  // ============================================================
  // SELECT REGION
  // ============================================================
  //
  // Clique no boneco.
  //
  // A região visual é convertida para atividade real.
  //
  // Exemplo:
  //
  // abdomen -> core
  // calves  -> legs
  //
  // ============================================================

  void selectRegion(
    BodyRegion region,
  ) {
    _selectedRegion = region;

    _selectActivityInternal(
      region.activity,
    );

    notifyListeners();
  }

  // ============================================================
  // SELECT ACTIVITY
  // ============================================================
  //
  // Permite selecionar também atividades que não aparecem no
  // boneco frontal:
  //
  // - Costas
  // - Corrida
  // - Caminhada
  //
  // ============================================================

  void selectActivity(
    TrainingActivityType activity,
  ) {
    _selectedActivity = activity;

    _selectedRegion = BodyRegionExtension.fromActivity(
      activity,
    );

    _loadDraftForActivity(
      activity,
    );

    notifyListeners();
  }

  // ============================================================
  // INTERNAL SELECT ACTIVITY
  // ============================================================

  void _selectActivityInternal(
    TrainingActivityType activity,
  ) {
    _selectedActivity = activity;

    _loadDraftForActivity(
      activity,
    );
  }

  // ============================================================
  // LOAD DRAFT
  // ============================================================

  void _loadDraftForActivity(
    TrainingActivityType activity,
  ) {
    _draftWeekdays
      ..clear()
      ..addAll(
        _schedules[activity]?.weekdays ??
            const <
              int
            >{},
      );
  }

  // ============================================================
  // CLEAR SELECTION
  // ============================================================

  void clearSelection() {
    if (_selectedActivity ==
            null &&
        _selectedRegion ==
            null &&
        _draftWeekdays.isEmpty) {
      return;
    }

    _selectedActivity = null;

    _selectedRegion = null;

    _draftWeekdays.clear();

    notifyListeners();
  }

  // ============================================================
  // TOGGLE WEEKDAY
  // ============================================================

  void toggleWeekday(
    int weekday,
  ) {
    _validateWeekday(
      weekday,
    );

    if (_draftWeekdays.contains(
      weekday,
    )) {
      _draftWeekdays.remove(
        weekday,
      );
    } else {
      _draftWeekdays.add(
        weekday,
      );
    }

    notifyListeners();
  }

  // ============================================================
  // SET WEEKDAY
  // ============================================================

  void setWeekday({
    required int weekday,
    required bool selected,
  }) {
    _validateWeekday(
      weekday,
    );

    final changed = selected
        ? _draftWeekdays.add(
            weekday,
          )
        : _draftWeekdays.remove(
            weekday,
          );

    if (changed) {
      notifyListeners();
    }
  }

  // ============================================================
  // SET DRAFT WEEKDAYS
  // ============================================================

  void setDraftWeekdays(
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

    _draftWeekdays
      ..clear()
      ..addAll(
        normalized,
      );

    notifyListeners();
  }

  // ============================================================
  // SAVE CURRENT ACTIVITY
  // ============================================================
  //
  // O método mantém o nome antigo "saveCurrentRegion" como alias
  // para não quebrar widgets existentes.
  //
  // ============================================================

  BodyRegionSchedule? saveCurrentActivity() {
    final activity = _selectedActivity;

    if (activity ==
        null) {
      return null;
    }

    if (_draftWeekdays.isEmpty) {
      _schedules.remove(
        activity,
      );

      notifyListeners();

      return null;
    }

    final schedule = BodyRegionSchedule(
      activity: activity,
      weekdays:
          Set<
            int
          >.from(
            _draftWeekdays,
          ),
    );

    _schedules[activity] = schedule;

    notifyListeners();

    return schedule;
  }

  // ============================================================
  // SAVE CURRENT REGION - COMPATIBILITY
  // ============================================================

  BodyRegionSchedule? saveCurrentRegion() {
    return saveCurrentActivity();
  }

  // ============================================================
  // SET SCHEDULE
  // ============================================================

  void setSchedule(
    BodyRegionSchedule schedule,
  ) {
    if (schedule.weekdays.isEmpty) {
      _schedules.remove(
        schedule.activity,
      );
    } else {
      _schedules[schedule.activity] = schedule;
    }

    if (_selectedActivity ==
        schedule.activity) {
      _draftWeekdays
        ..clear()
        ..addAll(
          schedule.weekdays,
        );
    }

    notifyListeners();
  }

  // ============================================================
  // REMOVE ACTIVITY
  // ============================================================

  void removeActivity(
    TrainingActivityType activity,
  ) {
    final removed = _schedules.remove(
      activity,
    );

    if (removed ==
        null) {
      return;
    }

    if (_selectedActivity ==
        activity) {
      _draftWeekdays.clear();
    }

    notifyListeners();
  }

  // ============================================================
  // REMOVE REGION - COMPATIBILITY
  // ============================================================

  void removeRegion(
    BodyRegion region,
  ) {
    removeActivity(
      region.activity,
    );
  }

  // ============================================================
  // IS ACTIVITY CONFIGURED
  // ============================================================

  bool isActivityConfigured(
    TrainingActivityType activity,
  ) {
    return _schedules.containsKey(
      activity,
    );
  }

  // ============================================================
  // IS REGION CONFIGURED
  // ============================================================

  bool isConfigured(
    BodyRegion region,
  ) {
    return isActivityConfigured(
      region.activity,
    );
  }

  // ============================================================
  // SCHEDULE FOR ACTIVITY
  // ============================================================

  BodyRegionSchedule? scheduleForActivity(
    TrainingActivityType activity,
  ) {
    return _schedules[activity];
  }

  // ============================================================
  // SCHEDULE FOR REGION
  // ============================================================

  BodyRegionSchedule? scheduleFor(
    BodyRegion region,
  ) {
    return scheduleForActivity(
      region.activity,
    );
  }

  // ============================================================
  // WEEKDAYS FOR ACTIVITY
  // ============================================================

  Set<
    int
  >
  weekdaysForActivity(
    TrainingActivityType activity,
  ) {
    return Set<
      int
    >.unmodifiable(
      _schedules[activity]?.weekdays ??
          const <
            int
          >{},
    );
  }

  // ============================================================
  // WEEKDAYS FOR REGION
  // ============================================================

  Set<
    int
  >
  weekdaysFor(
    BodyRegion region,
  ) {
    return weekdaysForActivity(
      region.activity,
    );
  }

  // ============================================================
  // ACTIVITIES FOR WEEKDAY
  // ============================================================
  //
  // Este método será usado depois pelo "Registrar treino".
  //
  // Exemplo:
  //
  // segunda
  //
  // ->
  //
  // Peito
  // Braço
  // Core
  //
  // ============================================================

  Set<
    TrainingActivityType
  >
  activitiesForWeekday(
    int weekday,
  ) {
    _validateWeekday(
      weekday,
    );

    final result =
        <
          TrainingActivityType
        >{};

    for (final schedule in _schedules.values) {
      if (schedule.containsDay(
        weekday,
      )) {
        result.add(
          schedule.activity,
        );
      }
    }

    return Set<
      TrainingActivityType
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // SCHEDULES FOR WEEKDAY
  // ============================================================

  List<
    BodyRegionSchedule
  >
  schedulesForWeekday(
    int weekday,
  ) {
    _validateWeekday(
      weekday,
    );

    final result = _schedules.values
        .where(
          (
            schedule,
          ) => schedule.containsDay(
            weekday,
          ),
        )
        .toList();

    result.sort(
      (
        first,
        second,
      ) => first.activity.order.compareTo(
        second.activity.order,
      ),
    );

    return List<
      BodyRegionSchedule
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  void loadSchedules(
    Iterable<
      BodyRegionSchedule
    >
    values, {
    bool notify = true,
  }) {
    _schedules.clear();

    for (final schedule in values) {
      if (schedule.weekdays.isEmpty) {
        continue;
      }

      _schedules[schedule.activity] = schedule;
    }

    final selected = _selectedActivity;

    if (selected !=
        null) {
      _loadDraftForActivity(
        selected,
      );
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  void clearAll() {
    _schedules.clear();

    _draftWeekdays.clear();

    _selectedActivity = null;

    _selectedRegion = null;

    _hoveredRegion = null;

    notifyListeners();
  }

  // ============================================================
  // TO MAP LIST
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  toMapList() {
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
