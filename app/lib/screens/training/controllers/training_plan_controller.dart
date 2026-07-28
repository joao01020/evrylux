import 'package:flutter/foundation.dart';

import '../helpers/training_date_helper.dart';
import '../models/training_plan_model.dart';
import '../services/training_service.dart';
import '../states/training_state.dart';

class TrainingPlanController extends ChangeNotifier {
  final TrainingService service;

  final TrainingState state;

  TrainingPlanController({required this.service, required this.state});

  // =========================================================
  // DIAS PLANEJADOS
  // =========================================================

  Set<int> get plannedWeekdays {
    return state.plannedWeekdays;
  }

  // =========================================================
  // META SEMANAL
  // =========================================================

  int get weeklyGoal {
    return state.weeklyGoal;
  }

  // =========================================================
  // ESTADO DE SALVAMENTO
  // =========================================================

  bool get isSavingPlan {
    return state.isSavingPlan;
  }

  // =========================================================
  // SALVAR PLANO SEMANAL
  // =========================================================

  Future<bool> setPlannedWeekdays(Set<int> weekdays) async {
    if (state.isSavingPlan) {
      return false;
    }

    state.clearMessages();

    final normalizedWeekdays = TrainingDateHelper.normalizeWeekdays(weekdays);

    final plan = TrainingPlanModel(plannedWeekdays: normalizedWeekdays);

    if (!plan.isValid) {
      state.setError('Selecione pelo menos um dia da semana.');

      notifyListeners();

      return false;
    }

    state.isSavingPlan = true;

    notifyListeners();

    try {
      await service.saveTrainingPlan(plannedWeekdays: plan.plannedWeekdays);

      state.setPlannedWeekdays(plan.plannedWeekdays);

      state.setSuccess('Plano semanal salvo com sucesso.');

      return true;
    } catch (error, stackTrace) {
      state.setError('Não foi possível salvar o plano semanal.');

      debugPrint('Erro salvando plano semanal: $error');

      debugPrintStack(stackTrace: stackTrace);

      return false;
    } finally {
      state.isSavingPlan = false;

      notifyListeners();
    }
  }

  // =========================================================
  // ALTERNAR DIA PLANEJADO
  // =========================================================

  Future<bool> togglePlannedWeekday(int weekday) async {
    if (!TrainingDateHelper.isValidWeekday(weekday)) {
      state.setError('Dia da semana inválido.');

      notifyListeners();

      return false;
    }

    final updatedWeekdays = Set<int>.from(state.plannedWeekdays);

    if (updatedWeekdays.contains(weekday)) {
      updatedWeekdays.remove(weekday);
    } else {
      updatedWeekdays.add(weekday);
    }

    if (updatedWeekdays.isEmpty) {
      state.setError('O plano precisa ter pelo menos um dia de treino.');

      notifyListeners();

      return false;
    }

    return setPlannedWeekdays(updatedWeekdays);
  }

  // =========================================================
  // ADICIONAR DIA PLANEJADO
  // =========================================================

  Future<bool> addPlannedWeekday(int weekday) async {
    if (!TrainingDateHelper.isValidWeekday(weekday)) {
      state.setError('Dia da semana inválido.');

      notifyListeners();

      return false;
    }

    if (state.plannedWeekdays.contains(weekday)) {
      return true;
    }

    final updatedWeekdays = Set<int>.from(state.plannedWeekdays);

    updatedWeekdays.add(weekday);

    return setPlannedWeekdays(updatedWeekdays);
  }

  // =========================================================
  // REMOVER DIA PLANEJADO
  // =========================================================

  Future<bool> removePlannedWeekday(int weekday) async {
    if (!TrainingDateHelper.isValidWeekday(weekday)) {
      state.setError('Dia da semana inválido.');

      notifyListeners();

      return false;
    }

    if (!state.plannedWeekdays.contains(weekday)) {
      return true;
    }

    if (state.plannedWeekdays.length == 1) {
      state.setError('O plano precisa ter pelo menos um dia de treino.');

      notifyListeners();

      return false;
    }

    final updatedWeekdays = Set<int>.from(state.plannedWeekdays);

    updatedWeekdays.remove(weekday);

    return setPlannedWeekdays(updatedWeekdays);
  }

