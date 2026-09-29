import 'dart:convert';

import '../../../../core/storage/local_storage.dart';
import '../../../models/crypto/crypto_transaction_model.dart';

class CryptoRepository {
  CryptoRepository({
    required this.storage,
  });

  // ============================================================
  // STORAGE
  // ============================================================

  final LocalStorage storage;

  // ============================================================
  // KEYS
  // ============================================================

  static const String key = 'crypto_transactions';

  // ============================================================
  // CACHE
  // ============================================================

  List<
    CryptoTransactionModel
  >?
  _cache;

  // ============================================================
  // MOEDAS SUPORTADAS
  // ============================================================

  static const List<
    String
  >
  supportedSymbols = [
    'BTC',
    'ETH',
    'SOL',
    'USDT',
  ];

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  load({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cache !=
            null) {
      return List<
        CryptoTransactionModel
      >.from(
        _cache!,
      );
    }

    final storedJson = await storage.get(
      key,
    );

    if (storedJson ==
            null ||
        storedJson.trim().isEmpty) {
      _cache =
          <
            CryptoTransactionModel
          >[];

      return <
        CryptoTransactionModel
      >[];
    }

    try {
      final decoded = jsonDecode(
        storedJson,
      );

      if (decoded
          is! List) {
        _cache =
            <
              CryptoTransactionModel
            >[];

        return <
          CryptoTransactionModel
        >[];
      }

      final transactions =
          <
            CryptoTransactionModel
          >[];

      for (final item in decoded) {
        if (item
            is! Map) {
          continue;
        }

        try {
          final transaction = CryptoTransactionModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          );

          transactions.add(
            transaction,
          );
        } catch (
          _
        ) {
          // Ignora registro inválido
          // sem impedir o carregamento
          // dos demais.
        }
      }

      transactions.sort(
        (
          first,
          second,
        ) {
          return second.date.compareTo(
            first.date,
          );
        },
      );

      _cache =
          List<
            CryptoTransactionModel
          >.from(
            transactions,
          );

      return List<
        CryptoTransactionModel
      >.from(
        transactions,
      );
    } on FormatException {
      _cache =
          <
            CryptoTransactionModel
          >[];

      return <
        CryptoTransactionModel
      >[];
    } on TypeError {
      _cache =
          <
            CryptoTransactionModel
          >[];

      return <
        CryptoTransactionModel
      >[];
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  save(
    List<
      CryptoTransactionModel
    >
    transactions,
  ) async {
    final transactionsCopy =
        List<
          CryptoTransactionModel
        >.from(
          transactions,
        );

    transactionsCopy.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    final encodedTransactions = jsonEncode(
      transactionsCopy.map(
        (
          transaction,
        ) {
          return transaction.toMap();
        },
      ).toList(),
    );

    await storage.save(
      key,
      encodedTransactions,
    );

    _cache = transactionsCopy;
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
    final transactions = await load();

    transactions.add(
      transaction,
    );

    await save(
      transactions,
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<
    bool
  >
  update(
    CryptoTransactionModel transaction,
  ) async {
    final transactions = await load();

    final index = transactions.indexWhere(
      (
        item,
      ) {
        return item.id ==
            transaction.id;
      },
    );

    if (index ==
        -1) {
      return false;
    }

    transactions[index] = transaction;

    await save(
      transactions,
    );

    return true;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    bool
  >
  delete(
    String id,
  ) async {
    final transactions = await load();

    final initialLength = transactions.length;

    transactions.removeWhere(
      (
        item,
      ) {
        return item.id ==
            id;
      },
    );

    final removed =
        transactions.length !=
        initialLength;

    if (!removed) {
      return false;
    }

    await save(
      transactions,
    );

    return true;
  }

  // ============================================================
  // GET BY SYMBOL
  // ============================================================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  bySymbol(
    String symbol,
  ) async {
    final transactions = await load();

    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    final filteredTransactions = transactions.where(
      (
        transaction,
      ) {
        return _normalizeSymbol(
              transaction.symbol,
            ) ==
            normalizedSymbol;
      },
    ).toList();

    filteredTransactions.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    return filteredTransactions;
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  Future<
    double
  >
  totalQuantity(
    String symbol,
  ) async {
    final transactions = await bySymbol(
      symbol,
    );

    double total = 0;

    for (final transaction in transactions) {
      final quantity = _safeValue(
        transaction.quantity,
      );

      total += quantity;
    }

    return total;
  }

  // ============================================================
  // TOTAL INVESTED
  // ============================================================

  Future<
    double
  >
  totalInvested(
    String symbol,
  ) async {
    final transactions = await bySymbol(
      symbol,
    );

    double total = 0;

    for (final transaction in transactions) {
      final invested = _safeValue(
        transaction.invested,
      );

      total += invested;
    }

    return total;
  }

  // ============================================================
  // CURRENT VALUE
  // ============================================================
  //
  // Valor atual =
  //
  // quantidade total
  // ×
  // cotação atual em BRL
  //
  // Exemplo:
  //
  // 0.001 BTC × R$ 600.000
  // = R$ 600
  //
  // ============================================================

  Future<
    double
  >
  currentValueBrl(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final price = _safeValue(
      currentPriceBrl,
    );

    if (price <=
        0) {
      return 0;
    }

    final quantity = await totalQuantity(
      symbol,
    );

    return quantity *
        price;
  }

  // ============================================================
  // PROFIT / LOSS
  // ============================================================
  //
  // Resultado =
  //
  // valor atual
  // -
  // total investido
  //
  // ============================================================

  Future<
    double
  >
  profitLossBrl(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final currentValue = await currentValueBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );

    final invested = await totalInvested(
      symbol,
    );

    return currentValue -
        invested;
  }

  // ============================================================
  // PROFIT / LOSS %
  // ============================================================

  Future<
    double
  >
  profitLossPercent(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final invested = await totalInvested(
      symbol,
    );

    if (invested <=
        0) {
      return 0;
    }

    final result = await profitLossBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );

    return (result /
            invested) *
        100;
  }

  // ============================================================
  // AVERAGE PURCHASE PRICE
  // ============================================================
  //
  // Preço médio =
  //
  // total investido
  // /
  // quantidade total
  //
  // ============================================================

  Future<
    double
  >
  averagePurchasePrice(
    String symbol,
  ) async {
    final quantity = await totalQuantity(
      symbol,
    );

    if (quantity <=
        0) {
      return 0;
    }

    final invested = await totalInvested(
      symbol,
    );

    return invested /
        quantity;
  }

  // ============================================================
  // ALL QUANTITIES
  // ============================================================

  Future<
    Map<
      String,
      double
    >
  >
  allQuantities() async {
    final result =
        <
          String,
          double
        >{};

    for (final symbol in supportedSymbols) {
      result[symbol] = await totalQuantity(
        symbol,
      );
    }

    return result;
  }

  // ============================================================
  // ALL INVESTED
  // ============================================================

  Future<
    Map<
      String,
      double
    >
  >
  allInvested() async {
    final result =
        <
          String,
          double
        >{};

    for (final symbol in supportedSymbols) {
      result[symbol] = await totalInvested(
        symbol,
      );
    }

    return result;
  }

  // ============================================================
  // TOTAL INVESTED PORTFOLIO
  // ============================================================

  Future<
    double
  >
  totalPortfolioInvested() async {
    double total = 0;

    for (final symbol in supportedSymbols) {
      total += await totalInvested(
        symbol,
      );
    }

    return total;
  }

  // ============================================================
  // CURRENT PORTFOLIO VALUE
  // ============================================================
  //
  // pricesBrl deve possuir:
  //
  // {
  //   'BTC': 600000,
  //   'ETH': 25000,
  //   'SOL': 800,
  //   'USDT': 5.40,
  // }
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
  ) async {
    double total = 0;

    for (final symbol in supportedSymbols) {
      final price = _findPrice(
        pricesBrl,
        symbol,
      );

      if (price <=
          0) {
        continue;
      }

      total += await currentValueBrl(
        symbol,
        currentPriceBrl: price,
      );
    }

    return total;
  }

  // ============================================================
  // PORTFOLIO PROFIT / LOSS
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
  ) async {
    final currentValue = await currentPortfolioValueBrl(
      pricesBrl,
    );

    final invested = await totalPortfolioInvested();

    return currentValue -
        invested;
  }

