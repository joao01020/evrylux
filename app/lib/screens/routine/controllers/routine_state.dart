import '../models/routine_day.dart';

class RoutineState {
  const RoutineState({
    required this.selectedDate,
    required this.weekStart,
    required this.days,
    required this.calendarExpanded,
    required this.loading,
    required this.saving,
    this.errorMessage,
  });

  factory RoutineState.initial({
    DateTime? now,
  }) {
    final selectedDate = _dateOnly(
      now ??
          DateTime.now(),
    );
    final weekStart = _startOfWeek(
      selectedDate,
    );

    return RoutineState(
      selectedDate: selectedDate,
      weekStart: weekStart,
      days: [
        RoutineDay(
          date: selectedDate,
        ),
      ],
      calendarExpanded: true,
      loading: false,
      saving: false,
    );
  }

  final DateTime selectedDate;
  final DateTime weekStart;
  final List<
    RoutineDay
  >
  days;
  final bool calendarExpanded;
  final bool loading;
  final bool saving;
  final String? errorMessage;

  DateTime get weekEnd => weekStart.add(
    const Duration(
      days: 6,
    ),
  );

  RoutineDay? get selectedDay => dayFor(
    selectedDate,
  );

  bool get hasError =>
      errorMessage !=
          null &&
      errorMessage!.isNotEmpty;

  RoutineDay? dayFor(
    DateTime date,
  ) {
    final normalized = _dateOnly(
      date,
    );

    for (final day in days) {
      if (day.normalizedDate ==
          normalized) {
        return day;
      }
    }

    return null;
  }

  RoutineState copyWith({
    DateTime? selectedDate,
    DateTime? weekStart,
    List<
      RoutineDay
    >?
    days,
    bool? calendarExpanded,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RoutineState(
      selectedDate: _dateOnly(
        selectedDate ??
            this.selectedDate,
      ),
      weekStart: _dateOnly(
        weekStart ??
            this.weekStart,
      ),
      days:
          days ??
          this.days,
      calendarExpanded:
          calendarExpanded ??
          this.calendarExpanded,
      loading:
          loading ??
          this.loading,
      saving:
          saving ??
          this.saving,
      errorMessage: clearError
          ? null
          : errorMessage ??
                this.errorMessage,
    );
  }

  static DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  static DateTime _startOfWeek(
    DateTime value,
  ) {
    final normalized = _dateOnly(
      value,
    );
    return normalized.subtract(
      Duration(
        days:
            normalized.weekday -
            1,
      ),
    );
  }
}
