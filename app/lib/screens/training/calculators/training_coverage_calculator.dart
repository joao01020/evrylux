import '../helpers/training_date_helper.dart';
import '../models/training_model.dart';

class TrainingCoverageCalculator {
  const TrainingCoverageCalculator._();

  // =========================================================
  // COBERTURA MENSAL
  // =========================================================

  static Map<
    String,
    int
  >
  monthlyCoverage({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    final now =
        referenceDate ??
        DateTime.now();

    final Map<
      String,
      int
    >
    coverage =
        <
          String,
          int
        >{};

    for (final training in trainings) {
      if (!_isCurrentMonth(
        training.date,
        now,
      )) {
        continue;
      }

      coverage.update(
        training.training,
        (
          currentValue,
        ) {
          return currentValue +
              1;
        },
        ifAbsent: () {
          return 1;
        },
      );
    }

    final orderedEntries = coverage.entries.toList()
      ..sort(
        (
          first,
          second,
        ) {
          final countComparison = second.value.compareTo(
            first.value,
          );

          if (countComparison !=
              0) {
            return countComparison;
          }

          return first.key.compareTo(
            second.key,
          );
        },
      );

    return Map<
      String,
      int
    >.fromEntries(
      orderedEntries,
    );
  }

  // =========================================================
  // TOTAL DE ATIVIDADES NO MÊS
  // =========================================================

  static int monthlyActivityCount({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    final now =
        referenceDate ??
        DateTime.now();

    return trainings.where(
      (
        training,
      ) {
        return _isCurrentMonth(
          training.date,
          now,
        );
      },
    ).length;
  }

  // =========================================================
  // DIAS TREINADOS NO MÊS
  // =========================================================

  static int monthlyCompletedDays({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    final now =
        referenceDate ??
        DateTime.now();

    final Set<
      String
    >
    trainedDates =
        <
          String
        >{};

    for (final training in trainings) {
      if (!_isCurrentMonth(
        training.date,
        now,
      )) {
        continue;
      }

      trainedDates.add(
        TrainingDateHelper.dateKey(
          training.date,
        ),
      );
    }

    return trainedDates.length;
  }

  // =========================================================
  // ATIVIDADE MAIS TREINADA
  // =========================================================

  static String? mostTrainedActivity({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    final coverage = monthlyCoverage(
      trainings: trainings,
      referenceDate: referenceDate,
    );

    if (coverage.isEmpty) {
      return null;
    }

    return coverage.entries.first.key;
  }

  // =========================================================
  // ATIVIDADES NÃO TREINADAS NO MÊS
  // =========================================================

  static List<
    String
  >
  untrainedActivities({
    required List<
      TrainingModel
    >
    trainings,
    required List<
      String
    >
    activityOptions,
    DateTime? referenceDate,
  }) {
    final coverage = monthlyCoverage(
      trainings: trainings,
      referenceDate: referenceDate,
    );

    return activityOptions.where(
      (
        activity,
      ) {
        return !coverage.containsKey(
          activity,
        );
      },
    ).toList();
  }

  // =========================================================
  // VERIFICAR MÊS
  // =========================================================

  static bool _isCurrentMonth(
    DateTime date,
    DateTime referenceDate,
  ) {
    return date.year ==
            referenceDate.year &&
        date.month ==
            referenceDate.month;
  }
}
