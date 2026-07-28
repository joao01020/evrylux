import 'training_model.dart';

class TrainingDataParser {
  static const Set<String> configurationKeys = {
    'trainingPlan',
    'weeklyGoal',
    'plannedWeekdays',
  };

  bool isConfigurationKey(String key) {
    return configurationKeys.contains(key) || key.startsWith('_');
  }

  List<TrainingModel> parseTrainings({
    required String day,
    required dynamic value,
  }) {
    final items = _normalizeItems(value);

    return items
        .whereType<Map>()
        .map((item) => _parseTraining(day, item))
        .whereType<TrainingModel>()
        .toList();
  }

  Set<int> parseWeekdays(dynamic value) {
    if (value is! List) {
      return <int>{};
    }

    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .where(isValidWeekday)
        .toSet();
  }

  Set<int> normalizeWeekdays(Set<int> weekdays) {
    return weekdays.where(isValidWeekday).toSet();
  }

  bool isValidWeekday(int weekday) {
    return weekday >= DateTime.monday && weekday <= DateTime.sunday;
  }

  List<dynamic> _normalizeItems(dynamic value) {
    if (value is List) {
      return value;
    }

    if (value is Map) {
      return <dynamic>[value];
    }

    return const <dynamic>[];
  }

  TrainingModel? _parseTraining(String day, Map data) {
    final training = data['training'];

    if (training == null) {
      return null;
    }

    return TrainingModel(
      day: day,
      training: training.toString(),
      minutes: _parseInt(data['minutes']),
      date: _parseDate(data['date']),
    );
  }

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }

  int _parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
