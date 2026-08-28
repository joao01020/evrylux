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
  });

  final RoutineState state;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<
    DateTime
  >
  onSelectDay;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFF272B36,
            ),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          WeekNavigation(
            weekStart: state.weekStart,
            onPrevious: onPreviousWeek,
            onNext: onNextWeek,
          ),
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
                  )
                : const SizedBox(
                    width: double.infinity,
                  ),
          ),
          Transform.translate(
            offset: const Offset(
              0,
              11,
            ),
            child: Tooltip(
              message: state.calendarExpanded
                  ? 'Recolher calendário'
                  : 'Expandir calendário',
              child: InkWell(
                onTap: onToggleExpanded,
                borderRadius: BorderRadius.circular(
                  20,
                ),
                child: Container(
                  width: 46,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF171A22,
                    ),
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    border: Border.all(
                      color: const Color(
                        0xFF272B36,
                      ),
                    ),
                  ),
                  child: AnimatedRotation(
                    turns: state.calendarExpanded
                        ? 0
                        : .5,
                    duration: const Duration(
                      milliseconds: 220,
                    ),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Color(
                        0xFF9298A6,
                      ),
                      size: 18,
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
