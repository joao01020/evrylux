import '../models/finance_model.dart';
import '../services/persistence/finance_service.dart';

class FinanceController {
  final FinanceService service;

  FinanceModel model = FinanceModel();

  FinanceController(
    this.service,
  );

  // ============================================================
  // PREÇOS DAS CRIPTOMOEDAS EM BRL
  // ============================================================

  double bitcoinPriceBrl = 0;

  double ethereumPriceBrl = 0;

  double solanaPriceBrl = 0;

  double usdtPriceBrl = 0;

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  loadData() async {
    model = await service.loadFinance();
  }

  // ============================================================
  // LOAD LOCAL
  // ============================================================

  Future<void> loadLocalData() async {
    model = await service.loadLocalFinance();
  }

  // ============================================================
  // REFRESH REMOTE
  // ============================================================

  Future<void> refreshRemoteData() async {
    model = await service.refreshFinance();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  saveData() async {
    await service.saveFinance(
      model,
    );
  }

  // ============================================================
  // PATRIMÔNIO
  // ============================================================

  void updatePatrimony(
    double value,
  ) {
    model.patrimony = _safeValue(
      value,
    );
  }

  void updateInvested(
    double value,
  ) {
    model.invested = _safeValue(
      value,
    );
  }

  void updateMonthlyGoal(
    double value,
  ) {
    model.monthlyGoal = _safeValue(
      value,
    );
  }

  void updateInvestmentGoal(
    double value,
  ) {
    model.investmentGoal = _safeValue(
      value,
    );
  }

  // ============================================================
  // PLANEJAMENTO
  // ============================================================

  void updateMinimumGoal(
    double value,
  ) {
    model.minimumGoal = _safeValue(
      value,
    );
  }

  void updateMediumGoal(
    double value,
  ) {
    model.mediumGoal = _safeValue(
      value,
    );
  }

  void updateMaximumGoal(
    double value,
  ) {
    model.maximumGoal = _safeValue(
      value,
    );
  }

  void updateProjectionYears(
    int value,
  ) {
    model.projectionYears =
        value <
            0
        ? 0
        : value;
  }

  // ============================================================
  // HISTÓRICO DE APORTES
  // ============================================================

  void registerContribution(
    double value,
  ) {
    final contribution = _safeValue(
      value,
    );

    if (contribution <=
        0) {
      return;
    }

    model.totalInvested += contribution;

    model.investedMonths++;

    model.averageContribution =
        model.investedMonths <=
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

  // ============================================================
  // CÁLCULOS
  // ============================================================

  double projectedValue(
    double monthly,
  ) {
    final safeMonthly = _safeValue(
      monthly,
    );

    return safeMonthly *
        model.projectionYears *
        12;
  }

  double yearsToGoal(
    double monthly,
  ) {
    final safeMonthly = _safeValue(
      monthly,
    );

    if (safeMonthly <=
        0) {
      return 0;
    }

    final remaining =
        model.investmentGoal -
        totalPatrimony;

    if (remaining <=
        0) {
      return 0;
    }

    return remaining /
        (safeMonthly *
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
        totalPatrimony +
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

  // ============================================================
  // CRIPTOMOEDAS - QUANTIDADES
  // ============================================================

  void updateBitcoin(
    double value,
  ) {
    model.bitcoin = _safeValue(
      value,
    );
  }

  void updateEthereum(
    double value,
  ) {
    model.ethereum = _safeValue(
      value,
    );
  }

  void updateSolana(
    double value,
  ) {
    model.solana = _safeValue(
      value,
    );
  }

  void updateUsdt(
    double value,
  ) {
    model.usdt = _safeValue(
      value,
    );
  }

  // ============================================================
  // CRIPTOMOEDAS - PREÇOS
  // ============================================================

  void updateBitcoinPrice(
    double value,
  ) {
    bitcoinPriceBrl = _safeValue(
      value,
    );
  }

  void updateEthereumPrice(
    double value,
  ) {
    ethereumPriceBrl = _safeValue(
      value,
    );
  }

  void updateSolanaPrice(
    double value,
  ) {
    solanaPriceBrl = _safeValue(
      value,
    );
  }

  void updateUsdtPrice(
    double value,
  ) {
    usdtPriceBrl = _safeValue(
      value,
    );
  }

  // ============================================================
  // VALOR DE CADA CRIPTO
  // ============================================================

  double get bitcoinValueBrl {
    return model.bitcoin *
        bitcoinPriceBrl;
  }

  double get ethereumValueBrl {
    return model.ethereum *
        ethereumPriceBrl;
  }

  double get solanaValueBrl {
    return model.solana *
        solanaPriceBrl;
  }

  double get usdtValueBrl {
    return model.usdt *
        usdtPriceBrl;
  }

  // ============================================================
  // TOTAL EM CRIPTO
  // ============================================================

  double get cryptoPatrimony {
    return bitcoinValueBrl +
        ethereumValueBrl +
        solanaValueBrl +
        usdtValueBrl;
  }

  // ============================================================
  // PATRIMÔNIO TOTAL
  // ============================================================
  //
  // Patrimônio manual/base
  // +
  // valor atual das criptomoedas
  //
  // ============================================================

  double get totalPatrimony {
    return model.patrimony +
        cryptoPatrimony;
  }

  // ============================================================
  // TOTAL INVESTIDO + CRIPTO
  // ============================================================
  //
  // Caso você queira considerar o valor investido como base
  // do patrimônio em vez de model.patrimony, use este getter.
  //
  // ============================================================

  double get investedPlusCrypto {
    return model.invested +
        cryptoPatrimony;
  }

  // ============================================================
  // SAFE VALUE
  // ============================================================

  double _safeValue(
    double value,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }
}
