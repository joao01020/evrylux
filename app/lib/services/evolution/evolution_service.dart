import '../../models/evolution/evolution_model.dart';
import '../../data/evolution/evolution_repository.dart';

class EvolutionService {
  final EvolutionRepository repository;

  EvolutionService({
    required this.repository,
  });

  Future<
    EvolutionModel
  >
  loadEvolution() async {
    final study = await repository.loadStudy();

    final training = await repository.loadTraining();

    final finance = await repository.loadFinance();

    final knowledge =
        (study.length /
                30)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    final health =
        (training.length /
                30)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    double invested = 0;

    if (finance["invested"] !=
        null) {
      invested =
          (finance["invested"]
                  as num)
              .toDouble();
    }

    final financeProgress =
        (invested /
                10000)
            .clamp(
              0.0,
              1.0,
            )
            .toDouble();

    return EvolutionModel(
      knowledge: knowledge,
      health: health,
      finance: financeProgress,
    );
  }
}
