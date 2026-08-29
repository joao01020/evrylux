import '../../data/repository/crypto/crypto_repository.dart';
import '../../models/crypto/crypto_transaction_model.dart';

class CryptoService {
  const CryptoService({
    required this.repository,
  });

  // ============================================================
  // REPOSITORY
  // ============================================================

  final CryptoRepository repository;

  // ============================================================
  // MOEDAS SUPORTADAS
  // ============================================================

  List<
    String
  >
  get supportedSymbols {
    return List<
      String
    >.unmodifiable(
      CryptoRepository.supportedSymbols,
    );
  }

  // ============================================================
  // CARREGAR TRANSAÇÕES POR MOEDA
  // ============================================================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  load(
    String symbol,
  ) {
    return repository.bySymbol(
      symbol,
    );
  }

  // ============================================================
  // CARREGAR TODAS AS TRANSAÇÕES
  // ============================================================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  loadAll({
    bool forceRefresh = false,
  }) {
    return repository.load(
      forceRefresh: forceRefresh,
    );
  }

  // ============================================================
  // ADICIONAR
  // ============================================================

  Future<
    void
  >
  add(
    CryptoTransactionModel transaction,
  ) {
    return repository.add(
      transaction,
    );
  }

  // ============================================================
  // EDITAR
  // ============================================================

  Future<
    bool
  >
  update(
    CryptoTransactionModel transaction,
  ) {
    return repository.update(
      transaction,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    bool
  >
  delete(
    String id,
  ) {
    return repository.delete(
      id,
    );
  }

  // ============================================================
  // TOTAL DE QUANTIDADE
  // ============================================================

  Future<
    double
  >
  totalQuantity(
    String symbol,
  ) {
    return repository.totalQuantity(
      symbol,
    );
  }

  // ============================================================
  // TOTAL INVESTIDO
  // ============================================================

  Future<
    double
  >
  totalInvested(
    String symbol,
  ) {
    return repository.totalInvested(
      symbol,
    );
  }

  // ============================================================
  // PREÇO MÉDIO DE COMPRA
  // ============================================================
  //
  // Exemplo:
  //
  // Total investido = R$ 1.000
  // Quantidade BTC = 0.002
  //
  // Preço médio = R$ 500.000 / BTC
  //
  // ============================================================

  Future<
    double
  >
  averagePurchasePrice(
    String symbol,
  ) {
    return repository.averagePurchasePrice(
      symbol,
    );
  }

  // ============================================================
  // VALOR ATUAL DE UMA CRIPTOMOEDA
  // ============================================================
  //
  // quantidade total
  // ×
  // cotação atual em BRL
  //
  // ============================================================

  Future<
    double
  >
  currentValueBrl(
    String symbol, {
    required double currentPriceBrl,
  }) {
    return repository.currentValueBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );
  }

  // ============================================================
  // LUCRO / PREJUÍZO EM REAIS
  // ============================================================

  Future<
    double
  >
  profitLossBrl(
    String symbol, {
    required double currentPriceBrl,
  }) {
    return repository.profitLossBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );
  }

  // ============================================================
  // LUCRO / PREJUÍZO EM %
  // ============================================================

  Future<
    double
  >
  profitLossPercent(
    String symbol, {
    required double currentPriceBrl,
  }) {
    return repository.profitLossPercent(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );
  }

  // ============================================================
  // QUANTIDADES DE TODAS AS MOEDAS
  // ============================================================
  //
  // Retorno:
  //
  // {
  //   'BTC': 0.001,
  //   'ETH': 0.02,
  //   'SOL': 1.5,
  //   'USDT': 10,
  // }
  //
  // ============================================================

  Future<
    Map<
      String,
      double
    >
  >
  allQuantities() {
    return repository.allQuantities();
  }

  // ============================================================
  // TOTAL INVESTIDO POR MOEDA
  // ============================================================
  //
  // Retorno:
  //
  // {
  //   'BTC': 500,
  //   'ETH': 200,
  //   'SOL': 100,
  //   'USDT': 50,
  // }
  //
  // ============================================================

  Future<
    Map<
      String,
      double
    >
  >
  allInvested() {
    return repository.allInvested();
  }

  // ============================================================
  // TOTAL INVESTIDO NA CARTEIRA DE CRIPTO
  // ============================================================
  //
  // Soma o dinheiro originalmente investido:
  //
  // BTC + ETH + SOL + USDT
  //
  // Isso NÃO representa o valor atual.
  //
  // ============================================================

  Future<
    double
  >
  totalPortfolioInvested() {
    return repository.totalPortfolioInvested();
  }

  // ============================================================
  // VALOR ATUAL DA CARTEIRA
  // ============================================================
  //
  // Exemplo de pricesBrl:
  //
  // {
  //   'BTC': 600000,
  //   'ETH': 25000,
  //   'SOL': 800,
  //   'USDT': 5.40,
  // }
  //
  // Retorna:
  //
  // quantidade BTC × preço BTC
  // +
  // quantidade ETH × preço ETH
  // +
  // quantidade SOL × preço SOL
  // +
  // quantidade USDT × preço USDT
  //
  // ============================================================

  Future<
    double
  >
  currentPortfolioValueBrl(
    Map<
      String,
      double
    >
    pricesBrl,
  ) {
    return repository.currentPortfolioValueBrl(
      pricesBrl,
    );
  }

  // ============================================================
  // RESULTADO TOTAL DA CARTEIRA
  // ============================================================
  //
  // valor atual
  // -
  // total investido
  //
  // ============================================================

  Future<
    double
  >
  portfolioProfitLossBrl(
    Map<
      String,
      double
    >
    pricesBrl,
  ) {
    return repository.portfolioProfitLossBrl(
      pricesBrl,
    );
  }

  // ============================================================
  // RESULTADO TOTAL DA CARTEIRA EM %
  // ============================================================

  Future<
    double
  >
  portfolioProfitLossPercent(
    Map<
      String,
      double
    >
    pricesBrl,
  ) {
    return repository.portfolioProfitLossPercent(
      pricesBrl,
    );
  }

  // ============================================================
  // POSSUI TRANSAÇÕES
  // ============================================================

  Future<
    bool
  >
  hasTransactions(
    String symbol,
  ) {
    return repository.hasTransactions(
      symbol,
    );
  }

  // ============================================================
  // QUANTIDADE DE TRANSAÇÕES
  // ============================================================

  Future<
    int
  >
  count({
    String? symbol,
  }) {
    return repository.count(
      symbol: symbol,
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() {
    return repository.refresh();
  }

  // ============================================================
  // INVALIDAR CACHE
  // ============================================================

  void invalidateCache() {
    repository.invalidateCache();
  }

  // ============================================================
  // LIMPAR CARTEIRA
  // ============================================================

  Future<
    void
  >
  clear() {
    return repository.clear();
  }
}
