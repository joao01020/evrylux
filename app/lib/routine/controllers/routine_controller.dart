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

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final RoutineRepository _repository;

  final String _userId;

  // ============================================================
  // STATE
  // ============================================================

  RoutineState _state;

  bool _initialized = false;

  // ============================================================
  // AUTO SAVE
  // ============================================================

  Timer? _saveDebounce;

  bool _saveRunning = false;

  bool _savePending = false;

  int _mutationVersion = 0;

  int _lastCommittedVersion = 0;

  static const Duration _autoSaveDelay = Duration(
    milliseconds: 700,
  );

  // ============================================================
  // GETTERS
  // ============================================================

  RoutineState get state => _state;

  RoutineDay get selectedDay {
    return _state.selectedDay ??
        RoutineDay(
          date: _state.selectedDate,
        );
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

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

  // ============================================================
  // LOAD WEEK
  // ============================================================

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

      _mutationVersion++;
      _lastCommittedVersion = _mutationVersion;
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

  // ============================================================
  // NAVEGAÇÃO DE SEMANA
  // ============================================================

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

  // ============================================================
  // SELECIONAR DIA
  // ============================================================

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

  // ============================================================
  // CALENDÁRIO
  // ============================================================

  void toggleCalendarExpanded() {
    _setState(
      _state.copyWith(
        calendarExpanded: !_state.calendarExpanded,
      ),
    );
  }

  // ============================================================
  // FOCO
  // ============================================================

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

  // ============================================================
  // BLOCKS
  // ============================================================

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

  // ============================================================
  // SAVE SELECTED DAY
  // ============================================================
  //
  // REGRA PRINCIPAL:
  //
  // O retorno do repository NÃO substitui mais o estado local.
  //
  // Isso é essencial para widgets interativos como mapa mental,
  // porque uma resposta atrasada do Supabase pode conter posição
  // ou texto antigo.
  //
  // O estado que está na memória é a fonte visual de verdade.
  //
  // O Supabase é usado aqui apenas para persistência.
  //
  // ============================================================

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

    final versionAtStart = _mutationVersion;

    final dayAtStart = selectedDay;

    _saveRunning = true;

    _setSaving(
      true,
    );

    try {
      await _repository.saveDay(
        userId: _userId,
        day: dayAtStart,
      );

      // ========================================================
      // NÃO SOBRESCREVER O ESTADO LOCAL
      // ========================================================
      //
      // Mesmo que o repository retorne RoutineDay, ignoramos o
      // retorno aqui.
      //
      // Assim evitamos:
      //
      // - texto voltando ao valor antigo;
      // - nó retornando à posição anterior;
      // - response race entre saves;
      // - reload implícito após salvar.
      //
      // ========================================================

      if (versionAtStart >
          _lastCommittedVersion) {
        _lastCommittedVersion = versionAtStart;
      }

      _setSaving(
        false,
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

      if (_savePending ||
          _mutationVersion >
              versionAtStart) {
        _savePending = false;

        // Se houve nova alteração enquanto o save estava em voo,
        // persistimos novamente o estado mais atual.
        await saveSelectedDay();
      }
    }
  }

  // ============================================================
  // DELETE SELECTED DAY
  // ============================================================

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

      _mutationVersion++;
      _lastCommittedVersion = _mutationVersion;
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

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    _setState(
      _state.copyWith(
        clearError: true,
      ),
    );
  }

  // ============================================================
  // CHANGE WEEK
  // ============================================================

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

  // ============================================================
  // MUTATION
  // ============================================================

  void _notifyMutation({
    bool autoSave = false,
  }) {
    _mutationVersion++;

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

  // ============================================================
  // AUTO SAVE
  // ============================================================

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

  // ============================================================
  // FLUSH
  // ============================================================

  Future<
    void
  >
  flushPendingSave() async {
    final hasDebounce =
        _saveDebounce !=
        null;

    final hasUnsavedMutation =
        _mutationVersion >
        _lastCommittedVersion;

    if (!hasDebounce &&
        !_savePending &&
        !hasUnsavedMutation) {
      return;
    }

    _saveDebounce?.cancel();

    _saveDebounce = null;

    if (_saveRunning) {
      _savePending = true;

      while (_saveRunning) {
        await Future<
          void
        >.delayed(
          const Duration(
            milliseconds: 20,
          ),
        );
      }

      if (_mutationVersion <=
              _lastCommittedVersion &&
          !_savePending) {
        return;
      }
    }

    await saveSelectedDay();
  }

  // ============================================================
  // SAVING FLAG
  // ============================================================
  //
  // Alterar apenas o flag de saving não substitui a lista de dias
  // nem os objetos BoardBlock/MindMapNode que já estão na memória.
  //
  // ============================================================

  void _setSaving(
    bool value,
  ) {
    _state = _state.copyWith(
      saving: value,
      clearError: value,
    );

    notifyListeners();
  }

  // ============================================================
  // SET STATE
  // ============================================================

  void _setState(
    RoutineState value,
  ) {
    _state = value;

    notifyListeners();
  }

  // ============================================================
  // ENSURE DATE
  // ============================================================

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

  // ============================================================
  // INDEX DATE
  // ============================================================

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

  // ============================================================
  // SORT DAYS
  // ============================================================

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

  // ============================================================
  // DATE ONLY
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

  // ============================================================
  // START OF WEEK
  // ============================================================

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

  // ============================================================
  // ERROR TEXT
  // ============================================================

  String _errorText(
    Object error,
  ) {
    final message = error.toString().trim();

    return message.isEmpty
        ? 'Não foi possível concluir a operação.'
        : message;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _saveDebounce?.cancel();

    super.dispose();
  }
}
