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

  // histórico visual antigo
  final List<
    String
  >
  history = [];

  // novos dados completos
  List<
    TrainingModel
  >
  trainings = [];

  String? selectedActivity;

  String? selectedDay;

  int streak = 0;

  int currentSeconds = 0;

  // ==========================================
  // CARREGAR TREINOS
  // ==========================================

  Future<
    void
  >
  load() async {
    try {
      trainings = await service.getTrainings();

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

      for (final TrainingModel training in trainings) {
        history.add(
          "${training.day} - "
          "${training.training} - "
          "${training.minutes} min",
        );

        final index = days.indexOf(
          training.day,
        );

        if (index >=
                0 &&
            !completedDays[index]) {
          completedDays[index] = true;

          streak++;
        }
      }

      notifyListeners();
    } catch (
      error
    ) {
      debugPrint(
        "Erro carregando treinos: $error",
      );
    }
  }

  // ==========================================
  // SALVAR TREINO PELA TELA
  // ==========================================

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

      date: DateTime.now(),
    );

    await saveTraining(
      model,
    );

    selectedActivity = null;

    currentSeconds = 0;

    await load();
  }

  // ==========================================
  // SALVAR DIRETO
  // ==========================================

  Future<
    void
  >
  saveTraining(
    TrainingModel model,
  ) async {
    try {
      await service.saveTraining(
        model,
      );

      notifyListeners();
    } catch (
      error
    ) {
      debugPrint(
        "Erro salvando treino: $error",
      );
    }
  }

  // ==========================================
  // HISTÓRICO COMPLETO
  // ==========================================

  Future<
    List<
      TrainingModel
    >
  >
  loadHistory() async {
    try {
      return await service.getTrainings();
    } catch (
      error
    ) {
      debugPrint(
        "Erro carregando histórico: $error",
      );

      return [];
    }
  }

  // ==========================================
  // BUSCAR TREINOS PELO DIA
  // ==========================================

  List<
    TrainingModel
  >
  getDayTrainings(
    DateTime date,
  ) {
    return trainings.where(
      (
        training,
      ) {
        return training.date.year ==
                date.year &&
            training.date.month ==
                date.month &&
            training.date.day ==
                date.day;
      },
    ).toList();
  }

  // ==========================================
  // CONTROLES UI
  // ==========================================

  void selectDay(
    int index,
  ) {
    if (index <
            0 ||
        index >=
            days.length) {
      return;
    }

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
