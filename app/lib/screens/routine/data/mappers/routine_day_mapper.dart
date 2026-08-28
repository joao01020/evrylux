import '../../models/routine_day.dart';
import '../dtos/routine_day_dto.dart';
import 'board_block_mapper.dart';

abstract final class RoutineDayMapper {
  // ============================================================
  // DTO -> MODEL
  // ============================================================

  static RoutineDay toModel(
    RoutineDayDto dto,
  ) {
    return RoutineDay(
      id: dto.id,
      date: _dateOnly(
        dto.date,
      ),
      focus: dto.focus,
      blocks: BoardBlockMapper.toModelList(
        dto.blocks,
      ),
    );
  }

  // ============================================================
  // MODEL -> DTO
  // ============================================================

  static RoutineDayDto toDto({
    required RoutineDay model,
    required String userId,
  }) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O userId não pode estar vazio.',
      );
    }

    return RoutineDayDto(
      id: model.id,
      userId: normalizedUserId,
      date: _dateOnly(
        model.normalizedDate,
      ),
      focus: model.focus,
      blocks: BoardBlockMapper.toDtoList(
        models: model.blocks,
        routineDayId: model.id,
      ),
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
          toModel,
        )
        .toList();

    models.sort(
      (
        first,
        second,
      ) => first.normalizedDate.compareTo(
        second.normalizedDate,
      ),
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
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O userId não pode estar vazio.',
      );
    }

    final dtos = models
        .map(
          (
            model,
          ) => toDto(
            model: model,
            userId: normalizedUserId,
          ),
        )
        .toList();

    dtos.sort(
      (
        first,
        second,
      ) => first.date.compareTo(
        second.date,
      ),
    );

    return dtos;
  }

  // ============================================================
  // MODEL -> DTO WITH DAY ID
  // ============================================================
  //
  // Útil quando o dia foi salvo no Supabase e ganhou um ID.
  //
  // Assim conseguimos reconstruir os blocos com o
  // routine_day_id correto.
  // ============================================================

  static RoutineDayDto toDtoWithDayId({
    required RoutineDay model,
    required String userId,
    required String routineDayId,
  }) {
    final normalizedUserId = userId.trim();

    final normalizedDayId = routineDayId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError.value(
        userId,
        'userId',
        'O userId não pode estar vazio.',
      );
    }

    if (normalizedDayId.isEmpty) {
      throw ArgumentError.value(
        routineDayId,
        'routineDayId',
        'O routineDayId não pode estar vazio.',
      );
    }

    return RoutineDayDto(
      id: normalizedDayId,
      userId: normalizedUserId,
      date: _dateOnly(
        model.normalizedDate,
      ),
      focus: model.focus,
      blocks: BoardBlockMapper.toDtoList(
        models: model.blocks,
        routineDayId: normalizedDayId,
      ),
    );
  }

  // ============================================================
  // NORMALIZE MODEL
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
      blocks: List.from(
        model.blocks,
      ),
    );
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
