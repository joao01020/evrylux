import 'package:flutter/foundation.dart';

import '../../helpers/training_date_helper.dart';
import '../../models/training_model.dart';
import '../../services/training_service.dart';
import '../../states/training_state.dart';

class TrainingHistoryController
    extends
        ChangeNotifier {
  final TrainingService service;

  final TrainingState state;

  TrainingHistoryController({
    required this.service,
    required this.state,
  });

  // =========================================================
  // HISTÓRICO FORMATADO
  // =========================================================

  List<
    String
  >
  get history {
    return state.history;
  }

  // =========================================================
  // TREINOS COMPLETOS
  // =========================================================

  List<
    TrainingModel
  >
  get trainings {
    return state.trainings;
  }

  // =========================================================
  // POSSUI HISTÓRICO
  // =========================================================

  bool get hasHistory {
    return state.history.isNotEmpty;
  }

  // =========================================================
  // POSSUI TREINOS
  // =========================================================

  bool get hasTrainings {
    return state.trainings.isNotEmpty;
  }

  // =========================================================
  // RECONSTRUIR HISTÓRICO VISUAL
  // =========================================================

  void rebuildHistory() {
    final orderedTrainings =
        List<
          TrainingModel
        >.from(
          state.trainings,
        );

    orderedTrainings.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    final formattedHistory =
        <
          String
        >[];

    for (final training in orderedTrainings) {
      final formattedDate = TrainingDateHelper.formatDate(
        training.date,
      );

      final timeText =
          training.minutes >
              0
          ? '${training.minutes} min'
          : 'sem cronômetro';

      formattedHistory.add(
        '$formattedDate - '
        '${training.training} - '
        '$timeText',
      );
    }

    state.setHistory(
      formattedHistory,
    );

    notifyListeners();
  }

  // =========================================================
  // CARREGAR HISTÓRICO DO SERVICE
  // =========================================================

  Future<
    List<
      TrainingModel
    >
  >
  loadHistory() async {
    try {
      final loadedTrainings = await service.getTrainings();

      return loadedTrainings;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'Erro carregando histórico: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  // =========================================================
  // ATUALIZAR HISTÓRICO COMPLETO
  // =========================================================

  Future<
    bool
  >
  refreshHistory() async {
    try {
      final loadedTrainings = await service.getTrainings();

      state.setTrainings(
        loadedTrainings,
      );

      rebuildHistory();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível atualizar o histórico.',
      );

      debugPrint(
        'Erro atualizando histórico: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      notifyListeners();

      return false;
    }
  }

  // =========================================================
  // BUSCAR TREINOS POR DIA
  // =========================================================

  List<
    TrainingModel
  >
  getDayTrainings(
    DateTime date,
  ) {
    final result = state.trainings.where(
      (
        training,
      ) {
        return TrainingDateHelper.isSameDay(
          training.date,
          date,
        );
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.date.compareTo(
          second.date,
        );
      },
    );

    return result;
  }

  // =========================================================
  // BUSCAR TREINOS POR PERÍODO
  // =========================================================

  List<
    TrainingModel
  >
  getTrainingsByPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = TrainingDateHelper.normalize(
      start,
    );

    final normalizedEnd = TrainingDateHelper.normalize(
      end,
    );

    final result = state.trainings.where(
      (
        training,
      ) {
        final trainingDate = TrainingDateHelper.normalize(
          training.date,
        );

        final isBeforeStart = trainingDate.isBefore(
          normalizedStart,
        );

        final isAfterEnd = trainingDate.isAfter(
          normalizedEnd,
        );

        return !isBeforeStart &&
            !isAfterEnd;
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.date.compareTo(
          second.date,
        );
      },
    );

    return result;
  }

  // =========================================================
  // BUSCAR TREINOS DA SEMANA ATUAL
  // =========================================================

  List<
    TrainingModel
  >
  get currentWeekTrainings {
    final now = DateTime.now();

    final startOfWeek = TrainingDateHelper.startOfWeek(
      now,
    );

    final endOfWeek = TrainingDateHelper.endOfWeek(
      now,
    );

    return getTrainingsByPeriod(
      start: startOfWeek,
      end: endOfWeek,
    );
  }

  // =========================================================
  // BUSCAR TREINOS DO MÊS ATUAL
  // =========================================================

  List<
    TrainingModel
  >
  get currentMonthTrainings {
    final now = DateTime.now();

    final startOfMonth = TrainingDateHelper.startOfMonth(
      now,
    );

    final endOfMonth = TrainingDateHelper.endOfMonth(
      now,
    );

    return getTrainingsByPeriod(
      start: startOfMonth,
      end: endOfMonth,
    );
  }

  // =========================================================
  // BUSCAR TREINOS POR ATIVIDADE
  // =========================================================

  List<
    TrainingModel
  >
  getTrainingsByActivity(
    String activity,
  ) {
    final normalizedActivity = activity.trim();

    if (normalizedActivity.isEmpty) {
      return [];
    }

    final result = state.trainings.where(
      (
        training,
      ) {
        return training.training ==
            normalizedActivity;
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    return result;
  }

  // =========================================================
  // BUSCAR TREINO MAIS RECENTE
  // =========================================================

  TrainingModel? get latestTraining {
    if (state.trainings.isEmpty) {
      return null;
    }

    final orderedTrainings =
        List<
          TrainingModel
        >.from(
          state.trainings,
        );

    orderedTrainings.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    return orderedTrainings.first;
  }

  // =========================================================
  // BUSCAR PRIMEIRO TREINO
  // =========================================================

  TrainingModel? get firstTraining {
    if (state.trainings.isEmpty) {
      return null;
    }

    final orderedTrainings =
        List<
          TrainingModel
        >.from(
          state.trainings,
        );

    orderedTrainings.sort(
      (
        first,
        second,
      ) {
        return first.date.compareTo(
          second.date,
        );
      },
    );

    return orderedTrainings.first;
  }

  // =========================================================
  // TOTAL DE REGISTROS
  // =========================================================

  int get totalTrainings {
    return state.trainings.length;
  }

  // =========================================================
  // TOTAL DE MINUTOS TREINADOS
  // =========================================================

  int get totalMinutes {
    int total = 0;

    for (final training in state.trainings) {
      total += training.minutes;
    }

    return total;
  }

  // =========================================================
  // LIMPAR HISTÓRICO VISUAL
  // =========================================================

  void clearVisualHistory() {
    if (state.history.isEmpty) {
      return;
    }

    state.clearHistory();

    notifyListeners();
  }
}
