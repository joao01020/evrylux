import '../models/finance_model.dart';
import '../services/persistence/finance_service.dart';

class FinanceController {
  final FinanceService service;

  FinanceModel model = FinanceModel();

  FinanceController(
    this.service,
  );

  Future<
    void
  >
  loadData() async {
    model = await service.loadFinance();
  }

  Future<
    void
  >
  saveData() async {
    await service.saveFinance(
      model,
    );
  }

  //========================================
  // Patrimônio
  //========================================

  void updatePatrimony(
    double value,
  ) {
    model.patrimony = value;
  }

  void updateInvested(
    double value,
  ) {
    model.invested = value;
  }

  void updateMonthlyGoal(
    double value,
  ) {
    model.monthlyGoal = value;
  }

  void updateInvestmentGoal(
    double value,
  ) {
    model.investmentGoal = value;
  }

  //========================================
  // Planejamento
  //========================================

  void updateMinimumGoal(
    double value,
  ) {
    model.minimumGoal = value;
  }

  void updateMediumGoal(
    double value,
  ) {
    model.mediumGoal = value;
  }

  void updateMaximumGoal(
    double value,
  ) {
    model.maximumGoal = value;
  }

  void updateProjectionYears(
    int value,
  ) {
    model.projectionYears = value;
  }

  //========================================
  // Histórico de aportes
  //========================================

  void registerContribution(
    double value,
  ) {
    model.totalInvested += value;

    model.investedMonths++;

    model.averageContribution =
        model.investedMonths ==
            0
        ? 0
        : model.totalInvested /
              model.investedMonths;
  }

  void resetContributionHistory() {
    model.totalInvested = 0;

    model.investedMonths = 0;

    model.averageContribution = 0;
  }

  //========================================
  // Cálculos
  //========================================

  double projectedValue(
    double monthly,
  ) {
    return monthly *
        model.projectionYears *
        12;
  }

  double yearsToGoal(
    double monthly,
  ) {
    if (monthly <=
        0) {
      return 0;
    }

    final remaining =
        model.investmentGoal -
        model.patrimony;

    if (remaining <=
        0) {
      return 0;
    }

    return remaining /
        (monthly *
            12);
  }

  double progressByRhythm(
    double monthly,
  ) {
    if (model.investmentGoal <=
        0) {
      return 0;
    }

    final projected =
        model.patrimony +
        projectedValue(
          monthly,
        );

    final progress =
        projected /
        model.investmentGoal;

    if (progress >
        1) {
      return 1;
    }

    if (progress <
        0) {
      return 0;
    }

    return progress;
  }

  //========================================
  // Criptomoedas
  //========================================

  void updateBitcoin(
    double value,
  ) {
    model.bitcoin = value;
  }

  void updateEthereum(
    double value,
  ) {
    model.ethereum = value;
  }

  void updateSolana(
    double value,
  ) {
    model.solana = value;
  }

  void updateUsdt(
    double value,
  ) {
    model.usdt = value;
  }
}
