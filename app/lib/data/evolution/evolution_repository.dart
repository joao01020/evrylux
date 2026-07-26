import 'dart:convert';

import '../../core/storage/local_storage.dart';

import '../../models/evolution/evolution_model.dart';

import '../study/study_repository.dart';
import '../training/training_repository.dart';
import '../../screens/finance/data/finance_repository.dart';

class EvolutionRepository {
  final StudyRepository studyRepository;

  final TrainingRepository trainingRepository;

  final FinanceRepository financeRepository;

  final LocalStorage storage;

  static const String evolutionKey = "evolution_history";

  EvolutionRepository({
    required this.studyRepository,

    required this.trainingRepository,

    required this.financeRepository,

    required this.storage,
  });

  // ======================================================
  // DADOS BASE DA EVOLUÇÃO
  // ======================================================

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

  // ======================================================
  // SALVAR HISTÓRICO
  // ======================================================

  Future<
    void
  >
  save(
    EvolutionModel model,
  ) async {
    final saved = await storage.get(
      evolutionKey,
    );

    Map<
      String,
      dynamic
    >
    history = {};

    if (saved !=
        null) {
      history =
          Map<
            String,
            dynamic
          >.from(
            jsonDecode(
              saved,
            ),
          );
    }

    final date =
        model.date ??
        DateTime.now();

    final key =
        "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";

    history[key] = model
        .copyWith(
          date: date,
        )
        .toMap();

    await storage.save(
      evolutionKey,

      jsonEncode(
        history,
      ),
    );
  }

  // ======================================================
  // CARREGAR HISTÓRICO
  // ======================================================

  Future<
    Map<
      String,
      EvolutionModel
    >
  >
  loadHistory() async {
    final saved = await storage.get(
      evolutionKey,
    );

    if (saved ==
        null) {
      return {};
    }

    final Map<
      String,
      dynamic
    >
    data =
        Map<
          String,
          dynamic
        >.from(
          jsonDecode(
            saved,
          ),
        );

    final Map<
      String,
      EvolutionModel
    >
    history = {};

    data.forEach(
      (
        key,
        value,
      ) {
        history[key] = EvolutionModel.fromMap(
          Map<
            String,
            dynamic
          >.from(
            value,
          ),
        );
      },
    );

    return history;
  }
}
