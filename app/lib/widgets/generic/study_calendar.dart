import 'package:flutter/material.dart';

class StudyCalendar
    extends
        StatefulWidget {
  const StudyCalendar({
    super.key,
    required this.selectedDate,
    required this.completedDates,
    required this.onDateSelected,
  });

  final DateTime selectedDate;

  final List<
    DateTime
  >
  completedDates;

  final ValueChanged<
    DateTime
  >
  onDateSelected;

  @override
  State<
    StudyCalendar
  >
  createState() {
    return _StudyCalendarState();
  }
}

class _StudyCalendarState
    extends
        State<
          StudyCalendar
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFF090A0E,
  );

  static const Color _surface = Color(
    0xFF111319,
  );

  static const Color _surfaceHover = Color(
    0xFF171A22,
  );

  static const Color _border = Color(
    0xFF292D38,
  );

  static const Color _primary = Color(
    0xFF7C5CFF,
  );

  static const Color _primarySoft = Color(
    0xFF9B87FF,
  );

  static const Color _textPrimary = Color(
    0xFFF5F7FA,
  );

  static const Color _textSecondary = Color(
    0xFF8D93A1,
  );

  static const Color _textMuted = Color(
    0xFF5F6572,
  );

  static const Color _success = Color(
    0xFF7BE495,
  );

  // ============================================================
  // DAYS
  // ============================================================

  static const List<
    String
  >
  _weekNames = [
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
    'DOM',
  ];

  static const List<
    String
  >
  _months = [
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

  // ============================================================
  // STATE
  // ============================================================

  late DateTime _weekStart;

  bool _expanded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _weekStart = _startOfWeek(
      widget.selectedDate,
    );
  }

  // ============================================================
  // DID UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant StudyCalendar oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (!_sameDate(
      oldWidget.selectedDate,
      widget.selectedDate,
    )) {
      final selectedWeek = _startOfWeek(
        widget.selectedDate,
      );

      if (!_sameDate(
        selectedWeek,
        _weekStart,
      )) {
        _weekStart = selectedWeek;
      }
    }
  }

  // ============================================================
  // WEEK
  // ============================================================

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return normalized.subtract(
      Duration(
        days:
            normalized.weekday -
            DateTime.monday,
      ),
    );
  }

  DateTime get _weekEnd {
    return _weekStart.add(
      const Duration(
        days: 6,
      ),
    );
  }

  // ============================================================
  // PREVIOUS WEEK
  // ============================================================

  void _previousWeek() {
    setState(
      () {
        _weekStart = _weekStart.subtract(
          const Duration(
            days: 7,
          ),
        );
      },
    );
  }

  // ============================================================
  // NEXT WEEK
  // ============================================================

  void _nextWeek() {
    setState(
      () {
        _weekStart = _weekStart.add(
          const Duration(
            days: 7,
          ),
        );
      },
    );
  }

  // ============================================================
  // EXPAND
  // ============================================================

  void _toggleExpanded() {
    setState(
      () {
        _expanded = !_expanded;
      },
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get _monthTitle {
    final middle = _weekStart.add(
      const Duration(
        days: 3,
      ),
    );

    return '${_months[middle.month - 1]} ${middle.year}';
  }

  // ============================================================
  // RANGE
  // ============================================================

  String get _weekRange {
    final start = _weekStart;

    final end = _weekEnd;

    if (start.month ==
        end.month) {
      return '${start.day} - ${end.day} '
          '${_months[start.month - 1].toLowerCase()}';
    }

    return '${start.day} '
        '${_shortMonth(start.month)} - '
        '${end.day} '
        '${_shortMonth(end.month)}';
  }

  String _shortMonth(
    int month,
  ) {
    final value =
        _months[month -
            1];

    return value
        .substring(
          0,
          3,
        )
        .toLowerCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: _background,

        border: Border.all(
          color: _border,
        ),

        borderRadius: BorderRadius.circular(
          18,
        ),
      ),

      child: Column(
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              0,
              14,
              0,
              10,
            ),

            child: _buildHeader(),
          ),

          // ====================================================
          // WEEK
          // ====================================================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),

            child: _buildWeek(),
          ),

          // ====================================================
          // EXPANDED MONTH
          // ====================================================
          AnimatedCrossFade(
            duration: const Duration(
              milliseconds: 220,
            ),

            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,

            firstChild: const SizedBox.shrink(),

            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                18,
                12,
                8,
              ),

              child: _buildMonth(),
            ),
          ),

          // ====================================================
          // BOTTOM DIVIDER
          // ====================================================
          const SizedBox(
            height: 14,
          ),

          _buildBottomToggle(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: [
        // ======================================================
        // PREVIOUS
        // ======================================================
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
          ),

          child: _navigationButton(
            icon: Icons.chevron_left_rounded,

            tooltip: 'Semana anterior',

            onPressed: _previousWeek,
          ),
        ),

        // ======================================================
        // TITLE
        // ======================================================
        Expanded(
          child: Column(
            children: [
              Text(
                _monthTitle,

                style: const TextStyle(
                  color: _textPrimary,

                  fontSize: 16,

                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                _weekRange,

                style: const TextStyle(
                  color: _textSecondary,

                  fontSize: 10,

                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // NEXT
        // ======================================================
        Padding(
          padding: const EdgeInsets.only(
            right: 2,
          ),

          child: _navigationButton(
            icon: Icons.chevron_right_rounded,

            tooltip: 'Próxima semana',

            onPressed: _nextWeek,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NAVIGATION BUTTON
  // ============================================================

  Widget _navigationButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,

      child: InkWell(
        borderRadius: BorderRadius.circular(
          12,
        ),

        onTap: onPressed,

        child: Container(
          width: 40,

          height: 40,

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              12,
            ),

            border: Border.all(
              color: _border,
            ),
          ),

          child: Icon(
            icon,

            color: _textPrimary,

            size: 22,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WEEK
  // ============================================================

  Widget _buildWeek() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: List.generate(
        7,
        (
          index,
        ) {
          final date = _weekStart.add(
            Duration(
              days: index,
            ),
          );

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),

              child: _buildDayCard(
                date: date,

                weekDay: _weekNames[index],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DAY CARD
  // ============================================================

  Widget _buildDayCard({
    required DateTime date,
    required String weekDay,
  }) {
    final selected = _sameDate(
      date,
      widget.selectedDate,
    );

    final completed = _isCompleted(
      date,
    );

    final today = _sameDate(
      date,
      DateTime.now(),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(
        16,
      ),

      onTap: () {
        widget.onDateSelected(
          DateTime(
            date.year,
            date.month,
            date.day,
          ),
        );
      },

      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),

        curve: Curves.easeOut,

        height: 92,

        decoration: BoxDecoration(
          color: selected
              ? _primary
              : _surface,

          borderRadius: BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: selected
                ? _primarySoft
                : today
                ? _primary.withValues(
                    alpha: 0.45,
                  )
                : _border,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(
                      alpha: 0.18,
                    ),

                    blurRadius: 14,
                  ),
                ]
              : null,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ==================================================
            // WEEKDAY
            // ==================================================
            Text(
              weekDay,

              style: TextStyle(
                color: selected
                    ? Colors.white.withValues(
                        alpha: 0.78,
                      )
                    : _textSecondary,

                fontSize: 10,

                fontWeight: FontWeight.w800,

                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            // ==================================================
            // NUMBER
            // ==================================================
            Text(
              '${date.day}',

              style: TextStyle(
                color: selected
                    ? Colors.white
                    : _textPrimary,

                fontSize: 20,

                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            // ==================================================
            // STATUS DOT
            // ==================================================
            Container(
              width: completed
                  ? 6
                  : 4,

              height: completed
                  ? 6
                  : 4,

              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: completed
                    ? selected
                          ? Colors.white
                          : _success
                    : selected
                    ? Colors.white.withValues(
                        alpha: 0.40,
                      )
                    : _textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MONTH
  // ============================================================

  Widget _buildMonth() {
    final centerDate = _weekStart.add(
      const Duration(
        days: 3,
      ),
    );

    final firstDay = DateTime(
      centerDate.year,
      centerDate.month,
      1,
    );

    final start = firstDay.subtract(
      Duration(
        days:
            firstDay.weekday -
            DateTime.monday,
      ),
    );

    final dates = List.generate(
      42,
      (
        index,
      ) => start.add(
        Duration(
          days: index,
        ),
      ),
    );

    return Column(
      children: [
        // ======================================================
        // WEEK NAMES
        // ======================================================
        Row(
          children: _weekNames.map(
            (
              day,
            ) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,

                    style: const TextStyle(
                      color: _textMuted,

                      fontSize: 9,

                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),

        const SizedBox(
          height: 8,
        ),

        // ======================================================
        // MONTH GRID
        // ======================================================
        GridView.builder(
          shrinkWrap: true,

          physics: const NeverScrollableScrollPhysics(),

          itemCount: dates.length,

          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,

            crossAxisSpacing: 5,

            mainAxisSpacing: 5,

            childAspectRatio: 1.35,
          ),

          itemBuilder:
              (
                context,
                index,
              ) {
                final date = dates[index];

                final selected = _sameDate(
                  date,
                  widget.selectedDate,
                );

                final completed = _isCompleted(
                  date,
                );

                final currentMonth =
                    date.month ==
                        centerDate.month &&
                    date.year ==
                        centerDate.year;

                return InkWell(
                  borderRadius: BorderRadius.circular(
                    10,
                  ),

                  onTap: () {
                    widget.onDateSelected(
                      DateTime(
                        date.year,
                        date.month,
                        date.day,
                      ),
                    );

                    setState(
                      () {
                        _weekStart = _startOfWeek(
                          date,
                        );
                      },
                    );
                  },

                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? _primary
                          : Colors.transparent,

                      borderRadius: BorderRadius.circular(
                        10,
                      ),

                      border: Border.all(
                        color: selected
                            ? _primarySoft
                            : Colors.transparent,
                      ),
                    ),

                    child: Stack(
                      alignment: Alignment.center,

                      children: [
                        Text(
                          '${date.day}',

                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : currentMonth
                                ? _textPrimary
                                : _textMuted,

                            fontSize: 11,

                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                        ),

                        if (completed)
                          Positioned(
                            bottom: 4,

                            child: Container(
                              width: 4,

                              height: 4,

                              decoration: BoxDecoration(
                                shape: BoxShape.circle,

                                color: selected
                                    ? Colors.white
                                    : _success,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }

  // ============================================================
  // BOTTOM TOGGLE
  // ============================================================

  Widget _buildBottomToggle() {
    return SizedBox(
      height: 24,

      child: Stack(
        alignment: Alignment.center,

        children: [
          const Divider(
            height: 1,

            thickness: 1,

            color: _border,
          ),

          InkWell(
            borderRadius: BorderRadius.circular(
              14,
            ),

            onTap: _toggleExpanded,

            child: Container(
              width: 46,

              height: 24,

              decoration: BoxDecoration(
                color: _surface,

                borderRadius: BorderRadius.circular(
                  14,
                ),

                border: Border.all(
                  color: _border,
                ),
              ),

              child: AnimatedRotation(
                duration: const Duration(
                  milliseconds: 180,
                ),

                turns: _expanded
                    ? 0.5
                    : 0,

                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,

                  size: 17,

                  color: _textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  bool _isCompleted(
    DateTime date,
  ) {
    for (final completed in widget.completedDates) {
      if (_sameDate(
        completed,
        date,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // SAME DATE
  // ============================================================

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }
}
