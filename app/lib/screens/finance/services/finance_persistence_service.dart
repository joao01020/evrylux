import '../../../models/finance/investment_history.dart';
import 'history/finance_history_storage.dart';

class FinancePersistenceService {
  final dynamic financeController;
  final FinanceHistoryStorage historyStorage;

  const FinancePersistenceService({
    required this.financeController,
    required this.historyStorage,
  });

  Future<
    List<
      InvestmentHistory
    >
  >
  loadHistory() {
    return historyStorage.load();
  }

  Future<
    void
  >
  save({
    required List<
      InvestmentHistory
    >
    history,
  }) async {
    await financeController.saveData();
    await historyStorage.save(
      history,
    );
  }
}
