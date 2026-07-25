import '../../data/finance/finance_repository.dart';
import '../../models/finance/finance_model.dart';

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
        "invested": model.invested,
        "monthlyGoal": model.monthlyGoal,
        "investmentGoal": model.investmentGoal,
        "bitcoin": model.bitcoin,
        "ethereum": model.ethereum,
        "solana": model.solana,
        "usdt": model.usdt,
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
