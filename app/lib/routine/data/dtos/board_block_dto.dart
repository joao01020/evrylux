import 'mind_map_node_dto.dart';

// ============================================================
// CHECK ITEM DTO
// ============================================================

class CheckItemDto {
  const CheckItemDto({
    required this.text,
    required this.completed,
    this.id,
    this.blockId,
    this.position = 0,
  });

  final String? id;
  final String? blockId;
  final String text;
  final bool completed;
  final int position;

  // ============================================================
  // COPY WITH
  // ============================================================

  CheckItemDto copyWith({
    String? id,
    String? blockId,
    String? text,
    bool? completed,
    int? position,
  }) {
    return CheckItemDto(
      id:
          id ??
          this.id,
      blockId:
          blockId ??
          this.blockId,
      text:
          text ??
          this.text,
      completed:
          completed ??
          this.completed,
      position:
          position ??
          this.position,
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
      if (id !=
          null)
        'id': id,
      if (blockId !=
          null)
        'block_id': blockId,
      'text': text,
      'completed': completed,
      'position': position,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory CheckItemDto.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CheckItemDto(
      id: _nullableString(
        map['id'],
      ),
      blockId: _nullableString(
        map['block_id'],
      ),
      text:
          _nullableString(
            map['text'],
          ) ??
          '',
      completed: _boolValue(
        map['completed'],
      ),
      position: _intValue(
        map['position'],
      ),
    );
  }
}

// ============================================================
// BOARD BLOCK DTO
// ============================================================

class BoardBlockDto {
  const BoardBlockDto({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.contentStatus,
    this.routineDayId,
    this.positionX,
    this.positionY,
    this.width,
    this.height,
    this.items = const [],
    this.mindMapNodes = const [],
  });

  final String id;

  final String? routineDayId;

  final String type;

  final String title;

  final String content;

  final String contentStatus;

  final double? positionX;

  final double? positionY;

  final double? width;

  final double? height;

  final List<
    CheckItemDto
  >
  items;

  final List<
    MindMapNodeDto
  >
  mindMapNodes;

  // ============================================================
  // COPY WITH
  // ============================================================

