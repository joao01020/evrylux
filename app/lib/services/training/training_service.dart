import '../../data/training/training_repository.dart';
import '../../models/training/training_model.dart';

class TrainingService {
  final TrainingRepository repository;

  TrainingService({
    required this.repository,
  });

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
      final day = entry.key;
      final value = entry.value;

      if (value
          is List) {
        for (final item in value) {
          trainings.add(
            TrainingModel(
              day: day,
              training: item["training"],
              minutes: item["minutes"],
            ),
          );
        }
      } else if (value
          is Map) {
        trainings.add(
          TrainingModel(
            day: day,
            training: value["training"],
            minutes: value["minutes"],
          ),
        );
      }
    }

    return trainings;
  }

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
}
