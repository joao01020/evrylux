import 'package:flutter/material.dart';

import '../../app/dependencies/app_dependencies.dart';

import '../actions/finance_screen_actions.dart';
import '../controllers/finance_screen_controller.dart';
import '../widgets/components/finance_screen_content.dart';

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

  // ============================================================
  // EXPANSÃO DOS CARDS
  // ============================================================

  bool _showEvolutionDetails = false;

  bool _showLastContributionDetails = false;

  // ============================================================
  // VISIBILIDADE GLOBAL DOS SALDOS
  // ============================================================

  bool _showBalances = true;

  // ============================================================
  // INIT
  // ============================================================

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

  // ============================================================
  // LOAD
  // ============================================================

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

  // ============================================================
  // REFRESH
  // ============================================================

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // MOSTRAR / OCULTAR TODOS OS SALDOS
  // ============================================================

  void _toggleBalances() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _showBalances = !_showBalances;
      },
    );
  }

  // ============================================================
  // TOGGLE EVOLUTION
  // ============================================================

  void _toggleEvolutionDetails() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _showEvolutionDetails = !_showEvolutionDetails;
      },
    );
  }

  // ============================================================
  // TOGGLE LAST CONTRIBUTION
  // ============================================================

  void _toggleLastContributionDetails() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _showLastContributionDetails = !_showLastContributionDetails;
      },
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Financeiro 💰',
      ),
      actions: [
        // ======================================================
        // OLHO - VISIBILIDADE GLOBAL
        // ======================================================
        IconButton(
          tooltip: _showBalances
              ? 'Ocultar todos os saldos'
              : 'Mostrar todos os saldos',
          onPressed: _toggleBalances,
          icon: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 180,
            ),
            child: Icon(
              _showBalances
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              key:
                  ValueKey<
                    bool
                  >(
                    _showBalances,
                  ),
            ),
          ),
        ),

        // ======================================================
        // PLANEJAMENTO
        // ======================================================
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

  // ============================================================
  // CONTRIBUTION BUTTON
  // ============================================================

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

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FinanceScreenContent(
      // ========================================================
      // DADOS
      // ========================================================
      model: _controller.model,

      projection: _controller.projection,

      balances: _controller.balances,

      history: _controller.history,

      // ========================================================
      // AÇÕES
      // ========================================================
      onPlanning: _actions.openPlanning,

      onHistory: _actions.openHistory,

      onBalance: _actions.openCryptoBalance,

      onVault: _actions.openVault,

      onPatrimony: _actions.editPatrimony,

      onObjective: _actions.editInvestmentGoal,

      onCrypto: _actions.openCrypto,

      onHistoryItem: _actions.showHistoryItem,

      onDeleteContribution: _actions.deleteContribution,

      // ========================================================
      // VISIBILIDADE GLOBAL DOS SALDOS
      // ========================================================
      showBalances: _showBalances,

      // ========================================================
      // EVOLUÇÃO
      // ========================================================
      showEvolutionDetails: _showEvolutionDetails,

      onToggleEvolution: _toggleEvolutionDetails,

      // ========================================================
      // ÚLTIMO APORTE
      // ========================================================
      showLastContributionDetails: _showLastContributionDetails,

      onToggleLastContribution: _toggleLastContributionDetails,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
