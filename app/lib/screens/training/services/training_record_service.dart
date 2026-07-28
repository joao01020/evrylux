import '../data/training_repository.dart';
import '../models/training_model.dart';
import '../models/training_data_parser.dart';

class TrainingRecordService {
  final TrainingRepository repository;
  final TrainingDataParser parser;

  TrainingRecordService({
    required this.repository,
    required this.parser,
  });

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

      if (parser.isConfigurationKey(
        day,
      )) {
        continue;
      }

      trainings.addAll(
        parser.parseTrainings(
          day: day,
          value: entry.value,
        ),
      );
    }

    trainings.sort(
      (
        first,
        second,
      ) => second.date.compareTo(
        first.date,
      ),
    );

    return trainings;
  }

  Future<
    void
  >
  saveTraining(
    TrainingModel model,
  ) {
    return repository.save(
      day: model.day,
      training: model.training,
      minutes: model.minutes,
      date: model.date,
    );
  }

  Future<
    void
  >
  clear() {
    return repository.clear();
  }
}
