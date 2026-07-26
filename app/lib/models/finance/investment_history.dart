class InvestmentHistory {
  /// Valor investido no aporte.
  final double value;

  /// Data do aporte.
  final DateTime date;

  /// Ritmo detectado.
  ///
  /// Valores esperados:
  ///
  /// - Tranquilo
  /// - Normal
  /// - Forte
  /// - Personalizado
  /// - Sem aporte
  final String rhythm;

  /// Quanto a barra de objetivo subiu.
  ///
  /// Valor entre 0 e 1.
  final double objectiveProgress;

  /// Quanto a barra de tempo diminuiu.
  ///
  /// Valor entre 0 e 1.
  final double timeProgress;

  const InvestmentHistory({
    required this.value,
    required this.date,
    required this.rhythm,
    required this.objectiveProgress,
    required this.timeProgress,
  });

  // =========================================================
  // ESTADO VAZIO
  // =========================================================

  factory InvestmentHistory.empty() {
    return InvestmentHistory(
      value: 0,
      date: DateTime.now(),
      rhythm: 'Sem aporte',
      objectiveProgress: 0,
      timeProgress: 0,
    );
  }

  // =========================================================
  // VALORES NORMALIZADOS
  // =========================================================

  double get safeValue {
    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  double get normalizedObjectiveProgress {
    if (!objectiveProgress.isFinite) {
      return 0;
    }

    return objectiveProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  double get normalizedTimeProgress {
    if (!timeProgress.isFinite) {
      return 0;
    }

    return timeProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  bool get hasContribution {
    return safeValue >
        0;
  }

  bool get hasProgress {
    return normalizedObjectiveProgress >
            0 ||
        normalizedTimeProgress >
            0;
  }

  String get normalizedRhythm {
    final normalized = rhythm.trim().toLowerCase();

    if (normalized.contains(
          'tranquilo',
        ) ||
        normalized.contains(
          'mínimo',
        ) ||
        normalized.contains(
          'minimo',
        )) {
      return 'Tranquilo';
    }

    if (normalized.contains(
          'normal',
        ) ||
        normalized.contains(
          'médio',
        ) ||
        normalized.contains(
          'medio',
        )) {
      return 'Normal';
    }

    if (normalized.contains(
          'forte',
        ) ||
        normalized.contains(
          'máximo',
        ) ||
        normalized.contains(
          'maximo',
        )) {
      return 'Forte';
    }

    if (normalized.contains(
      'personalizado',
    )) {
      return 'Personalizado';
    }

    if (normalized.contains(
          'sem aporte',
        ) ||
        safeValue <=
            0) {
      return 'Sem aporte';
    }

    if (rhythm.trim().isEmpty) {
      return 'Personalizado';
    }

    return rhythm.trim();
  }

  // =========================================================
  // JSON
  // =========================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'value': safeValue,
      'date': date.toIso8601String(),
      'rhythm': normalizedRhythm,
      'objectiveProgress': normalizedObjectiveProgress,
      'timeProgress': normalizedTimeProgress,
    };
  }

  factory InvestmentHistory.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final parsedValue = _parseDouble(
      json['value'],
    );

    final parsedObjectiveProgress = _parseDouble(
      json['objectiveProgress'],
    );

    final parsedTimeProgress = _parseDouble(
      json['timeProgress'],
    );

    final parsedDate = _parseDate(
      json['date'],
    );

    final parsedRhythm =
        json['rhythm']?.toString().trim() ??
        '';

    final safeParsedValue =
        parsedValue <
            0
        ? 0.0
        : parsedValue;

    final safeObjectiveProgress = parsedObjectiveProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    final safeTimeProgress = parsedTimeProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    return InvestmentHistory(
      value: safeParsedValue,
      date: parsedDate,
      rhythm: parsedRhythm.isEmpty
          ? safeParsedValue >
                    0
                ? 'Personalizado'
                : 'Sem aporte'
          : parsedRhythm,
      objectiveProgress: safeObjectiveProgress,
      timeProgress: safeTimeProgress,
    );
  }

  // =========================================================
  // CÓPIA
  // =========================================================

  InvestmentHistory copyWith({
    double? value,
    DateTime? date,
    String? rhythm,
    double? objectiveProgress,
    double? timeProgress,
  }) {
    return InvestmentHistory(
      value:
          value ??
          this.value,
      date:
          date ??
          this.date,
      rhythm:
          rhythm ??
          this.rhythm,
      objectiveProgress:
          objectiveProgress ??
          this.objectiveProgress,
      timeProgress:
          timeProgress ??
          this.timeProgress,
    );
  }

  // =========================================================
  // CONVERSÕES SEGURAS
  // =========================================================

  static double _parseDouble(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    if (value
        is num) {
      final number = value.toDouble();

      return number.isFinite
          ? number
          : 0;
    }

    final normalized = value.toString().trim().replaceAll(
      ',',
      '.',
    );

    final parsed = double.tryParse(
      normalized,
    );

    if (parsed ==
            null ||
        !parsed.isFinite) {
      return 0;
    }

    return parsed;
  }

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value ==
        null) {
      return DateTime.now();
    }

    return DateTime.tryParse(
          value.toString(),
        ) ??
        DateTime.now();
  }

  // =========================================================
  // COMPARAÇÃO
  // =========================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is InvestmentHistory &&
        other.value ==
            value &&
        other.date ==
            date &&
        other.rhythm ==
            rhythm &&
        other.objectiveProgress ==
            objectiveProgress &&
        other.timeProgress ==
            timeProgress;
  }

  @override
  int get hashCode {
    return Object.hash(
      value,
      date,
      rhythm,
      objectiveProgress,
      timeProgress,
    );
  }

  @override
  String toString() {
    return 'InvestmentHistory('
        'value: $value, '
        'date: $date, '
        'rhythm: $rhythm, '
        'objectiveProgress: $objectiveProgress, '
        'timeProgress: $timeProgress'
        ')';
  }
}
