import '../../models/training_activity_type.dart';
import 'body_region.dart';

// ============================================================
// BODY REGION SCHEDULE
// ============================================================
//
// Representa o planejamento semanal de uma atividade.
//
// O nome da classe foi mantido como BodyRegionSchedule para
// evitar quebrar todo o módulo de uma vez.
//
// Porém, agora a fonte de verdade é:
//
// TrainingActivityType
//
// Isso permite usar:
//
// - Peito
// - Pernas
// - Braço
// - Costas
// - Ombro
// - Core
// - Corrida
// - Caminhada
//
// Exemplo:
//
// Peito
// Seg • Qui
//
// activity:
// TrainingActivityType.chest
//
// weekdays:
// 1 = segunda
// 2 = terça
// 3 = quarta
// 4 = quinta
// 5 = sexta
// 6 = sábado
// 7 = domingo
//
// ============================================================

class BodyRegionSchedule {
  const BodyRegionSchedule({
    required this.activity,
    this.weekdays =
        const <
          int
        >{},
  });

  // ============================================================
  // DATA
  // ============================================================

  final TrainingActivityType activity;

  final Set<
    int
  >
  weekdays;

  // ============================================================
  // COMPATIBILIDADE - REGION
  // ============================================================
  //
  // Alguns widgets antigos ainda podem tentar acessar:
  //
  // schedule.region
  //
  // Retornamos a região visual principal correspondente.
  //
  // Exemplo:
  //
  // chest -> BodyRegion.chest
  // core  -> BodyRegion.abdomen
  // legs  -> BodyRegion.quadriceps
  //
  // Para:
  //
  // back
  // running
  // walking
  //
  // não existe região frontal correspondente.
  //
  // ============================================================

