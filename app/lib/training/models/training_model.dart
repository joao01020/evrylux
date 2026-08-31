// ============================================================
// TRAINING MODEL
// ============================================================
//
// Modelo de um registro de treino.
//
// Cronômetro removido.
//
// O registro agora contém apenas:
//
// - dia;
// - atividade;
// - data.
//
// O parâmetro/getter "minutes" foi mantido SOMENTE como ponte
// temporária de compatibilidade com arquivos antigos.
// Ele não é armazenado e sempre retorna 0.
//
// Depois que não houver mais nenhuma referência a ".minutes"
// no projeto, você pode remover o bloco LEGACY abaixo.
//
// ============================================================

class TrainingModel {
  const TrainingModel({
    required this.day,
    required this.training,
    required this.date,

    // ==========================================================
    // LEGACY
    // ==========================================================
    //
    // Ignorado. Mantido apenas para que construções antigas:
    //
    // TrainingModel(minutes: 0)
    //
    // não quebrem durante a migração.
    //
    // ==========================================================
    @Deprecated(
      'Cronômetro removido. Este parâmetro é ignorado.',
    )
    int? minutes,
  });

  // ============================================================
  // DATA
  // ============================================================

  final String day;

  final String training;

  final DateTime date;

  // ============================================================
  // LEGACY GETTER
  // ============================================================
  //
  // Não representa mais dado real.
  //
  // ============================================================

  @Deprecated(
    'Cronômetro removido. Sempre retorna 0.',
  )
  int get minutes => 0;

  // ============================================================
  // COPY WITH
  // ============================================================

  TrainingModel copyWith({
    String? day,
    String? training,
    DateTime? date,
  }) {
    return TrainingModel(
      day:
          day ??
          this.day,
      training:
          training ??
          this.training,
      date:
          date ??
          this.date,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'day': day,
      'training': training,
      'date': date.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory TrainingModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final rawDate = map['date'];

    final parsedDate =
        rawDate
            is DateTime
        ? rawDate
        : DateTime.tryParse(
            rawDate?.toString() ??
                '',
          );

    return TrainingModel(
      day:
          map['day']?.toString() ??
          '',
      training:
          map['training']?.toString() ??
          '',
      date:
          parsedDate?.toLocal() ??
          DateTime.now(),
    );
  }

  // ============================================================
  // EQUALITY HELPERS
  // ============================================================

  bool sameIdentity(
    TrainingModel other,
  ) {
    final first = date.toLocal();

    final second = other.date.toLocal();

    return day ==
            other.day &&
        training ==
            other.training &&
        first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  @override
  String toString() {
    return 'TrainingModel('
        'day: $day, '
        'training: $training, '
        'date: $date'
        ')';
  }
}
