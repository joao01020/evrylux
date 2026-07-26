import 'package:flutter/foundation.dart';

import '../../../../models/finance/crypto_transaction_model.dart';
import '../../services/crypto/crypto_service.dart';

class CryptoController
    extends
        ChangeNotifier {
  final CryptoService service;

  CryptoController({
    required this.service,
  });

  List<
    CryptoTransactionModel
  >
  transactions = [];

  double quantity = 0;

  double invested = 0;

  String currentSymbol = "";

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

    return transactions;
  }

  Future<
    void
  >
  load(
    String symbol,
  ) async {
    currentSymbol = symbol;

    transactions = await service.load(
      symbol,
    );

    quantity = await service.totalQuantity(
      symbol,
    );

    invested = await service.totalInvested(
      symbol,
    );

    notifyListeners();
  }

  Future<
    void
  >
  add(
    CryptoTransactionModel transaction,
  ) async {
    await service.add(
      transaction,
    );

    await load(
      transaction.symbol,
    );
  }

  Future<
    void
  >
  update(
    CryptoTransactionModel transaction,
  ) async {
    await service.update(
      transaction,
    );

    await load(
      transaction.symbol,
    );
  }

  Future<
    void
  >
  delete(
    String id,
  ) async {
    await service.delete(
      id,
    );

    if (currentSymbol.isNotEmpty) {
      await load(
        currentSymbol,
      );
    }
  }

  void clear() {
    transactions = [];

    quantity = 0;

    invested = 0;

    currentSymbol = "";

    notifyListeners();
  }
}
