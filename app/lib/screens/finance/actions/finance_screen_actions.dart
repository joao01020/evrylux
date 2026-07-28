/*
Apenas Cria e orquestra

*/

import 'package:flutter/material.dart';

import '../../../models/finance/investment_history.dart';

import '../controllers/finance_screen_controller.dart';

import 'finance_contribution_actions.dart';
import 'finance_dialog_actions.dart';
import 'finance_navigation_actions.dart';

class FinanceScreenActions {
  final BuildContext context;
  final FinanceScreenController controller;
  final VoidCallback refresh;
  final bool Function() isMounted;

  late final FinanceContributionActions _contributionActions;
  late final FinanceDialogActions _dialogActions;
  late final FinanceNavigationActions _navigationActions;

  FinanceScreenActions({
    required this.context,
    required this.controller,
    required this.refresh,
    required this.isMounted,
  }) {
    _contributionActions = FinanceContributionActions(
      context: context,
      controller: controller,
      refresh: refresh,
      isMounted: isMounted,
      showMessage: showMessage,
    );

    _dialogActions = FinanceDialogActions(
      context: context,
      controller: controller,
      refresh: refresh,
      isMounted: isMounted,
      showMessage: showMessage,
    );

    _navigationActions = FinanceNavigationActions(
      context: context,
      controller: controller,
      refresh: refresh,
      isMounted: isMounted,
      onDeleteContribution: deleteContribution,
    );
  }

  Future<
    void
  >
  openHistory() {
    return _navigationActions.openHistory();
  }

  void openVault() {
    _navigationActions.openVault();
  }

  Future<
    void
  >
  openCrypto(
    String symbol,
  ) {
    return _dialogActions.openCrypto(
      symbol,
    );
  }

  void openCryptoBalance() {
    _dialogActions.openCryptoBalance();
  }

  Future<
    void
  >
  openPlanning() {
    return _dialogActions.openPlanning();
  }

  Future<
    void
  >
  openContribution() {
    return _contributionActions.openContribution();
  }

  Future<
    void
  >
  deleteContribution(
    InvestmentHistory item,
  ) {
    return _contributionActions.deleteContribution(
      item,
    );
  }

  Future<
    void
  >
  editPatrimony() {
    return _dialogActions.editPatrimony();
  }

  Future<
    void
  >
  editInvestmentGoal() {
    return _dialogActions.editInvestmentGoal();
  }

  void showHistoryItem(
    InvestmentHistory item,
  ) {
    _dialogActions.showHistoryItem(
      item,
    );
  }

  void showMessage(
    String message,
  ) {
    if (!isMounted()) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }
}
