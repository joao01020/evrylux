import 'brain_trail_node.dart';

class BrainTrail {
  const BrainTrail({
    required this.model,
    required this.id,
    required this.rootObjectId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.nodes,
    this.ownerId,
    this.vaultObjectId,
  });

  final String model;
  final String id;
  final String? ownerId;
  final String rootObjectId;
  final String name;
  final String createdAt;
  final String updatedAt;
  final String? vaultObjectId;
  final List<BrainTrailNode> nodes;

  bool containsObject(String objectId) =>
      nodes.any((node) => node.objectId == objectId);

  BrainTrailNode? nodeById(String nodeId) {
    for (final node in nodes) {
      if (node.id == nodeId) return node;
    }
    return null;
  }

  List<BrainTrailNode> childrenOf(String? parentNodeId) {
    final children = nodes
        .where((node) => node.parentNodeId == parentNodeId)
        .toList();
    children.sort((a, b) => a.position.compareTo(b.position));
    return children;
  }

  factory BrainTrail.fromMap(Map<String, dynamic> map) {
    final rawNodes = map['nodes'];
    final nodes = rawNodes is List
        ? rawNodes
              .whereType<Map>()
              .map(
                (node) =>
                    BrainTrailNode.fromMap(Map<String, dynamic>.from(node)),
              )
              .toList(growable: false)
        : const <BrainTrailNode>[];

    return BrainTrail(
      model: _string(map['model']) ?? 'brain_trail_v1',
      id: _requiredString(map, 'id'),
      ownerId: _string(map['owner_id']),
      rootObjectId: _requiredString(map, 'root_object_id'),
      name: _string(map['name']) ?? '',
      createdAt: _string(map['created_at']) ?? '',
      updatedAt: _string(map['updated_at']) ?? '',
      vaultObjectId: _string(map['_vault_object_id']),
      nodes: nodes,
    );
  }

  Map<String, dynamic> toMap({bool includeVaultObjectId = true}) {
    return <String, dynamic>{
      'model': model,
      'id': id,
      'owner_id': ownerId,
      'root_object_id': rootObjectId,
      'name': name,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'nodes': nodes.map((node) => node.toMap()).toList(growable: false),
      if (includeVaultObjectId && vaultObjectId != null)
        '_vault_object_id': vaultObjectId,
    };
  }

  BrainTrail copyWith({
    String? model,
    String? id,
    String? ownerId,
    String? rootObjectId,
    String? name,
    String? createdAt,
    String? updatedAt,
    String? vaultObjectId,
    List<BrainTrailNode>? nodes,
  }) {
    return BrainTrail(
      model: model ?? this.model,
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      rootObjectId: rootObjectId ?? this.rootObjectId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      vaultObjectId: vaultObjectId ?? this.vaultObjectId,
      nodes: nodes ?? this.nodes,
    );
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = _string(map[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Campo obrigatório ausente em BrainTrail: $key');
    }
    return value;
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    return value.toString();
  }
}
