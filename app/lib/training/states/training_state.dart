import 'training_history_state.dart';
import 'training_status_state.dart';

class TrainingState with TrainingHistoryState, TrainingStatusState {
  static const Set<int> defaultPlannedWeekdays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  };

  final Set<int> plannedWeekdays = {...defaultPlannedWeekdays};

  final List<bool> completedDays = List<bool>.filled(7, false);

  final Set<String> selectedActivities = {};

  String? selectedDay;

  int currentSeconds = 0;
  int streak = 0;

  int get weeklyGoal {
    return plannedWeekdays.length;
  }

  String? get selectedActivity {
    if (selectedActivities.length != 1) {
      return null;
    }

    return selectedActivities.first;
  }

  bool get hasSelectedActivities {
    return selectedActivities.isNotEmpty;
  }

  void setPlannedWeekdays(Iterable<int> weekdays) {
    plannedWeekdays
      ..clear()
      ..addAll(weekdays);
  }

  bool isPlannedWeekday(int weekday) {
    return plannedWeekdays.contains(weekday);
  }

  void resetCompletedDays() {
    completedDays.fillRange(0, completedDays.length, false);
  }

  void setCompletedDay(int index, {bool completed = true}) {
    if (index < 0 || index >= completedDays.length) {
      return;
    }

    completedDays[index] = completed;
  }

  void toggleActivity(String activity) {
    if (!selectedActivities.remove(activity)) {
      selectedActivities.add(activity);
    }
  }

  bool isActivitySelected(String activity) {
    return selectedActivities.contains(activity);
  }

  void clearSelectedActivities() {
    selectedActivities.clear();
  }

  void updateTimer(int seconds) {
    currentSeconds = seconds < 0 ? 0 : seconds;
  }

  void resetTimer() {
    currentSeconds = 0;
  }

  void clearTemporaryState() {
    clearSelectedActivities();
    resetTimer();
    clearMessages();
  }

  void resetPlanState() {
    plannedWeekdays
      ..clear()
      ..addAll(defaultPlannedWeekdays);
  }

  void reset() {
    resetPlanState();
    resetCompletedDays();
    resetHistoryState();
    resetStatusState();

    selectedDay = null;

    clearSelectedActivities();
    resetTimer();

    streak = 0;
  }
}
