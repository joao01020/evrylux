import 'board_block_dto.dart';

class RoutineDayDto {
  const RoutineDayDto({
    required this.userId,
    required this.date,
    required this.focus,
    this.id,
    this.blocks = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String userId;
  final DateTime date;
  final String focus;
  final List<
    BoardBlockDto
  >
  blocks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RoutineDayDto copyWith({
    String? id,
    String? userId,
    DateTime? date,
    String? focus,
    List<
      BoardBlockDto
    >?
    blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoutineDayDto(
      id:
          id ??
          this.id,
      userId:
          userId ??
          this.userId,
      date:
          date ??
          this.date,
      focus:
          focus ??
          this.focus,
      blocks:
          blocks ??
          this.blocks,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  Map<
    String,
    dynamic
  >
  toMap({
    bool includeBlocks = true,
  }) {
    return {
      if (id !=
          null)
        'id': id,
      'user_id': userId,
      'date': _formatDate(
        date,
      ),
      'focus': focus,
      if (createdAt !=
          null)
        'created_at': createdAt!.toIso8601String(),
      if (updatedAt !=
          null)
        'updated_at': updatedAt!.toIso8601String(),
      if (includeBlocks)
        'blocks': blocks
            .map(
              (
                block,
              ) => block.toMap(),
            )
            .toList(),
    };
  }

  factory RoutineDayDto.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return RoutineDayDto(
      id: _nullableString(
        map['id'],
      ),
      userId: _requiredString(
        map,
        'user_id',
      ),
      date: _requiredDate(
        map,
        'date',
      ),
      focus:
          _nullableString(
            map['focus'],
          ) ??
          '',
      blocks: _blockList(
        map['blocks'],
      ),
      createdAt: _nullableDate(
        map['created_at'],
      ),
      updatedAt: _nullableDate(
        map['updated_at'],
      ),
    );
  }

  static List<
    BoardBlockDto
  >
  _blockList(
    Object? value,
  ) {
    if (value
        is! List) {
      return [];
    }

    return value
        .whereType<
          Map
        >()
        .map(
          (
            item,
          ) => BoardBlockDto.fromMap(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          ),
        )
        .toList();
  }

  static String _requiredString(
    Map<
      String,
      dynamic
    >
    map,
    String key,
  ) {
    final value = _nullableString(
      map[key],
    );

    if (value ==
            null ||
        value.isEmpty) {
      throw FormatException(
        'Campo obrigatório ausente: $key',
      );
    }

    return value;
  }

  static DateTime _requiredDate(
    Map<
      String,
      dynamic
    >
    map,
    String key,
  ) {
    final value = _nullableDate(
      map[key],
    );

    if (value ==
        null) {
      throw FormatException(
        'Data obrigatória inválida: $key',
      );
    }

    return value;
  }

  static DateTime? _nullableDate(
    Object? value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value ==
        null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }

  static String? _nullableString(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();
    return text.isEmpty
        ? null
        : text;
  }

  static String _formatDate(
    DateTime value,
  ) {
    final date = DateTime(
      value.year,
      value.month,
      value.day,
    );
    return date
        .toIso8601String()
        .split(
          'T',
        )
        .first;
  }
}
