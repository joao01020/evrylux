import 'package:flutter/material.dart';

import '../models/body_region_schedule.dart';

// ============================================================
// BODY WEEKDAY SELECTOR
// ============================================================
//
// Seletor visual de dias da semana.
//
// weekday:
//
// 1 = Seg
// 2 = Ter
// 3 = Qua
// 4 = Qui
// 5 = Sex
// 6 = Sáb
// 7 = Dom
//
// ============================================================

class BodyWeekdaySelector
    extends
        StatelessWidget {
  const BodyWeekdaySelector({
    super.key,
    required this.selectedWeekdays,
    required this.onToggle,
    this.compact = false,
  });

  final Set<
    int
  >
  selectedWeekdays;

  final ValueChanged<
    int
  >
  onToggle;

  final bool compact;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
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
    if (compact) {
      return Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (
            var weekday = DateTime.monday;
            weekday <=
                DateTime.sunday;
            weekday++
          )
            _buildCompactDay(
              weekday,
            ),
        ],
      );
    }

    return Column(
      children: [
        for (
          var weekday = DateTime.monday;
          weekday <=
              DateTime.sunday;
          weekday++
        )
          Padding(
            padding: EdgeInsets.only(
              bottom:
                  weekday ==
                      DateTime.sunday
                  ? 0
                  : 6,
            ),
            child: _buildDayRow(
              weekday,
            ),
          ),
      ],
    );
  }

  // ============================================================
  // DAY ROW
  // ============================================================

  Widget _buildDayRow(
    int weekday,
  ) {
    final selected = selectedWeekdays.contains(
      weekday,
    );

    return InkWell(
      onTap: () {
        onToggle(
          weekday,
        );
      },
      borderRadius: BorderRadius.circular(
        11,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 140,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            11,
          ),
          border: Border.all(
            color: selected
                ? _primaryDark
                : _border,
            width: selected
                ? 1.3
                : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(
                milliseconds: 140,
              ),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: selected
                    ? _primaryDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(
                  6,
                ),
                border: Border.all(
                  color: selected
                      ? _primaryDark
                      : _border,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(
              width: 9,
            ),
            Expanded(
              child: Text(
                BodyRegionSchedule.weekdayName(
                  weekday,
                ),
                style: TextStyle(
                  color: selected
                      ? _text
                      : _muted,
                  fontSize: 11,
                  fontWeight: selected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
            ),
            Text(
              _shortName(
                weekday,
              ),
              style: TextStyle(
                color: selected
                    ? _primaryDark
                    : _muted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPACT
  // ============================================================

  Widget _buildCompactDay(
    int weekday,
  ) {
    final selected = selectedWeekdays.contains(
      weekday,
    );

    return InkWell(
      onTap: () {
        onToggle(
          weekday,
        );
      },
      borderRadius: BorderRadius.circular(
        999,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 140,
        ),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : _surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? _primaryDark
                : _border,
          ),
        ),
        child: Text(
          _shortName(
            weekday,
          ),
          style: TextStyle(
            color: selected
                ? _primaryDark
                : _muted,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHORT NAME
  // ============================================================

  String _shortName(
    int weekday,
  ) {
    switch (weekday) {
      case DateTime.monday:
        return 'SEG';

      case DateTime.tuesday:
        return 'TER';

      case DateTime.wednesday:
        return 'QUA';

      case DateTime.thursday:
        return 'QUI';

      case DateTime.friday:
        return 'SEX';

      case DateTime.saturday:
        return 'SÁB';

      case DateTime.sunday:
        return 'DOM';

      default:
        return '';
    }
  }
}
