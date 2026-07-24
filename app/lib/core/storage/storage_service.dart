import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String trainingKey = "training_data";

  static const String studyKey = "study_data";

  // =========================
  // TREINO
  // =========================

  static Future<
    void
  >
  saveTraining(
    String day,
    String training,
    int minutes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    Map<
      String,
      dynamic
    >
    data = {};

    String? saved = prefs.getString(
      trainingKey,
    );

    if (saved !=
        null) {
      data = jsonDecode(
        saved,
      );
    }

    data[day] = {
      "activity": training,

      "minutes": minutes,

      "date": DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      trainingKey,

      jsonEncode(
        data,
      ),
    );
  }

  static Future<
    Map<
      String,
      dynamic
    >
  >
  getTraining() async {
    final prefs = await SharedPreferences.getInstance();

    String? saved = prefs.getString(
      trainingKey,
    );

    if (saved ==
        null) {
      return {};
    }

    return Map<
      String,
      dynamic
    >.from(
      jsonDecode(
        saved,
      ),
    );
  }

  // =========================
  // ESTUDOS
  // =========================

  static Future<
    void
  >
  saveStudy(
    String day,
    int minutes,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    Map<
      String,
      dynamic
    >
    data = {};

    String? saved = prefs.getString(
      studyKey,
    );

    if (saved !=
        null) {
      data = jsonDecode(
        saved,
      );
    }

    data[day] = {
      "minutes": minutes,

      "date": DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      studyKey,

      jsonEncode(
        data,
      ),
    );
  }

  static Future<
    Map<
      String,
      dynamic
    >
  >
  getStudy() async {
    final prefs = await SharedPreferences.getInstance();

    String? saved = prefs.getString(
      studyKey,
    );

    if (saved ==
        null) {
      return {};
    }

    return Map<
      String,
      dynamic
    >.from(
      jsonDecode(
        saved,
      ),
    );
  }
}
