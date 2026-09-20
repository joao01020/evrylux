import 'package:flutter/material.dart';

import 'training_history_records.dart';

// ============================================================
// TRAINING HISTORY SUMMARY
// ============================================================

class TrainingHistorySummary
    extends
        StatelessWidget {
  const TrainingHistorySummary({
    super.key,
    required this.entries,
  });

  final List<
    TrainingHistoryEntry
  >
  entries;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _soft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final int total = entries.length;

    // ==========================================================
    // DIAS ATIVOS
    // ==========================================================

    final int activeDays = entries
        .map(
          (
            TrainingHistoryEntry entry,
          ) {
            return DateTime(
              entry.date.year,
              entry.date.month,
              entry.date.day,
            );
          },
        )
        .toSet()
        .length;

    // ==========================================================
    // ATIVIDADES ÚNICAS
    // ==========================================================

    final int activities = entries
        .map(
          (
            TrainingHistoryEntry entry,
          ) {
            return entry.activity.trim().toLowerCase();
          },
        )
        .where(
          (
            String value,
          ) {
            return value.isNotEmpty;
          },
        )
        .toSet()
        .length;

    // ==========================================================
    // TEMPO TOTAL
    // ==========================================================

    final int minutes =
        entries.fold<
          int
        >(
          0,
          (
            int sum,
            TrainingHistoryEntry entry,
          ) {
            return sum +
                (entry.durationMinutes ??
                    0);
          },
        );

    // ==========================================================
    // CARDS
    // ==========================================================

    final List<
      _SummaryCard
    >
    cards =
        <
          _SummaryCard
        >[
          _SummaryCard(
            icon: Icons.fitness_center_rounded,
            label: 'Registros',
            value: '$total',
          ),
          _SummaryCard(
            icon: Icons.calendar_today_outlined,
            label: 'Dias ativos',
            value: '$activeDays',
          ),
          _SummaryCard(
            icon: Icons.category_outlined,
            label: 'Atividades',
            value: '$activities',
          ),
          _SummaryCard(
            icon: Icons.timer_outlined,
            label: 'Tempo',
            value: _formatMinutes(
              minutes,
            ),
          ),
        ];

    // ==========================================================
    // LAYOUT RESPONSIVO
    // ==========================================================

    return LayoutBuilder(
      builder:
          (
            BuildContext context,
            BoxConstraints constraints,
          ) {
            if (constraints.maxWidth <
                620) {
              final double cardWidth =
                  (constraints.maxWidth -
                      10) /
                  2;

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: cards
                    .map(
                      (
                        _SummaryCard card,
                      ) {
                        return SizedBox(
                          width: cardWidth,
                          child: card,
                        );
                      },
                    )
                    .toList(
                      growable: false,
                    ),
              );
            }

            return Row(
              children: [
                for (
                  int i = 0;
                  i <
                      cards.length;
                  i++
                ) ...[
                  Expanded(
                    child: cards[i],
                  ),
                  if (i <
                      cards.length -
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

  // ============================================================
  // FORMATAR MINUTOS
  // ============================================================

  static String _formatMinutes(
    int minutes,
  ) {
    if (minutes <=
        0) {
      return '0 min';
    }

    if (minutes <
        60) {
      return '$minutes min';
    }

    final int hours =
        minutes ~/
        60;

    final int rest =
        minutes %
        60;

    if (rest ==
        0) {
      return '${hours}h';
    }

    return '${hours}h ${rest}m';
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard
    extends
        StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  final String label;

  final String value;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: TrainingHistorySummary._surface,
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: TrainingHistorySummary._border,
        ),
      ),
      child: Row(
        children: [
          // ======================================================
          // ÍCONE
          // ======================================================
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: TrainingHistorySummary._soft,
              borderRadius: BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: TrainingHistorySummary._primary,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          // ======================================================
          // INFORMAÇÕES
          // ======================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TrainingHistorySummary._text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TrainingHistorySummary._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
