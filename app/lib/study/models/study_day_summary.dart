// ============================================================
// STUDY DAY SUMMARY
// ============================================================
//
// Dados exibidos ao clicar em um dia do calendário.
//
// As anotações do Cérebro são localizadas pela data de criação.
//
// Cada StudyDayNote carrega:
//
// - título;
// - tema;
// - preview;
// - conteúdo completo;
// - caminho local;
// - createdAt;
// - updatedAt.
//
// Assim o modal do calendário pode mostrar uma prévia e,
// ao clicar na anotação, abrir o conteúdo completo.
//
// ============================================================

class StudyDayNote {
  const StudyDayNote({
    required this.title,
    required this.topic,
    required this.preview,
    required this.content,
    required this.path,
    required this.createdAt,
    required this.updatedAt,
  });

  final String title;

  final String topic;

  /// Texto curto exibido no card do calendário.
  final String preview;

  /// Conteúdo completo da anotação.
  final String content;

  /// Caminho local do arquivo Markdown.
  ///
  /// Mantido aqui para futuras ações como:
  ///
  /// - abrir no Cérebro;
  /// - editar;
  /// - localizar o arquivo;
  /// - compartilhar/exportar.
  final String path;

  /// Data original em que a anotação foi criada.
  final DateTime createdAt;

  /// Última atualização da anotação.
  final DateTime updatedAt;

  bool get hasContent => content.trim().isNotEmpty;

  bool get hasPath => path.trim().isNotEmpty;
}

class StudyDaySummary {
  const StudyDaySummary({
    required this.date,
    required this.minutes,
    required this.timeAvailable,
    required this.completed,
    required this.notes,
  });

  final DateTime date;

  /// O Study atual ainda salva minutos por dia da semana.
  ///
  /// Por isso este valor é considerado confiável somente
  /// quando [timeAvailable] for true.
  final int minutes;

  final bool timeAvailable;

  final bool completed;

  final List<
    StudyDayNote
  >
  notes;

  int get noteCount => notes.length;

  bool get hasNotes => notes.isNotEmpty;

  bool get hasTime =>
      timeAvailable &&
      minutes >
          0;

  bool get hasAnyContent =>
      hasNotes ||
      hasTime ||
      completed;
}
