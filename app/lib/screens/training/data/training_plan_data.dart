class TrainingPlanData {
  final int weeklyGoal;
  final Set<
    int
  >
  plannedWeekdays;

  const TrainingPlanData({
    required this.weeklyGoal,
    required this.plannedWeekdays,
  });

  static const Set<
    int
  >
  defaultWeekdays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  };

  factory TrainingPlanData.defaultPlan() {
    return const TrainingPlanData(
      weeklyGoal: 3,
      plannedWeekdays: defaultWeekdays,
    );
  }
}
