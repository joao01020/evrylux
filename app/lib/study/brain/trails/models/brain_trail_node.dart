class BrainTrailNode {
  const BrainTrailNode({
    required this.id,
    required this.trailId,
    required this.objectId,
    required this.parentNodeId,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
  });

  final String id;
  final String trailId;
  final String objectId;
  final String? parentNodeId;
  final int position;
  final String createdAt;
  final String updatedAt;
  final String? displayName;

  bool get isRoot => parentNodeId == null;

  factory BrainTrailNode.fromMap(Map<String, dynamic> map) {
    return BrainTrailNode(
      id: _requiredString(map, 'id'),
      trailId: _requiredString(map, 'trail_id'),
      objectId: _requiredString(map, 'object_id'),
      parentNodeId: _nullableString(map['parent_node_id']),
      position: (map['position'] as num?)?.toInt() ?? 0,
      createdAt: _nullableString(map['created_at']) ?? '',
      updatedAt: _nullableString(map['updated_at']) ?? '',
      displayName: _nullableString(map['display_name']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'trail_id': trailId,
      'object_id': objectId,
      'parent_node_id': parentNodeId,
      'position': position,
      'created_at': createdAt,
      'updated_at': updatedAt,
      if (displayName != null && displayName!.trim().isNotEmpty)
        'display_name': displayName!.trim(),
    };
  }

  BrainTrailNode copyWith({
    String? id,
    String? trailId,
    String? objectId,
    String? parentNodeId,
    bool clearParentNodeId = false,
    int? position,
    String? createdAt,
    String? updatedAt,
    String? displayName,
    bool clearDisplayName = false,
  }) {
    return BrainTrailNode(
      id: id ?? this.id,
      trailId: trailId ?? this.trailId,
      objectId: objectId ?? this.objectId,
      parentNodeId: clearParentNodeId
          ? null
          : (parentNodeId ?? this.parentNodeId),
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = _nullableString(map[key]);
    if (value == null || value.isEmpty) {
      throw FormatException(
        'Campo obrigatório ausente em BrainTrailNode: $key',
      );
    }
    return value;
  }

  static String? _nullableString(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    return text;
  }
}
