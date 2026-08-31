import '../data/training_repository.dart';

import '../models/training_model.dart';

// =========================================================
// DADOS DO PLANO SEMANAL
// =========================================================

class TrainingPlanData {
  final int weeklyGoal;

  final Set<
    int
  >
  plannedWeekdays;

  const TrainingPlanData({
    required this.weeklyGoal,
    required this.plannedWeekdays,
  });

  // =======================================================
  // PLANO PADRÃO
  // =======================================================

  factory TrainingPlanData.defaultPlan() {
    return const TrainingPlanData(
      weeklyGoal: 3,
      plannedWeekdays: {
        DateTime.monday,
        DateTime.wednesday,
        DateTime.friday,
      },
    );
  }
}

// =========================================================
// SERVIÇO DE TREINOS
// =========================================================

class TrainingService {
  final TrainingRepository repository;

  TrainingService({
    required this.repository,
  });

  // =========================================================
  // BUSCAR TREINOS
  // =========================================================

  Future<
    List<
      TrainingModel
    >
  >
  getTrainings() async {
    final data = await repository.load();

    final List<
      TrainingModel
    >
    trainings = [];

    for (final entry in data.entries) {
      final day = entry.key.toString();

      final value = entry.value;

      // Evita interpretar configurações como treinos.
      if (_isConfigurationKey(
        day,
      )) {
        continue;
      }

      // =====================================================
      // FORMATO DE LISTA
      // =====================================================

      if (value
          is List) {
        for (final item in value) {
          if (item
              is! Map) {
            continue;
          }

          final training = item['training'];

          final minutes = item['minutes'];

          final date = item['date'];

          if (training ==
              null) {
            continue;
          }

          trainings.add(
            TrainingModel(
              date: _parseDate(
                date,
              ),
              day: day,
              training: training.toString(),
              minutes: _parseMinutes(
                minutes,
              ),
            ),
          );
        }
      }
      // =====================================================
      // FORMATO ÚNICO ANTIGO
      // =====================================================
      else if (value
          is Map) {
        final training = value['training'];

        final minutes = value['minutes'];

        final date = value['date'];

        if (training ==
            null) {
          continue;
        }

        trainings.add(
          TrainingModel(
            date: _parseDate(
              date,
            ),
            day: day,
            training: training.toString(),
            minutes: _parseMinutes(
              minutes,
            ),
          ),
        );
      }
    }

    trainings.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    return trainings;
  }

  // =========================================================
  // SALVAR TREINO
  // =========================================================

  Future<
    void
  >
  saveTraining(
    TrainingModel model,
  ) async {
    await repository.save(
      day: model.day,
      training: model.training,
      minutes: model.minutes,
      date: model.date,
    );
  }

  // =========================================================
  // ATUALIZAR TREINO
  // =========================================================

  Future<
    void
  >
  updateTraining({
    required TrainingModel original,
    required TrainingModel updated,
  }) {
    return repository.updateTraining(
      oldDay: original.day,
      oldTraining: original.training,
      oldDate: original.date,
      newDay: updated.day,
      newTraining: updated.training,
      newMinutes: updated.minutes,
      newDate: updated.date,
    );
  }

  // =========================================================
  // APAGAR TREINO
  // =========================================================

  Future<
    void
  >
  deleteTraining(
    TrainingModel model,
  ) {
    return repository.deleteTraining(
      day: model.day,
      training: model.training,
      date: model.date,
    );
  }

  // =========================================================
  // CARREGAR PLANO SEMANAL
  // =========================================================

  Future<
    TrainingPlanData
  >
  getTrainingPlan() async {
    try {
      final data = await repository.loadTrainingPlan();

      if (data ==
              null ||
          data.isEmpty) {
        return TrainingPlanData.defaultPlan();
      }

      final weekdays = _parseWeekdays(
        data['plannedWeekdays'],
      );

      final savedGoal = _parseWeeklyGoal(
        data['weeklyGoal'],
      );

      if (weekdays.isEmpty) {
        return TrainingPlanData.defaultPlan();
      }

      /*
       * A quantidade de dias selecionados é a fonte principal
       * da meta semanal.
       *
       * Isso evita um plano como:
       *
       * Meta: 3 dias
       * Dias selecionados: 4 dias
       */
      final normalizedGoal = weekdays.length;

      return TrainingPlanData(
        weeklyGoal:
            normalizedGoal >
                0
            ? normalizedGoal
            : savedGoal,
        plannedWeekdays: weekdays,
      );
    } catch (
      _
    ) {
      return TrainingPlanData.defaultPlan();
    }
  }

