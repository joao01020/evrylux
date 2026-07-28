class TrainingPlanModel {
  static const Set<
    int
  >
  defaultWeekdays = {
    DateTime.monday,
    DateTime.wednesday,
    DateTime.friday,
  };

  final Set<
    int
  >
  plannedWeekdays;

  const TrainingPlanModel({
    required this.plannedWeekdays,
  });

  factory TrainingPlanModel.defaultPlan() {
    return const TrainingPlanModel(
      plannedWeekdays: defaultWeekdays,
    );
  }

  factory TrainingPlanModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final weekdays = _parseWeekdays(
      map['plannedWeekdays'],
    );

    if (weekdays.isEmpty) {
      return TrainingPlanModel.defaultPlan();
    }

    return TrainingPlanModel(
      plannedWeekdays: weekdays,
    );
  }

  int get weeklyGoal {
    return plannedWeekdays.length;
  }

  List<
    int
  >
  get orderedWeekdays {
    return plannedWeekdays.toList()..sort();
  }

  bool get isValid {
    return plannedWeekdays.isNotEmpty &&
        plannedWeekdays.every(
          _isValidWeekday,
        );
  }

  bool containsWeekday(
    int weekday,
  ) {
    return plannedWeekdays.contains(
      weekday,
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'plannedWeekdays': orderedWeekdays,
    };
  }

  TrainingPlanModel copyWith({
    Set<
      int
    >?
    plannedWeekdays,
  }) {
    return TrainingPlanModel(
      plannedWeekdays: {
        ...(plannedWeekdays ??
            this.plannedWeekdays),
      },
    );
  }

  static Set<
    int
  >
  _parseWeekdays(
    dynamic value,
  ) {
    if (value
        is! List) {
      return {};
    }

    return value
        .map(
          _parseInt,
        )
        .whereType<
          int
        >()
        .where(
          _isValidWeekday,
        )
        .toSet();
  }

  static int? _parseInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static bool _isValidWeekday(
    int weekday,
  ) {
    return weekday >=
            DateTime.monday &&
        weekday <=
            DateTime.sunday;
  }

  @override
  bool operator ==(
    Object other,
  ) {
    return identical(
          this,
          other,
        ) ||
        other
                is TrainingPlanModel &&
            plannedWeekdays.length ==
                other.plannedWeekdays.length &&
            plannedWeekdays.containsAll(
              other.plannedWeekdays,
            );
  }

  @override
  int get hashCode {
    return Object.hashAll(
      orderedWeekdays,
    );
  }

  @override
  String toString() {
    return 'TrainingPlanModel('
        'plannedWeekdays: $orderedWeekdays, '
        'weeklyGoal: $weeklyGoal'
        ')';
  }
}
