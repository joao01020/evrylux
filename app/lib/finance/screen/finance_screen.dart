import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // FORMATAR MOEDA
  // ============================================================

  String _formatCurrency(
    double value,
  ) {
    final fixed = value
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integer = fixed.first;

    final cents =
        fixed.length >
            1
        ? fixed[1]
        : '00';

    final buffer = StringBuffer();

    for (
      var index = 0;
      index <
          integer.length;
      index++
    ) {
      final remaining =
          integer.length -
          index;

      buffer.write(
        integer[index],
      );

      if (remaining >
              1 &&
          remaining %
                  3 ==
              1) {
        buffer.write(
          '.',
        );
      }
    }

    return 'R\$ ${buffer.toString()},$cents';
  }

  // ============================================================
  // PARSE BRL
  // ============================================================

  double? _parseCurrency(
    String raw,
  ) {
    var value = raw
        .trim()
        .replaceAll(
          'R\$',
          '',
        )
        .replaceAll(
          ' ',
          '',
        );

    if (value.isEmpty) {
      return null;
    }

    if (value.contains(
      ',',
    )) {
      value = value
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    }

    return double.tryParse(
      value,
    );
  }

  // ============================================================
  // MODAL - OBJETIVO
  // ============================================================

  Future<
    void
  >
  _openObjectiveModal() async {
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
            final model = _controller.model;

            String objectiveName = _controller.objectiveName;

            return StatefulBuilder(
              builder:
                  (
                    context,
                    setModalState,
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
                            _FinanceModalHeader(
                              icon: Icons.track_changes_rounded,
                              title: 'Objetivo',
                              subtitle: 'Defina o patrimônio que você deseja alcançar.',
                              onClose: () {
                                Navigator.of(
                                  modalContext,
                                ).pop();
                              },
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 26,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  modalContext,
                                ).colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(
                                  18,
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    modalContext,
                                  ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.track_changes_rounded,
                                    size: 25,
                                    color: Theme.of(
                                      modalContext,
                                    ).colorScheme.primary,
                                  ),

                                  const SizedBox(
                                    height: 10,
                                  ),

                                  // ==============================
                                  // NOME CLICÁVEL
                                  // ==============================
                                  InkWell(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    onTap: () async {
                                      final updatedName = await _editObjectiveName();

                                      if (updatedName !=
                                              null &&
                                          modalContext.mounted) {
                                        setModalState(
                                          () {
                                            objectiveName = updatedName;
                                          },
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              objectiveName,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 7,
                                          ),

                                          Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: Theme.of(
                                              modalContext,
                                            ).colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  // ==============================
                                  // VALOR CLICÁVEL
                                  // ==============================
                                  InkWell(
                                    borderRadius: BorderRadius.circular(
                                      10,
                                    ),
                                    onTap: () async {
                                      final changed = await _editObjectiveValue();

                                      if (changed &&
                                          modalContext.mounted) {
                                        setModalState(
                                          () {},
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _showBalances
                                                ? _formatCurrency(
                                                    model.investmentGoal,
                                                  )
                                                : '••••••••',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 23,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 8,
                                          ),

                                          Icon(
                                            Icons.edit_rounded,
                                            size: 17,
                                            color: Theme.of(
                                              modalContext,
                                            ).colorScheme.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Text(
                              'Clique no nome ou no valor para editar.',
                              style: TextStyle(
                                color: Theme.of(
                                  modalContext,
                                ).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // EDITAR NOME
  // ============================================================

  Future<
    String?
  >
  _editObjectiveName() async {
    final controller = TextEditingController(
      text: _controller.objectiveName,
    );

    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Nome do objetivo',
                  ),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 60,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nome',
                      hintText: 'Ex.: Liberdade financeira',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted:
                        (
                          value,
                        ) {
                          Navigator.of(
                            dialogContext,
                          ).pop(
                            value,
                          );
                        },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          controller.text,
                        );
                      },
                      child: const Text(
                        'Salvar',
                      ),
                    ),
                  ],
                );
              },
        );

    controller.dispose();

    if (result ==
            null ||
        !mounted) {
      return null;
    }

    final normalized = result.trim();

    if (normalized.isEmpty) {
      _actions.showMessage(
        'Digite um nome para o objetivo.',
      );

      return null;
    }

    try {
      final objective = await _controller.updateObjectiveName(
        normalized,
      );

      final updatedName = objective.name.trim().isEmpty
          ? normalized
          : objective.name.trim();

      if (!mounted) {
        return updatedName;
      }

      setState(
        () {},
      );

      _actions.showMessage(
        'Nome do objetivo salvo.',
      );

      return updatedName;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE][OBJECTIVE][NAME] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _actions.showMessage(
          'Não foi possível salvar o nome do objetivo.',
        );
      }

      return null;
    }
  }

  // ============================================================
  // EDITAR VALOR
  // ============================================================

  Future<
    bool
  >
  _editObjectiveValue() async {
    final controller = TextEditingController(
      text: _controller.model.investmentGoal
          .toStringAsFixed(
            2,
          )
          .replaceAll(
            '.',
            ',',
          ),
    );

    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Valor do objetivo',
                  ),
                  content: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(
                          r'[0-9.,]',
                        ),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Objetivo final',
                      prefixText: 'R\$ ',
                      hintText: '10.000,00',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted:
                        (
                          value,
                        ) {
                          Navigator.of(
                            dialogContext,
                          ).pop(
                            value,
                          );
                        },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          controller.text,
                        );
                      },
                      child: const Text(
                        'Salvar',
                      ),
                    ),
                  ],
                );
              },
        );

    controller.dispose();

    if (result ==
            null ||
        !mounted) {
      return false;
    }

    final value = _parseCurrency(
      result,
    );

    if (value ==
            null ||
        value <=
            0) {
      _actions.showMessage(
        'Digite um valor válido maior que zero.',
      );

      return false;
    }

    try {
      await _controller.updateObjectiveValue(
        value,
      );

      if (!mounted) {
        return true;
      }

      setState(
        () {},
      );

      _actions.showMessage(
        'Valor do objetivo salvo.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE][OBJECTIVE][VALUE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _actions.showMessage(
          'Não foi possível salvar o valor do objetivo.',
        );
      }

      return false;
    }
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

      objectiveName: _controller.objectiveName,

      // ========================================================
      // AÇÕES
      // ========================================================
      onPlanning: _actions.openPlanning,

      onBalance: _actions.openCryptoBalance,

      onVault: _actions.openVault,

      onPatrimony: _actions.editPatrimony,

      onObjective: _openObjectiveModal,

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
