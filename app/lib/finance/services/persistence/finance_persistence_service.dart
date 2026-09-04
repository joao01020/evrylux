import '../history/finance_history_storage.dart';
import '../history/investment_history.dart';

class FinancePersistenceService {
  final dynamic financeController;

  final FinanceHistoryStorage historyStorage;

  const FinancePersistenceService({
    required this.financeController,
    required this.historyStorage,
  });

  // ============================================================
  // LOAD HISTORY
  // ============================================================

  Future<
    List<
      InvestmentHistory
    >
  >
  loadHistory() {
    return historyStorage.load();
  }

  // ============================================================
  // LOAD CACHED HISTORY
  // ============================================================

  Future<List<InvestmentHistory>> loadCachedHistory() {
    return historyStorage.loadLocal();
  }

  // ============================================================
  // REFRESH HISTORY
  // ============================================================

  Future<List<InvestmentHistory>> refreshHistory() {
    return historyStorage.refreshFromRemote();
  }

  // ============================================================
  // SAVE ALL
  // ============================================================

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
