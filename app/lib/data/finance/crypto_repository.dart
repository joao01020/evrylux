import 'dart:convert';

import '../../core/storage/local_storage.dart';
import '../../models/finance/crypto_transaction_model.dart';

class CryptoRepository {
  final LocalStorage storage;

  static const String key = "crypto_transactions";

  CryptoRepository({
    required this.storage,
  });

  Future<
    List<
      CryptoTransactionModel
    >
  >
  load() async {
    final json = await storage.get(
      key,
    );

    if (json ==
        null) {
      return [];
    }

    final List<
      dynamic
    >
    data = jsonDecode(
      json,
    );

    return data
        .map(
          (
            e,
          ) => CryptoTransactionModel.fromMap(
            Map<
              String,
              dynamic
            >.from(
              e,
            ),
          ),
        )
        .toList();
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
    await storage.save(
      key,
      jsonEncode(
        transactions
            .map(
              (
                e,
              ) => e.toMap(),
            )
            .toList(),
      ),
    );
  }

  Future<
    void
  >
  add(
    CryptoTransactionModel transaction,
  ) async {
    final list = await load();

    list.add(
      transaction,
    );

    await save(
      list,
    );
  }

  Future<
    void
  >
  update(
    CryptoTransactionModel transaction,
  ) async {
    final list = await load();

    final index = list.indexWhere(
      (
        e,
      ) =>
          e.id ==
          transaction.id,
    );

    if (index ==
        -1) {
      return;
    }

    list[index] = transaction;

    await save(
      list,
    );
  }

  Future<
    void
  >
  delete(
    String id,
  ) async {
    final list = await load();

    list.removeWhere(
      (
        e,
      ) =>
          e.id ==
          id,
    );

    await save(
      list,
    );
  }

  Future<
    List<
      CryptoTransactionModel
    >
  >
  bySymbol(
    String symbol,
  ) async {
    final list = await load();

    final filtered = list
        .where(
          (
            e,
          ) =>
              e.symbol ==
              symbol,
        )
        .toList();

    filtered.sort(
      (
        a,
        b,
      ) => b.date.compareTo(
        a.date,
      ),
    );

    return filtered;
  }

  Future<
    double
  >
  totalQuantity(
    String symbol,
  ) async {
    final list = await bySymbol(
      symbol,
    );

    return list.fold<
      double
    >(
      0.0,
      (
        double total,
        CryptoTransactionModel item,
      ) {
        return total +
            item.quantity;
      },
    );
  }

  Future<
    double
  >
  totalInvested(
    String symbol,
  ) async {
    final list = await bySymbol(
      symbol,
    );

    return list.fold<
      double
    >(
      0.0,
      (
        double total,
        CryptoTransactionModel item,
      ) {
        return total +
            item.invested;
      },
    );
  }

  Future<
    void
  >
  clear() async {
    await storage.save(
      key,
      jsonEncode(
        [],
      ),
    );
  }
}
