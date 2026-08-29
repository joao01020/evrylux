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
  // STATE
  // ============================================================

  List<
    CryptoTransactionModel
  >
  transactions = [];

  double quantity = 0;

  double invested = 0;

  String currentSymbol = '';

  bool isLoading = false;

  String? errorMessage;

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

    return transactions;
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
    final normalizedSymbol = symbol.trim().toUpperCase();

    if (normalizedSymbol.isEmpty) {
      clear();
      return;
    }

    currentSymbol = normalizedSymbol;

    isLoading = true;
    errorMessage = null;

    notifyListeners();

    try {
      transactions = await service.load(
        normalizedSymbol,
      );

      quantity = await service.totalQuantity(
        normalizedSymbol,
      );

      invested = await service.totalInvested(
        normalizedSymbol,
      );
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível carregar os dados de $normalizedSymbol.';

      debugPrint(
        '[CRYPTO CONTROLLER][LOAD] $error',
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
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível adicionar a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER][ADD] $error',
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
      await service.update(
        transaction,
      );

      await load(
        transaction.symbol,
      );
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível atualizar a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER][UPDATE] $error',
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
      await service.delete(
        id,
      );

      if (currentSymbol.isNotEmpty) {
        await load(
          currentSymbol,
        );
      } else {
        notifyListeners();
      }
    } catch (
      error,
      stackTrace
    ) {
      errorMessage = 'Não foi possível excluir a compra.';

      debugPrint(
        '[CRYPTO CONTROLLER][DELETE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (currentSymbol.isEmpty) {
      return;
    }

    await load(
      currentSymbol,
    );
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
  // CLEAR
  // ============================================================

  void clear() {
    transactions = [];

    quantity = 0;

    invested = 0;

    currentSymbol = '';

    isLoading = false;

    errorMessage = null;

    notifyListeners();
  }
}
