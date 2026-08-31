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
    required this.hasReminderForDate,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final DateTime weekStart;

  final DateTime selectedDate;

  final List<
    RoutineDay
  >
  days;

  // ============================================================
  // AÇÕES
  // ============================================================

  final ValueChanged<
    DateTime
  >
  onSelected;

  // ============================================================
  // LEMBRETES
  // ============================================================
  //
  // Recebe do RoutineCalendarPanel uma função que informa se
  // determinada data possui pelo menos um lembrete programado.
  //
  // O WeekCalendar apenas consulta essa informação e repassa
  // para o WeekDayCard.
  //
  // ============================================================

  final bool Function(
    DateTime date,
  )
  hasReminderForDate;

  // ============================================================
  // BUILD
  // ============================================================

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
            ) {
              return const SizedBox(
                width: 8,
              );
            },
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

              final hasReminder = hasReminderForDate(
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

                // ==================================================
                // INDICADOR DE LEMBRETE
                // ==================================================
                hasReminder: hasReminder,

                onTap: () {
                  onSelected(
                    date,
                  );
                },
              );
            },
      ),
    );
  }

  // ============================================================
  // BUSCAR DIA
  // ============================================================

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

  // ============================================================
  // NORMALIZAR DATA
  // ============================================================

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
