/*
abrir histórico
abrir cofre
*/

import 'package:flutter/material.dart';

import '../../../models/finance/investment_history.dart';

import '../controllers/finance_screen_controller.dart';
import '../history/finance_history_screen.dart';
import '../vault/vault_screen.dart';

class FinanceNavigationActions {
  final BuildContext context;
  final FinanceScreenController controller;
  final VoidCallback refresh;
  final bool Function() isMounted;

  final Future<void> Function(InvestmentHistory item) onDeleteContribution;

  const FinanceNavigationActions({
    required this.context,
    required this.controller,
    required this.refresh,
    required this.isMounted,
    required this.onDeleteContribution,
  });

  Future<void> openHistory() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return FinanceHistoryScreen(
            history: controller.history,
            onDelete: onDeleteContribution,
          );
        },
      ),
    );

    if (isMounted()) {
      refresh();
    }
  }

  void openVault() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const VaultScreen();
        },
      ),
    );
  }
}
