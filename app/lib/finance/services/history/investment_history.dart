class InvestmentHistory {
  // ============================================================
  // DADOS
  // ============================================================

  /// Valor investido no aporte.
  final double value;

  /// Data e hora reais do aporte.
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

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const InvestmentHistory({
    required this.value,
    required this.date,
    required this.rhythm,
    required this.objectiveProgress,
    required this.timeProgress,
  });

  // ============================================================
  // ESTADO VAZIO
  // ============================================================

  factory InvestmentHistory.empty() {
    return InvestmentHistory(
      value: 0,
      date: DateTime.now(),
      rhythm: 'Sem aporte',
      objectiveProgress: 0,
      timeProgress: 0,
    );
  }

  // ============================================================
  // VALOR SEGURO
  // ============================================================

  double get safeValue {
    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // PROGRESSO NORMALIZADO
  // ============================================================

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

  // ============================================================
  // ESTADOS
  // ============================================================

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

  // ============================================================
  // RITMO NORMALIZADO
  // ============================================================

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

  // ============================================================
  // DATA LOCAL
  // ============================================================

  /// Retorna a data no horário local do dispositivo.
  DateTime get localDate {
    return date.toLocal();
  }

  // ============================================================
  // DATA FORMATADA
  // ============================================================

  /// Exemplo:
  ///
  /// 29/08/2026
  String get formattedDate {
    final local = localDate;

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    final year = local.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // HORA FORMATADA
  // ============================================================

  /// Exemplo:
  ///
  /// 19:03
  String get formattedTime {
    final local = localDate;

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // ============================================================
  // DATA + HORA FORMATADA
  // ============================================================

  /// Exemplo:
  ///
  /// 29/08/2026 às 19:03
  String get formattedDateTime {
    return '$formattedDate às $formattedTime';
  }

  // ============================================================
  // JSON LOCAL
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'value': safeValue,

      'date': date.toUtc().toIso8601String(),

      'rhythm': normalizedRhythm,

      'objectiveProgress': normalizedObjectiveProgress,

      'timeProgress': normalizedTimeProgress,
    };
  }

  // ============================================================
  // JSON SUPABASE
  // ============================================================

  /// Usado caso seja necessário enviar diretamente
  /// para finance_contributions.
  ///
  /// user_id não é colocado aqui porque pertence ao
  /// usuário autenticado e deve ser adicionado pelo storage.
  Map<
    String,
    dynamic
  >
  toSupabaseJson() {
    return {
      'value': safeValue,

      'contribution_date': date.toUtc().toIso8601String(),

      'rhythm': normalizedRhythm,

      'objective_progress': normalizedObjectiveProgress,

      'time_progress': normalizedTimeProgress,
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory InvestmentHistory.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    // ==========================================================
    // VALUE
    // ==========================================================

    final parsedValue = _parseDouble(
      json['value'],
    );

    final safeParsedValue =
        parsedValue <
            0
        ? 0.0
        : parsedValue;

    // ==========================================================
    // OBJECTIVE PROGRESS
    // ==========================================================

    final parsedObjectiveProgress = _parseDouble(
      json['objectiveProgress'] ??
          json['objective_progress'],
    );

    final safeObjectiveProgress = parsedObjectiveProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    // ==========================================================
    // TIME PROGRESS
    // ==========================================================

    final parsedTimeProgress = _parseDouble(
      json['timeProgress'] ??
          json['time_progress'],
    );

    final safeTimeProgress = parsedTimeProgress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();

    // ==========================================================
    // DATE
    // ==========================================================

    final parsedDate = _parseDate(
      json['date'] ??
          json['contribution_date'] ??
          json['created_at'],
    );

    // ==========================================================
    // RHYTHM
    // ==========================================================

    final parsedRhythm =
        json['rhythm']?.toString().trim() ??
        '';

    // ==========================================================
    // RESULT
    // ==========================================================

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

  // ============================================================
  // COPY WITH
  // ============================================================

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

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

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

      if (!number.isFinite) {
        return 0;
      }

      return number;
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

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value.toLocal();
    }

    if (value ==
        null) {
      return DateTime.now();
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    if (parsed ==
        null) {
      return DateTime.now();
    }

    return parsed.toLocal();
  }

  // ============================================================
  // COMPARAÇÃO
  // ============================================================

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

  // ============================================================
  // DEBUG
  // ============================================================

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
