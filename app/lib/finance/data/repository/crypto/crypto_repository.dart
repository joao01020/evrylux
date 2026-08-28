import 'dart:convert';

import '../../../../core/storage/local_storage.dart';
import '../../../models/crypto/crypto_transaction_model.dart';

class CryptoRepository {
  final LocalStorage storage;

  static const String key = 'crypto_transactions';

  List<
    CryptoTransactionModel
  >?
  _cache;

  CryptoRepository({
    required this.storage,
  });

  // =========================
  // LEITURA E PERSISTÊNCIA
  // =========================

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

      final transactions = decoded
          .map(
            (
              item,
            ) => CryptoTransactionModel.fromMap(
              Map<
                String,
                dynamic
              >.from(
                item
                    as Map,
              ),
            ),
          )
          .toList();

      _cache = transactions;

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

    final encodedTransactions = jsonEncode(
      transactionsCopy
          .map(
            (
              transaction,
            ) => transaction.toMap(),
          )
          .toList(),
    );

    await storage.save(
      key,
      encodedTransactions,
    );

    _cache = transactionsCopy;
  }

  // =========================
  // CRUD
  // =========================

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
      ) =>
          item.id ==
          transaction.id,
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
      ) =>
          item.id ==
          id,
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

  // =========================
  // CONSULTAS
  // =========================

  Future<
    List<
      CryptoTransactionModel
    >
  >
  bySymbol(
    String symbol,
  ) async {
    final transactions = await load();
    final normalizedSymbol = symbol.trim().toUpperCase();

    final filteredTransactions = transactions.where(
      (
        transaction,
      ) {
        return transaction.symbol.trim().toUpperCase() ==
            normalizedSymbol;
      },
    ).toList();

    filteredTransactions.sort(
      (
        first,
        second,
      ) => second.date.compareTo(
        first.date,
      ),
    );

    return filteredTransactions;
  }

  Future<
    double
  >
  totalQuantity(
    String symbol,
  ) async {
    final transactions = await load();
    final normalizedSymbol = symbol.trim().toUpperCase();

    return transactions
        .where(
          (
            transaction,
          ) {
            return transaction.symbol.trim().toUpperCase() ==
                normalizedSymbol;
          },
        )
        .fold<
          double
        >(
          0.0,
          (
            total,
            transaction,
          ) {
            return total +
                transaction.quantity;
          },
        );
  }

  Future<
    double
  >
  totalInvested(
    String symbol,
  ) async {
    final transactions = await load();
    final normalizedSymbol = symbol.trim().toUpperCase();

    return transactions
        .where(
          (
            transaction,
          ) {
            return transaction.symbol.trim().toUpperCase() ==
                normalizedSymbol;
          },
        )
        .fold<
          double
        >(
          0.0,
          (
            total,
            transaction,
          ) {
            return total +
                transaction.invested;
          },
        );
  }

  // =========================
  // CACHE E LIMPEZA
  // =========================

  void invalidateCache() {
    _cache = null;
  }

  Future<
    void
  >
  refresh() async {
    await load(
      forceRefresh: true,
    );
  }

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
