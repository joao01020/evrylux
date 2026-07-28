import 'package:flutter/foundation.dart';

import '../helpers/training_date_helper.dart';
import '../services/training_service.dart';
import '../states/training_state.dart';

import 'training_history_controller.dart';
import 'training_load_controller.dart';
import 'training_plan_controller.dart';
import 'training_save_controller.dart';
import 'training_stats_controller.dart';
import 'training_ui_controller.dart';

class TrainingController extends ChangeNotifier {
  final TrainingService service;
  final TrainingState state;

  late final TrainingLoadController loadController;
  late final TrainingSaveController saveController;
  late final TrainingPlanController planController;
  late final TrainingHistoryController historyController;
  late final TrainingUiController uiController;
  late final TrainingStatsController statsController;

  static const List<String> activityOptions = [
    '🏋️ Peito',
    '🦵 Pernas',
    '💪 Braço',
    '🧱 Costas',
    '🎯 Ombro',
    '🔥 Core',
    '🏃 Corrida',
    '🚶 Caminhada',
  ];

  TrainingController({required this.service, TrainingState? initialState})
    : state = initialState ?? TrainingState() {
    _initializeControllers();
    _addListeners();
  }

  void _initializeControllers() {
    loadController = TrainingLoadController(service: service, state: state);

    saveController = TrainingSaveController(service: service, state: state);

    planController = TrainingPlanController(service: service, state: state);

    historyController = TrainingHistoryController(
      service: service,
      state: state,
    );

    uiController = TrainingUiController(
      state: state,
      activityOptions: activityOptions,
    );

    statsController = TrainingStatsController(
      state: state,
      activityOptions: activityOptions,
    );
  }

  void _addListeners() {
    loadController.addListener(_notify);
    saveController.addListener(_notify);
    planController.addListener(_notify);
    historyController.addListener(_notify);
    uiController.addListener(_notify);
    statsController.addListener(_notify);
  }

  void _notify() {
    notifyListeners();
  }

  // =========================================================
  // ESTADO GERAL
  // =========================================================

  bool get isLoading => state.isLoading;

  bool get isSaving => state.isSaving;

  String? get errorMessage => state.errorMessage;

  String? get successMessage => state.successMessage;

  // =========================================================
  // INTERFACE
  // =========================================================

  List<String> get days => TrainingDateHelper.weekDays;

  String? get selectedDay => state.selectedDay;

  Set<String> get selectedActivities => state.selectedActivities;

  int get currentSeconds => state.currentSeconds;

  // =========================================================
  // PLANO SEMANAL
  // =========================================================

  int get weeklyGoal => state.weeklyGoal;

  // =========================================================
  // PROGRESSO
  // =========================================================

  int get streak => state.streak;

  List<bool> get completedDays => state.completedDays;

  // =========================================================
  // HISTÓRICO
  // =========================================================

  List<String> get history => state.history;

  // =========================================================
  // ESTATÍSTICAS
  // =========================================================

  double get consistencyIndex => statsController.consistencyIndex;

  int get monthlyCompletedTrainings {
    return statsController.monthlyCompletedTrainings;
  }

  int get expectedTrainingsUntilToday {
    return statsController.expectedTrainingsUntilToday;
  }

  Map<String, int> get monthlyCoverage {
    return statsController.monthlyCoverage;
  }

  // =========================================================
  // CARREGAMENTO
  // =========================================================

  Future<void> load() async {
    final loaded = await loadController.load();

    if (!loaded) {
      return;
    }

    _refreshDerivedData();
  }

  // =========================================================
  // SALVAR TREINO
  // =========================================================

  Future<bool> save() async {
    final saved = await saveController.save();

    if (!saved) {
      return false;
    }

    _refreshDerivedData();

    return true;
  }

  // =========================================================
  // PLANO SEMANAL
  // =========================================================

  void setWeeklyGoal(int goal) {
    planController.setWeeklyGoal(goal);
    statsController.refresh();
  }

  // =========================================================
  // SELEÇÃO DO DIA
  // =========================================================

  void selectDay(int index) {
    uiController.selectDay(index);
  }

  // =========================================================
  // ATIVIDADES
  // =========================================================

  bool isActivitySelected(String activity) {
    return uiController.isActivitySelected(activity);
  }

  void toggleActivity(String activity) {
    uiController.toggleActivity(activity);
  }

  void clearSelectedActivities() {
    uiController.clearSelectedActivities();
  }

  // =========================================================
  // CRONÔMETRO
  // =========================================================

  void updateTimer(int seconds) {
    uiController.updateTimer(seconds);
  }

  // =========================================================
  // MENSAGENS
  // =========================================================

  void clearMessages() {
    uiController.clearMessages();
  }

  // =========================================================
  // DADOS DERIVADOS
  // =========================================================

  void _refreshDerivedData() {
    historyController.rebuildHistory();
    statsController.refresh();
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    loadController.removeListener(_notify);
    saveController.removeListener(_notify);
    planController.removeListener(_notify);
    historyController.removeListener(_notify);
    uiController.removeListener(_notify);
    statsController.removeListener(_notify);

    loadController.dispose();
    saveController.dispose();
    planController.dispose();
    historyController.dispose();
    uiController.dispose();
    statsController.dispose();

    super.dispose();
  }
}
