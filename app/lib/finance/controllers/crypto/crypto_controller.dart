import 'package:flutter/foundation.dart';

import '../../models/crypto/crypto_transaction_model.dart';
import '../../services/crypto/crypto_service.dart';

class CryptoController
    extends
        ChangeNotifier {
  CryptoController({
    required this.service,
  });

  // ============================================================
  // SERVICE
  // ============================================================

  final CryptoService service;

  // ============================================================
  // TRANSAÇÕES DA MOEDA ATUAL
  // ============================================================

  List<
    CryptoTransactionModel
  >
  transactions = [];

  // ============================================================
  // MOEDA ATUAL
  // ============================================================

  String currentSymbol = '';

  // ============================================================
  // DADOS DA MOEDA ATUAL
  // ============================================================

  double quantity = 0;

  double invested = 0;

  double averagePurchasePrice = 0;

  double currentPriceBrl = 0;

  double currentValueBrl = 0;

  double profitLossBrl = 0;

  double profitLossPercent = 0;

  // ============================================================
  // PREÇOS DA CARTEIRA
  // ============================================================

  final Map<
    String,
    double
  >
  _pricesBrl = {
    'BTC': 0,
    'ETH': 0,
    'SOL': 0,
    'USDT': 0,
  };

  // ============================================================
  // QUANTIDADES DA CARTEIRA
  // ============================================================

  Map<
    String,
    double
  >
  quantities = {
    'BTC': 0,
    'ETH': 0,
    'SOL': 0,
    'USDT': 0,
  };

  // ============================================================
  // VALORES INVESTIDOS POR MOEDA
  // ============================================================

  Map<
    String,
    double
  >
  investedBySymbol = {
    'BTC': 0,
    'ETH': 0,
    'SOL': 0,
    'USDT': 0,
  };

  // ============================================================
  // VALORES ATUAIS POR MOEDA
  // ============================================================

  Map<
    String,
    double
  >
  currentValuesBrl = {
    'BTC': 0,
    'ETH': 0,
    'SOL': 0,
    'USDT': 0,
  };

  // ============================================================
  // CARTEIRA TOTAL
  // ============================================================

  double totalCryptoInvested = 0;

  double cryptoPatrimonyBrl = 0;

  double portfolioProfitLossBrl = 0;

  double portfolioProfitLossPercent = 0;

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;

  bool isLoadingPortfolio = false;

  String? errorMessage;

  // ============================================================
  // PREÇOS
  // ============================================================

  Map<
    String,
    double
  >
  get pricesBrl {
    return Map<
      String,
      double
    >.unmodifiable(
      _pricesBrl,
    );
  }

  double priceFor(
    String symbol,
  ) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    return _pricesBrl[normalizedSymbol] ??
        0;
  }

  // ============================================================
  // GET QUANTITY BY SYMBOL
  // ============================================================

  double quantityFor(
    String symbol,
  ) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    return quantities[normalizedSymbol] ??
        0;
  }

  // ============================================================
  // GET INVESTED BY SYMBOL
  // ============================================================

  double investedFor(
    String symbol,
  ) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    return investedBySymbol[normalizedSymbol] ??
        0;
  }

  // ============================================================
  // GET CURRENT VALUE BY SYMBOL
  // ============================================================

  double currentValueFor(
    String symbol,
  ) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    return currentValuesBrl[normalizedSymbol] ??
        0;
  }

  // ============================================================
  // HAS CURRENT PRICE
  // ============================================================

  bool hasPrice(
    String symbol,
  ) {
    return priceFor(
          symbol,
        ) >
        0;
  }

  // ============================================================
  // GET BY SYMBOL
  // ============================================================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  getBySymbol(
    String symbol,
  ) async {
    await load(
      symbol,
    );

    return List<
      CryptoTransactionModel
    >.unmodifiable(
      transactions,
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load(
    String symbol,
  ) async {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    if (normalizedSymbol.isEmpty) {
      clearCurrent();
      return;
    }

    currentSymbol = normalizedSymbol;

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // TRANSAÇÕES
      // ========================================================

      transactions = await service.load(
        normalizedSymbol,
      );

      // ========================================================
      // QUANTIDADE
      // ========================================================

      quantity = _safeValue(
        await service.totalQuantity(
          normalizedSymbol,
        ),
      );

      // ========================================================
      // TOTAL INVESTIDO
      // ========================================================

      invested = _safeValue(
        await service.totalInvested(
          normalizedSymbol,
        ),
      );

      // ========================================================
      // PREÇO MÉDIO
      // ========================================================

      averagePurchasePrice = _safeValue(
        await service.averagePurchasePrice(
          normalizedSymbol,
        ),
      );

      // ========================================================
      // PREÇO ATUAL
      // ========================================================

      currentPriceBrl = priceFor(
        normalizedSymbol,
      );

      // ========================================================
      // VALOR ATUAL
      // ========================================================

      await _calculateCurrentSymbol();

      // ========================================================
      // ATUALIZA MAPAS
      // ========================================================

      quantities[normalizedSymbol] = quantity;

      investedBySymbol[normalizedSymbol] = invested;

      currentValuesBrl[normalizedSymbol] = currentValueBrl;
    } catch (
      error,
      stackTrace
    ) {
      errorMessage =
          'Não foi possível carregar os dados de '
          '$normalizedSymbol.';

      debugPrint(
        '[CRYPTO CONTROLLER][LOAD] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } finally {
      isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD WITH PRICE
  // ============================================================
  //
  // Útil quando a tela/API já possui a cotação atual.
  //
  // ============================================================

  Future<
    void
  >
  loadWithPrice(
    String symbol, {
    required double priceBrl,
  }) async {
    setPrice(
      symbol,
      priceBrl,
      notify: false,
    );

    await load(
      symbol,
    );
  }

  // ============================================================
  // LOAD PORTFOLIO
  // ============================================================

  Future<
    void
  >
  loadPortfolio() async {
    isLoadingPortfolio = true;
    errorMessage = null;

    notifyListeners();

    try {
      // ========================================================
      // QUANTIDADES
      // ========================================================

      quantities = await service.allQuantities();

      // ========================================================
      // TOTAL INVESTIDO POR MOEDA
      // ========================================================

      investedBySymbol = await service.allInvested();

      // ========================================================
      // TOTAL INVESTIDO EM CRIPTO
      // ========================================================

      totalCryptoInvested = _safeValue(
        await service.totalPortfolioInvested(),
      );

      // ========================================================
      // VALORES ATUAIS
      // ========================================================

      final newValues =
          <
            String,
            double
          >{};

      for (final symbol in service.supportedSymbols) {
        final price = priceFor(
          symbol,
        );

        if (price <=
            0) {
          newValues[symbol] = 0;

          continue;
        }

        newValues[symbol] = _safeValue(
          await service.currentValueBrl(
            symbol,
            currentPriceBrl: price,
          ),
        );
      }

      currentValuesBrl = newValues;

      // ========================================================
      // PATRIMÔNIO CRIPTO
      // ========================================================

      cryptoPatrimonyBrl = _safeValue(
        await service.currentPortfolioValueBrl(
          _pricesBrl,
        ),
      );

      // ========================================================
      // RESULTADO TOTAL
      // ========================================================

      portfolioProfitLossBrl = await service.portfolioProfitLossBrl(
        _pricesBrl,
      );

      portfolioProfitLossPercent = await service.portfolioProfitLossPercent(
        _pricesBrl,
      );

      // ========================================================
      // ATUALIZA MOEDA ATUAL
      // ========================================================

      if (currentSymbol.isNotEmpty) {
        quantity = quantityFor(
          currentSymbol,
        );

        invested = investedFor(
          currentSymbol,
        );

        currentPriceBrl = priceFor(
          currentSymbol,
        );

        currentValueBrl = currentValueFor(
          currentSymbol,
        );

        averagePurchasePrice = _calculateAveragePrice(
          quantity: quantity,
          invested: invested,
        );

        _calculateProfitLoss();
      }
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível carregar a carteira de criptomoedas.';

      debugPrint(
        '[CRYPTO CONTROLLER]'
        '[LOAD PORTFOLIO] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    } finally {
      isLoadingPortfolio = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SET PRICE
  // ============================================================

  void setPrice(
    String symbol,
    double priceBrl, {
    bool notify = true,
  }) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    if (normalizedSymbol.isEmpty) {
      return;
    }

    _pricesBrl[normalizedSymbol] = _safeValue(
      priceBrl,
    );

    if (normalizedSymbol ==
        currentSymbol) {
      currentPriceBrl =
          _pricesBrl[normalizedSymbol] ??
          0;

      _calculateCurrentSymbolFromMemory();
    }

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // SET PRICES
  // ============================================================

  void setPrices(
    Map<
      String,
      double
    >
    prices, {
    bool notify = true,
  }) {
    for (final entry in prices.entries) {
      final symbol = _normalizeSymbol(
        entry.key,
      );

      if (symbol.isEmpty) {
        continue;
      }

      _pricesBrl[symbol] = _safeValue(
        entry.value,
      );
    }

    if (currentSymbol.isNotEmpty) {
      currentPriceBrl = priceFor(
        currentSymbol,
      );

      _calculateCurrentSymbolFromMemory();
    }

    _calculatePortfolioFromMemory();

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<
    void
  >
  add(
    CryptoTransactionModel transaction,
  ) async {
    errorMessage = null;

    try {
      await service.add(
        transaction,
      );

      await load(
        transaction.symbol,
      );

      await loadPortfolio();
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível adicionar a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER][ADD] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<
    void
  >
  update(
    CryptoTransactionModel transaction,
  ) async {
    errorMessage = null;

    try {
      final updated = await service.update(
        transaction,
      );

      if (!updated) {
        throw StateError(
          'Transação não encontrada.',
        );
      }

      await load(
        transaction.symbol,
      );

      await loadPortfolio();
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível atualizar a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER]'
        '[UPDATE] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  delete(
    String id,
  ) async {
    errorMessage = null;

    try {
      final deleted = await service.delete(
        id,
      );

      if (!deleted) {
        throw StateError(
          'Transação não encontrada.',
        );
      }

      if (currentSymbol.isNotEmpty) {
        await load(
          currentSymbol,
        );
      }

      await loadPortfolio();
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível excluir a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER]'
        '[DELETE] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // REFRESH CURRENT
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (currentSymbol.isEmpty) {
      return;
    }

    service.invalidateCache();

    await load(
      currentSymbol,
    );
  }

  // ============================================================
  // REFRESH ALL
  // ============================================================

  Future<
    void
  >
  refreshAll() async {
    service.invalidateCache();

    await service.refresh();

    if (currentSymbol.isNotEmpty) {
      await load(
        currentSymbol,
      );
    }

    await loadPortfolio();
  }

  // ============================================================
  // CALCULATE CURRENT SYMBOL
  // ============================================================

  Future<
    void
  >
  _calculateCurrentSymbol() async {
    if (currentSymbol.isEmpty ||
        currentPriceBrl <=
            0) {
      currentValueBrl = 0;

      profitLossBrl = 0;

      profitLossPercent = 0;

      return;
    }

    currentValueBrl = _safeValue(
      await service.currentValueBrl(
        currentSymbol,
        currentPriceBrl: currentPriceBrl,
      ),
    );

    profitLossBrl = await service.profitLossBrl(
      currentSymbol,
      currentPriceBrl: currentPriceBrl,
    );

    profitLossPercent = await service.profitLossPercent(
      currentSymbol,
      currentPriceBrl: currentPriceBrl,
    );
  }

  // ============================================================
  // CALCULATE CURRENT SYMBOL FROM MEMORY
  // ============================================================

  void _calculateCurrentSymbolFromMemory() {
    if (currentSymbol.isEmpty) {
      return;
    }

    currentValueBrl =
        quantity *
        currentPriceBrl;

    currentValuesBrl[currentSymbol] = currentValueBrl;

    _calculateProfitLoss();

    _calculatePortfolioFromMemory();
  }

  // ============================================================
  // CALCULATE PROFIT / LOSS
  // ============================================================

  void _calculateProfitLoss() {
    profitLossBrl =
        currentValueBrl -
        invested;

    if (invested <=
        0) {
      profitLossPercent = 0;

      return;
    }

    profitLossPercent =
        (profitLossBrl /
            invested) *
        100;
  }

  // ============================================================
  // CALCULATE PORTFOLIO FROM MEMORY
  // ============================================================

  void _calculatePortfolioFromMemory() {
    double currentTotal = 0;

    double investedTotal = 0;

    for (final symbol in service.supportedSymbols) {
      final quantityValue = quantityFor(
        symbol,
      );

      final priceValue = priceFor(
        symbol,
      );

      final currentValue =
          quantityValue *
          priceValue;

      currentValuesBrl[symbol] = currentValue;

      currentTotal += currentValue;

      investedTotal += investedFor(
        symbol,
      );
    }

    cryptoPatrimonyBrl = currentTotal;

    totalCryptoInvested = investedTotal;

    portfolioProfitLossBrl =
        cryptoPatrimonyBrl -
        totalCryptoInvested;

    if (totalCryptoInvested <=
        0) {
      portfolioProfitLossPercent = 0;

      return;
    }

    portfolioProfitLossPercent =
        (portfolioProfitLossBrl /
            totalCryptoInvested) *
        100;
  }

  // ============================================================
  // CALCULATE AVERAGE PRICE
  // ============================================================

  double _calculateAveragePrice({
    required double quantity,
    required double invested,
  }) {
    if (quantity <=
        0) {
      return 0;
    }

    return invested /
        quantity;
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (errorMessage ==
        null) {
      return;
    }

    errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR CURRENT
  // ============================================================

  void clearCurrent({
    bool notify = true,
  }) {
    transactions = [];

    quantity = 0;

    invested = 0;

    averagePurchasePrice = 0;

    currentPriceBrl = 0;

    currentValueBrl = 0;

    profitLossBrl = 0;

    profitLossPercent = 0;

    currentSymbol = '';

    isLoading = false;

    errorMessage = null;

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR ALL STATE
  // ============================================================

  void clear() {
    clearCurrent(
      notify: false,
    );

    quantities = {
      'BTC': 0,
      'ETH': 0,
      'SOL': 0,
      'USDT': 0,
    };

    investedBySymbol = {
      'BTC': 0,
      'ETH': 0,
      'SOL': 0,
      'USDT': 0,
    };

    currentValuesBrl = {
      'BTC': 0,
      'ETH': 0,
      'SOL': 0,
      'USDT': 0,
    };

    _pricesBrl
      ..clear()
      ..addAll(
        {
          'BTC': 0,
          'ETH': 0,
          'SOL': 0,
          'USDT': 0,
        },
      );

    totalCryptoInvested = 0;

    cryptoPatrimonyBrl = 0;

    portfolioProfitLossBrl = 0;

    portfolioProfitLossPercent = 0;

    isLoadingPortfolio = false;

    errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // NORMALIZE SYMBOL
  // ============================================================

  String _normalizeSymbol(
    String symbol,
  ) {
    return symbol.trim().toUpperCase();
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
