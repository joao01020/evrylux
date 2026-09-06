import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class EvolutionCalendar
    extends
        StatefulWidget {
  const EvolutionCalendar({
    super.key,
    required this.history,
    required this.selectedDate,
    required this.onDateSelected,
    required this.onCreateNote,
  });

  final Map<
    String,
    List<
      String
    >
  >
  history;

  final DateTime selectedDate;

  final Function(
    DateTime,
  )
  onDateSelected;

  final Function(
    DateTime,
  )
  onCreateNote;

  @override
  State<
    EvolutionCalendar
  >
  createState() {
    return _EvolutionCalendarState();
  }
}

class _EvolutionCalendarState
    extends
        State<
          EvolutionCalendar
        > {
  // ============================================================
  // COLORS
  // ============================================================

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

  static const Color _completed = Color(
    0xFF4C9B63,
  );

  // ============================================================
  // CURRENT MONTH
  // ============================================================

  late DateTime currentDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    currentDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  // ============================================================
  // UPDATE FROM PARENT
  // ============================================================

  @override
  void didUpdateWidget(
    covariant EvolutionCalendar oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final monthChanged =
        oldWidget.selectedDate.year !=
            widget.selectedDate.year ||
        oldWidget.selectedDate.month !=
            widget.selectedDate.month;

    if (!monthChanged) {
      return;
    }

    currentDate = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  // ============================================================
  // DATE KEY
  // ============================================================

  String dateKey(
    DateTime date,
  ) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // PREVIOUS MONTH
  // ============================================================

  void _previousMonth() {
    setState(
      () {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month -
              1,
        );
      },
    );
  }

  // ============================================================
  // NEXT MONTH
  // ============================================================

  void _nextMonth() {
    setState(
      () {
        currentDate = DateTime(
          currentDate.year,
          currentDate.month +
              1,
        );
      },
    );
  }

  // ============================================================
  // OPEN MENU
  // ============================================================

  void openMenu(
    BuildContext context,
    Offset position,
    int day,
  ) {
    showMenu<
          String
        >(
          context: context,
          position: RelativeRect.fromLTRB(
            position.dx,
            position.dy,
            position.dx +
                10,
            position.dy +
                10,
          ),
          items: const [
            PopupMenuItem<
              String
            >(
              value: 'note',
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note_rounded,
                    size: 20,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    'Criar anotação',
                  ),
                ],
              ),
            ),
          ],
        )
        .then(
          (
            value,
          ) {
            if (value !=
                'note') {
              return;
            }

            final date = DateTime(
              currentDate.year,
              currentDate.month,
              day,
            );

            widget.onCreateNote(
              date,
            );
          },
        );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final daysInMonth = DateTime(
      currentDate.year,
      currentDate.month +
          1,
      0,
    ).day;

    final monthTitle = _formatMonthYear(
      currentDate,
    );

    return Card(
      elevation: 0,
      color: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: const BorderSide(
          color: _border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          children: [
            // ======================================================
            // HEADER CENTRALIZADO
            // ======================================================
            //
            // As setas ficam próximas do título do mês.
            //
            // Isso evita o mesmo problema visual da tela de Rotina:
            // navegação temporal nas extremidades pode parecer
            // navegação de página/tela.
            //
            // ======================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CalendarNavigationButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Mês anterior',
                  onTap: _previousMonth,
                ),

                const SizedBox(
                  width: 14,
                ),

                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 150,
                  ),
                  child: Text(
                    monthTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                _CalendarNavigationButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Próximo mês',
                  onTap: _nextMonth,
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            // ======================================================
            // WEEK LABELS
            // ======================================================
            const Row(
              children: [
                _WeekLabel(
                  label: 'SEG',
                ),
                _WeekLabel(
                  label: 'TER',
                ),
                _WeekLabel(
                  label: 'QUA',
                ),
                _WeekLabel(
                  label: 'QUI',
                ),
                _WeekLabel(
                  label: 'SEX',
                ),
                _WeekLabel(
                  label: 'SÁB',
                ),
                _WeekLabel(
                  label: 'DOM',
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // ======================================================
            // CALENDAR GRID
            // ======================================================
            _buildCalendarGrid(
              daysInMonth,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CALENDAR GRID
  // ============================================================

  Widget _buildCalendarGrid(
    int daysInMonth,
  ) {
    final firstDay = DateTime(
      currentDate.year,
      currentDate.month,
      1,
    );

    final leadingEmptyDays =
        firstDay.weekday -
        DateTime.monday;

    final totalItems =
        leadingEmptyDays +
        daysInMonth;

    final rows =
        (totalItems /
                7)
            .ceil();

    final normalizedItemCount =
        rows *
        7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: normalizedItemCount,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.05,
      ),
      itemBuilder:
          (
            context,
            index,
          ) {
            if (index <
                leadingEmptyDays) {
              return const SizedBox.shrink();
            }

            final day =
                index -
                leadingEmptyDays +
                1;

            if (day >
                daysInMonth) {
              return const SizedBox.shrink();
            }

            final date = DateTime(
              currentDate.year,
              currentDate.month,
              day,
            );

            final key = dateKey(
              date,
            );

            final completed = widget.history.containsKey(
              key,
            );

            final selected =
                widget.selectedDate.day ==
                    day &&
                widget.selectedDate.month ==
                    currentDate.month &&
                widget.selectedDate.year ==
                    currentDate.year;

            return _EvolutionDayCell(
              day: day,
              selected: selected,
              completed: completed,
              onTap: () {
                widget.onDateSelected(
                  date,
                );
              },
              onSecondaryTap:
                  (
                    position,
                  ) {
                    openMenu(
                      context,
                      position,
                      day,
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // MONTH LABEL
  // ============================================================

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
}

// ============================================================
// CALENDAR NAVIGATION BUTTON
// ============================================================

class _CalendarNavigationButton
    extends
        StatefulWidget {
  const _CalendarNavigationButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;

  final String tooltip;

  final VoidCallback onTap;

  @override
  State<
    _CalendarNavigationButton
  >
  createState() {
    return _CalendarNavigationButtonState();
  }
}

class _CalendarNavigationButtonState
    extends
        State<
          _CalendarNavigationButton
        > {
  bool _hovered = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(
        milliseconds: 450,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (
              _,
            ) {
              setState(
                () {
                  _hovered = true;
                },
              );
            },
        onExit:
            (
              _,
            ) {
              setState(
                () {
                  _hovered = false;
                },
              );
            },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 160,
            ),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered
                  ? _EvolutionCalendarState._primarySoftest
                  : _EvolutionCalendarState._surfaceSoft,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _hovered
                    ? _EvolutionCalendarState._primary.withValues(
                        alpha: 0.28,
                      )
                    : _EvolutionCalendarState._border,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hovered
                  ? _EvolutionCalendarState._primary
                  : _EvolutionCalendarState._text,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// WEEK LABEL
// ============================================================

class _WeekLabel
    extends
        StatelessWidget {
  const _WeekLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _EvolutionCalendarState._muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

// ============================================================
// EVOLUTION DAY CELL
// ============================================================

class _EvolutionDayCell
    extends
        StatefulWidget {
  const _EvolutionDayCell({
    required this.day,
    required this.selected,
    required this.completed,
    required this.onTap,
    required this.onSecondaryTap,
  });

  final int day;

  final bool selected;

  final bool completed;

  final VoidCallback onTap;

  final ValueChanged<
    Offset
  >
  onSecondaryTap;

  @override
  State<
    _EvolutionDayCell
  >
  createState() {
    return _EvolutionDayCellState();
  }
}

class _EvolutionDayCellState
    extends
        State<
          _EvolutionDayCell
        > {
  bool _hovered = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    final selected = widget.selected;

    final completed = widget.completed;

    final background = selected
        ? _EvolutionCalendarState._primarySoft
        : completed
        ? _EvolutionCalendarState._primarySoftest
        : _hovered
        ? _EvolutionCalendarState._surfaceSoft
        : _EvolutionCalendarState._surface;

    final border = selected
        ? _EvolutionCalendarState._primary.withValues(
            alpha: 0.55,
          )
        : completed
        ? _EvolutionCalendarState._completed.withValues(
            alpha: 0.34,
          )
        : _hovered
        ? _EvolutionCalendarState._primary.withValues(
            alpha: 0.20,
          )
        : _EvolutionCalendarState._border;

    final textColor = selected
        ? const Color(
            0xFF2E6A36,
          )
        : completed
        ? const Color(
            0xFF346E42,
          )
        : _EvolutionCalendarState._text;

    return Listener(
      onPointerDown:
          (
            event,
          ) {
            if (event.kind ==
                    PointerDeviceKind.mouse &&
                event.buttons ==
                    kSecondaryMouseButton) {
              widget.onSecondaryTap(
                event.position,
              );
            }
          },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter:
            (
              _,
            ) {
              setState(
                () {
                  _hovered = true;
                },
              );
            },
        onExit:
            (
              _,
            ) {
              setState(
                () {
                  _hovered = false;
                },
              );
            },
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 170,
            ),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: border,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(
                          0x10000000,
                        ),
                        blurRadius: 8,
                        offset: Offset(
                          0,
                          3,
                        ),
                      ),
                    ]
                  : const [],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.day}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (completed) ...[
                    const SizedBox(
                      height: 4,
                    ),
                    Container(
                      width: selected
                          ? 18
                          : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? _EvolutionCalendarState._primary
                            : _EvolutionCalendarState._completed,
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
