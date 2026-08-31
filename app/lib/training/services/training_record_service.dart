import '../data/training_repository.dart';
import '../models/training_model.dart';
import '../models/data/training_data_parser.dart';

// ============================================================
// TRAINING RECORD SERVICE
// ============================================================
//
// Responsável pelos registros de treino.
//
// Cronômetro removido.
//
// Agora cada registro possui apenas:
//
// - dia;
// - atividade;
// - data.
//
// ============================================================

class TrainingRecordService {
  const TrainingRecordService({
    required this.repository,
    required this.parser,
  });

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final TrainingRepository repository;

  final TrainingDataParser parser;

  // ============================================================
  // CARREGAR TREINOS
  // ============================================================

  Future<
    List<
      TrainingModel
    >
  >
  getTrainings() async {
    final data = await repository.load();

    final trainings =
        <
          TrainingModel
        >[];

    for (final entry in data.entries) {
      final day = entry.key.toString();

      // ========================================================
      // IGNORAR CONFIGURAÇÕES
      // ========================================================

      if (parser.isConfigurationKey(
        day,
      )) {
        continue;
      }

      // ========================================================
      // PARSE
      // ========================================================

      final parsed = parser.parseTrainings(
        day: day,
        value: entry.value,
      );

      trainings.addAll(
        parsed,
      );
    }

    // ==========================================================
    // MAIS RECENTES PRIMEIRO
    // ==========================================================

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

  // ============================================================
  // SALVAR TREINO
  // ============================================================
  //
  // Cronômetro removido.
  //
  // Antes:
  //
  // repository.save(
  //   day: model.day,
  //   training: model.training,
  //   minutes: model.minutes,
  //   date: model.date,
  // );
  //
  // Agora:
  //
  // repository.save(
  //   day: model.day,
  //   training: model.training,
  //   date: model.date,
  // );
  //
  // ============================================================

  Future<
    void
  >
  saveTraining(
    TrainingModel model,
  ) {
    return repository.save(
      day: model.day,
      training: model.training,
      date: model.date,
    );
  }

  // ============================================================
  // LIMPAR TREINOS
  // ============================================================

  Future<
    void
  >
  clear() {
    return repository.clear();
  }
}
