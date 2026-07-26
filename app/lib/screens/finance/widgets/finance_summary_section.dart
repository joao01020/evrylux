import 'package:flutter/material.dart';

import '../utils/finance_screen_formatter.dart';

class FinanceSummarySection
    extends
        StatelessWidget {
  final double patrimony;
  final double investmentGoal;

  final double minimumGoal;
  final double mediumGoal;
  final double maximumGoal;

  final VoidCallback onPatrimonyTap;
  final VoidCallback onObjectiveTap;
  final VoidCallback onRhythmsTap;

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
  });

  Widget _miniCard({
    required BuildContext context,
    required String icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            16,
          ),
          child: Card(
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                16,
              ),
              side: BorderSide(
                color: Theme.of(
                  context,
                ).dividerColor,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 14,
              ),
              child: Column(
                children: [
                  Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        _miniCard(
          context: context,
          icon: '💼',
          title: 'Patrimônio',
          value: FinanceScreenFormatter.currency(
            patrimony,
          ),
          onTap: onPatrimonyTap,
        ),

        const SizedBox(
          width: 8,
        ),

        _miniCard(
          context: context,
          icon: '🎯',
          title: 'Objetivo',
          value:
              investmentGoal >
                  0
              ? FinanceScreenFormatter.currency(
                  investmentGoal,
                )
              : 'Não definido',
          onTap: onObjectiveTap,
        ),

        const SizedBox(
          width: 8,
        ),

        _miniCard(
          context: context,
          icon: '📊',
          title: 'Ritmos',
          value:
              '${FinanceScreenFormatter.currency(minimumGoal)}\n'
              '${FinanceScreenFormatter.currency(mediumGoal)}\n'
              '${FinanceScreenFormatter.currency(maximumGoal)}',
          onTap: onRhythmsTap,
        ),
      ],
    );
  }
}
