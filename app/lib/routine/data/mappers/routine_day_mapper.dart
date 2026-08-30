import '../../models/routine_day.dart';
import '../dtos/routine_day_dto.dart';
import 'board_block_mapper.dart';

abstract final class RoutineDayMapper {
  // ============================================================
  // DTO -> MODEL
  // ============================================================
  //
  // Toda conversão dos blocos fica centralizada no
  // BoardBlockMapper.
  //
  // Isso é importante porque propriedades específicas do bloco,
  // como:
  //
  // - position
  // - width
  // - height
  // - items
  // - mindMapNodes
  //
  // precisam ser preservadas pelo BoardBlockMapper.
  //
  // ============================================================

  static RoutineDay toModel(
    RoutineDayDto dto,
  ) {
    final blocks = BoardBlockMapper.toModelList(
      dto.blocks,
    );

    return RoutineDay(
      id: dto.id,
      date: _dateOnly(
        dto.date,
      ),
      focus: dto.focus,
      blocks: blocks,
    );
  }

  // ============================================================
  // MODEL -> DTO
  // ============================================================

  static RoutineDayDto toDto({
    required RoutineDay model,
    required String userId,
  }) {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final blocks = BoardBlockMapper.toDtoList(
      models: model.blocks,
      routineDayId: model.id,
    );

    return RoutineDayDto(
      id: model.id,
      userId: normalizedUserId,
      date: _dateOnly(
        model.normalizedDate,
      ),
      focus: model.focus,
      blocks: blocks,
    );
  }

  // ============================================================
  // DTO LIST -> MODEL LIST
  // ============================================================

  static List<
    RoutineDay
  >
  toModelList(
    Iterable<
      RoutineDayDto
    >
    dtos,
  ) {
    final models = dtos
        .map(
          (
            dto,
          ) => toModel(
            dto,
          ),
        )
        .toList();

    models.sort(
      (
        first,
        second,
      ) {
        return first.normalizedDate.compareTo(
          second.normalizedDate,
        );
      },
    );

    return models;
  }

  // ============================================================
  // MODEL LIST -> DTO LIST
  // ============================================================

  static List<
    RoutineDayDto
  >
  toDtoList({
    required Iterable<
      RoutineDay
    >
    models,
    required String userId,
  }) {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final dtos = models.map(
      (
        model,
      ) {
        return toDto(
          model: model,
          userId: normalizedUserId,
        );
      },
    ).toList();

    dtos.sort(
      (
        first,
        second,
      ) {
        return first.date.compareTo(
          second.date,
        );
      },
    );

    return dtos;
  }

  // ============================================================
  // MODEL -> DTO WITH DAY ID
  // ============================================================
  //
  // Usado quando o dia já possui um ID confirmado pelo Supabase.
  //
  // Nesse caso, todos os blocos recebem o mesmo routine_day_id
  // durante a conversão.
  //
  // ============================================================

  static RoutineDayDto toDtoWithDayId({
    required RoutineDay model,
    required String userId,
    required String routineDayId,
  }) {
    final normalizedUserId = _validateUserId(
      userId,
    );

    final normalizedDayId = _validateRoutineDayId(
      routineDayId,
    );

    final blocks = BoardBlockMapper.toDtoList(
      models: model.blocks,
      routineDayId: normalizedDayId,
    );

    return RoutineDayDto(
      id: normalizedDayId,
      userId: normalizedUserId,
      date: _dateOnly(
        model.normalizedDate,
      ),
      focus: model.focus,
      blocks: blocks,
    );
  }

  // ============================================================
  // NORMALIZE MODEL
  // ============================================================
  //
  // Não recriamos individualmente os BoardBlock aqui.
  //
  // Mantemos as mesmas instâncias porque propriedades mutáveis
  // de interface, como width e height do mapa mental, precisam
  // continuar preservadas.
  //
  // ============================================================

  static RoutineDay normalizeModel(
    RoutineDay model,
  ) {
    return RoutineDay(
      id: model.id,
      date: _dateOnly(
        model.date,
      ),
      focus: model.focus,
      blocks: List.of(
        model.blocks,
      ),
    );
  }

  // ============================================================
  // VALIDATE USER ID
  // ============================================================

  static String _validateUserId(
    String userId,
  ) {
    final normalized = userId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O userId não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // VALIDATE ROUTINE DAY ID
  // ============================================================

  static String _validateRoutineDayId(
    String routineDayId,
  ) {
    final normalized = routineDayId.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        routineDayId,
        'routineDayId',
        'O routineDayId não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // DATE ONLY
  // ============================================================

  static DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }
}
