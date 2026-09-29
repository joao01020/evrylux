import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../../../core/storage/local_storage.dart';
import '../../../models/crypto/crypto_transaction_model.dart';

class CryptoRepository {
  CryptoRepository({required this.storage});

  // ============================================================
  // STORAGE
  // ============================================================

  final LocalStorage storage;

  // ============================================================
  // KEYS
  // ============================================================

  static const String key = 'crypto_transactions';

  static const String _cloudTable = 'finance_crypto_transactions';

  // ============================================================
  // CACHE
  // ============================================================

  List<CryptoTransactionModel>? _cache;

  // ============================================================
  // MOEDAS SUPORTADAS
  // ============================================================

  static const List<String> supportedSymbols = ['BTC', 'ETH', 'SOL', 'USDT'];

  // ============================================================
  // CLOUD-AWARE LOAD
  // ============================================================

  Future<List<CryptoTransactionModel>> load({bool forceRefresh = false}) async {
    if (kIsWeb || forceRefresh) {
      try {
        return await _syncWithCloud();
      } catch (error, stackTrace) {
        debugPrint('[CRYPTO REPOSITORY][CLOUD LOAD] $error');
        debugPrint('$stackTrace');
        return _loadLocal(forceRefresh: forceRefresh);
      }
    }

    return _loadLocal(forceRefresh: forceRefresh);
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<List<CryptoTransactionModel>> _loadLocal({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache != null) {
      return List<CryptoTransactionModel>.from(_cache!);
    }

    final storedJson = await storage.get(key);

    if (storedJson == null || storedJson.trim().isEmpty) {
      _cache = <CryptoTransactionModel>[];

      return <CryptoTransactionModel>[];
    }

    try {
      final decoded = jsonDecode(storedJson);

      if (decoded is! List) {
        _cache = <CryptoTransactionModel>[];

        return <CryptoTransactionModel>[];
      }

      final transactions = <CryptoTransactionModel>[];

      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }

        try {
          final transaction = CryptoTransactionModel.fromMap(
            Map<String, dynamic>.from(item),
          );

          transactions.add(transaction);
        } catch (_) {
          // Ignora registro inválido
          // sem impedir o carregamento
          // dos demais.
        }
      }

      transactions.sort((first, second) {
        return second.date.compareTo(first.date);
      });

      _cache = List<CryptoTransactionModel>.from(transactions);

      return List<CryptoTransactionModel>.from(transactions);
    } on FormatException {
      _cache = <CryptoTransactionModel>[];

      return <CryptoTransactionModel>[];
    } on TypeError {
      _cache = <CryptoTransactionModel>[];

      return <CryptoTransactionModel>[];
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> save(List<CryptoTransactionModel> transactions) async {
    final transactionsCopy = List<CryptoTransactionModel>.from(transactions);

    transactionsCopy.sort((first, second) {
      return second.date.compareTo(first.date);
    });

    final encodedTransactions = jsonEncode(
      transactionsCopy.map((transaction) {
        return transaction.toMap();
      }).toList(),
    );

    await storage.save(key, encodedTransactions);

    _cache = transactionsCopy;
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<void> add(CryptoTransactionModel transaction) async {
    final transactions = await _loadLocal();

    final index = transactions.indexWhere((item) => item.id == transaction.id);

    if (index == -1) {
      transactions.add(transaction);
    } else {
      transactions[index] = transaction;
    }

    await save(transactions);

    try {
      await _upsertCloudTransaction(transaction);
      await _syncFinanceAggregates(transactions);
    } catch (error, stackTrace) {
      debugPrint('[CRYPTO REPOSITORY][ADD CLOUD] $error');
      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<bool> update(CryptoTransactionModel transaction) async {
    var transactions = await _loadLocal();

    var index = transactions.indexWhere((item) => item.id == transaction.id);

    if (index == -1 && kIsWeb) {
      transactions = await _syncWithCloud();
      index = transactions.indexWhere((item) => item.id == transaction.id);
    }

    if (index == -1) {
      return false;
    }

    transactions[index] = transaction;
    await save(transactions);

    try {
      await _upsertCloudTransaction(transaction);
      await _syncFinanceAggregates(transactions);
    } catch (error, stackTrace) {
      debugPrint('[CRYPTO REPOSITORY][UPDATE CLOUD] $error');
      debugPrint('$stackTrace');
    }

    return true;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> delete(String id) async {
    var transactions = await _loadLocal();

    var before = transactions.length;
    transactions.removeWhere((item) => item.id == id);
    var removed = transactions.length != before;

    if (!removed && kIsWeb) {
      transactions = await _syncWithCloud();
      before = transactions.length;
      transactions.removeWhere((item) => item.id == id);
      removed = transactions.length != before;
    }

    if (!removed) {
      return false;
    }

    await save(transactions);

    try {
      await _tombstoneCloudTransaction(id);
      await _syncFinanceAggregates(transactions);
    } catch (error, stackTrace) {
      debugPrint('[CRYPTO REPOSITORY][DELETE CLOUD] $error');
      debugPrint('$stackTrace');
    }

    return true;
  }

  // ============================================================
  // GET BY SYMBOL
  // ============================================================

  Future<List<CryptoTransactionModel>> bySymbol(String symbol) async {
    final transactions = await load();

    final normalizedSymbol = _normalizeSymbol(symbol);

    final filteredTransactions = transactions.where((transaction) {
      return _normalizeSymbol(transaction.symbol) == normalizedSymbol;
    }).toList();

    filteredTransactions.sort((first, second) {
      return second.date.compareTo(first.date);
    });

    return filteredTransactions;
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  Future<double> totalQuantity(String symbol) async {
    final transactions = await bySymbol(symbol);

    double total = 0;

    for (final transaction in transactions) {
      final quantity = _safeValue(transaction.quantity);

      total += quantity;
    }

    return total;
  }

  // ============================================================
  // TOTAL INVESTED
  // ============================================================

  Future<double> totalInvested(String symbol) async {
    final transactions = await bySymbol(symbol);

    double total = 0;

    for (final transaction in transactions) {
      final invested = _safeValue(transaction.invested);

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

  Future<double> currentValueBrl(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final price = _safeValue(currentPriceBrl);

    if (price <= 0) {
      return 0;
    }

    final quantity = await totalQuantity(symbol);

    return quantity * price;
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

  Future<double> profitLossBrl(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final currentValue = await currentValueBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );

    final invested = await totalInvested(symbol);

    return currentValue - invested;
  }

  // ============================================================
  // PROFIT / LOSS %
  // ============================================================

  Future<double> profitLossPercent(
    String symbol, {
    required double currentPriceBrl,
  }) async {
    final invested = await totalInvested(symbol);

    if (invested <= 0) {
      return 0;
    }

    final result = await profitLossBrl(
      symbol,
      currentPriceBrl: currentPriceBrl,
    );

    return (result / invested) * 100;
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

  Future<double> averagePurchasePrice(String symbol) async {
    final quantity = await totalQuantity(symbol);

    if (quantity <= 0) {
      return 0;
    }

    final invested = await totalInvested(symbol);

    return invested / quantity;
  }

  // ============================================================
  // ALL QUANTITIES
  // ============================================================

  Future<Map<String, double>> allQuantities() async {
    final result = <String, double>{};

    for (final symbol in supportedSymbols) {
      result[symbol] = await totalQuantity(symbol);
    }

    return result;
  }

  // ============================================================
  // ALL INVESTED
  // ============================================================

  Future<Map<String, double>> allInvested() async {
    final result = <String, double>{};

    for (final symbol in supportedSymbols) {
      result[symbol] = await totalInvested(symbol);
    }

    return result;
  }

  // ============================================================
  // TOTAL INVESTED PORTFOLIO
  // ============================================================

  Future<double> totalPortfolioInvested() async {
    double total = 0;

    for (final symbol in supportedSymbols) {
      total += await totalInvested(symbol);
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

  Future<double> currentPortfolioValueBrl(Map<String, double> pricesBrl) async {
    double total = 0;

    for (final symbol in supportedSymbols) {
      final price = _findPrice(pricesBrl, symbol);

      if (price <= 0) {
        continue;
      }

      total += await currentValueBrl(symbol, currentPriceBrl: price);
    }

    return total;
  }

  // ============================================================
  // PORTFOLIO PROFIT / LOSS
  // ============================================================

  Future<double> portfolioProfitLossBrl(Map<String, double> pricesBrl) async {
    final currentValue = await currentPortfolioValueBrl(pricesBrl);

    final invested = await totalPortfolioInvested();

    return currentValue - invested;
  }

  // ============================================================
  // PORTFOLIO PROFIT / LOSS %
  // ============================================================

  Future<double> portfolioProfitLossPercent(
    Map<String, double> pricesBrl,
  ) async {
    final invested = await totalPortfolioInvested();

    if (invested <= 0) {
      return 0;
    }

    final result = await portfolioProfitLossBrl(pricesBrl);

    return (result / invested) * 100;
  }

  // ============================================================
  // HAS TRANSACTIONS
  // ============================================================

  Future<bool> hasTransactions(String symbol) async {
    final transactions = await bySymbol(symbol);

    return transactions.isNotEmpty;
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<int> count({String? symbol}) async {
    if (symbol == null || symbol.trim().isEmpty) {
      final transactions = await load();

      return transactions.length;
    }

    final transactions = await bySymbol(symbol);

    return transactions.length;
  }

  // ============================================================
  // TWO-WAY CLOUD SYNC
  // ============================================================

  User? get _currentUser => Supabase.instance.client.auth.currentUser;

  Future<List<CryptoTransactionModel>> _syncWithCloud() async {
    final user = _currentUser;

    if (user == null) {
      return _loadLocal(forceRefresh: true);
    }

    final local = await _loadLocal(forceRefresh: true);

    final response = await Supabase.instance.client
        .from(_cloudTable)
        .select('id,symbol,date,quantity,invested,updated_at,deleted_at')
        .eq('user_id', user.id);

    final remoteRows = response;
    final remoteIds = <String>{};

    final merged = <String, CryptoTransactionModel>{
      for (final item in local)
        if (item.id.trim().isNotEmpty) item.id: item,
    };

    for (final raw in remoteRows) {
      final row = Map<String, dynamic>.from(raw);
      final id = row['id']?.toString().trim() ?? '';

      if (id.isEmpty) continue;

      remoteIds.add(id);

      final deletedAt = row['deleted_at'];

      if (deletedAt != null && deletedAt.toString().trim().isNotEmpty) {
        merged.remove(id);
        continue;
      }

      try {
        final transaction = CryptoTransactionModel.fromMap(row);
        if (transaction.isValid) {
          merged[id] = transaction;
        }
      } catch (_) {}
    }

    final localOnly = local
        .where(
          (item) => item.id.trim().isNotEmpty && !remoteIds.contains(item.id),
        )
        .toList(growable: false);

    if (localOnly.isNotEmpty) {
      final rows = localOnly
          .map((item) => _cloudRow(userId: user.id, transaction: item))
          .toList(growable: false);

      await Supabase.instance.client
          .from(_cloudTable)
          .upsert(rows, onConflict: 'user_id,id');

      for (final item in localOnly) {
        merged[item.id] = item;
      }
    }

    final result = merged.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    await save(result);
    await _syncFinanceAggregates(result);

    debugPrint(
      '[CRYPTO REPOSITORY][TWO WAY SYNC] '
      'local=${local.length} remote=${remoteRows.length} merged=${result.length}',
    );

    return List<CryptoTransactionModel>.from(result);
  }

  Future<void> _upsertCloudTransaction(
    CryptoTransactionModel transaction,
  ) async {
    final user = _currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from(_cloudTable)
        .upsert(
          _cloudRow(userId: user.id, transaction: transaction),
          onConflict: 'user_id,id',
        );
  }

  Future<void> _tombstoneCloudTransaction(String id) async {
    final user = _currentUser;
    if (user == null || id.trim().isEmpty) return;

    final now = DateTime.now().toUtc().toIso8601String();

    final updated = await Supabase.instance.client
        .from(_cloudTable)
        .update({'deleted_at': now, 'updated_at': now})
        .eq('user_id', user.id)
        .eq('id', id)
        .select('id');

    if (updated.isNotEmpty) return;

    await Supabase.instance.client.from(_cloudTable).upsert({
      'user_id': user.id,
      'id': id,
      'symbol': 'BTC',
      'date': now,
      'quantity': 0.0,
      'invested': 0.0,
      'updated_at': now,
      'deleted_at': now,
    }, onConflict: 'user_id,id');
  }

  Map<String, dynamic> _cloudRow({
    required String userId,
    required CryptoTransactionModel transaction,
  }) {
    return {
      'user_id': userId,
      'id': transaction.id,
      'symbol': _normalizeSymbol(transaction.symbol),
      'date': transaction.date.toUtc().toIso8601String(),
      'quantity': _safeValue(transaction.quantity),
      'invested': _safeValue(transaction.invested),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'deleted_at': null,
    };
  }

  Future<void> _syncFinanceAggregates(
    List<CryptoTransactionModel> transactions,
  ) async {
    final user = _currentUser;
    if (user == null) return;

    final quantities = <String, double>{
      for (final symbol in supportedSymbols) symbol: 0.0,
    };

    final invested = <String, double>{
      for (final symbol in supportedSymbols) symbol: 0.0,
    };

    for (final transaction in transactions) {
      final symbol = _normalizeSymbol(transaction.symbol);

      if (!supportedSymbols.contains(symbol)) continue;

      quantities[symbol] =
          (quantities[symbol] ?? 0.0) + _safeValue(transaction.quantity);

      invested[symbol] =
          (invested[symbol] ?? 0.0) + _safeValue(transaction.invested);
    }

    await Supabase.instance.client.from('finance_data').upsert({
      'user_id': user.id,
      'bitcoin': quantities['BTC'] ?? 0.0,
      'ethereum': quantities['ETH'] ?? 0.0,
      'solana': quantities['SOL'] ?? 0.0,
      'usdt': quantities['USDT'] ?? 0.0,
      'bitcoin_invested': invested['BTC'] ?? 0.0,
      'ethereum_invested': invested['ETH'] ?? 0.0,
      'solana_invested': invested['SOL'] ?? 0.0,
      'usdt_invested': invested['USDT'] ?? 0.0,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // ============================================================
  // NORMALIZE SYMBOL
  // ============================================================

  String _normalizeSymbol(String symbol) {
    return symbol.trim().toUpperCase();
  }

  // ============================================================
  // FIND PRICE
  // ============================================================

  double _findPrice(Map<String, double> prices, String symbol) {
    final normalizedSymbol = _normalizeSymbol(symbol);

    for (final entry in prices.entries) {
      if (_normalizeSymbol(entry.key) == normalizedSymbol) {
        return _safeValue(entry.value);
      }
    }

    return 0;
  }

  // ============================================================
  // SAFE VALUE
  // ============================================================

  double _safeValue(double value) {
    if (!value.isFinite || value < 0) {
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

  Future<void> refresh() async {
    await load(forceRefresh: true);
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void> clear() async {
    await storage.save(key, jsonEncode(<dynamic>[]));

    _cache = <CryptoTransactionModel>[];
  }
}