  // =========================================================
  // SALVAR PLANO SEMANAL
  // =========================================================

  Future<
    void
  >
  saveTrainingPlan({
    required Set<
      int
    >
    plannedWeekdays,
  }) async {
    final normalizedWeekdays = _normalizeWeekdays(
      plannedWeekdays,
    );

    if (normalizedWeekdays.isEmpty) {
      throw ArgumentError(
        'Selecione pelo menos um dia da semana.',
      );
    }

    await repository.saveTrainingPlan(
      weeklyGoal: normalizedWeekdays.length,
      plannedWeekdays: normalizedWeekdays.toList()..sort(),
    );
  }

  // =========================================================
  // SALVAR META E DIAS
  // =========================================================

  Future<
    void
  >
  updateTrainingPlan({
    required int weeklyGoal,
    required Set<
      int
    >
    plannedWeekdays,
  }) async {
    final normalizedWeekdays = _normalizeWeekdays(
      plannedWeekdays,
    );

    if (normalizedWeekdays.isEmpty) {
      throw ArgumentError(
        'Selecione pelo menos um dia da semana.',
      );
    }

    /*
     * A quantidade real de dias selecionados prevalece sobre
     * o número recebido.
     */
    final normalizedGoal = normalizedWeekdays.length;

    await repository.saveTrainingPlan(
      weeklyGoal: normalizedGoal,
      plannedWeekdays: normalizedWeekdays.toList()..sort(),
    );
  }

  // =========================================================
  // CONVERTER DIAS SALVOS
  // =========================================================

  Set<
    int
  >
  _parseWeekdays(
    dynamic value,
  ) {
    if (value
        is! List) {
      return <
        int
      >{};
    }

    final Set<
      int
    >
    weekdays =
        <
          int
        >{};

    for (final item in value) {
      final parsed = int.tryParse(
        item.toString(),
      );

      if (parsed ==
          null) {
        continue;
      }

      if (_isValidWeekday(
        parsed,
      )) {
        weekdays.add(
          parsed,
        );
      }
    }

    return weekdays;
  }

  // =========================================================
  // NORMALIZAR DIAS DA SEMANA
  // =========================================================

  Set<
    int
  >
  _normalizeWeekdays(
    Set<
      int
    >
    weekdays,
  ) {
    return weekdays.where(
      (
        weekday,
      ) {
        return _isValidWeekday(
          weekday,
        );
      },
    ).toSet();
  }

  // =========================================================
  // VALIDAR DIA DA SEMANA
  // =========================================================

  bool _isValidWeekday(
    int weekday,
  ) {
    return weekday >=
            DateTime.monday &&
        weekday <=
            DateTime.sunday;
  }

  // =========================================================
  // CONVERTER META SEMANAL
  // =========================================================

  int _parseWeeklyGoal(
    dynamic value,
  ) {
    final parsed = int.tryParse(
      value?.toString() ??
          '',
    );

    if (parsed ==
            null ||
        parsed <
            1 ||
        parsed >
            7) {
      return 3;
    }

    return parsed;
  }

  // =========================================================
  // IDENTIFICAR CONFIGURAÇÕES
  // =========================================================

  bool _isConfigurationKey(
    String key,
  ) {
    return key ==
            'trainingPlan' ||
        key ==
            'weeklyGoal' ||
        key ==
            'plannedWeekdays' ||
        key.startsWith(
          '_',
        );
  }

  // =========================================================
  // CONVERTER DATA
  // =========================================================

  DateTime _parseDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value !=
        null) {
      final parsed = DateTime.tryParse(
        value.toString(),
      );

      if (parsed !=
          null) {
        return parsed;
      }
    }

    return DateTime.now();
  }

  // =========================================================
  // CONVERSÃO SEGURA DE MINUTOS
  // =========================================================

  int _parseMinutes(
    dynamic value,
  ) {
    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  // =========================================================
  // LIMPAR SOMENTE OS TREINOS
  // =========================================================

  Future<
    void
  >
  clearOldData() async {
    await repository.clear();
  }

  // =========================================================
  // LIMPAR SOMENTE O PLANO SEMANAL
  // =========================================================

  Future<
    void
  >
  clearTrainingPlan() async {
    await repository.clearTrainingPlan();
  }

  // =========================================================
  // RESET COMPLETO
  // =========================================================

  Future<
    void
  >
  resetTrainingStorage() async {
    await repository.clear();

    await repository.clearTrainingPlan();
  }
}
