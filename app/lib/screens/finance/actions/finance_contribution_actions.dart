/*
abrir diálogo de aporte
registrar aporte
excluir aporte
salvar histórico financeiro
*/

import 'package:flutter/material.dart';

import '../services/history/investment_history.dart';

import '../controllers/finance_screen_controller.dart';
import '../dialogs/contribution_dialog.dart';
import '../utils/finance_screen_formatter.dart';

class FinanceContributionActions {
  final BuildContext context;
  final FinanceScreenController controller;
  final VoidCallback refresh;
  final bool Function() isMounted;
  final ValueChanged<
    String
  >
  showMessage;

  const FinanceContributionActions({
    required this.context,
    required this.controller,
    required this.refresh,
    required this.isMounted,
    required this.showMessage,
  });

  Future<
    void
  >
  openContribution() async {
    final contribution = await showContributionDialog(
      context: context,
    );

    if (contribution ==
            null ||
        !isMounted()) {
      return;
    }

    controller.addContribution(
      contribution,
    );

    refresh();

    final saved = await _saveAll(
      failureMessage: 'O aporte foi registrado, mas ocorreu um erro ao salvar.',
    );

    if (!saved ||
        !isMounted()) {
      return;
    }

    showMessage(
      'Aporte de '
      '${FinanceScreenFormatter.currency(contribution)} '
      'registrado.',
    );
  }

  Future<
    void
  >
  deleteContribution(
    InvestmentHistory item,
  ) async {
    final removed = controller.removeContribution(
      item,
    );

    if (!removed) {
      return;
    }

    if (isMounted()) {
      refresh();
    }

    final saved = await _saveAll(
      failureMessage: 'O aporte foi removido, mas ocorreu um erro ao salvar.',
    );

    if (!saved ||
        !isMounted()) {
      return;
    }

    showMessage(
      'Aporte de '
      '${FinanceScreenFormatter.currency(item.safeValue)} '
      'excluído.',
    );
  }

  Future<
    bool
  >
  _saveAll({
    required String failureMessage,
  }) async {
    try {
      await controller.saveAll();
      return true;
    } catch (
      _
    ) {
      if (isMounted()) {
        showMessage(
          failureMessage,
        );
      }

      return false;
    }
  }
}
