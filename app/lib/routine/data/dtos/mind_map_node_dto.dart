class MindMapNodeDto {
  const MindMapNodeDto({
    required this.id,
    required this.blockId,
    required this.label,
    required this.positionX,
    required this.positionY,
    required this.sourcePort,
    required this.targetPort,
    this.parentId,
    this.isRoot = false,
  });

  final String id;
  final String blockId;
  final String? parentId;
  final String label;
  final double positionX;
  final double positionY;
  final bool isRoot;
  final String sourcePort;
  final String targetPort;

  MindMapNodeDto copyWith({
    String? id,
    String? blockId,
    String? parentId,
    bool removeParent = false,
    String? label,
    double? positionX,
    double? positionY,
    bool? isRoot,
    String? sourcePort,
    String? targetPort,
  }) {
    return MindMapNodeDto(
      id:
          id ??
          this.id,
      blockId:
          blockId ??
          this.blockId,
      parentId: removeParent
          ? null
          : parentId ??
                this.parentId,
      label:
          label ??
          this.label,
      positionX:
          positionX ??
          this.positionX,
      positionY:
          positionY ??
          this.positionY,
      isRoot:
          isRoot ??
          this.isRoot,
      sourcePort:
          sourcePort ??
          this.sourcePort,
      targetPort:
          targetPort ??
          this.targetPort,
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'block_id': blockId,
      'parent_id': parentId,
      'label': label,
      'position_x': positionX,
      'position_y': positionY,
      'is_root': isRoot,
      'source_port': sourcePort,
      'target_port': targetPort,
    };
  }

  factory MindMapNodeDto.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return MindMapNodeDto(
      id: _requiredString(
        map,
        'id',
      ),
      blockId: _requiredString(
        map,
        'block_id',
      ),
      parentId: _nullableString(
        map['parent_id'],
      ),
      label:
          _nullableString(
            map['label'],
          ) ??
          '',
      positionX: _doubleValue(
        map['position_x'],
      ),
      positionY: _doubleValue(
        map['position_y'],
      ),
      isRoot: _boolValue(
        map['is_root'],
      ),
      sourcePort:
          _nullableString(
            map['source_port'],
          ) ??
          'right',
      targetPort:
          _nullableString(
            map['target_port'],
          ) ??
          'left',
    );
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

  static double _doubleValue(
    Object? value,
  ) {
    if (value
        is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static bool _boolValue(
    Object? value,
  ) {
    if (value
        is bool) {
      return value;
    }

    return value ==
            1 ||
        value?.toString().toLowerCase() ==
            'true';
  }
}
