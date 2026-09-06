import 'package:flutter/material.dart';

import '../../controllers/routine_state.dart';
import 'reminder_day_status.dart';

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
    required this.reminderStatusForDate,
  });

  final RoutineState state;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final ValueChanged<
    DateTime
  >
  onSelectDay;
  final VoidCallback onToggleExpanded;
  final ReminderDayStatus Function(
    DateTime date,
  )
  reminderStatusForDate;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );
  static const Color _surfaceSoft = Color(
    0xFFF7FAF7,
  );
  static const Color _border = Color(
    0xFFD7E3D9,
  );
  static const Color _primary = Color(
    0xFF198754,
  );
  static const Color _primarySoft = Color(
    0xFFBFE8B8,
  );
  static const Color _primarySoftest = Color(
    0xFFEAF7E7,
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
    final weekStart = _resolveWeekStart();
    final selectedDate = _resolveSelectedDate(
      weekStart,
    );
    final weekDates =
        List<
          DateTime
        >.generate(
          7,
          (
            index,
          ) => DateUtils.dateOnly(
            weekStart.add(
              Duration(
                days: index,
              ),
            ),
          ),
        );

    final titleDate = weekDates[3];
    final title = _formatMonthYear(
      titleDate,
    );
    final rangeText = _formatWeekRange(
      weekDates.first,
      weekDates.last,
    );
    final isExpanded = _resolveCalendarExpanded();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            10,
          ),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(
              color: _border,
            ),
            borderRadius: BorderRadius.circular(
              22,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x09000000,
                ),
                blurRadius: 14,
                offset: Offset(
                  0,
                  5,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              // ========================================================
              // HEADER CENTRALIZADO
              // ========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CalendarNavButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Semana anterior',
                    onTap: onPreviousWeek,
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 170,
                    ),
                    child: Column(
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          rangeText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 14,
                  ),
                  _CalendarNavButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Próxima semana',
                    onTap: onNextWeek,
                  ),
                ],
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
                      final compact =
                          constraints.maxWidth <
                          760;

                      if (compact) {
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.center,
                          children: weekDates.map(
                            (
                              date,
                            ) {
                              return SizedBox(
                                width: 92,
                                child: _WeekDayCard(
                                  date: date,
                                  selected: _isSameDate(
                                    date,
                                    selectedDate,
                                  ),
                                  reminderStatus: reminderStatusForDate(
                                    date,
                                  ),
                                  onTap: () => onSelectDay(
                                    date,
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        );
                      }

                      return Row(
                        children: [
                          for (
                            var i = 0;
                            i <
                                weekDates.length;
                            i++
                          ) ...[
                            Expanded(
                              child: _WeekDayCard(
                                date: weekDates[i],
                                selected: _isSameDate(
                                  weekDates[i],
                                  selectedDate,
                                ),
                                reminderStatus: reminderStatusForDate(
                                  weekDates[i],
                                ),
                                onTap: () => onSelectDay(
                                  weekDates[i],
                                ),
                              ),
                            ),
                            if (i !=
                                weekDates.length -
                                    1)
                              const SizedBox(
                                width: 10,
                              ),
                          ],
                        ],
                      );
                    },
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(
                999,
              ),
              child: Ink(
                width: 48,
                height: 28,
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(
                    999,
                  ),
                  border: Border.all(
                    color: const Color(
                      0xFF9AD394,
                    ),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(
                        0x10000000,
                      ),
                      blurRadius: 6,
                      offset: Offset(
                        0,
                        2,
                      ),
                    ),
                  ],
                ),
                child: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: _primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DateTime _resolveWeekStart() {
    try {
      final dynamic rawState = state;
      final value = rawState.weekStart;

      if (value
          is DateTime) {
        return DateUtils.dateOnly(
          value,
        );
      }
    } catch (
      _
    ) {}

    return DateUtils.dateOnly(
      DateTime.now(),
    );
  }

  DateTime _resolveSelectedDate(
    DateTime fallback,
  ) {
    try {
      final dynamic rawState = state;
      final value = rawState.selectedDay;

      if (value
          is DateTime) {
        return DateUtils.dateOnly(
          value,
        );
      }

      if (value !=
          null) {
        final dynamic dateValue = value.date;

        if (dateValue
            is DateTime) {
          return DateUtils.dateOnly(
            dateValue,
          );
        }
      }
    } catch (
      _
    ) {}

    return fallback;
  }

  bool _resolveCalendarExpanded() {
    try {
      final dynamic rawState = state;
      final value = rawState.isCalendarExpanded;

      if (value
          is bool) {
        return value;
      }
    } catch (
      _
    ) {}

    try {
      final dynamic rawState = state;
      final value = rawState.calendarExpanded;

      if (value
          is bool) {
        return value;
      }
    } catch (
      _
    ) {}

    return true;
  }

  bool _isSameDate(
    DateTime a,
    DateTime b,
  ) {
    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day;
  }

  String _formatMonthYear(
    DateTime date,
  ) {
    const months =
        <
          String
        >[
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro',
        ];

    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatWeekRange(
    DateTime start,
    DateTime end,
  ) {
    const shortMonths =
        <
          String
        >[
          'jan',
          'fev',
          'mar',
          'abr',
          'mai',
          'jun',
          'jul',
          'ago',
          'set',
          'out',
          'nov',
          'dez',
        ];

    final startText = '${start.day} ${shortMonths[start.month - 1]}';
    final endText = '${end.day} ${shortMonths[end.month - 1]}';

    return '$startText - $endText';
  }
}

class _CalendarNavButton
    extends
        StatelessWidget {
  const _CalendarNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            14,
          ),
          child: Ink(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: RoutineCalendarPanel._surfaceSoft,
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: RoutineCalendarPanel._border,
              ),
            ),
            child: Icon(
              icon,
              color: RoutineCalendarPanel._text,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekDayCard
    extends
        StatelessWidget {
  const _WeekDayCard({
    required this.date,
    required this.selected,
    required this.reminderStatus,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final ReminderDayStatus reminderStatus;
  final VoidCallback onTap;

  static const Color _surface = RoutineCalendarPanel._surface;
  static const Color _border = RoutineCalendarPanel._border;
  static const Color _primary = RoutineCalendarPanel._primary;
  static const Color _primarySoft = RoutineCalendarPanel._primarySoft;
  static const Color _text = RoutineCalendarPanel._text;
  static const Color _muted = RoutineCalendarPanel._muted;

  @override
  Widget build(
    BuildContext context,
  ) {
    final dayName = _weekdayLabel(
      date.weekday,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          18,
        ),
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _primarySoft
                : _surface,
            borderRadius: BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: selected
                  ? const Color(
                      0xFF9ED49A,
                    )
                  : _border,
              width: selected
                  ? 1.3
                  : 1,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(
                        0x14000000,
                      ),
                      blurRadius: 10,
                      offset: Offset(
                        0,
                        4,
                      ),
                    ),
                  ]
                : const [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dayName,
                style: TextStyle(
                  color: selected
                      ? const Color(
                          0xFF3E6F3F,
                        )
                      : _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(
                height: 8,
              ),
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected
                      ? const Color(
                          0xFF2E6A36,
                        )
                      : _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              _ReminderIndicator(
                status: reminderStatus,
                selected: selected,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _weekdayLabel(
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

class _ReminderIndicator
    extends
        StatelessWidget {
  const _ReminderIndicator({
    required this.status,
    required this.selected,
  });

  final ReminderDayStatus status;
  final bool selected;

  @override
  Widget build(
    BuildContext context,
  ) {
    if (status ==
        ReminderDayStatus.none) {
      return Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(
            0xFFC6D4C8,
          ),
          borderRadius: BorderRadius.circular(
            999,
          ),
        ),
      );
    }

    if (status ==
        ReminderDayStatus.mixed) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _dot(
            const Color(
              0xFF31A45C,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          _dot(
            const Color(
              0xFFC97E3B,
            ),
          ),
        ],
      );
    }

    return _dot(
      status ==
              ReminderDayStatus.active
          ? (selected
                ? const Color(
                    0xFF2F7A3D,
                  )
                : const Color(
                    0xFF31A45C,
                  ))
          : const Color(
              0xFFC97E3B,
            ),
      elongated: selected,
    );
  }

  Widget _dot(
    Color color, {
    bool elongated = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 180,
      ),
      width: elongated
          ? 28
          : 8,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(
          999,
        ),
      ),
    );
  }
}
