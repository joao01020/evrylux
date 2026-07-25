class EvolutionModel {
  final double knowledge;

  final double health;

  final double finance;

  final DateTime? date;

  const EvolutionModel({
    required this.knowledge,

    required this.health,

    required this.finance,

    this.date,
  });

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      "knowledge": knowledge,

      "health": health,

      "finance": finance,

      "date": date?.toIso8601String(),
    };
  }

  factory EvolutionModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return EvolutionModel(
      knowledge:
          (map["knowledge"]
                  as num?)
              ?.toDouble() ??
          0.0,

      health:
          (map["health"]
                  as num?)
              ?.toDouble() ??
          0.0,

      finance:
          (map["finance"]
                  as num?)
              ?.toDouble() ??
          0.0,

      date:
          map["date"] !=
              null
          ? DateTime.parse(
              map["date"],
            )
          : null,
    );
  }

  EvolutionModel copyWith({
    double? knowledge,

    double? health,

    double? finance,

    DateTime? date,
  }) {
    return EvolutionModel(
      knowledge:
          knowledge ??
          this.knowledge,

      health:
          health ??
          this.health,

      finance:
          finance ??
          this.finance,

      date:
          date ??
          this.date,
    );
  }
}
