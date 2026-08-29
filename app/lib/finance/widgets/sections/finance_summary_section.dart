import 'package:flutter/material.dart';

class FinanceSummarySection
    extends
        StatelessWidget {
  const FinanceSummarySection({
    super.key,
    required this.objectiveName,
    required this.investmentGoal,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,
    required this.onObjectiveTap,
    required this.onRhythmsTap,
    this.showBalances = true,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String objectiveName;

  final double investmentGoal;

  final double minimumGoal;

  final double mediumGoal;

  final double maximumGoal;

  // ============================================================
  // AÇÕES
  // ============================================================

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
            // ==================================================
            // OBJETIVO
            // ==================================================

            final normalizedObjectiveName = objectiveName.trim().isEmpty
                ? 'Objetivo financeiro'
                : objectiveName.trim();

            final objectiveCard = _FinanceSummaryCard(
              icon: Icons.track_changes_rounded,
              title: normalizedObjectiveName,
              content: _money(
                investmentGoal,
              ),
              onTap: onObjectiveTap,
            );

            // ==================================================
            // RITMOS
            // ==================================================

            final rhythmsCard = _FinanceSummaryCard(
              icon: Icons.bar_chart_rounded,
              title: 'Ritmos',
              content: _rhythmsText(),
              onTap: onRhythmsTap,
              compactContent: true,
            );

            // ==================================================
            // MOBILE
            // ==================================================

            if (constraints.maxWidth <
                760) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  objectiveCard,

                  const SizedBox(
                    height: 8,
                  ),

                  rhythmsCard,
                ],
              );
            }

            // ==================================================
            // DESKTOP
            // ==================================================

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: objectiveCard,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: rhythmsCard,
                ),
              ],
            );
          },
    );
  }

  // ============================================================
  // RITMOS
  //
  // Os ritmos continuam sempre visíveis.
  // ============================================================

  String _rhythmsText() {
    return '${_currency(minimumGoal)}\n'
        '${_currency(mediumGoal)}\n'
        '${_currency(maximumGoal)}';
  }

  // ============================================================
  // MONEY
  //
  // O objetivo respeita o olho global.
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
    this.compactContent = false,
  });

  final IconData icon;

  final String title;

  final String content;

  final VoidCallback onTap;

  final bool compactContent;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          15,
        ),
        child: Container(
          width: double.infinity,

          // ====================================================
          // ALTURA COMPACTA
          // ====================================================
          height: 96,

          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // =================================================
              // ÍCONE
              // =================================================
              Icon(
                icon,
                size: 19,
                color: colorScheme.onSurface,
              ),

              const SizedBox(
                height: 5,
              ),

              // =================================================
              // TÍTULO
              // =================================================
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              SizedBox(
                height: compactContent
                    ? 2
                    : 4,
              ),

              // =================================================
              // CONTEÚDO
              // =================================================
              Flexible(
                child: Text(
                  content,
                  textAlign: TextAlign.center,
                  maxLines: compactContent
                      ? 3
                      : 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compactContent
                        ? 11.5
                        : 13,
                    height: compactContent
                        ? 1.12
                        : 1,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
