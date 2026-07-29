import 'package:flutter/material.dart';

import '../data/repository/study_repository.dart';
import '../models/study_model.dart';
import '../brain/services/study_service.dart';

class StudyController
    extends
        ChangeNotifier {
  late final StudyService service;

  StudyController({
    StudyService? service,
  }) {
    this.service =
        service ??
        StudyService(
          repository: StudyRepository(),
        );
  }

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

  List<
    bool
  >
  completedDays = List.filled(
    7,
    false,
  );

  String? selectedDay;

  int streak = 0;

  int currentSeconds = 0;

  int totalStudyMinutes = 0;

  List<
    StudyModel
  >
  studies = [];

  Future<
    void
  >
  loadStudies() async {
    studies = await service.getStudies();

    totalStudyMinutes = 0;

    for (final study in studies) {
      totalStudyMinutes += study.minutes;
    }

    streak = studies.length;

    completedDays = List.filled(
      7,
      false,
    );

    for (
      int i = 0;
      i <
          days.length;
      i++
    ) {
      completedDays[i] = studies.any(
        (
          study,
        ) {
          return study.day ==
              days[i];
        },
      );
    }

    notifyListeners();
  }

  void selectDay(
    int index,
  ) {
    selectedDay = days[index];

    notifyListeners();
  }

  void updateTimer(
    int seconds,
  ) {
    currentSeconds = seconds;

    notifyListeners();
  }

  Future<
    void
  >
  saveStudy() async {
    if (selectedDay ==
        null) {
      return;
    }

    final minutes =
        currentSeconds ~/
        60;

    await service.saveStudy(
      selectedDay!,

      minutes,
    );

    await loadStudies();
  }
}
