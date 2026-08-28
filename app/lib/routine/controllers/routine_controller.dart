import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/routine_repository.dart';
import '../models/board_block.dart';
import '../models/routine_day.dart';
import 'routine_state.dart';

class RoutineController
    extends
        ChangeNotifier {
  RoutineController({
    required RoutineRepository repository,
    required String userId,
    DateTime? initialDate,
  }) : _repository =
           repository,
       _userId = userId,
       _state = RoutineState.initial(
         now: initialDate,
       );

  final RoutineRepository _repository;
  final String _userId;

  RoutineState _state;

  bool _initialized = false;

  Timer? _saveDebounce;

  bool _saveRunning = false;
  bool _savePending = false;

  static const Duration _autoSaveDelay = Duration(
    milliseconds: 700,
  );

  RoutineState get state => _state;

  RoutineDay get selectedDay {
    return _state.selectedDay ??
        RoutineDay(
          date: _state.selectedDate,
        );
  }

  Future<
    void
  >
  initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await loadWeek();
  }

  Future<
    void
  >
  loadWeek() async {
    _cancelAutoSave();

    _setState(
      _state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final loadedDays = await _repository.loadWeek(
        userId: _userId,
        weekStart: _state.weekStart,
      );

      final days =
          List<
            RoutineDay
          >.from(
            loadedDays,
          );

      _ensureDate(
        days,
        _state.selectedDate,
      );

      _sortDays(
        days,
      );

      _setState(
        _state.copyWith(
          days: days,
          loading: false,
          clearError: true,
        ),
      );
    } catch (
      error
    ) {
      _setState(
        _state.copyWith(
          loading: false,
          errorMessage: _errorText(
            error,
          ),
        ),
      );
    }
  }

  Future<
    void
  >
  previousWeek() async {
    await _changeWeek(
      -7,
    );
  }

  Future<
    void
  >
  nextWeek() async {
    await _changeWeek(
      7,
    );
  }

  Future<
    void
  >
  goToToday() async {
    await flushPendingSave();

    final today = _dateOnly(
      DateTime.now(),
    );

    _setState(
      _state.copyWith(
        selectedDate: today,
        weekStart: _startOfWeek(
          today,
        ),
      ),
    );

    await loadWeek();
  }

  Future<
    void
  >
  selectDay(
    DateTime date,
  ) async {
    final normalized = _dateOnly(
      date,
    );

    if (_sameDate(
      normalized,
      _state.selectedDate,
    )) {
      return;
    }

    await flushPendingSave();

    final days =
        List<
          RoutineDay
        >.from(
          _state.days,
        );

    _ensureDate(
      days,
      normalized,
    );

    _sortDays(
      days,
    );

    _setState(
      _state.copyWith(
        selectedDate: normalized,
        days: days,
      ),
    );
  }

  void toggleCalendarExpanded() {
    _setState(
      _state.copyWith(
        calendarExpanded: !_state.calendarExpanded,
      ),
    );
  }

  void updateFocus(
    String value,
  ) {
    selectedDay.updateFocus(
      value,
    );

    _notifyMutation(
      autoSave: true,
    );
  }

  void addBlock(
    BoardBlock block,
  ) {
    selectedDay.addBlock(
      block,
    );

    _notifyMutation(
      autoSave: true,
    );
  }

  bool removeBlock(
    String blockId,
  ) {
    final removed = selectedDay.removeBlockById(
      blockId,
    );

    if (removed) {
      _notifyMutation(
        autoSave: true,
      );
    }

    return removed;
  }

  void notifyBlockChanged() {
    _notifyMutation(
      autoSave: true,
    );
  }

  Future<
    void
  >
  saveSelectedDay() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;

    if (_saveRunning) {
      _savePending = true;
      return;
    }

    _saveRunning = true;

    _setState(
      _state.copyWith(
        saving: true,
        clearError: true,
      ),
    );

    try {
      final savedDay = await _repository.saveDay(
        userId: _userId,
        day: selectedDay,
      );

      final days =
          List<
            RoutineDay
          >.from(
            _state.days,
          );

      final index = _indexOfDate(
        days,
        savedDay.date,
      );

      if (index <
          0) {
        days.add(
          savedDay,
        );
      } else {
        days[index] = savedDay;
      }

      _sortDays(
        days,
      );

      _setState(
        _state.copyWith(
          days: days,
          saving: false,
          clearError: true,
        ),
      );
    } catch (
      error
    ) {
      _setState(
        _state.copyWith(
          saving: false,
          errorMessage: _errorText(
            error,
          ),
        ),
      );
    } finally {
      _saveRunning = false;

      if (_savePending) {
        _savePending = false;

        await saveSelectedDay();
      }
    }
  }

  Future<
    void
  >
  deleteSelectedDay() async {
    _cancelAutoSave();

    final day = selectedDay;

    _setState(
      _state.copyWith(
        saving: true,
        clearError: true,
      ),
    );

    try {
      if (day.id !=
          null) {
        await _repository.deleteDay(
          userId: _userId,
          dayId: day.id!,
        );
      }

      final days =
          List<
              RoutineDay
            >.from(
              _state.days,
            )
            ..removeWhere(
              (
                item,
              ) =>
                  item.normalizedDate ==
                  day.normalizedDate,
            )
            ..add(
              RoutineDay(
                date: _state.selectedDate,
              ),
            );

      _sortDays(
        days,
      );

      _setState(
        _state.copyWith(
          days: days,
          saving: false,
          clearError: true,
        ),
      );
    } catch (
      error
    ) {
      _setState(
        _state.copyWith(
          saving: false,
          errorMessage: _errorText(
            error,
          ),
        ),
      );
    }
  }

  void clearError() {
    _setState(
      _state.copyWith(
        clearError: true,
      ),
    );
  }

  Future<
    void
  >
  _changeWeek(
    int numberOfDays,
  ) async {
    await flushPendingSave();

    final weekStart = _state.weekStart.add(
      Duration(
        days: numberOfDays,
      ),
    );

    _setState(
      _state.copyWith(
        weekStart: weekStart,
        selectedDate: weekStart,
      ),
    );

    await loadWeek();
  }

  void _notifyMutation({
    bool autoSave = false,
  }) {
    _state = _state.copyWith(
      days:
          List<
            RoutineDay
          >.from(
            _state.days,
          ),
    );

    notifyListeners();

    if (autoSave) {
      _scheduleAutoSave();
    }
  }

  void _scheduleAutoSave() {
    _saveDebounce?.cancel();

    _saveDebounce = Timer(
      _autoSaveDelay,
      () {
        saveSelectedDay();
      },
    );
  }

  void _cancelAutoSave() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
  }

  Future<
    void
  >
  flushPendingSave() async {
    if (_saveDebounce ==
            null &&
        !_savePending) {
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = null;

    await saveSelectedDay();
  }

  void _setState(
    RoutineState value,
  ) {
    _state = value;

    notifyListeners();
  }

  void _ensureDate(
    List<
      RoutineDay
    >
    days,
    DateTime date,
  ) {
    if (_indexOfDate(
          days,
          date,
        ) <
        0) {
      days.add(
        RoutineDay(
          date: _dateOnly(
            date,
          ),
        ),
      );
    }
  }

  int _indexOfDate(
    List<
      RoutineDay
    >
    days,
    DateTime date,
  ) {
    final normalized = _dateOnly(
      date,
    );

    return days.indexWhere(
      (
        day,
      ) =>
          day.normalizedDate ==
          normalized,
    );
  }

  void _sortDays(
    List<
      RoutineDay
    >
    days,
  ) {
    days.sort(
      (
        a,
        b,
      ) => a.normalizedDate.compareTo(
        b.normalizedDate,
      ),
    );
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

  DateTime _startOfWeek(
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

  String _errorText(
    Object error,
  ) {
    final message = error.toString().trim();

    return message.isEmpty
        ? 'Não foi possível concluir a operação.'
        : message;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();

    super.dispose();
  }
}
