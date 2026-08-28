import 'package:flutter/material.dart';

import '../../models/routine_day.dart';
import 'week_day_card.dart';

class WeekCalendar
    extends
        StatelessWidget {
  const WeekCalendar({
    super.key,
    required this.weekStart,
    required this.selectedDate,
    required this.days,
    required this.onSelected,
  });

  final DateTime weekStart;
  final DateTime selectedDate;
  final List<
    RoutineDay
  >
  days;
  final ValueChanged<
    DateTime
  >
  onSelected;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      height: 106,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder:
            (
              _,
              __,
            ) => const SizedBox(
              width: 8,
            ),
        itemBuilder:
            (
              _,
              index,
            ) {
              final date = _dateOnly(
                weekStart.add(
                  Duration(
                    days: index,
                  ),
                ),
              );
              final routineDay = _findDay(
                date,
              );

              return WeekDayCard(
                day: date,
                selected:
                    date ==
                    _dateOnly(
                      selectedDate,
                    ),
                today:
                    date ==
                    _dateOnly(
                      DateTime.now(),
                    ),
                progress:
                    routineDay?.progress ??
                    0,
                hasContent:
                    routineDay?.hasBlocks ??
                    false,
                onTap: () => onSelected(
                  date,
                ),
              );
            },
      ),
    );
  }

  RoutineDay? _findDay(
    DateTime date,
  ) {
    for (final day in days) {
      if (day.normalizedDate ==
          date) {
        return day;
      }
    }
    return null;
  }

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }
}
