import 'package:flutter/material.dart';

import '../../../../models/finance/investment_history.dart';

import 'finance_history_formatter.dart';
import 'investment_rhythm_style.dart';

class InvestmentTimelineItem
    extends
        StatelessWidget {
  final InvestmentHistory item;
  final bool isFirst;
  final bool isLast;

  final ValueChanged<
    InvestmentHistory
  >?
  onTap;
  final ValueChanged<
    InvestmentHistory
  >?
  onDelete;

  const InvestmentTimelineItem({
    super.key,
    required this.item,
    required this.isFirst,
    required this.isLast,
    this.onTap,
    this.onDelete,
  });

  Widget _informationChip({
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.10,
        ),
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),

          const SizedBox(
            width: 5,
          ),

          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<
    void
  >
  _showDeleteConfirmation(
    BuildContext context,
  ) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir aporte?',
                  ),
                  content: Text(
                    'O aporte de '
                    '${FinanceHistoryFormatter.currency(item.value)} '
                    'será removido do histórico.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      child: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed ==
        true) {
      onDelete?.call(
        item,
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final rhythm = InvestmentRhythmStyle.normalize(
      item.rhythm,
    );

    final color = InvestmentRhythmStyle.color(
      item.rhythm,
    );

    final icon = InvestmentRhythmStyle.icon(
      item.rhythm,
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : color.withValues(
                            alpha: 0.25,
                          ),
                  ),
                ),

                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface,
                      width: 4,
                    ),
                  ),
                ),

                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : color.withValues(
                            alpha: 0.25,
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: 14,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap:
                      onTap ==
                          null
                      ? null
                      : () {
                          onTap!(
                            item,
                          );
                        },
                  borderRadius: BorderRadius.circular(
                    16,
                  ),
                  child: Ink(
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(
                        alpha: 0.06,
                      ),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color: color.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: color.withValues(
                                  alpha: 0.13,
                                ),
                                borderRadius: BorderRadius.circular(
                                  13,
                                ),
                              ),
                              child: Icon(
                                icon,
                                color: color,
                                size: 21,
                              ),
                            ),

                            const SizedBox(
                              width: 11,
                            ),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    FinanceHistoryFormatter.currency(
                                      item.value,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 3,
                                  ),

                                  Text(
                                    '${FinanceHistoryFormatter.date(item.date)} '
                                    'às ${FinanceHistoryFormatter.time(item.date)}',
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

                            if (onDelete !=
                                null)
                              IconButton(
                                tooltip: 'Excluir aporte',
                                onPressed: () {
                                  _showDeleteConfirmation(
                                    context,
                                  );
                                },
                                icon: const Icon(
                                  Icons.delete_outline,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),

                        const SizedBox(
                          height: 13,
                        ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _informationChip(
                              color: color,
                              icon: icon,
                              label: rhythm,
                            ),

                            _informationChip(
                              color: Colors.blue,
                              icon: Icons.flag_outlined,
                              label: '+${FinanceHistoryFormatter.percentage(item.objectiveProgress)} no objetivo',
                            ),

                            _informationChip(
                              color: Colors.orange,
                              icon: Icons.schedule_outlined,
                              label: '-${FinanceHistoryFormatter.percentage(item.timeProgress.abs())} do tempo',
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 11,
                        ),

                        Text(
                          InvestmentRhythmStyle.description(
                            item.rhythm,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
