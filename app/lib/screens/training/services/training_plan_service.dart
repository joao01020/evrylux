import '../data/training_repository.dart';
import '../models/training_plan_data.dart';
import '../models/training_data_parser.dart';

class TrainingPlanService {
  final TrainingRepository repository;
  final TrainingDataParser parser;

  TrainingPlanService({required this.repository, required this.parser});

  Future<TrainingPlanData> getPlan() async {
    try {
      final data = await repository.loadTrainingPlan();
      final weekdays = parser.parseWeekdays(data?['plannedWeekdays']);

      if (weekdays.isEmpty) {
        return TrainingPlanData.defaultPlan();
      }

      return TrainingPlanData(
        weeklyGoal: weekdays.length,
        plannedWeekdays: weekdays,
      );
    } catch (_) {
      return TrainingPlanData.defaultPlan();
    }
  }

  Future<void> savePlan({required Set<int> plannedWeekdays}) {
    return _saveNormalizedPlan(plannedWeekdays);
  }

  Future<void> updatePlan({
    required int weeklyGoal,
    required Set<int> plannedWeekdays,
  }) {
    _validateWeeklyGoal(weeklyGoal);

    return _saveNormalizedPlan(plannedWeekdays);
  }

  Future<void> _saveNormalizedPlan(Set<int> plannedWeekdays) {
    final weekdays = parser.normalizeWeekdays(plannedWeekdays).toList()..sort();

    if (weekdays.isEmpty) {
      throw ArgumentError('Selecione pelo menos um dia da semana.');
    }

    return repository.saveTrainingPlan(
      weeklyGoal: weekdays.length,
      plannedWeekdays: weekdays,
    );
  }

  void _validateWeeklyGoal(int weeklyGoal) {
    if (weeklyGoal < 1 || weeklyGoal > 7) {
      throw ArgumentError.value(
        weeklyGoal,
        'weeklyGoal',
        'A meta semanal deve estar entre 1 e 7.',
      );
    }
  }

  Future<void> clear() {
    return repository.clearTrainingPlan();
  }
}
