class InvestmentFormValidation {
  final double currentPatrimony;
  final double minimumGoal;
  final double mediumGoal;
  final double maximumGoal;
  final int projectionYears;

  const InvestmentFormValidation({
    required this.currentPatrimony,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,
    required this.projectionYears,
  });

  bool get hasAnyValue {
    return currentPatrimony >
            0 ||
        minimumGoal >
            0 ||
        mediumGoal >
            0 ||
        maximumGoal >
            0 ||
        projectionYears >
            0;
  }

  bool get hasCompletePlanning {
    return minimumGoal >
            0 &&
        mediumGoal >
            0 &&
        maximumGoal >
            0 &&
        projectionYears >
            0;
  }

  bool get goalsAreOrdered {
    return minimumGoal <=
            mediumGoal &&
        mediumGoal <=
            maximumGoal;
  }

  bool get isValid {
    return hasCompletePlanning &&
        goalsAreOrdered;
  }

  String? get message {
    if (!hasAnyValue) {
      return null;
    }

    if (minimumGoal <=
        0) {
      return 'Informe um ritmo tranquilo maior que zero.';
    }

    if (mediumGoal <=
        0) {
      return 'Informe um ritmo normal maior que zero.';
    }

    if (maximumGoal <=
        0) {
      return 'Informe um ritmo forte maior que zero.';
    }

    if (!goalsAreOrdered) {
      return 'Use a ordem: ritmo tranquilo ≤ ritmo normal ≤ ritmo forte.';
    }

    if (projectionYears <=
        0) {
      return 'Informe um tempo de projeção maior que zero.';
    }

    return null;
  }
}
