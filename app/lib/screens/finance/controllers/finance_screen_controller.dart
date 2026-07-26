import 'package:flutter/foundation.dart';

import '../../../app_dependencies.dart';
import '../../../core/utils/finance_projection.dart';
import '../../../models/finance/investment_history.dart';

class FinanceScreenController
    extends
        ChangeNotifier {
  final _financeController = financeController;

  final List<
    InvestmentHistory
  >
  investmentHistory = [];

  double bitcoin = 0;
  double ethereum = 0;
  double solana = 0;
  double usdt = 0;

  bool isLoading = true;
  bool _disposed = false;

  dynamic get model => _financeController.model;

  FinanceProjection get projection {
    return FinanceProjection(
      model: model,
      history: investmentHistory,
    );
  }

  Future<
    void
  >
  load() async {
    isLoading = true;
    _notify();

    try {
      await Future.wait(
        [
          _financeController.loadData(),
          loadCryptoBalances(),
        ],
      );
    } finally {
      isLoading = false;
      _notify();
    }
  }

  Future<
    void
  >
  loadCryptoBalances() async {
    bitcoin = await _loadCryptoQuantity(
      'BTC',
    );
    ethereum = await _loadCryptoQuantity(
      'ETH',
    );
    solana = await _loadCryptoQuantity(
      'SOL',
    );
    usdt = await _loadCryptoQuantity(
      'USDT',
    );

    _notify();
  }

  Future<
    double
  >
  _loadCryptoQuantity(
    String symbol,
  ) async {
    await cryptoController.load(
      symbol,
    );

    return cryptoController.quantity;
  }

  Future<
    void
  >
  savePlanning({
    required double invested,
    required double minimumGoal,
    required double mediumGoal,
    required double maximumGoal,
    required int projectionYears,
  }) async {
    model.invested = invested;
    model.minimumGoal = minimumGoal;
    model.mediumGoal = mediumGoal;
    model.maximumGoal = maximumGoal;
    model.projectionYears = projectionYears;
    model.monthlyGoal = mediumGoal;

    await _save();
  }

  Future<
    void
  >
  addContribution(
    double contribution,
  ) async {
    final historyEntry = projection.createHistoryEntry(
      contribution: contribution,
    );

    investmentHistory.add(
      historyEntry,
    );

    model.invested += contribution;
    model.totalInvested += contribution;
    model.investedMonths += 1;
    model.patrimony += contribution;

    _updateAverageContribution();

    await _save();
  }

  Future<
    void
  >
  deleteContribution(
    InvestmentHistory item,
  ) async {
    investmentHistory.remove(
      item,
    );

    model.invested = _subtractWithoutNegative(
      model.invested,
      item.safeValue,
    );

    model.totalInvested = _subtractWithoutNegative(
      model.totalInvested,
      item.safeValue,
    );

    model.patrimony = _subtractWithoutNegative(
      model.patrimony,
      item.safeValue,
    );

    if (model.investedMonths >
        0) {
      model.investedMonths -= 1;
    }

    _updateAverageContribution();

    await _save();
  }

  Future<
    void
  >
  updatePatrimony(
    double value,
  ) async {
    model.patrimony = value;

    await _save();
  }

  Future<
    void
  >
  updateInvestmentGoal(
    double value,
  ) async {
    model.investmentGoal = value;

    await _save();
  }

  void _updateAverageContribution() {
    model.averageContribution =
        model.investedMonths >
            0
        ? model.totalInvested /
              model.investedMonths
        : 0;
  }

  double _subtractWithoutNegative(
    double currentValue,
    double valueToRemove,
  ) {
    return (currentValue -
            valueToRemove)
        .clamp(
          0.0,
          double.infinity,
        );
  }

  Future<
    void
  >
  _save() async {
    await _financeController.saveData();

    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
