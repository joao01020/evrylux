import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // ======================================================
  // CHAVES DO ARMAZENAMENTO
  // ======================================================

  static const String trainingKey = 'training_data';

  static const String trainingPlanKey = 'training_plan_data';

  static const String studyKey = 'study_data';

  static const String financeKey = 'finance_data';

  static const String evolutionKey = 'evolution_history';

  // ======================================================
  // EVOLUTION
  // ======================================================

  static Future<void> saveEvolution(
    String day,
    Map<String, dynamic> evolution,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> data = {};

    final saved = prefs.getString(evolutionKey);

    if (saved != null) {
      final decoded = _decodeMap(saved);

      data = Map<String, dynamic>.from(decoded);
    }

    data[day] = {
      'knowledge': evolution['knowledge'],
      'health': evolution['health'],
      'finance': evolution['finance'],
      'date': DateTime.now().toIso8601String(),
    };

    await prefs.setString(evolutionKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getEvolution() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(evolutionKey);

    if (saved == null) {
      return {};
    }

    return _decodeMap(saved);
  }

  static Future<void> clearEvolution() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(evolutionKey);
  }

  // ======================================================
  // TREINO
  // ======================================================

  static Future<void> saveTraining(
    String day,
    String training,
    int minutes, {
    DateTime? date,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> data = {};

    final saved = prefs.getString(trainingKey);

    if (saved != null) {
      data = _decodeMap(saved);
    }

    final trainingDate = date ?? DateTime.now();

    final newTraining = {
      'training': training,
      'activity': training,
      'minutes': minutes,
      'date': trainingDate.toIso8601String(),
    };

    final currentDayData = data[day];

    // ====================================================
    // DIA AINDA NÃO POSSUI REGISTROS
    // ====================================================

    if (currentDayData == null) {
      data[day] = [newTraining];
    }
    // ====================================================
    // DIA JÁ ESTÁ NO FORMATO DE LISTA
    // ====================================================
    else if (currentDayData is List) {
      final updatedList = List<dynamic>.from(currentDayData);

      updatedList.add(newTraining);

      data[day] = updatedList;
    }
    // ====================================================
    // CONVERTER FORMATO ANTIGO PARA LISTA
    // ====================================================
    else if (currentDayData is Map) {
      data[day] = [Map<String, dynamic>.from(currentDayData), newTraining];
    }
    // ====================================================
    // DADO INVÁLIDO: SUBSTITUIR POR UMA LISTA NOVA
    // ====================================================
    else {
      data[day] = [newTraining];
    }

    await prefs.setString(trainingKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getTraining() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(trainingKey);

    if (saved == null) {
      return {};
    }

    return _decodeMap(saved);
  }

  // ======================================================
  // APAGAR TREINOS SALVOS
  // ======================================================

  static Future<void> clearTraining() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(trainingKey);
  }

  // ======================================================
  // PLANO SEMANAL DE TREINO
  // ======================================================

  static Future<void> saveTrainingPlan({
    required int weeklyGoal,
    required List<int> plannedWeekdays,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final normalizedWeekdays =
        plannedWeekdays
            .where((weekday) {
              return weekday >= DateTime.monday && weekday <= DateTime.sunday;
            })
            .toSet()
            .toList()
          ..sort();

    if (normalizedWeekdays.isEmpty) {
      throw ArgumentError('Selecione pelo menos um dia da semana.');
    }

    final normalizedGoal = normalizedWeekdays.length;

    final data = {
      'weeklyGoal': normalizedGoal,
      'plannedWeekdays': normalizedWeekdays,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(trainingPlanKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getTrainingPlan() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(trainingPlanKey);

    if (saved == null) {
      return {};
    }

    final data = _decodeMap(saved);

    final rawWeekdays = data['plannedWeekdays'];

    if (rawWeekdays is! List) {
      return {};
    }

    final plannedWeekdays =
        rawWeekdays
            .map((value) {
              return int.tryParse(value.toString());
            })
            .whereType<int>()
            .where((weekday) {
              return weekday >= DateTime.monday && weekday <= DateTime.sunday;
            })
            .toSet()
            .toList()
          ..sort();

    if (plannedWeekdays.isEmpty) {
      return {};
    }

    return {
      'weeklyGoal': plannedWeekdays.length,
      'plannedWeekdays': plannedWeekdays,
      'updatedAt': data['updatedAt'],
    };
  }

  static Future<void> clearTrainingPlan() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(trainingPlanKey);
  }

  // ======================================================
  // RESET COMPLETO DO TREINO
  // ======================================================

  static Future<void> clearAllTrainingData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(trainingKey);

    await prefs.remove(trainingPlanKey);
  }

  // ======================================================
  // ESTUDOS
  // ======================================================

  static Future<void> saveStudy(String day, int minutes) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> data = {};

    final saved = prefs.getString(studyKey);

    if (saved != null) {
      data = _decodeMap(saved);
    }

    data[day] = {'minutes': minutes, 'date': DateTime.now().toIso8601String()};

    await prefs.setString(studyKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getStudy() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(studyKey);

    if (saved == null) {
      return {};
    }

    return _decodeMap(saved);
  }

  static Future<void> clearStudy() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(studyKey);
  }

  // ======================================================
  // FINANÇAS
  // ======================================================

  static Future<void> saveFinance(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(financeKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>> getFinance() async {
    final prefs = await SharedPreferences.getInstance();

    final saved = prefs.getString(financeKey);

    if (saved == null) {
      return {};
    }

    return _decodeMap(saved);
  }

  static Future<void> clearFinance() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(financeKey);
  }

  // ======================================================
  // CONVERSÃO SEGURA DE JSON
  // ======================================================

  static Map<String, dynamic> _decodeMap(String source) {
    try {
      final decoded = jsonDecode(source);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {};
    } catch (_) {
      return {};
    }
  }
}
