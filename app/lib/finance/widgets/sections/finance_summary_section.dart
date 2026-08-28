import 'package:flutter/material.dart';

class FinanceSummarySection
    extends
        StatelessWidget {
  const FinanceSummarySection({
    super.key,
    required this.patrimony,
    required this.investmentGoal,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,
    required this.onPatrimonyTap,
    required this.onObjectiveTap,
    required this.onRhythmsTap,
    this.showBalances = true,
  });

  final double patrimony;
  final double investmentGoal;
  final double minimumGoal;
  final double mediumGoal;
  final double maximumGoal;

  final VoidCallback onPatrimonyTap;
  final VoidCallback onObjectiveTap;
  final VoidCallback onRhythmsTap;

  // ============================================================
  // VISIBILIDADE DOS SALDOS
  // ============================================================

  final bool showBalances;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final cards = [
              // ==================================================
              // PATRIMÔNIO
              // ==================================================
              _FinanceSummaryCard(
                icon: Icons.work_outline_rounded,
                title: 'Patrimônio',
                content: _money(
                  patrimony,
                ),
                onTap: onPatrimonyTap,
              ),

              // ==================================================
              // OBJETIVO
              // ==================================================
              _FinanceSummaryCard(
                icon: Icons.track_changes_rounded,
                title: 'Objetivo',
                content: _money(
                  investmentGoal,
                ),
                onTap: onObjectiveTap,
              ),

              // ==================================================
              // RITMOS
              //
              // Ritmos permanecem sempre visíveis.
              // ==================================================
              _FinanceSummaryCard(
                icon: Icons.bar_chart_rounded,
                title: 'Ritmos',
                content: _rhythmsText(),
                onTap: onRhythmsTap,
              ),
            ];

            // ====================================================
            // MOBILE
            // ====================================================

            if (constraints.maxWidth <
                760) {
              return Column(
                children: cards
                    .map(
                      (
                        card,
                      ) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }

            // ====================================================
            // DESKTOP
            // ====================================================

            return Row(
              children: [
                Expanded(
                  child: cards[0],
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: cards[1],
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: cards[2],
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // RITMOS
  //
  // NÃO respeita showBalances.
  // Deve permanecer sempre visível.
  // ============================================================

  String _rhythmsText() {
    return '${_currency(minimumGoal)}\n'
        '${_currency(mediumGoal)}\n'
        '${_currency(maximumGoal)}';
  }

  // ============================================================
  // MONEY
  //
  // Usado apenas nos valores que devem ser ocultados:
  //
  // - Patrimônio
  // - Objetivo
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
// FINANCE SUMMARY CARD
// ============================================================

class _FinanceSummaryCard
    extends
        StatelessWidget {
  const _FinanceSummaryCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String content;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          18,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Text(
              content,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
