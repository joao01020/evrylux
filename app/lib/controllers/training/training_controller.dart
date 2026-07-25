import 'package:flutter/foundation.dart';

import '../../models/training/training_model.dart';
import '../../services/training/training_service.dart';

class TrainingController
    extends
        ChangeNotifier {
  final TrainingService service;

  TrainingController({
    required this.service,
  });

  final List<
    bool
  >
  completedDays = List.filled(
    7,
    false,
  );

  final List<
    String
  >
  days = [
    "segunda",
    "terça",
    "quarta",
    "quinta",
    "sexta",
    "sábado",
    "domingo",
  ];

  final List<
    String
  >
  activityOptions = [
    "🏋️ Peito",
    "🦵 Pernas",
    "💪 Braço",
    "🔥 Corrida",
    "🚶 Caminhada",
  ];

  final List<
    String
  >
  history = [];

  String? selectedActivity;

  String? selectedDay;

  int streak = 0;

  int currentSeconds = 0;

  Future<
    void
  >
  load() async {
    final studies = await service.getTrainings();

    history.clear();

    streak = 0;

    for (
      int i = 0;
      i <
          completedDays.length;
      i++
    ) {
      completedDays[i] = false;
    }

    for (final TrainingModel training in studies) {
      history.add(
        "${training.day} - ${training.training} - ${training.minutes} min",
      );

      if (!completedDays[days.indexOf(
        training.day,
      )]) {
        completedDays[days.indexOf(
              training.day,
            )] =
            true;
        streak++;
      }
    }

    notifyListeners();
  }

  Future<
    void
  >
  save() async {
    if (selectedDay ==
            null ||
        selectedActivity ==
            null) {
      return;
    }

    final model = TrainingModel(
      day: selectedDay!,
      training: selectedActivity!,
      minutes:
          currentSeconds ~/
          60,
    );

    await service.saveTraining(
      model,
    );

    selectedActivity = null;

    await load();

    notifyListeners();
  }

  void selectDay(
    int index,
  ) {
    selectedDay = days[index];

    notifyListeners();
  }

  void selectActivity(
    String activity,
  ) {
    selectedActivity = activity;

    notifyListeners();
  }

  void updateTimer(
    int seconds,
  ) {
    currentSeconds = seconds;

    notifyListeners();
  }
}
