import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String trainingKey = "training_data";

  static const String studyKey = "study_data";

  static const String financeKey = "finance_data";

  static const String evolutionKey = "evolution_history";

  // ======================================================
  // EVOLUTION
  // ======================================================

  static Future<
    void
  >
  saveEvolution(
    String day,
    Map<
      String,
      dynamic
    >
    evolution,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    Map<
      String,
      dynamic
    >
    data = {};

    final saved = prefs.getString(
      evolutionKey,
    );

    if (saved !=
        null) {
      data =
          Map<
            String,
            dynamic
          >.from(
            jsonDecode(
              saved,
            ),
          );
    }

    data[day] = {
      "knowledge": evolution["knowledge"],

      "health": evolution["health"],

      "finance": evolution["finance"],

      "date": DateTime.now().toIso8601String(),
    };

    await prefs.setString(
      evolutionKey,
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
  getEvolution() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(
      evolutionKey,
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

  static Future<
    void
  >
  clearEvolution() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      evolutionKey,
    );
  }

  // ======================================================
  // TREINO
  // ======================================================

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

    final saved = prefs.getString(
      trainingKey,
    );

    if (saved !=
        null) {
      data =
          Map<
            String,
            dynamic
          >.from(
            jsonDecode(
              saved,
            ),
          );
    }

    data[day] = {
      "training": training,

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

    final saved = prefs.getString(
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

  // APAGAR TREINOS SALVOS

  static Future<
    void
  >
  clearTraining() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      trainingKey,
    );
  }

  // ======================================================
  // ESTUDOS
  // ======================================================

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

    final saved = prefs.getString(
      studyKey,
    );

    if (saved !=
        null) {
      data =
          Map<
            String,
            dynamic
          >.from(
            jsonDecode(
              saved,
            ),
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

    final saved = prefs.getString(
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

  static Future<
    void
  >
  clearStudy() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      studyKey,
    );
  }

  // ======================================================
  // FINANÇAS
  // ======================================================

  static Future<
    void
  >
  saveFinance(
    Map<
      String,
      dynamic
    >
    data,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      financeKey,
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
  getFinance() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(
      financeKey,
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

  static Future<
    void
  >
  clearFinance() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      financeKey,
    );
  }
}
