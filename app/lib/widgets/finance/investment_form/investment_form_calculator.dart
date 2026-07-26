class InvestmentFormCalculator {
  final double currentPatrimony;
  final int projectionYears;

  const InvestmentFormCalculator({
    required this.currentPatrimony,
    required this.projectionYears,
  });

  int get projectionMonths {
    if (projectionYears <=
        0) {
      return 0;
    }

    return projectionYears *
        12;
  }

  double projection(
    double monthlyContribution,
  ) {
    if (monthlyContribution <=
            0 ||
        projectionMonths <=
            0) {
      return currentPatrimony;
    }

    return currentPatrimony +
        monthlyContribution *
            projectionMonths;
  }

  double totalContributed(
    double monthlyContribution,
  ) {
    if (monthlyContribution <=
            0 ||
        projectionMonths <=
            0) {
      return 0;
    }

    return monthlyContribution *
        projectionMonths;
  }
}
