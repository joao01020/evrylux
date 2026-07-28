import 'package:flutter/foundation.dart';

import '../helpers/training_date_helper.dart';
import '../models/training_plan_model.dart';
import '../services/training_service.dart';
import '../states/training_state.dart';

class TrainingLoadController
    extends
        ChangeNotifier {
  final TrainingService service;

  final TrainingState state;

  TrainingLoadController({
    required this.service,
    required this.state,
  });

  // =========================================================
  // CARREGAR DADOS DO MÓDULO
  // =========================================================

  Future<
    bool
  >
  load() async {
    if (state.isLoading) {
      return false;
    }

    state.isLoading = true;
    state.clearMessages();

    notifyListeners();

    try {
      final loadedTrainings = await service.getTrainings();

      final loadedPlan = await service.getTrainingPlan();

      state.setTrainings(
        loadedTrainings,
      );

      final normalizedWeekdays = TrainingDateHelper.normalizeWeekdays(
        loadedPlan.plannedWeekdays,
      );

      final trainingPlan = normalizedWeekdays.isEmpty
          ? TrainingPlanModel.defaultPlan()
          : TrainingPlanModel(
              plannedWeekdays: normalizedWeekdays,
            );

      state.setPlannedWeekdays(
        trainingPlan.plannedWeekdays,
      );

      _selectCurrentDay();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível carregar os dados de treino.',
      );

      debugPrint(
        'Erro carregando dados de treino: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // RECARREGAR APENAS OS TREINOS
  // =========================================================

  Future<
    bool
  >
  reloadTrainings() async {
    if (state.isLoading) {
      return false;
    }

    state.isLoading = true;
    state.clearMessages();

    notifyListeners();

    try {
      final loadedTrainings = await service.getTrainings();

      state.setTrainings(
        loadedTrainings,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível atualizar os treinos.',
      );

      debugPrint(
        'Erro atualizando treinos: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // RECARREGAR APENAS O PLANO
  // =========================================================

  Future<
    bool
  >
  reloadPlan() async {
    if (state.isLoading) {
      return false;
    }

    state.isLoading = true;
    state.clearMessages();

    notifyListeners();

    try {
      final loadedPlan = await service.getTrainingPlan();

      final normalizedWeekdays = TrainingDateHelper.normalizeWeekdays(
        loadedPlan.plannedWeekdays,
      );

      final trainingPlan = normalizedWeekdays.isEmpty
          ? TrainingPlanModel.defaultPlan()
          : TrainingPlanModel(
              plannedWeekdays: normalizedWeekdays,
            );

      state.setPlannedWeekdays(
        trainingPlan.plannedWeekdays,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível atualizar o plano semanal.',
      );

      debugPrint(
        'Erro atualizando plano semanal: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isLoading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // SELECIONAR DIA ATUAL
  // =========================================================

  void _selectCurrentDay() {
    state.selectedDay ??= TrainingDateHelper.getDayName(
      DateTime.now(),
    );
  }
}
