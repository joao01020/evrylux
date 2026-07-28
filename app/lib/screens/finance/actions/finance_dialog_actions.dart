/*
diálogo de criptomoeda
diálogo de saldo
planejamento
edição de patrimônio
edição da meta
mensagem do histórico

*/

import 'package:flutter/material.dart';

import '../../../models/finance/investment_history.dart';

import '../controllers/finance_screen_controller.dart';

import '../dialogs/edit_finance_value_dialog.dart';
import '../dialogs/finance_planning_dialog.dart';

import '../utils/finance_screen_formatter.dart';

import '../widgets/crypto/crypto_balance_dialog.dart';
import '../widgets/crypto/crypto_dialog.dart';

class FinanceDialogActions {
  final BuildContext context;
  final FinanceScreenController controller;
  final VoidCallback refresh;
  final bool Function() isMounted;
  final ValueChanged<String> showMessage;

  const FinanceDialogActions({
    required this.context,
    required this.controller,
    required this.refresh,
    required this.isMounted,
    required this.showMessage,
  });

  Future<void> openCrypto(String symbol) async {
    await showDialog<void>(
      context: context,
      builder: (_) {
        return CryptoDialog(symbol: symbol);
      },
    );

    if (!isMounted()) {
      return;
    }

    try {
      await controller.refreshCryptoBalances();

      if (isMounted()) {
        refresh();
      }
    } catch (_) {
      if (isMounted()) {
        showMessage('Não foi possível atualizar os saldos das criptomoedas.');
      }
    }
  }

  void openCryptoBalance() {
    final balances = controller.balances;

    showDialog<void>(
      context: context,
      builder: (_) {
        return CryptoBalanceDialog(
          bitcoin: balances.bitcoin,
          ethereum: balances.ethereum,
          solana: balances.solana,
          usdt: balances.usdt,
        );
      },
    );
  }

  Future<void> openPlanning() async {
    final model = controller.model;

    final result = await showFinancePlanningDialog(
      context: context,
      invested: model.invested,
      minimumGoal: model.minimumGoal,
      mediumGoal: model.mediumGoal,
      maximumGoal: model.maximumGoal,
      projectionYears: model.projectionYears,
    );

    if (result == null || !isMounted()) {
      return;
    }

    controller.applyPlanning(result);

    refresh();

    try {
      await controller.saveModel();
    } catch (_) {
      if (isMounted()) {
        showMessage(
          'O planejamento foi alterado, mas ocorreu um erro ao salvar.',
        );
      }

      return;
    }

    if (isMounted()) {
      showMessage('Planejamento salvo.');
    }
  }

  Future<void> editPatrimony() {
    return _editValue(
      title: 'Editar patrimônio',
      label: 'Patrimônio atual',
      currentValue: controller.model.patrimony,
      update: controller.updatePatrimony,
    );
  }

  Future<void> editInvestmentGoal() {
    return _editValue(
      title: 'Editar objetivo financeiro',
      label: 'Objetivo final',
      currentValue: controller.model.investmentGoal,
      update: controller.updateInvestmentGoal,
    );
  }

  Future<void> _editValue({
    required String title,
    required String label,
    required double currentValue,
    required ValueChanged<double> update,
  }) async {
    final value = await showEditFinanceValueDialog(
      context: context,
      title: title,
      label: label,
      currentValue: currentValue,
    );

    if (value == null || !isMounted()) {
      return;
    }

    update(value);

    refresh();

    try {
      await controller.saveModel();
    } catch (_) {
      if (isMounted()) {
        showMessage('O valor foi alterado, mas ocorreu um erro ao salvar.');
      }

      return;
    }

    if (isMounted()) {
      showMessage('Valor atualizado.');
    }
  }

  void showHistoryItem(InvestmentHistory item) {
    showMessage(
      '${FinanceScreenFormatter.currency(item.safeValue)} • '
      '${item.normalizedRhythm}',
    );
  }
}
