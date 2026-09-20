import 'package:flutter/material.dart';

import '../../models/routine_day.dart';

import 'reminder_day_status.dart';
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
    required this.reminderStatusForDate,
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
  // STATUS DOS LEMBRETES
  // ============================================================
  //
  // Recebe do RoutineCalendarPanel uma função que informa
  // o estado completo dos lembretes de determinada data.
  //
  // Estados possíveis:
  //
  // none
  //   -> nenhum lembrete
  //
  // active
  //   -> existe pelo menos um lembrete futuro
  //
  // expired
  //   -> existem apenas lembretes expirados
  //
  // mixed
  //   -> existem lembretes ativos e expirados no mesmo dia
  //
  // O WeekCalendar apenas consulta o status e o repassa
  // diretamente para o WeekDayCard.
  //
  // ============================================================

  final ReminderDayStatus Function(
    DateTime date,
  )
  reminderStatusForDate;

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
              _,
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
              // ==================================================
              // DATA DO CARD
              // ==================================================

              final date = _dateOnly(
                weekStart.add(
                  Duration(
                    days: index,
                  ),
                ),
              );

              // ==================================================
              // DADOS DA ROTINA
              // ==================================================

              final routineDay = _findDay(
                date,
              );

              // ==================================================
              // STATUS DO LEMBRETE
              // ==================================================

              final reminderStatus = reminderStatusForDate(
                date,
              );

              // ==================================================
              // CARD
              // ==================================================

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
                // STATUS COMPLETO DO LEMBRETE
                // ==================================================
                reminderStatus: reminderStatus,

                // ==================================================
                // SELEÇÃO
                // ==================================================
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
