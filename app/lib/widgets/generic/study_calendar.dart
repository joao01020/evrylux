import 'package:flutter/material.dart';

class StudyCalendar
    extends
        StatefulWidget {
  const StudyCalendar({
    super.key,
    required this.selectedDate,
    required this.completedDates,
    this.contentDates =
        const <
          DateTime
        >[],
    required this.onDateSelected,
  });

  final DateTime selectedDate;

  final List<
    DateTime
  >
  completedDates;

  /// Datas que possuem conteúdo/anotações.
  ///
  /// Opcional para manter o calendário genérico e compatível
  /// com outras telas que já usam StudyCalendar.
  final List<
    DateTime
  >
  contentDates;

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
  // COLORS — TEMA CLARO
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7FAF7,
  );

  static const Color _border = Color(
    0xFFD7E3D9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primarySoft = Color(
    0xFF9FDF98,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _textPrimary = Color(
    0xFF172019,
  );

  static const Color _textSecondary = Color(
    0xFF68746B,
  );

  static const Color _textMuted = Color(
    0xFF9AA39C,
  );

  static const Color _success = Color(
    0xFF3B6939,
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
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      decoration: BoxDecoration(
        color: _background,
        border: Border.all(
          color: _border,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0D000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              2,
              9,
              2,
              7,
            ),
            child: _buildHeader(),
          ),

          // ====================================================
          // WEEK ONLY
          // ====================================================
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: _buildWeek(),
          ),
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
        _navigationButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Semana anterior',
          onPressed: _previousWeek,
        ),

        // ======================================================
        // TITLE
        // ======================================================
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                height: 1,
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
        _navigationButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próxima semana',
          onPressed: _nextWeek,
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
          11,
        ),
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(
              11,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Icon(
            icon,
            color: _textPrimary,
            size: 21,
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

    final hasContent = _hasContent(
      date,
    );

    final today = _sameDate(
      date,
      DateTime.now(),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(
        14,
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
        height: 74,
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : _surface,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? _primarySoft
                : today
                ? _primary.withValues(
                    alpha: 0.55,
                  )
                : _border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _primary.withValues(
                      alpha: 0.18,
                    ),
                    blurRadius: 12,
                    offset: const Offset(
                      0,
                      4,
                    ),
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
                    ? _primaryDark
                    : _textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.45,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // NUMBER
            // ==================================================
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected
                    ? _primaryDark
                    : _textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // STATUS
            // ==================================================
            //
            // ● = estudo concluído
            // ■ = conteúdo/anotação
            //
            // ==================================================
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==============================================
                // STUDY STATUS
                // ==============================================
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
                              ? _primaryDark
                              : _success
                        : selected
                        ? _primaryDark.withValues(
                            alpha: 0.35,
                          )
                        : _textMuted.withValues(
                            alpha: 0.55,
                          ),
                  ),
                ),

                if (hasContent) ...[
                  const SizedBox(
                    width: 4,
                  ),

                  // ============================================
                  // CONTENT STATUS
                  // ============================================
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        2,
                      ),
                      color: selected
                          ? _primaryDark
                          : _primaryDark.withValues(
                              alpha: 0.82,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
  // CONTENT
  // ============================================================

  bool _hasContent(
    DateTime date,
  ) {
    for (final contentDate in widget.contentDates) {
      if (_sameDate(
        contentDate,
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
