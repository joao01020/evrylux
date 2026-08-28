import 'package:flutter/material.dart';

import '../../services/history/investment_history.dart';

class InvestmentTimeline
    extends
        StatelessWidget {
  const InvestmentTimeline({
    super.key,
    required this.history,
    required this.showHeader,
    required this.onDelete,
    required this.onTap,
    this.showBalances = true,
  });

  final List<
    InvestmentHistory
  >
  history;

  final bool showHeader;

  final ValueChanged<
    InvestmentHistory
  >
  onDelete;

  final ValueChanged<
    InvestmentHistory
  >
  onTap;

  final bool showBalances;

  double get total {
    double result = 0;

    for (final item in history) {
      result += item.safeValue;
    }

    return result;
  }

  double get average {
    if (history.isEmpty) {
      return 0;
    }

    return total /
        history.length;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

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
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            const Text(
              'Histórico',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 14,
            ),
          ],

          // ====================================================
          // SUMMARY
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _TimelineMetric(
                  icon: Icons.account_balance_wallet_outlined,
                  value: _money(
                    total,
                  ),
                  label: 'Total aportado',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _TimelineMetric(
                  icon: Icons.bar_chart_rounded,
                  value: _money(
                    average,
                  ),
                  label: 'Média por aporte',
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _TimelineMetric(
                  icon: Icons.format_list_numbered_rounded,
                  value: '${history.length}',
                  label: 'Aportes',
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          ...history.map(
            (
              item,
            ) {
              return _buildItem(
                context,
                item,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    InvestmentHistory item,
  ) {
    return InkWell(
      onTap: () {
        onTap(
          item,
        );
      },
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.all(
          14,
        ),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(
            14,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _money(
                      item.safeValue,
                    ),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Text(
                    item.normalizedRhythm,
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Excluir',
              onPressed: () {
                onDelete(
                  item,
                );
              },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _money(
    double value,
  ) {
    if (!showBalances) {
      return 'R\$ ••••••';
    }

    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _TimelineMetric
    extends
        StatelessWidget {
  const _TimelineMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
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
          ),

          const SizedBox(
            height: 12,
          ),

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            label,
          ),
        ],
      ),
    );
  }
}
