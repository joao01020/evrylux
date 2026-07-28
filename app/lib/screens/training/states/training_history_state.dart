import '../models/training_model.dart';

mixin TrainingHistoryState {
  final List<
    String
  >
  history = [];
  List<
    TrainingModel
  >
  trainings = [];

  bool get hasTrainings => trainings.isNotEmpty;

  void setTrainings(
    Iterable<
      TrainingModel
    >
    values,
  ) {
    trainings =
        List<
          TrainingModel
        >.from(
          values,
        );
  }

  void clearTrainings() {
    trainings.clear();
  }

  void setHistory(
    Iterable<
      String
    >
    values,
  ) {
    history
      ..clear()
      ..addAll(
        values,
      );
  }

  void clearHistory() {
    history.clear();
  }

  void resetHistoryState() {
    clearHistory();
    clearTrainings();
  }
}
