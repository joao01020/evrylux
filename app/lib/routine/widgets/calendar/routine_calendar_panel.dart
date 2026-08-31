import 'package:flutter/material.dart';

import '../../controllers/routine_state.dart';
import 'week_calendar.dart';
import 'week_navigation.dart';

class RoutineCalendarPanel
    extends
        StatelessWidget {
  const RoutineCalendarPanel({
    super.key,
    required this.state,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onSelectDay,
    required this.onToggleExpanded,
    required this.hasReminderForDate,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF347A3D,
  );

  static const Color _greenLight = Color(
    0xFFC9F2C5,
  );

  static const Color _greenBorder = Color(
    0xFFA9DEA5,
  );

  static const Color _panelBackground = Color(
    0xFFF8FCF6,
  );

  static const Color _border = Color(
    0xFFDCE8DA,
  );

  // ============================================================
  // STATE
  // ============================================================

  final RoutineState state;

  // ============================================================
  // LEMBRETES
  // ============================================================
  //
  // O painel não precisa conhecer repository nem Supabase.
  //
  // Ele recebe apenas uma função que responde:
  //
  // "Esta data possui pelo menos um lembrete?"
  //
  // O WeekCalendar usa essa função para decidir se mostra
  // o sino no card daquele dia.
  //
  // ============================================================

  final bool Function(
    DateTime date,
  )
  hasReminderForDate;

  // ============================================================
  // ACTIONS
  // ============================================================

  final VoidCallback onPreviousWeek;

  final VoidCallback onNextWeek;

  final ValueChanged<
    DateTime
  >
  onSelectDay;

  final VoidCallback onToggleExpanded;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: _panelBackground,
        border: Border(
          bottom: BorderSide(
            color: _border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // NAVEGAÇÃO DA SEMANA
          // ====================================================
          WeekNavigation(
            weekStart: state.weekStart,
            onPrevious: onPreviousWeek,
            onNext: onNextWeek,
          ),

          // ====================================================
          // CALENDÁRIO
          // ====================================================
          AnimatedSize(
            duration: const Duration(
              milliseconds: 280,
            ),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: state.calendarExpanded
                ? WeekCalendar(
                    weekStart: state.weekStart,
                    selectedDate: state.selectedDate,
                    days: state.days,
                    onSelected: onSelectDay,
                    hasReminderForDate: hasReminderForDate,
                  )
                : const SizedBox(
                    width: double.infinity,
                  ),
          ),

          // ====================================================
          // BOTÃO EXPANDIR / RECOLHER
          // ====================================================
          Transform.translate(
            offset: const Offset(
              0,
              11,
            ),
            child: Tooltip(
              message: state.calendarExpanded
                  ? 'Recolher calendário'
                  : 'Expandir calendário',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleExpanded,
                  borderRadius: BorderRadius.circular(
                    20,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    width: 48,
                    height: 26,
                    decoration: BoxDecoration(
                      color: _greenLight,
                      borderRadius: BorderRadius.circular(
                        20,
                      ),
                      border: Border.all(
                        color: _greenBorder,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(
                            0x12000000,
                          ),
                          blurRadius: 6,
                          offset: Offset(
                            0,
                            2,
                          ),
                        ),
                      ],
                    ),
                    child: AnimatedRotation(
                      turns: state.calendarExpanded
                          ? 0
                          : .5,
                      duration: const Duration(
                        milliseconds: 220,
                      ),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: _green,
                        size: 19,
                      ),
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