  BodyRegion? get region {
    return BodyRegionExtension.fromActivity(
      activity,
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  String get label => activity.label;

  // ============================================================
  // ID
  // ============================================================

  String get activityId => activity.id;

  // ============================================================
  // COUNT
  // ============================================================

  int get daysPerWeek => weekdays.length;

  // ============================================================
  // EMPTY
  // ============================================================

  bool get isEmpty => weekdays.isEmpty;

  bool get isNotEmpty => weekdays.isNotEmpty;

  // ============================================================
  // BODY REGION
  // ============================================================

  bool get isBodyRegion => activity.isBodyRegion;

  // ============================================================
  // CARDIO
  // ============================================================

  bool get isCardio => activity.isCardio;

  // ============================================================
  // ORDERED DAYS
  // ============================================================

  List<
    int
  >
  get orderedWeekdays {
    final values = weekdays.toList();

    values.sort();

    return values;
  }

  // ============================================================
  // CONTAINS
  // ============================================================

  bool containsDay(
    int weekday,
  ) {
    return weekdays.contains(
      weekday,
    );
  }

  // ============================================================
  // COMPACT LABEL
  // ============================================================
  //
  // Exemplo:
  //
  // {1, 4}
  //
  // Seg • Qui
  //
  // ============================================================

  String get compactDaysLabel {
    if (weekdays.isEmpty) {
      return 'Nenhum dia';
    }

    return orderedWeekdays
        .map(
          shortWeekdayName,
        )
        .join(
          ' • ',
        );
  }

  // ============================================================
  // FREQUENCY LABEL
  // ============================================================

  String get frequencyLabel {
    if (daysPerWeek ==
        0) {
      return 'Nenhum treino configurado';
    }

    if (daysPerWeek ==
        1) {
      return '1 dia por semana';
    }

    return '$daysPerWeek dias por semana';
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BodyRegionSchedule copyWith({
    TrainingActivityType? activity,
    Set<
      int
    >?
    weekdays,
  }) {
    return BodyRegionSchedule(
      activity:
          activity ??
          this.activity,
      weekdays:
          weekdays !=
              null
          ? Set<
              int
            >.from(
              weekdays,
            )
          : Set<
              int
            >.from(
              this.weekdays,
            ),
    );
  }

  // ============================================================
  // COPY WITH WEEKDAY
  // ============================================================

  BodyRegionSchedule copyWithWeekday(
    int weekday,
  ) {
    _validateWeekday(
      weekday,
    );

    final updated =
        Set<
          int
        >.from(
          weekdays,
        );

    updated.add(
      weekday,
    );

    return copyWith(
      weekdays: updated,
    );
  }

  // ============================================================
  // COPY WITHOUT WEEKDAY
  // ============================================================

  BodyRegionSchedule copyWithoutWeekday(
    int weekday,
  ) {
    _validateWeekday(
      weekday,
    );

    final updated =
        Set<
          int
        >.from(
          weekdays,
        );

    updated.remove(
      weekday,
    );

    return copyWith(
      weekdays: updated,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================
  //
  // NOVO FORMATO:
  //
  // {
  //   "activity": "chest",
  //   "weekdays": [1, 4]
  // }
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'activity': activity.id,

      'weekdays': orderedWeekdays,
    };
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return toMap();
  }

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Aceita o formato novo:
  //
  // activity = chest
  //
  // e também o formato antigo:
  //
  // region = chest
  // region = abdomen
  // region = quadriceps
  //
  // Assim dados antigos não quebram durante a migração.
  //
  // ============================================================

  factory BodyRegionSchedule.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final activity = _extractActivity(
      map,
    );

    if (activity ==
        null) {
      throw ArgumentError(
        'Atividade de treino inválida: '
        '${map['activity'] ?? map['region']}',
      );
    }

    final weekdays = _parseWeekdays(
      map['weekdays'],
    );

    return BodyRegionSchedule(
      activity: activity,
      weekdays: weekdays,
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BodyRegionSchedule.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return BodyRegionSchedule.fromMap(
      json,
    );
  }

  // ============================================================
  // EXTRACT ACTIVITY
  // ============================================================

  static TrainingActivityType? _extractActivity(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    // ==========================================================
    // NOVO FORMATO
    // ==========================================================

    final rawActivity = map['activity']?.toString();

    final activity = TrainingActivityTypeExtension.fromAny(
      rawActivity,
    );

    if (activity !=
        null) {
      return activity;
    }

    // ==========================================================
    // COMPATIBILIDADE COM FORMATO ANTIGO
    // ==========================================================
    //
    // Exemplo:
    //
    // {
    //   "region": "abdomen"
    // }
    //
    // abdomen -> core
    //
    // ==========================================================

    final rawRegion = map['region']?.toString();

    final region = BodyRegionExtension.fromId(
      rawRegion,
    );

    if (region !=
        null) {
      return region.activity;
    }

    // ==========================================================
    // TENTAR REGION COMO LABEL/ACTIVITY ANTIGA
    // ==========================================================

    return TrainingActivityTypeExtension.fromAny(
      rawRegion,
    );
  }

  // ============================================================
  // PARSE WEEKDAYS
  // ============================================================

  static Set<
    int
  >
  _parseWeekdays(
    dynamic rawWeekdays,
  ) {
    final weekdays =
        <
          int
        >{};

    if (rawWeekdays
        is! Iterable) {
      return weekdays;
    }

    for (final raw in rawWeekdays) {
      final day =
          raw
              is int
          ? raw
          : int.tryParse(
              raw.toString(),
            );

      if (day ==
          null) {
        continue;
      }

      if (day <
              DateTime.monday ||
          day >
              DateTime.sunday) {
        continue;
      }

      weekdays.add(
        day,
      );
    }

    return weekdays;
  }

  // ============================================================
  // WEEKDAY NAME
  // ============================================================

  static String weekdayName(
    int weekday,
  ) {
    switch (weekday) {
      case DateTime.monday:
        return 'Segunda';

      case DateTime.tuesday:
        return 'Terça';

      case DateTime.wednesday:
        return 'Quarta';

      case DateTime.thursday:
        return 'Quinta';

      case DateTime.friday:
        return 'Sexta';

      case DateTime.saturday:
        return 'Sábado';

      case DateTime.sunday:
        return 'Domingo';

      default:
        return '';
    }
  }

  // ============================================================
  // SHORT WEEKDAY
  // ============================================================

  static String shortWeekdayName(
    int weekday,
  ) {
    switch (weekday) {
      case DateTime.monday:
        return 'Seg';

      case DateTime.tuesday:
        return 'Ter';

      case DateTime.wednesday:
        return 'Qua';

      case DateTime.thursday:
        return 'Qui';

      case DateTime.friday:
        return 'Sex';

      case DateTime.saturday:
        return 'Sáb';

      case DateTime.sunday:
        return 'Dom';

      default:
        return '';
    }
  }

  // ============================================================
  // VALIDATE WEEKDAY
  // ============================================================

  static void _validateWeekday(
    int weekday,
  ) {
    if (weekday <
            DateTime.monday ||
        weekday >
            DateTime.sunday) {
      throw ArgumentError.value(
        weekday,
        'weekday',
        'O dia da semana deve estar entre '
            '${DateTime.monday} e '
            '${DateTime.sunday}.',
      );
    }
  }

  // ============================================================
  // EQUALITY
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

    if (other
        is! BodyRegionSchedule) {
      return false;
    }

    if (other.activity !=
        activity) {
      return false;
    }

    if (other.weekdays.length !=
        weekdays.length) {
      return false;
    }

    for (final weekday in weekdays) {
      if (!other.weekdays.contains(
        weekday,
      )) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // HASH CODE
  // ============================================================

  @override
  int get hashCode {
    final ordered = orderedWeekdays;

    return Object.hashAll(
      <
        Object
      >[
        activity,
        ...ordered,
      ],
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'BodyRegionSchedule('
        'activity: ${activity.id}, '
        'weekdays: $orderedWeekdays'
        ')';
  }
}
