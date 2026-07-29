import 'package:flutter/material.dart';

import 'finance_history_formatter.dart';

class InvestmentTimelineSummary extends StatelessWidget {
  final double totalInvested;
  final double averageContribution;
  final int contributionCount;

  const InvestmentTimelineSummary({
    super.key,
    required this.totalInvested,
    required this.averageContribution,
    required this.contributionCount,
  });

  Widget _summaryCard({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
  }) {
    final color = Theme.of(context).colorScheme.primary;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),

            const SizedBox(height: 10),

            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 3),

            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _summaryCard(
          context: context,
          label: 'Total aportado',
          value: FinanceHistoryFormatter.currency(totalInvested),
          icon: Icons.account_balance_wallet_outlined,
        ),

        const SizedBox(width: 10),

        _summaryCard(
          context: context,
          label: 'Média por aporte',
          value: FinanceHistoryFormatter.currency(averageContribution),
          icon: Icons.equalizer_outlined,
        ),

        const SizedBox(width: 10),

        _summaryCard(
          context: context,
          label: 'Aportes',
          value: contributionCount.toString(),
          icon: Icons.format_list_numbered_outlined,
        ),
      ],
    );
  }
}
