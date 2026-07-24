import 'dart:convert';

import '../models/finance_model.dart';
import '../core/storage/local_storage.dart';

class FinanceService {
  static const String financeKey = "finance_data";

  final LocalStorage storage;

  FinanceService({
    required this.storage,
  });

  static String calculateEstimate({
    required double current,
    required double goal,
    required double monthly,
  }) {
    final missing =
        goal -
        current;

    if (missing <=
        0) {
      return "Meta alcançada 🎉";
    }

    if (monthly <=
        0) {
      return "Defina um investimento mensal";
    }

    final months =
        (missing /
                monthly)
            .ceil();

    final years =
        months ~/
        12;
    final rest =
        months %
        12;

    if (years >
        0) {
      return "$years anos e $rest meses";
    }

    return "$months meses";
  }

  Future<
    void
  >
  saveFinance(
    FinanceModel model,
  ) async {
    final data = jsonEncode(
      {
        "invested": model.invested,
        "monthlyGoal": model.monthlyGoal,
        "investmentGoal": model.investmentGoal,
        "bitcoin": model.bitcoin,
        "ethereum": model.ethereum,
        "solana": model.solana,
        "usdt": model.usdt,
        "selectedDay": model.selectedDay,
        "completedDays": model.completedDays,
      },
    );

    await storage.save(
      financeKey,
      data,
    );
  }

  Future<
    FinanceModel
  >
  loadFinance() async {
    final result = await storage.get(
      financeKey,
    );

    if (result ==
        null) {
      return FinanceModel();
    }

    final data = jsonDecode(
      result,
    );

    return FinanceModel(
      invested:
          (data["invested"] ??
                  0.0)
              .toDouble(),
      monthlyGoal:
          (data["monthlyGoal"] ??
                  0.0)
              .toDouble(),
      investmentGoal:
          (data["investmentGoal"] ??
                  0.0)
              .toDouble(),
      bitcoin:
          (data["bitcoin"] ??
                  0.0)
              .toDouble(),
      ethereum:
          (data["ethereum"] ??
                  0.0)
              .toDouble(),
      solana:
          (data["solana"] ??
                  0.0)
              .toDouble(),
      usdt:
          (data["usdt"] ??
                  0.0)
              .toDouble(),
      selectedDay: data["selectedDay"],
      completedDays:
          data["completedDays"] !=
              null
          ? List<
              bool
            >.from(
              data["completedDays"],
            )
          : List.filled(
              7,
              false,
            ),
    );
  }

  Future<
    void
  >
  clearFinance() async {
    await storage.remove(
      financeKey,
    );
  }
}