  BoardBlockDto copyWith({
    String? id,
    String? routineDayId,
    String? type,
    String? title,
    String? content,
    String? contentStatus,
    double? positionX,
    double? positionY,
    double? width,
    double? height,
    List<
      CheckItemDto
    >?
    items,
    List<
      MindMapNodeDto
    >?
    mindMapNodes,
  }) {
    return BoardBlockDto(
      id:
          id ??
          this.id,
      routineDayId:
          routineDayId ??
          this.routineDayId,
      type:
          type ??
          this.type,
      title:
          title ??
          this.title,
      content:
          content ??
          this.content,
      contentStatus:
          contentStatus ??
          this.contentStatus,
      positionX:
          positionX ??
          this.positionX,
      positionY:
          positionY ??
          this.positionY,
      width:
          width ??
          this.width,
      height:
          height ??
          this.height,
      items:
          items ??
          this.items,
      mindMapNodes:
          mindMapNodes ??
          this.mindMapNodes,
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap({
    bool includeRelations = true,
  }) {
    return {
      'id': id,

      if (routineDayId !=
          null)
        'routine_day_id': routineDayId,

      'type': type,

      'title': title,

      'content': content,

      'content_status': contentStatus,

      'position_x': positionX,

      'position_y': positionY,

      'width': width,

      'height': height,

      if (includeRelations)
        'items': items
            .map(
              (
                item,
              ) => item.toMap(),
            )
            .toList(),

      if (includeRelations)
        'mind_map_nodes': mindMapNodes
            .map(
              (
                node,
              ) => node.toMap(),
            )
            .toList(),
    };
  }

  // ============================================================
  // DATABASE MAP
  // ============================================================
  //
  // Retorna apenas as colunas da tabela routine_blocks.
  //
  // As relações:
  // - items
  // - mind_map_nodes
  //
  // devem ser salvas separadamente.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toDatabaseMap({
    String? dayId,
  }) {
    return {
      'id': id,

      if (dayId !=
          null)
        'routine_day_id': dayId
      else if (routineDayId !=
          null)
        'routine_day_id': routineDayId,

      'type': type,

      'title': title,

      'content': content,

      'content_status': contentStatus,

      'position_x': positionX,

      'position_y': positionY,

      'width': width,

      'height': height,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory BoardBlockDto.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return BoardBlockDto(
      id: _requiredString(
        map,
        'id',
      ),
      routineDayId: _nullableString(
        map['routine_day_id'] ??
            map['routineDayId'],
      ),
      type:
          _nullableString(
            map['type'],
          ) ??
          'note',
      title:
          _nullableString(
            map['title'],
          ) ??
          '',
      content:
          _nullableString(
            map['content'],
          ) ??
          '',
      contentStatus:
          _nullableString(
            map['content_status'] ??
                map['contentStatus'],
          ) ??
          'idea',
      positionX: _nullableDouble(
        map['position_x'] ??
            map['positionX'],
      ),
      positionY: _nullableDouble(
        map['position_y'] ??
            map['positionY'],
      ),
      width: _nullableDouble(
        map['width'],
      ),
      height: _nullableDouble(
        map['height'],
      ),
      items: _mapList(
        map['items'],
        CheckItemDto.fromMap,
      ),
      mindMapNodes: _mapList(
        map['mind_map_nodes'] ??
            map['mindMapNodes'],
        MindMapNodeDto.fromMap,
      ),
    );
  }

  // ============================================================
  // WITHOUT RELATIONS
  // ============================================================

  BoardBlockDto withoutRelations() {
    return BoardBlockDto(
      id: id,
      routineDayId: routineDayId,
      type: type,
      title: title,
      content: content,
      contentStatus: contentStatus,
      positionX: positionX,
      positionY: positionY,
      width: width,
      height: height,
    );
  }

  // ============================================================
  // WITH DAY ID
  // ============================================================

  BoardBlockDto withRoutineDayId(
    String dayId,
  ) {
    return copyWith(
      routineDayId: dayId,
    );
  }

  // ============================================================
  // CHECK ITEM MAPS
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  checkItemsToDatabaseMaps() {
    return List.generate(
      items.length,
      (
        index,
      ) {
        final item = items[index];

        return {
          if (item.id !=
              null)
            'id': item.id,

          'block_id': id,

          'text': item.text,

          'completed': item.completed,

          'position': index,
        };
      },
    );
  }

  // ============================================================
  // MIND MAP MAPS
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  mindMapNodesToDatabaseMaps() {
    return mindMapNodes
        .map(
          (
            node,
          ) => {
            ...node.toMap(),
            'block_id': id,
          },
        )
        .toList();
  }
}

// ============================================================
// MAP LIST
// ============================================================

List<
  T
>
_mapList<
  T
>(
  Object? value,
  T Function(
    Map<
      String,
      dynamic
    >,
  )
  converter,
) {
  if (value
      is! List) {
    return <
      T
    >[];
  }

  final result =
      <
        T
      >[];

  for (final item in value) {
    if (item
        is Map) {
      result.add(
        converter(
          Map<
            String,
            dynamic
          >.from(
            item,
          ),
        ),
      );
    }
  }

  return result;
}

// ============================================================
// REQUIRED STRING
// ============================================================

String
_requiredString(
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

// ============================================================
// NULLABLE STRING
// ============================================================

String?
_nullableString(
  Object? value,
) {
  if (value ==
      null) {
    return null;
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return text;
}

// ============================================================
// NULLABLE DOUBLE
// ============================================================

double?
_nullableDouble(
  Object? value,
) {
  if (value ==
      null) {
    return null;
  }

  if (value
      is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString(),
  );
}

// ============================================================
// INT VALUE
// ============================================================

int
_intValue(
  Object? value,
) {
  if (value
      is int) {
    return value;
  }

  if (value
      is num) {
    return value.toInt();
  }

  return int.tryParse(
        value?.toString() ??
            '',
      ) ??
      0;
}

// ============================================================
// BOOL VALUE
// ============================================================

bool
_boolValue(
  Object? value,
) {
  if (value
      is bool) {
    return value;
  }

  if (value
      is num) {
    return value !=
        0;
  }

  final normalized = value?.toString().trim().toLowerCase();

  return normalized ==
          'true' ||
      normalized ==
          '1' ||
      normalized ==
          'yes' ||
      normalized ==
          'sim';
}
