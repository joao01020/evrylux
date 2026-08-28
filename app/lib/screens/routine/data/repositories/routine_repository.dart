import '../../models/routine_day.dart';

abstract interface class RoutineRepository {
  // ============================================================
  // LOAD WEEK
  // ============================================================

  /// Carrega todos os dias pertencentes à semana informada.
  ///
  /// [weekStart] deve representar o primeiro dia da semana.
  Future<
    List<
      RoutineDay
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
  });

  // ============================================================
  // LOAD DAY
  // ============================================================

  /// Busca um único dia pela data.
  ///
  /// Retorna null quando ainda não existe um registro salvo.
  Future<
    RoutineDay?
  >
  loadDay({
    required String userId,
    required DateTime date,
  });

  // ============================================================
  // SAVE DAY
  // ============================================================

  /// Cria ou atualiza um dia.
  ///
  /// A implementação deve ser responsável por persistir também
  /// os blocos pertencentes ao dia.
  Future<
    RoutineDay
  >
  saveDay({
    required String userId,
    required RoutineDay day,
  });

  // ============================================================
  // DELETE DAY
  // ============================================================

  /// Exclui o dia e todos os dados relacionados a ele.
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  });

  // ============================================================
  // DAY EXISTS
  // ============================================================

  /// Verifica se já existe um dia persistido para a data.
  Future<
    bool
  >
  dayExists({
    required String userId,
    required DateTime date,
  });

  // ============================================================
  // CLEAR LOCAL DATA
  // ============================================================

  /// Limpa qualquer cache/local state mantido pela implementação.
  ///
  /// Em um repository exclusivamente Supabase este método pode
  /// simplesmente não realizar nenhuma operação.
  Future<
    void
  >
  clearLocalData(
    String userId,
  );
}
