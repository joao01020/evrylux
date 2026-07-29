import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';

import 'actions/finance_screen_actions.dart';
import 'controllers/finance_screen_controller.dart';
import 'widgets/components/finance_screen_content.dart';

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
  late final FinanceScreenController _controller;
  late final FinanceScreenActions _actions;

  @override
  void initState() {
    super.initState();

    _controller = FinanceScreenController(
      financeController: financeController,
      cryptoController: cryptoController,
    );

    _actions = FinanceScreenActions(
      context: context,
      controller: _controller,
      refresh: _refresh,
      isMounted: () => mounted,
    );

    _loadScreen();
  }

  Future<
    void
  >
  _loadScreen() async {
    try {
      await _controller.load();
    } catch (
      _
    ) {
      if (mounted) {
        _actions.showMessage(
          'Não foi possível carregar todos os dados financeiros.',
        );
      }
    }

    _refresh();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Financeiro 💰',
      ),
      actions: [
        IconButton(
          tooltip: 'Planejamento',
          onPressed: _actions.openPlanning,
          icon: const Icon(
            Icons.tune_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildContributionButton() {
    return FloatingActionButton.extended(
      onPressed: _actions.openContribution,
      icon: const Icon(
        Icons.add,
      ),
      label: const Text(
        'Registrar aporte',
      ),
    );
  }

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FinanceScreenContent(
      model: _controller.model,
      projection: _controller.projection,
      balances: _controller.balances,
      history: _controller.history,
      onPlanning: _actions.openPlanning,
      onHistory: _actions.openHistory,
      onBalance: _actions.openCryptoBalance,
      onVault: _actions.openVault,
      onPatrimony: _actions.editPatrimony,
      onObjective: _actions.editInvestmentGoal,
      onCrypto: _actions.openCrypto,
      onHistoryItem: _actions.showHistoryItem,
      onDeleteContribution: _actions.deleteContribution,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _buildContributionButton(),
      body: _buildBody(),
    );
  }
}
