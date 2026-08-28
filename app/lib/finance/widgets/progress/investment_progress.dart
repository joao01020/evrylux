import 'package:flutter/material.dart';

import '../../projections/finance_projection.dart';

class InvestmentProgress
    extends
        StatelessWidget {
  final FinanceProjection projection;

  /// Exibe ou esconde o patrimônio atual.
  final bool showPatrimony;

  /// Exibe ou esconde a média real dos aportes.
  final bool showAverageContribution;

  /// Exibe ou esconde o tempo estimado.
  final bool showEstimatedTime;

  /// Controla a visibilidade de todos os valores monetários.
  final bool showBalances;

  const InvestmentProgress({
    super.key,
    required this.projection,
    this.showPatrimony = true,
    this.showAverageContribution = true,
    this.showEstimatedTime = true,
    this.showBalances = true,
  });

  // =========================================================
  // FORMATAÇÃO
  // =========================================================

  String _formatCurrency(
    double value,
  ) {
    if (!showBalances) {
      return 'R\$ ••••••';
    }

    final safeValue = value.isFinite
        ? value
        : 0.0;

    final isNegative =
        safeValue <
        0;

    final absoluteValue = safeValue.abs();

    final parts = absoluteValue
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integerPart = parts.first;

    final decimalPart =
        parts.length >
            1
        ? parts.last
        : '00';

    final reversed = integerPart
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

    final formattedInteger = formatted
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    final sign = isNegative
        ? '-'
        : '';

    return '${sign}R\$ $formattedInteger,$decimalPart';
  }

  String _formatPercentage(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final normalized = safeValue.clamp(
      0.0,
      100.0,
    );

    if (normalized ==
        normalized.roundToDouble()) {
      return '${normalized.toStringAsFixed(0)}%';
    }

    return '${normalized.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  // =========================================================
  // CORES
  // =========================================================

  Color _objectiveColor(
    BuildContext context,
  ) {
    final progress = projection.objectiveBar;

    if (progress >=
        1) {
      return Colors.green;
    }

    if (progress >=
        0.75) {
      return Colors.purple;
    }

    if (progress >=
        0.50) {
      return Colors.blue;
    }

    if (progress >=
        0.25) {
      return Colors.orange;
    }

    return Theme.of(
      context,
    ).colorScheme.primary;
  }

  Color _timeColor(
    BuildContext context,
  ) {
    final timeRemaining = projection.timeRemainingBar;

    if (timeRemaining <=
        0) {
      return Colors.green;
    }

    if (timeRemaining <=
        0.25) {
      return Colors.purple;
    }

    if (timeRemaining <=
        0.50) {
      return Colors.blue;
    }

    if (timeRemaining <=
        0.75) {
      return Colors.orange;
    }

    return Theme.of(
      context,
    ).colorScheme.secondary;
  }

  // =========================================================
  // COMPONENTES
  // =========================================================

  Widget _header(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            projection.goalReached
                ? Icons.emoji_events_outlined
                : Icons.trending_up_outlined,
            color: Theme.of(
              context,
            ).colorScheme.onPrimaryContainer,
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
                projection.goalReached
                    ? 'Objetivo alcançado'
                    : 'Evolução do objetivo',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                projection.goalReached
                    ? 'Você concluiu seu planejamento financeiro.'
                    : 'Cada aporte avança seu objetivo e reduz o tempo restante.',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressSection({
    required BuildContext context,
    required String title,
    required String subtitle,
    required double value,
    required double percentage,
    required Color color,
    required IconData icon,
  }) {
    final safeValue = value.clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.14,
                  ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: color,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _formatPercentage(
                  percentage,
                ),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(
              20,
            ),
            child: LinearProgressIndicator(
              value: safeValue,
              minHeight: 12,
              backgroundColor: color.withValues(
                alpha: 0.12,
              ),
              valueColor:
                  AlwaysStoppedAnimation<
                    Color
                  >(
                    color,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _informationCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final effectiveColor =
        color ??
        Theme.of(
          context,
        ).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveColor,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _financialSummary(
    BuildContext context,
  ) {
    final items =
        <
          Widget
        >[];

    if (showPatrimony) {
      items.add(
        _informationCard(
          context: context,
          label: 'Patrimônio atual',
          value: _formatCurrency(
            projection.model.patrimony,
          ),
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
        ),
      );
    }

    if (showAverageContribution) {
      items.add(
        _informationCard(
          context: context,
          label: 'Média dos aportes',
          value: _formatCurrency(
            projection.averageContribution >
                    0
                ? projection.averageContribution
                : projection.model.averageContribution,
          ),
          icon: Icons.equalizer_outlined,
          color: Colors.blue,
        ),
      );
    }

    if (showEstimatedTime) {
      items.add(
        _informationCard(
          context: context,
          label: 'Tempo estimado',
          value: projection.estimatedRemainingTimeText,
          icon: Icons.schedule_outlined,
          color: Colors.orange,
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            if (constraints.maxWidth <
                600) {
              return Column(
                children: [
                  for (
                    int index = 0;
                    index <
                        items.length;
                    index++
                  ) ...[
                    items[index],

                    if (index <
                        items.length -
                            1)
                      const SizedBox(
                        height: 10,
                      ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (
                  int index = 0;
                  index <
                      items.length;
                  index++
                ) ...[
                  Expanded(
                    child: items[index],
                  ),

                  if (index <
                      items.length -
                          1)
                    const SizedBox(
                      width: 10,
                    ),
                ],
              ],
            );
          },
    );
  }

  Widget _goalSummary(
    BuildContext context,
  ) {
    final hasGoal =
        projection.model.investmentGoal >
        0;

    if (!hasGoal) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),

            const SizedBox(
              width: 10,
            ),

            const Expanded(
              child: Text(
                'Defina um objetivo final para acompanhar seu progresso financeiro.',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _summaryValue(
                  context: context,
                  label: 'Objetivo final',
                  value: _formatCurrency(
                    projection.model.investmentGoal,
                  ),
                ),
              ),

              Container(
                width: 1,
                height: 45,
                margin: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                color: Theme.of(
                  context,
                ).dividerColor,
              ),

              Expanded(
                child: _summaryValue(
                  context: context,
                  label: 'Ainda falta',
                  value: _formatCurrency(
                    projection.missingMoney,
                  ),
                  alignEnd: true,
                ),
              ),
            ],
          ),

          if (projection.goalReached) ...[
            const SizedBox(
              height: 14,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),

                  SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      'Parabéns! Seu patrimônio alcançou o objetivo definido.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryValue({
    required BuildContext context,
    required String label,
    required String value,
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
          ),
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd
              ? TextAlign.end
              : TextAlign.start,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // TELA
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final objectiveColor = _objectiveColor(
      context,
    );

    final timeColor = _timeColor(
      context,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: BorderSide(
          color: Theme.of(
            context,
          ).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              context,
            ),

            const SizedBox(
              height: 22,
            ),

            _goalSummary(
              context,
            ),

            const SizedBox(
              height: 16,
            ),

            _progressSection(
              context: context,
              title: 'Progresso do objetivo',
              subtitle: '${_formatCurrency(projection.model.patrimony)} de ${_formatCurrency(projection.model.investmentGoal)}',
              value: projection.objectiveBar,
              percentage: projection.objectivePercentage,
              color: objectiveColor,
              icon: Icons.flag_outlined,
            ),

            const SizedBox(
              height: 12,
            ),

            _progressSection(
              context: context,
              title: 'Tempo restante',
              subtitle: projection.estimatedRemainingTimeText,
              value: projection.timeRemainingBar,
              percentage: projection.timeRemainingPercentage,
              color: timeColor,
              icon: Icons.hourglass_bottom_outlined,
            ),

            const SizedBox(
              height: 16,
            ),

            _financialSummary(
              context,
            ),
          ],
        ),
      ),
    );
  }
}
