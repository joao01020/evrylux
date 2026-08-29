import 'package:flutter/material.dart';

import '../../app/dependencies/app_dependencies.dart';

import '../actions/finance_screen_actions.dart';
import '../controllers/finance_screen_controller.dart';
import '../services/history/investment_history.dart';
import '../widgets/common/empty_last_contribution.dart';
import '../widgets/components/finance_screen_content.dart';
import '../widgets/progress/investment_progress.dart';
import '../widgets/timeline/investment_timeline.dart';

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
  // MOSTRAR / OCULTAR SALDOS
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
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Financeiro 💰',
      ),
      actions: [
        // ======================================================
        // OLHO
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
  // ÚLTIMO APORTE
  // ============================================================

  List<
    InvestmentHistory
  >
  get _latestContribution {
    if (_controller.history.isEmpty) {
      return [];
    }

    return [
      _controller.history.last,
    ];
  }

  // ============================================================
  // MODAL - SUA EVOLUÇÃO
  // ============================================================

  Future<
    void
  >
  _openEvolutionModal() async {
    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 660,
      ),
      builder:
          (
            modalContext,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24 +
                    MediaQuery.of(
                      modalContext,
                    ).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // HEADER
                    // ==========================================
                    _FinanceModalHeader(
                      icon: Icons.trending_up_rounded,
                      title: 'Sua evolução',
                      subtitle: 'O objetivo cresce enquanto o tempo restante diminui.',
                      onClose: () {
                        Navigator.of(
                          modalContext,
                        ).pop();
                      },
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // CONTEÚDO
                    // ==========================================
                    InvestmentProgress(
                      projection: _controller.projection,
                      showPatrimony: true,
                      showAverageContribution: true,
                      showEstimatedTime: true,
                      showBalances: _showBalances,
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // MODAL - ÚLTIMO APORTE
  // ============================================================

  Future<
    void
  >
  _openLastContributionModal() async {
    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 660,
      ),
      builder:
          (
            modalContext,
          ) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24 +
                    MediaQuery.of(
                      modalContext,
                    ).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // HEADER
                    // ==========================================
                    _FinanceModalHeader(
                      icon: Icons.savings_rounded,
                      title: 'Último aporte',
                      subtitle: _controller.history.isEmpty
                          ? 'Nenhum aporte registrado.'
                          : 'Seu aporte mais recente.',
                      onClose: () {
                        Navigator.of(
                          modalContext,
                        ).pop();
                      },
                    ),

                    const SizedBox(
                      height: 22,
                    ),

                    // ==========================================
                    // CONTEÚDO
                    // ==========================================
                    if (_controller.history.isEmpty)
                      const EmptyLastContribution()
                    else
                      InvestmentTimeline(
                        history: _latestContribution,
                        showHeader: false,
                        onDelete: _actions.deleteContribution,
                        onTap: _actions.showHistoryItem,
                        showBalances: _showBalances,
                      ),

                    const SizedBox(
                      height: 18,
                    ),

                    // ==========================================
                    // HISTÓRICO COMPLETO
                    // ==========================================
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            modalContext,
                          ).pop();

                          _actions.openHistory();
                        },
                        icon: const Icon(
                          Icons.history_rounded,
                        ),
                        label: const Text(
                          'Ver todos os aportes',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

      balances: _controller.balances,

      // ========================================================
      // AÇÕES
      // ========================================================
      onPlanning: _actions.openPlanning,

      onBalance: _actions.openCryptoBalance,

      onVault: _actions.openVault,

      onPatrimony: _actions.editPatrimony,

      onObjective: _actions.editInvestmentGoal,

      onCrypto: _actions.openCrypto,

      // ========================================================
      // MODAIS
      // ========================================================
      onOpenEvolution: _openEvolutionModal,

      onOpenLastContribution: _openLastContributionModal,

      // ========================================================
      // NOVO BOTÃO +
      // ========================================================
      onContribution: _actions.openContribution,

      // ========================================================
      // VISIBILIDADE DOS SALDOS
      // ========================================================
      showBalances: _showBalances,
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

      // ========================================================
      // SEM FLOATING ACTION BUTTON
      //
      // O aporte agora é aberto pelo botão +
      // junto dos atalhos.
      // ========================================================
      body: _buildBody(),
    );
  }
}

// ============================================================
// HEADER DOS MODAIS
// ============================================================

class _FinanceModalHeader
    extends
        StatelessWidget {
  const _FinanceModalHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onClose;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
      ],
    );
  }
}
