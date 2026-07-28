import 'package:flutter/foundation.dart';

import '../helpers/training_date_helper.dart';
import '../states/training_state.dart';

class TrainingUiController extends ChangeNotifier {
  final TrainingState state;

  final List<String> activityOptions;

  TrainingUiController({required this.state, required this.activityOptions});

  // =========================================================
  // DIAS DA SEMANA
  // =========================================================

  List<String> get days {
    return TrainingDateHelper.weekDays;
  }

  // =========================================================
  // DIA SELECIONADO
  // =========================================================

  String? get selectedDay {
    return state.selectedDay;
  }

  // =========================================================
  // ATIVIDADES SELECIONADAS
  // =========================================================

  Set<String> get selectedActivities {
    return state.selectedActivities;
  }

  String? get selectedActivity {
    return state.selectedActivity;
  }

  bool get hasSelectedActivities {
    return state.hasSelectedActivities;
  }

  // =========================================================
  // CRONÔMETRO
  // =========================================================

  int get currentSeconds {
    return state.currentSeconds;
  }

  // =========================================================
  // SELECIONAR DIA PELO ÍNDICE
  // =========================================================

  void selectDay(int index) {
    if (index < 0 || index >= days.length) {
      return;
    }

    final day = days[index];

    if (state.selectedDay == day) {
      return;
    }

    state.selectedDay = day;

    notifyListeners();
  }

  // =========================================================
  // DEFINIR DIA DIRETAMENTE
  // =========================================================

  void setSelectedDay(String? day) {
    if (day == null) {
      if (state.selectedDay == null) {
        return;
      }

      state.selectedDay = null;

      notifyListeners();

      return;
    }

    final normalizedDay = day.trim();

    if (normalizedDay.isEmpty) {
      return;
    }

    if (!days.contains(normalizedDay)) {
      return;
    }

    if (state.selectedDay == normalizedDay) {
      return;
    }

    state.selectedDay = normalizedDay;

    notifyListeners();
  }

  // =========================================================
  // SELECIONAR DIA ATUAL
  // =========================================================

  void selectCurrentDay() {
    final currentDay = TrainingDateHelper.getDayName(DateTime.now());

    if (state.selectedDay == currentDay) {
      return;
    }

    state.selectedDay = currentDay;

    notifyListeners();
  }

  // =========================================================
  // SELECIONAR ATIVIDADE
  // =========================================================

  void selectActivity(String activity) {
    toggleActivity(activity);
  }

  // =========================================================
  // ALTERNAR ATIVIDADE
  // =========================================================

  void toggleActivity(String activity) {
    final normalizedActivity = activity.trim();

    if (normalizedActivity.isEmpty) {
      return;
    }

    if (!activityOptions.contains(normalizedActivity)) {
      return;
    }

    state.toggleActivity(normalizedActivity);

    notifyListeners();
  }

  // =========================================================
  // VERIFICAR ATIVIDADE SELECIONADA
  // =========================================================

  bool isActivitySelected(String activity) {
    return state.isActivitySelected(activity);
  }

  // =========================================================
  // LIMPAR ATIVIDADES SELECIONADAS
  // =========================================================

  void clearSelectedActivities() {
    if (state.selectedActivities.isEmpty) {
      return;
    }

    state.clearSelectedActivities();

    notifyListeners();
  }

  // =========================================================
  // SELECIONAR APENAS UMA ATIVIDADE
  // =========================================================

  void selectOnlyActivity(String activity) {
    final normalizedActivity = activity.trim();

    if (normalizedActivity.isEmpty) {
      return;
    }

    if (!activityOptions.contains(normalizedActivity)) {
      return;
    }

    final alreadySelected =
        state.selectedActivities.length == 1 &&
        state.selectedActivities.contains(normalizedActivity);

    if (alreadySelected) {
      return;
    }

    state.clearSelectedActivities();

    state.selectedActivities.add(normalizedActivity);

    notifyListeners();
  }

  // =========================================================
  // ATUALIZAR CRONÔMETRO
  // =========================================================

  void updateTimer(int seconds) {
    final normalizedSeconds = seconds < 0 ? 0 : seconds;

    if (state.currentSeconds == normalizedSeconds) {
      return;
    }

    state.updateTimer(normalizedSeconds);

    notifyListeners();
  }

  // =========================================================
  // ADICIONAR TEMPO
  // =========================================================

  void addTimerSeconds(int seconds) {
    if (seconds <= 0) {
      return;
    }

    state.updateTimer(state.currentSeconds + seconds);

    notifyListeners();
  }

  // =========================================================
  // REMOVER TEMPO
  // =========================================================

  void removeTimerSeconds(int seconds) {
    if (seconds <= 0) {
      return;
    }

    final updatedSeconds = state.currentSeconds - seconds;

    state.updateTimer(updatedSeconds < 0 ? 0 : updatedSeconds);

    notifyListeners();
  }

  // =========================================================
  // RESETAR CRONÔMETRO
  // =========================================================

  void resetTimer() {
    if (state.currentSeconds == 0) {
      return;
    }

    state.resetTimer();

    notifyListeners();
  }

  // =========================================================
  // LIMPAR MENSAGENS
  // =========================================================

  void clearMessages() {
    if (!state.hasError && !state.hasSuccess) {
      return;
    }

    state.clearMessages();

    notifyListeners();
  }

  // =========================================================
  // LIMPAR ESTADO TEMPORÁRIO
  // =========================================================

  void clearTemporaryState() {
    final hadSelectedActivities = state.selectedActivities.isNotEmpty;

    final hadTimer = state.currentSeconds > 0;

    final hadMessages = state.hasError || state.hasSuccess;

    if (!hadSelectedActivities && !hadTimer && !hadMessages) {
      return;
    }

    state.clearTemporaryState();

    notifyListeners();
  }

  // =========================================================
  // RESET COMPLETO
  // =========================================================

  void resetState() {
    state.reset();

    notifyListeners();
  }
}