  // ============================================================
  // PORTFOLIO PROFIT / LOSS %
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
  ) async {
    final invested = await totalPortfolioInvested();

    if (invested <=
        0) {
      return 0;
    }

    final result = await portfolioProfitLossBrl(
      pricesBrl,
    );

    return (result /
            invested) *
        100;
  }

  // ============================================================
  // HAS TRANSACTIONS
  // ============================================================

  Future<
    bool
  >
  hasTransactions(
    String symbol,
  ) async {
    final transactions = await bySymbol(
      symbol,
    );

    return transactions.isNotEmpty;
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count({
    String? symbol,
  }) async {
    if (symbol ==
            null ||
        symbol.trim().isEmpty) {
      final transactions = await load();

      return transactions.length;
    }

    final transactions = await bySymbol(
      symbol,
    );

    return transactions.length;
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
  // FIND PRICE
  // ============================================================

  double _findPrice(
    Map<
      String,
      double
    >
    prices,
    String symbol,
  ) {
    final normalizedSymbol = _normalizeSymbol(
      symbol,
    );

    for (final entry in prices.entries) {
      if (_normalizeSymbol(
            entry.key,
          ) ==
          normalizedSymbol) {
        return _safeValue(
          entry.value,
        );
      }
    }

    return 0;
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

  // ============================================================
  // INVALIDATE CACHE
  // ============================================================

  void invalidateCache() {
    _cache = null;
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    await load(
      forceRefresh: true,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    await storage.save(
      key,
      jsonEncode(
        <
          dynamic
        >[],
      ),
    );

    _cache =
        <
          CryptoTransactionModel
        >[];
  }
}
