import 'package:flutter/foundation.dart';

import '../../calculators/training_consistency_calculator.dart';
import '../../calculators/training_coverage_calculator.dart';
import '../../calculators/training_streak_calculator.dart';
import '../../helpers/training_date_helper.dart';
import '../../states/training_state.dart';

class TrainingStatsController
    extends
        ChangeNotifier {
  final TrainingState state;

  final List<
    String
  >
  activityOptions;

  TrainingStatsController({
    required this.state,
    required this.activityOptions,
  });

  // =========================================================
  // ATUALIZAR ESTATÍSTICAS ARMAZENADAS NO ESTADO
  // =========================================================

  void refresh() {
    _updateCompletedDays();
    _updateCurrentStreak();

    notifyListeners();
  }

  // =========================================================
  // ATUALIZAR DIAS CONCLUÍDOS NA SEMANA
  // =========================================================

  void _updateCompletedDays() {
    state.resetCompletedDays();

    final now = DateTime.now();

    final startOfWeek = TrainingDateHelper.startOfWeek(
      now,
    );

    final endOfWeek = TrainingDateHelper.endOfWeek(
      now,
    );

    for (final training in state.trainings) {
      final trainingDate = TrainingDateHelper.normalize(
        training.date,
      );

      if (trainingDate.isBefore(
        startOfWeek,
      )) {
        continue;
      }

      if (trainingDate.isAfter(
        endOfWeek,
      )) {
        continue;
      }

      final weekdayIndex =
          trainingDate.weekday -
          1;

      state.setCompletedDay(
        weekdayIndex,
      );
    }
  }

  // =========================================================
  // ATUALIZAR SEQUÊNCIA ATUAL
  // =========================================================

  void _updateCurrentStreak() {
    state.streak = TrainingStreakCalculator.calculate(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // COBERTURA MENSAL
  // =========================================================

  Map<
    String,
    int
  >
  get monthlyCoverage {
    return TrainingCoverageCalculator.monthlyCoverage(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // TOTAL DE ATIVIDADES NO MÊS
  // =========================================================

  int get monthlyActivityCount {
    return TrainingCoverageCalculator.monthlyActivityCount(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // DIAS TREINADOS NO MÊS
  // =========================================================

  int get monthlyCompletedTrainings {
    return TrainingCoverageCalculator.monthlyCompletedDays(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // TREINOS ESPERADOS ATÉ HOJE
  // =========================================================

  int get expectedTrainingsUntilToday {
    return TrainingConsistencyCalculator.expectedTrainingsUntilToday(
      plannedWeekdays: state.plannedWeekdays,
    );
  }

  // =========================================================
  // ÍNDICE DE CONSISTÊNCIA
  // =========================================================

  double get consistencyIndex {
    return TrainingConsistencyCalculator.consistencyIndex(
      trainings: state.trainings,
      plannedWeekdays: state.plannedWeekdays,
    );
  }

  // =========================================================
  // PORCENTAGEM DE CONSISTÊNCIA
  // =========================================================

  int get consistencyPercentage {
    return TrainingConsistencyCalculator.consistencyPercentage(
      trainings: state.trainings,
      plannedWeekdays: state.plannedWeekdays,
    );
  }

  // =========================================================
  // MENSAGEM DE CONSISTÊNCIA
  // =========================================================

  String get consistencyMessage {
    return TrainingConsistencyCalculator.consistencyMessage(
      trainings: state.trainings,
      plannedWeekdays: state.plannedWeekdays,
    );
  }

  // =========================================================
  // RESUMO DE CONSISTÊNCIA
  // =========================================================

  String get consistencySummary {
    return TrainingConsistencyCalculator.consistencySummary(
      trainings: state.trainings,
      plannedWeekdays: state.plannedWeekdays,
    );
  }

  // =========================================================
  // ATIVIDADE MAIS TREINADA
  // =========================================================

  String? get mostTrainedActivity {
    return TrainingCoverageCalculator.mostTrainedActivity(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // ATIVIDADES AINDA NÃO TREINADAS NO MÊS
  // =========================================================

  List<
    String
  >
  get untrainedActivitiesThisMonth {
    return TrainingCoverageCalculator.untrainedActivities(
      trainings: state.trainings,
      activityOptions: activityOptions,
    );
  }

  // =========================================================
  // MAIOR SEQUÊNCIA
  // =========================================================

  int get longestStreak {
    return TrainingStreakCalculator.longestStreak(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // TREINOU HOJE
  // =========================================================

  bool get trainedToday {
    return TrainingStreakCalculator.trainedToday(
      trainings: state.trainings,
    );
  }

  // =========================================================
  // SEQUÊNCIA ATUAL
  // =========================================================

  int get currentStreak {
    return state.streak;
  }

  // =========================================================
  // META SEMANAL
  // =========================================================

  int get weeklyGoal {
    return state.weeklyGoal;
  }

  // =========================================================
  // DIAS CONCLUÍDOS NA SEMANA
  // =========================================================

  int get completedDaysThisWeek {
    return state.completedDays.where(
      (
        completed,
      ) {
        return completed;
      },
    ).length;
  }

  // =========================================================
  // DIAS PLANEJADOS CONCLUÍDOS NA SEMANA
  // =========================================================

  int get completedPlannedDaysThisWeek {
    int total = 0;

    for (
      int index = 0;
      index <
          state.completedDays.length;
      index++
    ) {
      final weekday =
          index +
          1;

      final completed = state.completedDays[index];

      final planned = state.plannedWeekdays.contains(
        weekday,
      );

      if (completed &&
          planned) {
        total++;
      }
    }

    return total;
  }

  // =========================================================
  // PROGRESSO DA META SEMANAL
  // =========================================================

  double get weeklyProgress {
    final goal = state.weeklyGoal;

    if (goal <=
        0) {
      return 0;
    }

    final progress =
        completedPlannedDaysThisWeek /
        goal;

    return progress.clamp(
      0.0,
      1.0,
    );
  }

  // =========================================================
  // PORCENTAGEM DA META SEMANAL
  // =========================================================

  int get weeklyProgressPercentage {
    return (weeklyProgress *
            100)
        .round();
  }

  // =========================================================
  // META SEMANAL CONCLUÍDA
  // =========================================================

  bool get weeklyGoalCompleted {
    if (state.weeklyGoal <=
        0) {
      return false;
    }

    return completedPlannedDaysThisWeek >=
        state.weeklyGoal;
  }

  // =========================================================
  // POSSUI DADOS DE TREINO
  // =========================================================

  bool get hasTrainingData {
    return state.trainings.isNotEmpty;
  }
}
