import 'package:flutter/material.dart';

enum TrainingHistoryPeriod {
  today,
  last7Days,
  last30Days,
  last90Days,
  last6Months,
  lastYear,
  all,
  custom,
}

extension TrainingHistoryPeriodLabel
    on
        TrainingHistoryPeriod {
  String get label {
    switch (this) {
      case TrainingHistoryPeriod.today:
        return 'Hoje';
      case TrainingHistoryPeriod.last7Days:
        return '7 dias';
      case TrainingHistoryPeriod.last30Days:
        return '30 dias';
      case TrainingHistoryPeriod.last90Days:
        return '90 dias';
      case TrainingHistoryPeriod.last6Months:
        return '6 meses';
      case TrainingHistoryPeriod.lastYear:
        return '1 ano';
      case TrainingHistoryPeriod.all:
        return 'Tudo';
      case TrainingHistoryPeriod.custom:
        return 'Personalizado';
    }
  }
}

class TrainingHistoryFilter
    extends
        StatelessWidget {
  const TrainingHistoryFilter({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
    this.customStart,
    this.customEnd,
    this.onCustomRangeTap,
  });

  final TrainingHistoryPeriod selectedPeriod;
  final ValueChanged<
    TrainingHistoryPeriod
  >
  onChanged;
  final DateTime? customStart;
  final DateTime? customEnd;
  final VoidCallback? onCustomRangeTap;

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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 17,
                color: _primary,
              ),
              SizedBox(
                width: 7,
              ),
              Text(
                'Período',
                style: TextStyle(
                  color: _text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrainingHistoryPeriod.values
                .map(
                  (
                    period,
                  ) => _buildChip(
                    period,
                  ),
                )
                .toList(
                  growable: false,
                ),
          ),
          if (selectedPeriod ==
                  TrainingHistoryPeriod.custom &&
              customStart !=
                  null &&
              customEnd !=
                  null) ...[
            const SizedBox(
              height: 10,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(
                10,
              ),
              onTap: onCustomRangeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: _soft,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: _border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.date_range_rounded,
                      size: 16,
                      color: _muted,
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      '${_formatDate(customStart!)} — ${_formatDate(customEnd!)}',
                      style: const TextStyle(
                        color: _text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(
    TrainingHistoryPeriod period,
  ) {
    final selected =
        selectedPeriod ==
        period;

    return InkWell(
      borderRadius: BorderRadius.circular(
        999,
      ),
      onTap: () => onChanged(
        period,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 150,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : _soft,
          borderRadius: BorderRadius.circular(
            999,
          ),
          border: Border.all(
            color: selected
                ? _primary
                : _border,
          ),
        ),
        child: Text(
          period.label,
          style: TextStyle(
            color: selected
                ? Colors.white
                : _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  static String _formatDate(
    DateTime date,
  ) {
    final d = date.day.toString().padLeft(
      2,
      '0',
    );
    final m = date.month.toString().padLeft(
      2,
      '0',
    );
    return '$d/$m/${date.year}';
  }
}
