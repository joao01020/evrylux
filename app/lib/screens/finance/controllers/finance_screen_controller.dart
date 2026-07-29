import '../projections/finance_projection.dart';
import '../services/history/investment_history.dart';

import '../models/crypto/crypto_balances.dart';

import '../services/crypto/crypto_balance_service.dart';
import '../services/finance_contribution_service.dart';
import '../services/finance_persistence_service.dart';
import '../services/history/finance_history_storage.dart';

class FinanceScreenController {
  final dynamic financeController;
  final dynamic cryptoController;

  final FinanceContributionService _contributionService = const FinanceContributionService();

  late final CryptoBalanceService _cryptoBalanceService;

  late final FinancePersistenceService _persistenceService;

  final List<
    InvestmentHistory
  >
  history = [];

  CryptoBalances balances = const CryptoBalances();

  bool isLoading = true;

  FinanceScreenController({
    required this.financeController,
    required this.cryptoController,
  }) {
    _cryptoBalanceService = CryptoBalanceService(
      cryptoController: cryptoController,
    );

    _persistenceService = FinancePersistenceService(
      financeController: financeController,
      historyStorage: const FinanceHistoryStorage(),
    );
  }

  dynamic get model {
    return financeController.model;
  }

  FinanceProjection get projection {
    return FinanceProjection(
      model: model,
      history: history,
    );
  }

  Future<
    void
  >
  load() async {
    isLoading = true;

    try {
      await financeController.loadData();

      balances = await _cryptoBalanceService.loadBalances();

      final storedHistory = await _persistenceService.loadHistory();

      history
        ..clear()
        ..addAll(
          storedHistory,
        );
    } finally {
      isLoading = false;
    }
  }

  Future<
    void
  >
  refreshCryptoBalances() async {
    balances = await _cryptoBalanceService.loadBalances();
  }

  void applyPlanning(
    dynamic planning,
  ) {
    model.invested = planning.invested;
    model.minimumGoal = planning.minimumGoal;
    model.mediumGoal = planning.mediumGoal;
    model.maximumGoal = planning.maximumGoal;
    model.projectionYears = planning.projectionYears;

    model.monthlyGoal = planning.mediumGoal;
  }

  InvestmentHistory addContribution(
    double contribution,
  ) {
    final entry = projection.createHistoryEntry(
      contribution: contribution,
    );

    history.add(
      entry,
    );

    history.sort(
      (
        a,
        b,
      ) => a.date.compareTo(
        b.date,
      ),
    );

    _contributionService.addContribution(
      model: model,
      contribution: contribution,
    );

    return entry;
  }

  bool removeContribution(
    InvestmentHistory contribution,
  ) {
    final removed = history.remove(
      contribution,
    );

    if (!removed) {
      return false;
    }

    _contributionService.removeContribution(
      model: model,
      contribution: contribution,
    );

    return true;
  }

  void updatePatrimony(
    double value,
  ) {
    model.patrimony = value;
  }

  void updateInvestmentGoal(
    double value,
  ) {
    model.investmentGoal = value;
  }

  Future<
    void
  >
  saveModel() async {
    await financeController.saveData();
  }

  Future<
    void
  >
  saveAll() async {
    await _persistenceService.save(
      history: history,
    );
  }
}
