import '../data/training_repository.dart';
import '../models/training_model.dart';
import '../models/data/training_plan_data.dart';

import '../models/data/training_data_parser.dart';
import 'training_plan_service.dart';
import 'training_record_service.dart';

class TrainingService {
  final TrainingRepository repository;

  late final TrainingRecordService recordService;
  late final TrainingPlanService planService;

  TrainingService({
    required this.repository,
  }) {
    final parser = TrainingDataParser();

    recordService = TrainingRecordService(
      repository: repository,
      parser: parser,
    );

    planService = TrainingPlanService(
      repository: repository,
      parser: parser,
    );
  }

  Future<
    List<
      TrainingModel
    >
  >
  getTrainings() {
    return recordService.getTrainings();
  }

  Future<
    void
  >
  saveTraining(
    TrainingModel model,
  ) {
    return recordService.saveTraining(
      model,
    );
  }

  Future<
    TrainingPlanData
  >
  getTrainingPlan() {
    return planService.getPlan();
  }

  Future<
    void
  >
  saveTrainingPlan({
    required Set<
      int
    >
    plannedWeekdays,
  }) {
    return planService.savePlan(
      plannedWeekdays: plannedWeekdays,
    );
  }

  Future<
    void
  >
  updateTrainingPlan({
    required int weeklyGoal,
    required Set<
      int
    >
    plannedWeekdays,
  }) {
    return planService.updatePlan(
      weeklyGoal: weeklyGoal,
      plannedWeekdays: plannedWeekdays,
    );
  }

  Future<
    void
  >
  clearOldData() {
    return recordService.clear();
  }

  Future<
    void
  >
  clearTrainingPlan() {
    return planService.clear();
  }

  Future<
    void
  >
  resetTrainingStorage() async {
    await Future.wait(
      [
        recordService.clear(),
        planService.clear(),
      ],
    );
  }
}
