import 'package:flutter/material.dart';

import '../../projections/finance_projection.dart';
import '../../services/history/investment_history.dart';
import '../progress/investment_progress.dart';
import '../timeline/investment_timeline.dart';
import '../wallet/wallet_card.dart';
import '../../models/crypto/crypto_balances.dart';
import '../common/empty_last_contribution.dart';
import '../sections/finance_intro.dart';
import '../sections/finance_section_header.dart';
import '../sections/finance_summary_section.dart';

class FinanceScreenContent
    extends
        StatelessWidget {
  final dynamic model;

  final FinanceProjection projection;

  final CryptoBalances balances;

  final List<
    InvestmentHistory
  >
  history;

  final VoidCallback onPlanning;

  final VoidCallback onHistory;

  final VoidCallback onBalance;

  final VoidCallback onVault;

  final VoidCallback onPatrimony;

  final VoidCallback onObjective;

  final ValueChanged<
    String
  >
  onCrypto;

  final ValueChanged<
    InvestmentHistory
  >
  onHistoryItem;

  final ValueChanged<
    InvestmentHistory
  >
  onDeleteContribution;

  // ============================================================
  // VISIBILIDADE DOS SALDOS
  // ============================================================

  final bool showBalances;

  // ============================================================
  // MOSTRAR MAIS / MENOS
  // ============================================================

  final bool showEvolutionDetails;

  final VoidCallback onToggleEvolution;

  final bool showLastContributionDetails;

  final VoidCallback onToggleLastContribution;

  const FinanceScreenContent({
    super.key,
    required this.model,
    required this.projection,
    required this.balances,
    required this.history,
    required this.onPlanning,
    required this.onHistory,
    required this.onBalance,
    required this.onVault,
    required this.onPatrimony,
    required this.onObjective,
    required this.onCrypto,
    required this.onHistoryItem,
    required this.onDeleteContribution,
    required this.showBalances,
    required this.showEvolutionDetails,
    required this.onToggleEvolution,
    required this.showLastContributionDetails,
    required this.onToggleLastContribution,
  });

  // ============================================================
  // ÚLTIMO APORTE
  // ============================================================

  List<
    InvestmentHistory
  >
  get latestContribution {
    if (history.isEmpty) {
      return [];
    }

    return [
      history.last,
    ];
  }

  // ============================================================
  // TOTAL APORTADO
  // ============================================================

  double get totalContributed {
    double total = 0;

    for (final item in history) {
      total += item.safeValue;
    }

    return total;
  }

  // ============================================================
  // MÉDIA
  // ============================================================

  double get averageContribution {
    if (history.isEmpty) {
      return 0;
    }

    return totalContributed /
        history.length;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // INTRO
          // ====================================================
          const FinanceIntro(),

          const SizedBox(
            height: 28,
          ),

          // ====================================================
          // CARTEIRA
          // ====================================================
          WalletCard(
            patrimony: model.patrimony,
            invested: model.invested,
            bitcoin: balances.bitcoin,
            ethereum: balances.ethereum,
            solana: balances.solana,
            usdt: balances.usdt,
            onBalance: onBalance,
            onBitcoin: () => onCrypto(
              'BTC',
            ),
            onEthereum: () => onCrypto(
              'ETH',
            ),
            onSolana: () => onCrypto(
              'SOL',
            ),
            onUsdt: () => onCrypto(
              'USDT',
            ),
            onVault: onVault,

            // ==================================================
            // OLHO GLOBAL
            // ==================================================
            showBalances: showBalances,
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // RESUMO
          // ====================================================
          FinanceSummarySection(
            patrimony: model.patrimony,
            investmentGoal: model.investmentGoal,
            minimumGoal: model.minimumGoal,
            mediumGoal: model.mediumGoal,
            maximumGoal: model.maximumGoal,
            onPatrimonyTap: onPatrimony,
            onObjectiveTap: onObjective,
            onRhythmsTap: onPlanning,

            // ==================================================
            // OLHO GLOBAL
            //
            // Patrimônio e Objetivo serão ocultados.
            // Ritmos permanecem visíveis.
            // ==================================================
            showBalances: showBalances,
          ),

          const SizedBox(
            height: 32,
          ),

          // ====================================================
          // SUA EVOLUÇÃO
          // ====================================================
          FinanceSectionHeader(
            title: 'Sua evolução',
            subtitle: 'O objetivo cresce enquanto o tempo restante diminui.',
            trailing: _buildToggleButton(
              expanded: showEvolutionDetails,
              onPressed: onToggleEvolution,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // SUA EVOLUÇÃO - MENOS
          // ====================================================
          if (!showEvolutionDetails)
            _buildCollapsedEvolution(
              context,
            ),

          // ====================================================
          // SUA EVOLUÇÃO - MAIS
          // ====================================================
          if (showEvolutionDetails)
            InvestmentProgress(
              projection: projection,
              showPatrimony: true,
              showAverageContribution: true,
              showEstimatedTime: true,

              // ================================================
              // OLHO GLOBAL
              // ================================================
              showBalances: showBalances,
            ),

          const SizedBox(
            height: 32,
          ),

          // ====================================================
          // ÚLTIMO APORTE
          // ====================================================
          FinanceSectionHeader(
            title: 'Último aporte',
            subtitle: history.isEmpty
                ? 'Nenhum aporte registrado.'
                : 'Seu aporte mais recente.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(
                    Icons.history,
                    size: 18,
                  ),
                  label: const Text(
                    'Ver todos',
                  ),
                ),

                const SizedBox(
                  width: 4,
                ),

                _buildToggleButton(
                  expanded: showLastContributionDetails,
                  onPressed: onToggleLastContribution,
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // ÚLTIMO APORTE - MENOS
          // ====================================================
          if (!showLastContributionDetails)
            _buildContributionSummary(
              context,
            ),

          // ====================================================
          // ÚLTIMO APORTE - MAIS
          // ====================================================
          if (showLastContributionDetails)
            if (history.isEmpty)
              const EmptyLastContribution()
            else
              InvestmentTimeline(
                history: latestContribution,
                showHeader: false,
                onDelete: onDeleteContribution,
                onTap: onHistoryItem,

                // ==============================================
                // OLHO GLOBAL
                // ==============================================
                showBalances: showBalances,
              ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÃO MOSTRAR MAIS / MENOS
  // ============================================================

  Widget _buildToggleButton({
    required bool expanded,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: AnimatedRotation(
        turns: expanded
            ? 0.5
            : 0,
        duration: const Duration(
          milliseconds: 200,
        ),
        child: const Icon(
          Icons.expand_more_rounded,
          size: 18,
        ),
      ),
      label: Text(
        expanded
            ? 'Mostrar menos'
            : 'Mostrar mais',
      ),
    );
  }

  // ============================================================
  // SUA EVOLUÇÃO RECOLHIDA
  // ============================================================

  Widget _buildCollapsedEvolution(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // CABEÇALHO
          // ====================================================
          Row(
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
                  Icons.trending_up_rounded,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evolução do objetivo',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Cada aporte avança seu objetivo e reduz o tempo restante.',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 26,
          ),

          // ====================================================
          // OBJETIVO / FALTA
          // ====================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: [
                // ==================================================
                // OBJETIVO FINAL
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objetivo final',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall,
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _balanceText(
                          _toDouble(
                            model.investmentGoal,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DIVISOR
                // ==================================================
                Container(
                  width: 1,
                  height: 46,
                  color: colorScheme.outlineVariant,
                ),

                // ==================================================
                // AINDA FALTA
                // ==================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ainda falta',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall,
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        _balanceText(
                          projection.missingMoney,
                        ),
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESUMO ÚLTIMO APORTE
  // ============================================================

  Widget _buildContributionSummary(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // TOTAL
          // ====================================================
          Expanded(
            child: _buildContributionMetric(
              context: context,
              icon: Icons.account_balance_wallet_outlined,
              value: _balanceText(
                totalContributed,
              ),
              label: 'Total aportado',
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ====================================================
          // MÉDIA
          // ====================================================
          Expanded(
            child: _buildContributionMetric(
              context: context,
              icon: Icons.bar_chart_rounded,
              value: _balanceText(
                averageContribution,
              ),
              label: 'Média por aporte',
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          // ====================================================
          // QUANTIDADE
          //
          // Não é saldo monetário, permanece visível.
          // ====================================================
          Expanded(
            child: _buildContributionMetric(
              context: context,
              icon: Icons.format_list_numbered_rounded,
              value: '${history.length}',
              label: 'Aportes',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MÉTRICA
  // ============================================================

  Widget _buildContributionMetric({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SALDO VISÍVEL / OCULTO
  // ============================================================

  String _balanceText(
    double value,
  ) {
    if (!showBalances) {
      return 'R\$ ••••••';
    }

    return _currency(
      value,
    );
  }

  // ============================================================
  // CONVERTER DOUBLE
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // MOEDA
  // ============================================================

  String _currency(
    double value,
  ) {
    final negative =
        value <
        0;

    final safeValue = value.abs();

    final fixed = safeValue.toStringAsFixed(
      2,
    );

    final parts = fixed.split(
      '.',
    );

    final integer = parts.first;

    final decimal =
        parts.length >
            1
        ? parts[1]
        : '00';

    final reversed = integer
        .split(
          '',
        )
        .reversed
        .toList();

    final formatted = StringBuffer();

    for (
      int index = 0;
      index <
          reversed.length;
      index++
    ) {
      if (index >
              0 &&
          index %
                  3 ==
              0) {
        formatted.write(
          '.',
        );
      }

      formatted.write(
        reversed[index],
      );
    }

    final finalInteger = formatted
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    return '${negative ? '-' : ''}'
        'R\$ $finalInteger,$decimal';
  }
}
