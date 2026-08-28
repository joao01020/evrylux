import '../../core/storage/storage_service.dart';

/*

|
| Screen
|    ↓
| Controller
|    ↓
| Service
|    ↓
| Repository
|    ↓
| StorageService
|
| Cada camada recebe apenas a dependência da camada abaixo.
| Assim toda a aplicação utiliza uma única instância dos serviços,
| facilitando manutenção, testes e evolução do projeto.

*/

class TrainingRepository {
  // =========================================================
  // CARREGAR TREINOS
  // =========================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    return await StorageService.getTraining();
  }

  // =========================================================
  // SALVAR TREINO
  // =========================================================

  Future<
    void
  >
  save({
    required String day,
    required String training,
    required int minutes,
    required DateTime date,
  }) async {
    await StorageService.saveTraining(
      day,
      training,
      minutes,
      date: date,
    );
  }

  // =========================================================
  // CARREGAR PLANO SEMANAL
  // =========================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  loadTrainingPlan() async {
    final data = await StorageService.getTrainingPlan();

    if (data.isEmpty) {
      return null;
    }

    return data;
  }

  // =========================================================
  // SALVAR PLANO SEMANAL
  // =========================================================

  Future<
    void
  >
  saveTrainingPlan({
    required int weeklyGoal,
    required List<
      int
    >
    plannedWeekdays,
  }) async {
    final normalizedWeekdays =
        plannedWeekdays
            .where(
              (
                weekday,
              ) {
                return weekday >=
                        DateTime.monday &&
                    weekday <=
                        DateTime.sunday;
              },
            )
            .toSet()
            .toList()
          ..sort();

    if (normalizedWeekdays.isEmpty) {
      throw ArgumentError(
        'Selecione pelo menos um dia da semana.',
      );
    }

    await StorageService.saveTrainingPlan(
      weeklyGoal: normalizedWeekdays.length,
      plannedWeekdays: normalizedWeekdays,
    );
  }

  // =========================================================
  // LIMPAR PLANO SEMANAL
  // =========================================================

  Future<
    void
  >
  clearTrainingPlan() async {
    await StorageService.clearTrainingPlan();
  }

  // =========================================================
  // LIMPAR TREINOS
  // =========================================================

  Future<
    void
  >
  clear() async {
    await StorageService.clearTraining();
  }

  // =========================================================
  // RESET COMPLETO
  // =========================================================

  Future<
    void
  >
  clearAll() async {
    await StorageService.clearTraining();

    await StorageService.clearTrainingPlan();
  }
}
