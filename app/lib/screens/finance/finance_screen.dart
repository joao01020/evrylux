import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

import '../../core/utils/finance_projection.dart';

import '../../models/finance/investment_history.dart';

import '../../widgets/finance/investment_progress.dart';
import '../../widgets/finance/investment_timeline.dart';
import '../../widgets/finance/wallet_card.dart';

import 'widgets/crypto/crypto_balance_dialog.dart';
import 'widgets/crypto/crypto_dialog.dart';

import 'dialogs/contribution_dialog.dart';
import 'dialogs/edit_finance_value_dialog.dart';
import 'dialogs/finance_planning_dialog.dart';

import 'utils/finance_screen_formatter.dart';

import 'widgets/finance_intro.dart';
import 'widgets/finance_section_header.dart';
import 'widgets/finance_summary_section.dart';

import 'vault/vault_screen.dart';

class FinanceScreen
    extends
        StatefulWidget {
  const FinanceScreen({
    super.key,
  });

  @override
  State<
    FinanceScreen
  >
  createState() {
    return _FinanceScreenState();
  }
}

class _FinanceScreenState
    extends
        State<
          FinanceScreen
        > {
  final _controller = financeController;

  final List<
    InvestmentHistory
  >
  investmentHistory = [];

  double bitcoin = 0;
  double ethereum = 0;
  double solana = 0;
  double usdt = 0;

  bool _isLoading = true;

  // =========================================================
  // CICLO DE VIDA
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadScreen();
  }

  // =========================================================
  // CARREGAMENTO
  // =========================================================

  Future<
    void
  >
  _loadScreen() async {
    {
      await Future.wait(
        [
          _controller.loadData(),
          _loadCryptoBalances(),
        ],
      );
    }
    {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
        },
      );
    }
  }

  Future<
    void
  >
  _loadCryptoBalances() async {
    bitcoin = await _loadCryptoQuantity(
      'BTC',
    );

    ethereum = await _loadCryptoQuantity(
      'ETH',
    );

    solana = await _loadCryptoQuantity(
      'SOL',
    );

    usdt = await _loadCryptoQuantity(
      'USDT',
    );
  }

  Future<
    double
  >
  _loadCryptoQuantity(
    String symbol,
  ) async {
    await cryptoController.load(
      symbol,
    );

    return cryptoController.quantity;
  }

  Future<
    void
  >
  _refreshCryptoBalances() async {
    await _loadCryptoBalances();

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // =========================================================
  // PROJEÇÃO
  // =========================================================

  FinanceProjection get _projection {
    return FinanceProjection(
      model: _controller.model,
      history: investmentHistory,
    );
  }

  // =========================================================
  // NAVEGAÇÃO
  // =========================================================

  void _openVault() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return const VaultScreen();
            },
      ),
    );
  }

  // =========================================================
  // CRIPTOMOEDAS
  // =========================================================

  Future<
    void
  >
  _openCryptoDialog(
    String symbol,
  ) async {
    await showDialog<
      void
    >(
      context: context,
      builder:
          (
            _,
          ) {
            return CryptoDialog(
              symbol: symbol,
            );
          },
    );

    await _refreshCryptoBalances();
  }

  void _openCryptoBalance() {
    showDialog<
      void
    >(
      context: context,
      builder:
          (
            _,
          ) {
            return CryptoBalanceDialog(
              bitcoin: bitcoin,
              ethereum: ethereum,
              solana: solana,
              usdt: usdt,
            );
          },
    );
  }

  // =========================================================
  // PLANEJAMENTO
  // =========================================================

  Future<
    void
  >
  _openPlanningDialog() async {
    final model = _controller.model;

    final result = await showFinancePlanningDialog(
      context: context,
      invested: model.invested,
      minimumGoal: model.minimumGoal,
      mediumGoal: model.mediumGoal,
      maximumGoal: model.maximumGoal,
      projectionYears: model.projectionYears,
    );

    if (result ==
            null ||
        !mounted) {
      return;
    }

    model.invested = result.invested;
    model.minimumGoal = result.minimumGoal;
    model.mediumGoal = result.mediumGoal;
    model.maximumGoal = result.maximumGoal;
    model.projectionYears = result.projectionYears;
    model.monthlyGoal = result.mediumGoal;

    await _controller.saveData();

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );

    _showMessage(
      'Planejamento salvo.',
    );
  }

  // =========================================================
  // APORTES
  // =========================================================

  Future<
    void
  >
  _openContributionDialog() async {
    final contribution = await showContributionDialog(
      context: context,
    );

    if (contribution ==
            null ||
        !mounted) {
      return;
    }

    final model = _controller.model;

    final historyEntry = _projection.createHistoryEntry(
      contribution: contribution,
    );

    setState(
      () {
        investmentHistory.add(
          historyEntry,
        );

        model.invested += contribution;
        model.totalInvested += contribution;
        model.investedMonths += 1;
        model.patrimony += contribution;

        model.averageContribution =
            model.investedMonths >
                0
            ? model.totalInvested /
                  model.investedMonths
            : 0;
      },
    );

    await _controller.saveData();

    if (!mounted) {
      return;
    }

    _showMessage(
      'Aporte de '
      '${FinanceScreenFormatter.currency(contribution)} '
      'registrado.',
    );
  }

  Future<
    void
  >
  _deleteContribution(
    InvestmentHistory item,
  ) async {
    final model = _controller.model;

    setState(
      () {
        investmentHistory.remove(
          item,
        );

        model.invested = _subtractWithoutNegative(
          model.invested,
          item.safeValue,
        );

        model.totalInvested = _subtractWithoutNegative(
          model.totalInvested,
          item.safeValue,
        );

        model.patrimony = _subtractWithoutNegative(
          model.patrimony,
          item.safeValue,
        );

        if (model.investedMonths >
            0) {
          model.investedMonths -= 1;
        }

        model.averageContribution =
            model.investedMonths >
                0
            ? model.totalInvested /
                  model.investedMonths
            : 0;
      },
    );

    await _controller.saveData();

    if (!mounted) {
      return;
    }

    _showMessage(
      'Aporte de '
      '${FinanceScreenFormatter.currency(item.safeValue)} '
      'excluído.',
    );
  }

  double _subtractWithoutNegative(
    double currentValue,
    double valueToRemove,
  ) {
    return (currentValue -
            valueToRemove)
        .clamp(
          0.0,
          double.infinity,
        );
  }

  // =========================================================
  // EDIÇÃO
  // =========================================================

  Future<
    void
  >
  _editPatrimony() async {
    final model = _controller.model;

    final value = await showEditFinanceValueDialog(
      context: context,
      title: 'Editar patrimônio',
      label: 'Patrimônio atual',
      currentValue: model.patrimony,
    );

    if (value ==
            null ||
        !mounted) {
      return;
    }

    model.patrimony = value;

    await _saveEditedValue();
  }

  Future<
    void
  >
  _editInvestmentGoal() async {
    final model = _controller.model;

    final value = await showEditFinanceValueDialog(
      context: context,
      title: 'Editar objetivo financeiro',
      label: 'Objetivo final',
      currentValue: model.investmentGoal,
    );

    if (value ==
            null ||
        !mounted) {
      return;
    }

    model.investmentGoal = value;

    await _saveEditedValue();
  }

  Future<
    void
  >
  _saveEditedValue() async {
    await _controller.saveData();

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );

    _showMessage(
      'Valor atualizado.',
    );
  }

  // =========================================================
  // MENSAGENS
  // =========================================================

  void _showMessage(
    String message,
  ) {
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

  void _showHistoryItem(
    InvestmentHistory item,
  ) {
    _showMessage(
      '${FinanceScreenFormatter.currency(item.safeValue)} • '
      '${item.normalizedRhythm}',
    );
  }

  // =========================================================
  // TELA
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final model = _controller.model;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Financeiro 💰',
        ),
        actions: [
          IconButton(
            tooltip: 'Planejamento',
            onPressed: _openPlanningDialog,
            icon: const Icon(
              Icons.tune_outlined,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openContributionDialog,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Registrar aporte',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FinanceIntro(),

                  const SizedBox(
                    height: 28,
                  ),

                  WalletCard(
                    patrimony: model.patrimony,
                    invested: model.invested,
                    bitcoin: bitcoin,
                    ethereum: ethereum,
                    solana: solana,
                    usdt: usdt,
                    onBalance: _openCryptoBalance,
                    onBitcoin: () {
                      _openCryptoDialog(
                        'BTC',
                      );
                    },
                    onEthereum: () {
                      _openCryptoDialog(
                        'ETH',
                      );
                    },
                    onSolana: () {
                      _openCryptoDialog(
                        'SOL',
                      );
                    },
                    onUsdt: () {
                      _openCryptoDialog(
                        'USDT',
                      );
                    },
                    onVault: _openVault,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  FinanceSummarySection(
                    patrimony: model.patrimony,
                    investmentGoal: model.investmentGoal,
                    minimumGoal: model.minimumGoal,
                    mediumGoal: model.mediumGoal,
                    maximumGoal: model.maximumGoal,
                    onPatrimonyTap: _editPatrimony,
                    onObjectiveTap: _editInvestmentGoal,
                    onRhythmsTap: _openPlanningDialog,
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  const FinanceSectionHeader(
                    title: 'Sua evolução',
                    subtitle: 'O objetivo cresce enquanto o tempo restante diminui.',
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  InvestmentProgress(
                    projection: _projection,
                    showPatrimony: true,
                    showAverageContribution: true,
                    showEstimatedTime: true,
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  FinanceSectionHeader(
                    title: 'Histórico',
                    subtitle: 'Cada aporte representa um avanço no seu caminho.',
                    trailing: FilledButton.icon(
                      onPressed: _openContributionDialog,
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                      ),
                      label: const Text(
                        'Aporte',
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  InvestmentTimeline(
                    history: investmentHistory,
                    showHeader: false,
                    onDelete: _deleteContribution,
                    onTap: _showHistoryItem,
                  ),
                ],
              ),
            ),
    );
  }
}
