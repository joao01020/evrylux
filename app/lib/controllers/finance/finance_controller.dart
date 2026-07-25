import '../../models/finance/finance_model.dart';
import '../../services/finance/finance_service.dart';

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
