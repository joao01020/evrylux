import '../../models/routine_day.dart';
import '../datasources/routine_remote_data_source.dart';
import '../dtos/routine_day_dto.dart';
import '../mappers/routine_day_mapper.dart';
import 'routine_repository.dart';

class SupabaseRoutineRepository
    implements
        RoutineRepository {
  const SupabaseRoutineRepository({
    required RoutineRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  final RoutineRemoteDataSource _remoteDataSource;

  // ============================================================
  // LOAD WEEK
  // ============================================================

  @override
  Future<
    List<
      RoutineDay
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    _remoteDataSource.ensureAuthenticatedUser(
      userId,
    );

    final records = await _remoteDataSource.loadWeek(
      userId: userId,
      weekStart: weekStart,
    );

    final days =
        <
          RoutineDay
        >[];

    for (final record in records) {
      final dto = RoutineDayDto.fromMap(
        record,
      );

      final model = RoutineDayMapper.toModel(
        dto,
      );

      days.add(
        model,
      );
    }

    days.sort(
      (
        a,
        b,
      ) => a.normalizedDate.compareTo(
        b.normalizedDate,
      ),
    );

    return days;
  }

  // ============================================================
  // LOAD DAY
  // ============================================================

  @override
  Future<
    RoutineDay?
  >
  loadDay({
    required String userId,
    required DateTime date,
  }) async {
    _remoteDataSource.ensureAuthenticatedUser(
      userId,
    );

    final record = await _remoteDataSource.getDay(
      userId: userId,
      date: date,
    );

    if (record ==
        null) {
      return null;
    }

    final dto = RoutineDayDto.fromMap(
      record,
    );

    return RoutineDayMapper.toModel(
      dto,
    );
  }

  // ============================================================
  // SAVE DAY
  // ============================================================

  @override
  Future<
    RoutineDay
  >
  saveDay({
    required String userId,
    required RoutineDay day,
  }) async {
    _remoteDataSource.ensureAuthenticatedUser(
      userId,
    );

    final dto = RoutineDayMapper.toDto(
      model: day,
      userId: userId,
    );

    // ==========================================================
    // IMPORTANTE
    // ==========================================================
    //
    // Agora enviamos os blocos também.
    //
    // Antes estava:
    //
    // includeBlocks: false
    //
    // e por isso somente o dia/foco era enviado.
    //
    // ==========================================================

    final payload = dto.toMap(
      includeBlocks: true,
    );

    final record = await _remoteDataSource.saveDay(
      userId: userId,
      data: payload,
    );

    final savedDto = RoutineDayDto.fromMap(
      record,
    );

    return RoutineDayMapper.toModel(
      savedDto,
    );
  }

  // ============================================================
  // DELETE DAY
  // ============================================================

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    _remoteDataSource.ensureAuthenticatedUser(
      userId,
    );

    await _remoteDataSource.deleteDay(
      userId: userId,
      dayId: dayId,
    );
  }

  // ============================================================
  // DAY EXISTS
  // ============================================================

  @override
  Future<
    bool
  >
  dayExists({
    required String userId,
    required DateTime date,
  }) async {
    _remoteDataSource.ensureAuthenticatedUser(
      userId,
    );

    return _remoteDataSource.dayExists(
      userId: userId,
      date: date,
    );
  }

  // ============================================================
  // CLEAR LOCAL DATA
  // ============================================================

  @override
  Future<
    void
  >
  clearLocalData(
    String userId,
  ) async {
    // ==========================================================
    // Este repository trabalha diretamente com o Supabase.
    //
    // Não existe cache local neste momento.
    //
    // Caso futuramente você adicione:
    //
    // SharedPreferences
    // SQLite
    // Hive
    // Isar
    //
    // a limpeza poderá ser implementada aqui.
    // ==========================================================
  }
}
