import '../../data/training/training_repository.dart';

import '../../models/training/training_model.dart';

class TrainingService {
  final TrainingRepository repository;

  TrainingService({
    required this.repository,
  });

  // ==========================================
  // BUSCAR TREINOS
  // ==========================================

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

      // ==================================
      // FORMATO LISTA
      // ==================================

      if (value
          is List) {
        for (final item in value) {
          if (item
              is Map) {
            final training = item["training"];

            final minutes = item["minutes"];

            final date = item["date"];

            if (training ==
                    null ||
                minutes ==
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
      }
      // ==================================
      // FORMATO ÚNICO
      // ==================================
      else if (value
          is Map) {
        final training = value["training"];

        final minutes = value["minutes"];

        final date = value["date"];

        if (training ==
                null ||
            minutes ==
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

    return trainings;
  }

  // ==========================================
  // CONVERTER DATA
  // ==========================================

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

  // ==========================================
  // CONVERSÃO SEGURA DE MINUTOS
  // ==========================================

  int _parseMinutes(
    dynamic value,
  ) {
    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // ==========================================
  // SALVAR TREINO
  // ==========================================

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
    );
  }

  // ==========================================
  // LIMPAR DADOS ANTIGOS
  // ==========================================

  Future<
    void
  >
  clearOldData() async {
    await repository.clear();
  }

  // ==========================================
  // RESET COMPLETO DOS TREINOS
  // ==========================================

  Future<
    void
  >
  resetTrainingStorage() async {
    await clearOldData();
  }
}