  // =========================================================
  // VERIFICAR DIA PLANEJADO
  // =========================================================

  bool isPlannedWeekday(int weekday) {
    return state.isPlannedWeekday(weekday);
  }

  // =========================================================
  // DIAS PLANEJADOS ORDENADOS
  // =========================================================

  List<int> get orderedPlannedWeekdays {
    return TrainingDateHelper.sortWeekdays(state.plannedWeekdays);
  }

  // =========================================================
  // NOMES DOS DIAS PLANEJADOS
  // =========================================================

  List<String> get plannedWeekdayNames {
    return TrainingDateHelper.weekdayNames(state.plannedWeekdays);
  }

  // =========================================================
  // TEXTO DOS DIAS PLANEJADOS
  // =========================================================

  String get plannedWeekdaysText {
    if (state.plannedWeekdays.isEmpty) {
      return 'Nenhum dia selecionado';
    }

    return TrainingDateHelper.weekdaysText(state.plannedWeekdays);
  }

  // =========================================================
  // TEXTO DA META SEMANAL
  // =========================================================

  String get weeklyGoalText {
    final goal = state.weeklyGoal;

    if (goal == 1) {
      return 'Treinar 1 dia por semana';
    }

    return 'Treinar $goal dias por semana';
  }

  // =========================================================
  // ALTERAR META SEMANAL ANTIGA
  // =========================================================

  /// Mantido para compatibilidade com telas antigas.
  ///
  /// Esse método altera apenas o estado local.
  /// Para persistir o plano, prefira [setPlannedWeekdays].
  void setWeeklyGoal(int goal) {
    if (goal < 1 || goal > 7) {
      return;
    }

    final currentWeekdays = TrainingDateHelper.sortWeekdays(
      state.plannedWeekdays,
    );

    final updatedWeekdays = <int>{};

    for (final weekday in currentWeekdays) {
      if (updatedWeekdays.length >= goal) {
        break;
      }

      updatedWeekdays.add(weekday);
    }

    for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++) {
      if (updatedWeekdays.length >= goal) {
        break;
      }

      updatedWeekdays.add(weekday);
    }

    final hasChanged = !_setsAreEqual(state.plannedWeekdays, updatedWeekdays);

    if (!hasChanged) {
      return;
    }

    state.setPlannedWeekdays(updatedWeekdays);

    notifyListeners();
  }

  // =========================================================
  // DEFINIR PLANO PADRÃO LOCALMENTE
  // =========================================================

  void setDefaultPlan() {
    final defaultPlan = TrainingPlanModel.defaultPlan();

    final hasChanged = !_setsAreEqual(
      state.plannedWeekdays,
      defaultPlan.plannedWeekdays,
    );

    if (!hasChanged) {
      return;
    }

    state.setPlannedWeekdays(defaultPlan.plannedWeekdays);

    notifyListeners();
  }

  // =========================================================
  // SALVAR PLANO PADRÃO
  // =========================================================

  Future<bool> saveDefaultPlan() {
    final defaultPlan = TrainingPlanModel.defaultPlan();

    return setPlannedWeekdays(defaultPlan.plannedWeekdays);
  }

  // =========================================================
  // VERIFICAR SE É O PLANO PADRÃO
  // =========================================================

  bool get isDefaultPlan {
    final defaultPlan = TrainingPlanModel.defaultPlan();

    return _setsAreEqual(state.plannedWeekdays, defaultPlan.plannedWeekdays);
  }

  // =========================================================
  // COMPARAR CONJUNTOS
  // =========================================================

  bool _setsAreEqual(Set<int> first, Set<int> second) {
    if (first.length != second.length) {
      return false;
    }

    return first.containsAll(second);
  }
}
