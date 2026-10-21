import 'package:uuid/uuid.dart';

import '../repositories/brain_repository_web.dart';

/// Trilhas Web gravadas como objetos genéricos E2EE no mesmo Vault das notas.
class BrainTrailStore {
  static const _uuid = Uuid();
  static const _model = 'brain_trail_v1';

  BrainRepository get _repo => BrainRepository();

  Future<List<Map<String, dynamic>>> load() => _repo.loadImportMetadata(_model);

  Future<Map<String, dynamic>> create(
    String rootId,
    String name,
    String? ownerId,
  ) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc().toIso8601String();
    return _repo.saveImportMetadata({
      'model': _model,
      'id': id,
      'owner_id': ownerId,
      'root_object_id': rootId,
      'name': name,
      'created_at': now,
      'updated_at': now,
      'nodes': <Map<String, dynamic>>[
        {
          'id': _uuid.v4(),
          'trail_id': id,
          'object_id': rootId,
          'parent_node_id': null,
          'position': 0,
          'created_at': now,
          'updated_at': now,
        },
      ],
    });
  }

  Future<Map<String, dynamic>> updateTrail(
    Map<String, dynamic> trail, {
    String? name,
    List<Map<String, dynamic>>? nodes,
  }) async {
    final changed = Map<String, dynamic>.from(trail)
      ..remove('_vault_object_id');
    if (name != null) changed['name'] = name;
    if (nodes != null) changed['nodes'] = nodes;
    changed['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return _repo.saveImportMetadata(
      changed,
      vaultObjectId: trail['_vault_object_id'] as String?,
    );
  }

  Future<Map<String, dynamic>> addNode(
    Map<String, dynamic> trail,
    String parentNodeId,
    String objectId,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (!nodes.any((n) => n['id'] == parentNodeId)) {
      throw StateError('Tópico pai não encontrado.');
    }
    if (nodes.any((n) => n['object_id'] == objectId)) {
      throw StateError('Nota já vinculada à Trilha.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    nodes.add({
      'id': _uuid.v4(),
      'trail_id': trail['id'],
      'object_id': objectId,
      'parent_node_id': parentNodeId,
      'position': nodes
          .where((n) => n['parent_node_id'] == parentNodeId)
          .length,
      'created_at': now,
      'updated_at': now,
    });
    return updateTrail(trail, nodes: nodes);
  }

  Future<Map<String, dynamic>> renameNode(
    Map<String, dynamic> trail,
    String nodeId,
    String? displayName,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final i = nodes.indexWhere((n) => n['id'] == nodeId);
    if (i < 0) throw StateError('Tópico não encontrado.');
    if (displayName == null || displayName.trim().isEmpty) {
      nodes[i].remove('display_name');
    } else {
      nodes[i]['display_name'] = displayName.trim();
    }
    nodes[i]['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return updateTrail(trail, nodes: nodes);
  }

  Future<Map<String, dynamic>> removeBranch(
    Map<String, dynamic> trail,
    String nodeId,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final target = nodes.where((n) => n['id'] == nodeId);
    if (target.isEmpty || target.first['parent_node_id'] == null) {
      throw StateError('Não é possível remover a raiz da Trilha.');
    }
    final removed = <String>{nodeId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final n in nodes) {
        if (removed.contains(n['parent_node_id']) &&
            removed.add(n['id'] as String))
          changed = true;
      }
    }
    nodes.removeWhere((n) => removed.contains(n['id']));
    return updateTrail(trail, nodes: nodes);
  }

  Future<Map<String, dynamic>> pruneMissingObjects(
    Map<String, dynamic> trail,
    Set<String> existingObjectIds,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final removed = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final n in nodes) {
        final parent = n['parent_node_id'];
        final id = n['id'] as String;
        if (removed.contains(id)) continue;
        if (!existingObjectIds.contains(n['object_id']) ||
            (parent != null &&
                (removed.contains(parent) ||
                    !nodes.any((other) => other['id'] == parent)))) {
          removed.add(id);
          changed = true;
        }
      }
    }
    if (removed.isEmpty) return trail;
    nodes.removeWhere((n) => removed.contains(n['id']));
    return updateTrail(trail, nodes: nodes);
  }
}
