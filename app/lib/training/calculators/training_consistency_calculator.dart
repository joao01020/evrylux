// Avalia o quão consistente você está sendo em relação ao seu plano semanal de treinos para o mês atual,
//retornando índices numéricos, porcentagens e mensagens motivacionais dinâmicas.

import '../helpers/training_date_helper.dart';
import '../models/training_model.dart';

class TrainingConsistencyCalculator {
  const TrainingConsistencyCalculator._();

  // =========================================================
  // TREINOS ESPERADOS ATÉ HOJE
  // =========================================================

  static int expectedTrainingsUntilToday({
    required Set<
      int
    >
    plannedWeekdays,
    DateTime? referenceDate,
  }) {
    final normalizedWeekdays = TrainingDateHelper.normalizeWeekdays(
      plannedWeekdays,
    );

    if (normalizedWeekdays.isEmpty) {
      return 0;
    }

    final now =
        referenceDate ??
        DateTime.now();

    final today = TrainingDateHelper.normalize(
      now,
    );

    DateTime currentDate = DateTime(
      today.year,
      today.month,
      1,
    );

    int expected = 0;

    while (!currentDate.isAfter(
      today,
    )) {
      if (normalizedWeekdays.contains(
        currentDate.weekday,
      )) {
        expected++;
      }

      currentDate = currentDate.add(
        const Duration(
          days: 1,
        ),
      );
    }

    return expected;
  }

  // =========================================================
  // DIAS TREINADOS NO MÊS
  // =========================================================

  static int completedTrainingDays({
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
      final isCurrentMonth =
          training.date.year ==
              now.year &&
          training.date.month ==
              now.month;

      if (!isCurrentMonth) {
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
  // ÍNDICE DE CONSISTÊNCIA
  // =========================================================

  static double consistencyIndex({
    required List<
      TrainingModel
    >
    trainings,
    required Set<
      int
    >
    plannedWeekdays,
    DateTime? referenceDate,
  }) {
    final expected = expectedTrainingsUntilToday(
      plannedWeekdays: plannedWeekdays,
      referenceDate: referenceDate,
    );

    if (expected <=
        0) {
      return 0.0;
    }

    final completed = completedTrainingDays(
      trainings: trainings,
      referenceDate: referenceDate,
    );

    final result =
        completed /
        expected;

    return result.clamp(
      0.0,
      1.0,
    );
  }

  // =========================================================
  // PORCENTAGEM DE CONSISTÊNCIA
  // =========================================================

  static int consistencyPercentage({
    required List<
      TrainingModel
    >
    trainings,
    required Set<
      int
    >
    plannedWeekdays,
    DateTime? referenceDate,
  }) {
    final index = consistencyIndex(
      trainings: trainings,
      plannedWeekdays: plannedWeekdays,
      referenceDate: referenceDate,
    );

    return (index *
            100)
        .round();
  }

  // =========================================================
  // MENSAGEM DE CONSISTÊNCIA
  // =========================================================

  static String consistencyMessage({
    required List<
      TrainingModel
    >
    trainings,
    required Set<
      int
    >
    plannedWeekdays,
    DateTime? referenceDate,
  }) {
    final completed = completedTrainingDays(
      trainings: trainings,
      referenceDate: referenceDate,
    );

    if (completed ==
        0) {
      return 'Seu ritmo começa com o primeiro treino.';
    }

    final index = consistencyIndex(
      trainings: trainings,
      plannedWeekdays: plannedWeekdays,
      referenceDate: referenceDate,
    );

    if (index >=
        1.0) {
      return 'Você está acompanhando ou superando seu plano.';
    }

    if (index >=
        0.75) {
      return 'Você está muito próximo do ritmo planejado.';
    }

    if (index >=
        0.5) {
      return 'Seu ritmo continua vivo. Continue construindo.';
    }

    return 'Você já começou. Agora pode recuperar seu ritmo aos poucos.';
  }

  // =========================================================
  // RESUMO DE CONSISTÊNCIA
  // =========================================================

  static String consistencySummary({
    required List<
      TrainingModel
    >
    trainings,
    required Set<
      int
    >
    plannedWeekdays,
    DateTime? referenceDate,
  }) {
    final expected = expectedTrainingsUntilToday(
      plannedWeekdays: plannedWeekdays,
      referenceDate: referenceDate,
    );

    if (expected <=
        0) {
      return 'Defina os dias de treino para acompanhar seu ritmo.';
    }

    final completed = completedTrainingDays(
      trainings: trainings,
      referenceDate: referenceDate,
    );

    if (completed ==
            1 &&
        expected ==
            1) {
      return 'Você cumpriu o treino planejado até agora.';
    }

    return 'Você cumpriu $completed dos $expected '
        'treinos planejados até agora.';
  }
}
