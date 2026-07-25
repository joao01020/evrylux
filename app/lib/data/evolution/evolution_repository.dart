import '../../data/study/study_repository.dart';
import '../../data/training/training_repository.dart';
import '../../data/finance/finance_repository.dart';

class EvolutionRepository {
  final StudyRepository studyRepository;

  final TrainingRepository trainingRepository;

  final FinanceRepository financeRepository;

  EvolutionRepository({
    required this.studyRepository,
    required this.trainingRepository,
    required this.financeRepository,
  });

  Future<
    Map<
      String,
      dynamic
    >
  >
  loadStudy() {
    return studyRepository.load();
  }

  Future<
    Map<
      String,
      dynamic
    >
  >
  loadTraining() {
    return trainingRepository.load();
  }

  Future<
    Map<
      String,
      dynamic
    >
  >
  loadFinance() {
    return financeRepository.load();
  }
}
