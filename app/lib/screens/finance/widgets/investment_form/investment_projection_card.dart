import 'package:flutter/material.dart';

import 'investment_form_formatter.dart';

class InvestmentProjectionCard
    extends
        StatelessWidget {
  final Color color;
  final String title;
  final String description;

  final double monthlyContribution;
  final double contributed;
  final double projectedPatrimony;

  final int projectionYears;

  const InvestmentProjectionCard({
    super.key,
    required this.color,
    required this.title,
    required this.description,
    required this.monthlyContribution,
    required this.contributed,
    required this.projectedPatrimony,
    required this.projectionYears,
  });

  Widget _information({
    required BuildContext context,
    required String label,
    required String value,
    required String helper,
  }) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 2,
          ),

          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          16,
        ),
        side: BorderSide(
          color: color.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Text(
                  '${InvestmentFormFormatter.currency(monthlyContribution)}/mês',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              description,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    if (constraints.maxWidth <
                        390) {
                      return Column(
                        children: [
                          _information(
                            context: context,
                            label: InvestmentFormFormatter.projectionPeriod(
                              projectionYears,
                            ),
                            value: InvestmentFormFormatter.currency(
                              contributed,
                            ),
                            helper: 'Total em aportes',
                          ),

                          const SizedBox(
                            height: 10,
                          ),

                          _information(
                            context: context,
                            label: 'Você terá',
                            value: InvestmentFormFormatter.currency(
                              projectedPatrimony,
                            ),
                            helper: 'Patrimônio projetado',
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _information(
                            context: context,
                            label: InvestmentFormFormatter.projectionPeriod(
                              projectionYears,
                            ),
                            value: InvestmentFormFormatter.currency(
                              contributed,
                            ),
                            helper: 'Total em aportes',
                          ),
                        ),

                        const SizedBox(
                          width: 12,
                        ),

                        Expanded(
                          child: _information(
                            context: context,
                            label: 'Você terá',
                            value: InvestmentFormFormatter.currency(
                              projectedPatrimony,
                            ),
                            helper: 'Patrimônio projetado',
                          ),
                        ),
                      ],
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
