import '../brain/models/brain_concept.dart';
import '../../web_app/models/web_brain_entry.dart';
import '../../web_app/services/web_brain_repository.dart';
import '../../web_app/services/web_brain_secure_storage.dart';
import '../data/repository/study_repository_contract.dart';
import '../models/study_day_summary.dart';

class StudyDayService {
  StudyDayService({
    required this.repository,
    WebBrainSecureStorage? brainStorage,
  }) : _brainStorage = brainStorage ?? WebBrainSecureStorage();

  final StudyRepositoryContract repository;
  final WebBrainSecureStorage _brainStorage;

  List<DateTime>? _cachedContentDates;

  Future<StudyDaySummary> loadDay(DateTime date) async {
    final normalizedDate = _normalizeDate(date);
    final notes = await _loadNotesForDate(normalizedDate);
    final timeAvailable = _isInCurrentWeek(normalizedDate);

    var minutes = 0;
    if (timeAvailable) {
      minutes = await repository.getMinutes(
        _weekdayStorageName(normalizedDate),
      );
    }

    return StudyDaySummary(
      date: normalizedDate,
      minutes: minutes,
      timeAvailable: timeAvailable,
      completed: timeAvailable && minutes > 0,
      notes: notes,
    );
  }

  Future<List<DateTime>> loadContentDates({bool forceRefresh = false}) async {
    final cached = _cachedContentDates;
    if (!forceRefresh && cached != null) {
      return cached;
    }

    final entries = await _loadBrainEntries();
    final unique = <String, DateTime>{};

    for (final entry in entries) {
      final date = _normalizeDate(entry.updatedAt);
      unique[_dateKey(date)] = date;
    }

    final result = unique.values.toList()..sort();
    _cachedContentDates = List<DateTime>.unmodifiable(result);
    return _cachedContentDates!;
  }

  void invalidateContentDates() {
    _cachedContentDates = null;
  }

  Future<List<StudyDayNote>> _loadNotesForDate(DateTime date) async {
    final entries = await _loadBrainEntries();
    final result = <StudyDayNote>[];

    for (final entry in entries) {
      final entryDate = _normalizeDate(entry.updatedAt);
      if (!_sameDate(entryDate, date)) {
        continue;
      }

      final description = entry.description.trim();
      result.add(
        StudyDayNote(
          title: entry.title,
          topic: entry.type.label,
          preview: _preview(description),
          content: description,
          path: '',
          createdAt: entry.updatedAt,
          updatedAt: entry.updatedAt,
        ),
      );
    }

    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<StudyDayNote>.unmodifiable(result);
  }

  Future<List<WebBrainEntry>> _loadBrainEntries() async {
    try {
      final vaultId = await _brainStorage.loadVaultId();
      if (vaultId == null) {
        return const <WebBrainEntry>[];
      }

      final hasKey = await _brainStorage.containsKeyBundle(vaultId: vaultId);
      if (!hasKey) {
        return const <WebBrainEntry>[];
      }

      final repository = WebBrainRepository(
        vaultId: vaultId,
        storage: _brainStorage,
      );

      return await repository.loadEntries();
    } catch (_) {
      return const <WebBrainEntry>[];
    }
  }

  String _preview(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= 160) {
      return clean;
    }
    return '${clean.substring(0, 157)}...';
  }

  DateTime _normalizeDate(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool _isInCurrentWeek(DateTime date) {
    final now = _normalizeDate(DateTime.now());
    final monday = now.subtract(Duration(days: now.weekday - DateTime.monday));
    final sunday = monday.add(const Duration(days: 6));
    return !date.isBefore(monday) && !date.isAfter(sunday);
  }

  String _weekdayStorageName(DateTime date) {
    const names = <int, String>{
      DateTime.monday: 'segunda',
      DateTime.tuesday: 'terça',
      DateTime.wednesday: 'quarta',
      DateTime.thursday: 'quinta',
      DateTime.friday: 'sexta',
      DateTime.saturday: 'sábado',
      DateTime.sunday: 'domingo',
    };
    return names[date.weekday] ?? 'segunda';
  }
}
