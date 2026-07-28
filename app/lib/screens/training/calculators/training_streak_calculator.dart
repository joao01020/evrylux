import '../helpers/training_date_helper.dart';
import '../models/training_model.dart';

class TrainingStreakCalculator {
  const TrainingStreakCalculator._();

  // =========================================================
  // CALCULAR SEQUÊNCIA ATUAL
  // =========================================================

  static int calculate({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    if (trainings.isEmpty) {
      return 0;
    }

    final Set<
      String
    >
    trainedDateKeys = trainings.map(
      (
        training,
      ) {
        return TrainingDateHelper.dateKey(
          training.date,
        );
      },
    ).toSet();

    final now =
        referenceDate ??
        DateTime.now();

    DateTime currentDate = TrainingDateHelper.normalize(
      now,
    );

    final todayKey = TrainingDateHelper.dateKey(
      currentDate,
    );

    if (!trainedDateKeys.contains(
      todayKey,
    )) {
      currentDate = currentDate.subtract(
        const Duration(
          days: 1,
        ),
      );
    }

    int streak = 0;

    while (trainedDateKeys.contains(
      TrainingDateHelper.dateKey(
        currentDate,
      ),
    )) {
      streak++;

      currentDate = currentDate.subtract(
        const Duration(
          days: 1,
        ),
      );
    }

    return streak;
  }

  // =========================================================
  // MAIOR SEQUÊNCIA DO HISTÓRICO
  // =========================================================

  static int longestStreak({
    required List<
      TrainingModel
    >
    trainings,
  }) {
    if (trainings.isEmpty) {
      return 0;
    }

    final uniqueDates =
        trainings
            .map(
              (
                training,
              ) {
                return TrainingDateHelper.normalize(
                  training.date,
                );
              },
            )
            .toSet()
            .toList()
          ..sort();

    if (uniqueDates.isEmpty) {
      return 0;
    }

    int currentStreak = 1;
    int longestStreak = 1;

    for (
      int index = 1;
      index <
          uniqueDates.length;
      index++
    ) {
      final previousDate =
          uniqueDates[index -
              1];

      final currentDate = uniqueDates[index];

      final difference = currentDate
          .difference(
            previousDate,
          )
          .inDays;

      if (difference ==
          1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }

      if (currentStreak >
          longestStreak) {
        longestStreak = currentStreak;
      }
    }

    return longestStreak;
  }

  // =========================================================
  // VERIFICAR TREINO HOJE
  // =========================================================

  static bool trainedToday({
    required List<
      TrainingModel
    >
    trainings,
    DateTime? referenceDate,
  }) {
    final now =
        referenceDate ??
        DateTime.now();

    return trainings.any(
      (
        training,
      ) {
        return TrainingDateHelper.isSameDay(
          training.date,
          now,
        );
      },
    );
  }
}
