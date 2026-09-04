import '../brain/models/brain_file.dart';
import '../brain/services/brain_storage.dart';
import '../data/repository/study_repository.dart';
import '../models/study_day_summary.dart';

// ============================================================
// STUDY DAY SERVICE
// ============================================================
//
// Responsável por:
//
// - localizar anotações pela DATA DE CRIAÇÃO;
// - carregar datas que possuem anotações;
// - carregar o conteúdo COMPLETO da anotação;
// - carregar o tempo estudado da semana atual.
//
// IMPORTANTE:
//
// O StudyRepository atual ainda armazena minutos por dia da
// semana. Por isso o tempo histórico exato continua disponível
// somente para a semana atual.
//
// As anotações usam BrainFile.createdAt.
//
// ============================================================

class StudyDayService {
  StudyDayService({
    required this.repository,
    this.brainStorage = const BrainStorage(),
  });

  final StudyRepository repository;

  final BrainStorage brainStorage;

  List<DateTime>? _cachedContentDates;

  // ============================================================
  // LOAD DAY
  // ============================================================

  Future<
    StudyDaySummary
  >
  loadDay(
    DateTime date,
  ) async {
    final normalizedDate = _normalizeDate(
      date,
    );

    final notes = await _loadNotesForDate(
      normalizedDate,
    );

    final timeAvailable = _isInCurrentWeek(
      normalizedDate,
    );

    var minutes = 0;

    if (timeAvailable) {
      minutes = await repository.getMinutes(
        _weekdayStorageName(
          normalizedDate,
        ),
      );
    }

    return StudyDaySummary(
      date: normalizedDate,

      minutes: minutes,

      timeAvailable: timeAvailable,

      completed:
          timeAvailable &&
          minutes >
              0,

      notes: notes,
    );
  }

  // ============================================================
  // CONTENT DATES
  // ============================================================
  //
  // Datas que possuem anotações criadas.
  //
  // Usado pelo StudyCalendar para exibir o indicador visual.
  //
  // ============================================================

  Future<
    List<
      DateTime
    >
  >
  loadContentDates({
    bool forceRefresh = false,
  }) async {
    final cached = _cachedContentDates;

    if (!forceRefresh &&
        cached != null) {
      return cached;
    }

    final dates = await brainStorage.loadCreatedDates();

    final normalizedDates =
        <
          DateTime
        >[];

    for (final date in dates) {
      normalizedDates.add(
        _normalizeDate(
          date,
        ),
      );
    }

    normalizedDates.sort();

    final result = List<
      DateTime
    >.unmodifiable(
      normalizedDates,
    );

    _cachedContentDates = result;

    return result;
  }

  void invalidateContentDates() {
    _cachedContentDates = null;
  }

  // ============================================================
  // NOTES FOR DATE
  // ============================================================

  Future<
    List<
      StudyDayNote
    >
  >
  _loadNotesForDate(
    DateTime date,
  ) async {
    final files = await brainStorage.loadNotesCreatedOn(
      date,
    );

    final result =
        <
          StudyDayNote
        >[];

    for (final note in files) {
      result.add(
        _toDayNote(
          note,
        ),
      );
    }

    result.sort(
      (
        first,
        second,
      ) {
        return second.updatedAt.compareTo(
          first.updatedAt,
        );
      },
    );

    return List<
      StudyDayNote
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // BRAIN FILE -> DAY NOTE
  // ============================================================
  //
  // IMPORTANTE:
  //
  // StudyDayNote agora exige:
  //
  // - title
  // - topic
  // - preview
  // - content
  // - path
  // - createdAt
  // - updatedAt
  //
  // Por isso TODOS esses campos precisam ser enviados aqui.
  //
  // ============================================================

  StudyDayNote _toDayNote(
    BrainFile note,
  ) {
    final title = note.title.trim();

    final topic = note.topic.trim();

    final content = note.content.trim();

    final path = note.path.trim();

    return StudyDayNote(
      title: title.isEmpty
          ? 'Sem título'
          : title,

      topic: topic.isEmpty
          ? 'Sem tema'
          : topic,

      preview: _preview(
        content,
      ),

      // ========================================================
      // CONTEÚDO COMPLETO
      // ========================================================
      content: content,

      // ========================================================
      // CAMINHO LOCAL DO MARKDOWN
      // ========================================================
      path: path,

      // ========================================================
      // DATA DE CRIAÇÃO
      // ========================================================
      createdAt: note.createdAt.toLocal(),

      // ========================================================
      // ÚLTIMA ATUALIZAÇÃO
      // ========================================================
      updatedAt: note.updatedAt.toLocal(),
    );
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  String _preview(
    String value,
  ) {
    final normalized = value
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    if (normalized.isEmpty) {
      return 'Sem conteúdo.';
    }

    if (normalized.length <=
        110) {
      return normalized;
    }

    return '${normalized.substring(0, 107)}...';
  }

  // ============================================================
  // CURRENT WEEK
  // ============================================================

  bool _isInCurrentWeek(
    DateTime date,
  ) {
    final today = _normalizeDate(
      DateTime.now(),
    );

    final monday = today.subtract(
      Duration(
        days:
            today.weekday -
            DateTime.monday,
      ),
    );

    final sunday = monday.add(
      const Duration(
        days: 6,
      ),
    );

    return !date.isBefore(
          monday,
        ) &&
        !date.isAfter(
          sunday,
        );
  }

  // ============================================================
  // STORAGE DAY NAME
  // ============================================================

  String _weekdayStorageName(
    DateTime date,
  ) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'segunda';

      case DateTime.tuesday:
        return 'terça';

      case DateTime.wednesday:
        return 'quarta';

      case DateTime.thursday:
        return 'quinta';

      case DateTime.friday:
        return 'sexta';

      case DateTime.saturday:
        return 'sábado';

      case DateTime.sunday:
        return 'domingo';

      default:
        return 'segunda';
    }
  }

  // ============================================================
  // NORMALIZE DATE
  // ============================================================

  DateTime _normalizeDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    return DateTime(
      local.year,
      local.month,
      local.day,
    );
  }
}
