import 'package:flutter/material.dart';

import '../../models/crypto/crypto_balances.dart';

import '../sections/finance_intro.dart';
import '../wallet/wallet_card.dart';

class FinanceScreenContent
    extends
        StatelessWidget {
  const FinanceScreenContent({
    super.key,
    required this.model,
    required this.balances,
    required this.objectiveName,
    required this.onPlanning,
    required this.onBalance,
    required this.onVault,
    required this.onPatrimony,
    required this.onObjective,
    required this.onCrypto,
    required this.onOpenEvolution,
    required this.onOpenLastContribution,
    required this.onContribution,
    required this.showBalances,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final dynamic model;

  final CryptoBalances balances;

  final String objectiveName;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onPlanning;

  final VoidCallback onBalance;

  final VoidCallback onVault;

  final VoidCallback onPatrimony;

  final VoidCallback onObjective;

  final VoidCallback onContribution;

  final ValueChanged<
    String
  >
  onCrypto;

  // ============================================================
  // MODAIS EXISTENTES
  // ============================================================

  final VoidCallback onOpenEvolution;

  final VoidCallback onOpenLastContribution;

  // ============================================================
  // SALDOS
  // ============================================================

  final bool showBalances;

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
        32,
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

            onBitcoin: () {
              onCrypto(
                'BTC',
              );
            },

            onEthereum: () {
              onCrypto(
                'ETH',
              );
            },

            onSolana: () {
              onCrypto(
                'SOL',
              );
            },

            onUsdt: () {
              onCrypto(
                'USDT',
              );
            },

            onVault: onVault,

            showBalances: showBalances,
          ),

          const SizedBox(
            height: 16,
          ),

          // ====================================================
          // ATALHOS
          // ====================================================
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // =================================================
              // EVOLUÇÃO
              // =================================================
              _FinanceShortcutButton(
                tooltip: 'Sua evolução',
                icon: Icons.trending_up_rounded,
                onTap: onOpenEvolution,
              ),

              // =================================================
              // ÚLTIMO APORTE
              // =================================================
              _FinanceShortcutButton(
                tooltip: 'Último aporte',
                icon: Icons.savings_rounded,
                onTap: onOpenLastContribution,
              ),

              // =================================================
              // REGISTRAR APORTE
              // =================================================
              _FinanceShortcutButton(
                tooltip: 'Registrar aporte',
                icon: Icons.add_rounded,
                onTap: onContribution,
              ),

              // =================================================
              // OBJETIVO
              // =================================================
              _FinanceShortcutButton(
                tooltip: 'Objetivo',
                icon: Icons.track_changes_rounded,
                onTap: () {
                  _showObjectiveModal(
                    context,
                  );
                },
              ),

              // =================================================
              // RITMOS
              // =================================================
              _FinanceShortcutButton(
                tooltip: 'Ritmos',
                icon: Icons.bar_chart_rounded,
                onTap: () {
                  _showRhythmsModal(
                    context,
                  );
                },
              ),
            ],
          ),

          const SizedBox(
            height: 30,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODAL - OBJETIVO
  // ============================================================

  Future<
    void
  >
  _showObjectiveModal(
    BuildContext context,
  ) async {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER
                  // ============================================
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

                  // ============================================
                  // CARD
                  // ============================================
                  _ObjectiveModalCard(
                    name: objectiveName,
                    value: _money(
                      _toDouble(
                        model.investmentGoal,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ============================================
                  // EDITAR
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          modalContext,
                        ).pop();

                        onObjective();
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                      ),
                      label: const Text(
                        'Editar objetivo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // MODAL - RITMOS
  // ============================================================

  Future<
    void
  >
  _showRhythmsModal(
    BuildContext context,
  ) async {
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ============================================
                  // HEADER
                  // ============================================
                  _FinanceModalHeader(
                    icon: Icons.bar_chart_rounded,
                    title: 'Ritmos',
                    subtitle: 'Veja os seus três níveis de aporte planejados.',
                    onClose: () {
                      Navigator.of(
                        modalContext,
                      ).pop();
                    },
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  // ============================================
                  // VALORES
                  // ============================================
                  _RhythmsModalCard(
                    minimum: _currency(
                      _toDouble(
                        model.minimumGoal,
                      ),
                    ),
                    medium: _currency(
                      _toDouble(
                        model.mediumGoal,
                      ),
                    ),
                    maximum: _currency(
                      _toDouble(
                        model.maximumGoal,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ============================================
                  // EDITAR PLANEJAMENTO
                  // ============================================
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          modalContext,
                        ).pop();

                        onPlanning();
                      },
                      icon: const Icon(
                        Icons.tune_rounded,
                      ),
                      label: const Text(
                        'Editar planejamento',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // MONEY
  // ============================================================

  String _money(
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
  // DOUBLE
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
  // CURRENCY
  // ============================================================

  String _currency(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final negative =
        safeValue <
        0;

    final absolute = safeValue.abs();

    final parts = absolute
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integer = parts.first;

    final decimal =
        parts.length >
            1
        ? parts.last
        : '00';

    final reversed = integer
        .split(
          '',
        )
        .reversed
        .toList();

    final buffer = StringBuffer();

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
        buffer.write(
          '.',
        );
      }

      buffer.write(
        reversed[index],
      );
    }

    final formattedInteger = buffer
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    final sign = negative
        ? '-'
        : '';

    return '${sign}R\$ $formattedInteger,$decimal';
  }
}

// ============================================================
// BOTÃO DE ATALHO
// ============================================================

class _FinanceShortcutButton
    extends
        StatelessWidget {
  const _FinanceShortcutButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;

  final IconData icon;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: 0.16,
              ),
            ),
          ),
          child: Icon(
            icon,
            size: 22,
            color: colorScheme.primary,
          ),
        ),
      ),
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

// ============================================================
// CARD - OBJETIVO
// ============================================================

class _ObjectiveModalCard
    extends
        StatelessWidget {
  const _ObjectiveModalCard({
    required this.name,
    required this.value,
  });

  final String name;

  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.track_changes_rounded,
            size: 28,
            color: colorScheme.primary,
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            name.trim().isEmpty
                ? 'Objetivo financeiro'
                : name.trim(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CARD - RITMOS
// ============================================================

class _RhythmsModalCard
    extends
        StatelessWidget {
  const _RhythmsModalCard({
    required this.minimum,
    required this.medium,
    required this.maximum,
  });

  final String minimum;

  final String medium;

  final String maximum;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _RhythmItem(
            title: 'Mínimo',
            value: minimum,
            icon: Icons.speed_rounded,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _RhythmItem(
            title: 'Médio',
            value: medium,
            icon: Icons.trending_up_rounded,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _RhythmItem(
            title: 'Máximo',
            value: maximum,
            icon: Icons.rocket_launch_outlined,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ITEM DO RITMO
// ============================================================

class _RhythmItem
    extends
        StatelessWidget {
  const _RhythmItem({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;

  final String value;

  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 22,
            color: colorScheme.primary,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
