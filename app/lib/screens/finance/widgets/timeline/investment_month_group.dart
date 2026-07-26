import 'package:flutter/material.dart';

import '../../../../models/finance/investment_history.dart';

import 'finance_history_formatter.dart';
import 'investment_timeline_item.dart';

class InvestmentMonthGroup
    extends
        StatelessWidget {
  final List<
    InvestmentHistory
  >
  items;

  final ValueChanged<
    InvestmentHistory
  >?
  onTap;
  final ValueChanged<
    InvestmentHistory
  >?
  onDelete;

  const InvestmentMonthGroup({
    super.key,
    required this.items,
    this.onTap,
    this.onDelete,
  });

  double get _monthTotal {
    return items.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.value;
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                FinanceHistoryFormatter.monthGroupTitle(
                  items.first.date,
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Text(
              FinanceHistoryFormatter.currency(
                _monthTotal,
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(
                  context,
                ).colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        for (
          int index = 0;
          index <
              items.length;
          index++
        )
          InvestmentTimelineItem(
            item: items[index],
            isFirst:
                index ==
                0,
            isLast:
                index ==
                items.length -
                    1,
            onTap: onTap,
            onDelete: onDelete,
          ),

        const SizedBox(
          height: 8,
        ),
      ],
    );
  }
}
