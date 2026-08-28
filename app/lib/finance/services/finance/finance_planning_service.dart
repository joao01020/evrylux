class FinancePlanningService {
  const FinancePlanningService();

  void apply({
    required dynamic model,
    required dynamic result,
  }) {
    model.invested = result.invested;
    model.minimumGoal = result.minimumGoal;
    model.mediumGoal = result.mediumGoal;
    model.maximumGoal = result.maximumGoal;
    model.projectionYears = result.projectionYears;
    model.monthlyGoal = result.mediumGoal;
  }
}
