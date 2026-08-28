import '../../data/repository/finance_repository.dart';
import '../../models/finance_model.dart';

class FinanceService {
  final FinanceRepository repository;

  FinanceService({
    required this.repository,
  });

  static String calculateEstimate({
    required double current,
    required double goal,
    required double monthly,
  }) {
    final missing =
        goal -
        current;

    if (missing <=
        0) {
      return "Meta alcançada 🎉";
    }

    if (monthly <=
        0) {
      return "Defina um investimento mensal";
    }

    final months =
        (missing /
                monthly)
            .ceil();

    final years =
        months ~/
        12;
    final rest =
        months %
        12;

    if (years >
        0) {
      return "$years anos e $rest meses";
    }

    return "$months meses";
  }

  Future<
    void
  >
  saveFinance(
    FinanceModel model,
  ) async {
    await repository.save(
      {
        // Patrimônio
        "patrimony": model.patrimony,
        "invested": model.invested,
        "monthlyGoal": model.monthlyGoal,
        "investmentGoal": model.investmentGoal,

        // Planejamento
        "minimumGoal": model.minimumGoal,
        "mediumGoal": model.mediumGoal,
        "maximumGoal": model.maximumGoal,
        "projectionYears": model.projectionYears,

        // Histórico
        "totalInvested": model.totalInvested,
        "investedMonths": model.investedMonths,
        "averageContribution": model.averageContribution,

        // Criptomoedas
        "bitcoin": model.bitcoin,
        "ethereum": model.ethereum,
        "solana": model.solana,
        "usdt": model.usdt,

        // Outros
        "selectedDay": model.selectedDay,
        "completedDays": model.completedDays,
      },
    );
  }

  Future<
    FinanceModel
  >
  loadFinance() async {
    final data = await repository.load();

    if (data.isEmpty) {
      return FinanceModel();
    }

    return FinanceModel(
      // Patrimônio
      patrimony:
          (data["patrimony"] ??
                  0)
              .toDouble(),
      invested:
          (data["invested"] ??
                  0)
              .toDouble(),
      monthlyGoal:
          (data["monthlyGoal"] ??
                  0)
              .toDouble(),
      investmentGoal:
          (data["investmentGoal"] ??
                  0)
              .toDouble(),

      // Planejamento
      minimumGoal:
          (data["minimumGoal"] ??
                  0)
              .toDouble(),
      mediumGoal:
          (data["mediumGoal"] ??
                  0)
              .toDouble(),
      maximumGoal:
          (data["maximumGoal"] ??
                  0)
              .toDouble(),
      projectionYears:
          data["projectionYears"] ??
          10,

      // Histórico
      totalInvested:
          (data["totalInvested"] ??
                  0)
              .toDouble(),
      investedMonths:
          data["investedMonths"] ??
          0,
      averageContribution:
          (data["averageContribution"] ??
                  0)
              .toDouble(),

      // Criptomoedas
      bitcoin:
          (data["bitcoin"] ??
                  0)
              .toDouble(),
      ethereum:
          (data["ethereum"] ??
                  0)
              .toDouble(),
      solana:
          (data["solana"] ??
                  0)
              .toDouble(),
      usdt:
          (data["usdt"] ??
                  0)
              .toDouble(),

      // Outros
      selectedDay: data["selectedDay"],

      completedDays:
          data["completedDays"] !=
              null
          ? List<
              bool
            >.from(
              data["completedDays"],
            )
          : List.filled(
              7,
              false,
            ),
    );
  }

  Future<
    void
  >
  clearFinance() async {
    await repository.save(
      {},
    );
  }
}
