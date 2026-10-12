import 'package:uuid/uuid.dart';

import '../../../app/dependencies/app_dependencies.dart' as app;
import '../vault/models/brain_vault_object_type.dart';

/// Trail metadata is E2EE in the same vault and sync queue as Brain notes.
/// Object identifiers are the canonical BrainFile.path values, not note copies.
class BrainTrailStore {
  static const _uuid = Uuid();
  static const _model = 'brain_trail_v1';

  Future<List<Map<String, dynamic>>> load() async {
    final objects = await app.brainVaultService.loadAllEncryptedObjects();
    final active = objects.where((object) => object.isActive).toList();
    final decoded = await app.brainVaultService.decodeEncryptedObjects(active);
    final trails = <Map<String, dynamic>>[];
    for (var i = 0; i < decoded.length; i++) {
      final payload = decoded[i];
      if (payload?.type != BrainVaultObjectType.generic ||
          payload?.data['model'] != _model) {
        continue;
      }
      trails.add({
        ...payload!.data,
        '_vault_object_id': active[i].header.objectId,
      });
    }
    return trails;
  }

  Future<Map<String, dynamic>> create(
    String rootId,
    String name,
    String? ownerId,
  ) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final id = _uuid.v4();
    final data = <String, dynamic>{
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
    };
    final object = await app.brainVaultService.createObject(
      type: BrainVaultObjectType.generic,
      data: data,
    );
    await app.brainSyncQueueService.enqueueObject(object);
    return {...data, '_vault_object_id': object.header.objectId};
  }

  Future<Map<String, dynamic>> addNode(
    Map<String, dynamic> trail,
    String parentNodeId,
    String objectId,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    if (!nodes.any((node) => node['id'] == parentNodeId)) {
      throw StateError('Nó pai não encontrado.');
    }
    if (nodes.any((node) => node['object_id'] == objectId)) {
      throw StateError('Esta nota já pertence à trilha.');
    }
    final now = DateTime.now().toUtc().toIso8601String();
    final siblings = nodes.where(
      (node) => node['parent_node_id'] == parentNodeId,
    );
    nodes.add({
      'id': _uuid.v4(),
      'trail_id': trail['id'],
      'object_id': objectId,
      'parent_node_id': parentNodeId,
      'position': siblings.length,
      'created_at': now,
      'updated_at': now,
    });
    return updateTrail(trail, nodes: nodes);
  }

  Future<Map<String, dynamic>> updateTrail(
    Map<String, dynamic> trail, {
    String? name,
    List<Map<String, dynamic>>? nodes,
  }) async {
    final data = Map<String, dynamic>.from(trail)..remove('_vault_object_id');
    if (name != null) {
      data['name'] = name;
    }
    if (nodes != null) {
      data['nodes'] = _reindex(nodes);
    }
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final updated = await app.brainVaultService.updateObject(
      objectId: trail['_vault_object_id'] as String,
      type: BrainVaultObjectType.generic,
      data: data,
    );
    await app.brainSyncQueueService.enqueueObject(updated);
    return {...data, '_vault_object_id': updated.header.objectId};
  }

  Future<Map<String, dynamic>> renameNode(
    Map<String, dynamic> trail,
    String nodeId,
    String? displayName,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    final index = nodes.indexWhere((node) => node['id'] == nodeId);
    if (index < 0) {
      throw StateError('Nó não encontrado.');
    }
    if (displayName == null || displayName.trim().isEmpty) {
      nodes[index].remove('display_name');
    } else {
      nodes[index]['display_name'] = displayName.trim();
    }
    nodes[index]['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return updateTrail(trail, nodes: nodes);
  }

  /// Desvincula a ramificação selecionada, sem apagar nenhuma nota do Vault.
  Future<Map<String, dynamic>> removeBranch(
    Map<String, dynamic> trail,
    String nodeId,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    final target = nodes.where((node) => node['id'] == nodeId).toList();
    if (target.isEmpty) {
      throw StateError('Nó não encontrado.');
    }
    if (target.first['parent_node_id'] == null) {
      throw StateError('A raiz não pode ser desvinculada da própria Trilha.');
    }
    final ids = <String>{nodeId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final node in nodes) {
        if (ids.contains(node['parent_node_id']) &&
            ids.add(node['id'] as String)) {
          changed = true;
        }
      }
    }
    nodes.removeWhere((node) => ids.contains(node['id']));
    return updateTrail(trail, nodes: nodes);
  }

  /// Remove referências quebradas para notas apagadas e também elimina
  /// sub-ramos órfãos cujo pai desapareceu.
  Future<Map<String, dynamic>> pruneMissingObjects(
    Map<String, dynamic> trail,
    Set<String> existingObjectIds,
  ) async {
    final nodes = (trail['nodes'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
    if (nodes.isEmpty) {
      return trail;
    }

    final removedIds = <String>{};
    var changed = false;
    var hasChanges = true;

    while (hasChanges) {
      hasChanges = false;
      for (final node in nodes) {
        final nodeId = node['id'] as String;
        if (removedIds.contains(nodeId)) {
          continue;
        }
        final objectId = node['object_id'] as String;
        final parentId = node['parent_node_id'] as String?;
        final missingObject = !existingObjectIds.contains(objectId);
        final missingParent =
            parentId != null &&
            (removedIds.contains(parentId) ||
                !nodes.any((other) => other['id'] == parentId));
        if (missingObject || missingParent) {
          removedIds.add(nodeId);
          hasChanges = true;
          changed = true;
        }
      }
    }

    if (!changed) {
      return trail;
    }

    final kept = nodes
        .where((node) => !removedIds.contains(node['id']))
        .toList();
    return updateTrail(trail, nodes: kept);
  }

  List<Map<String, dynamic>> _reindex(List<Map<String, dynamic>> nodes) {
    final normalized = nodes
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
    final now = DateTime.now().toUtc().toIso8601String();
    final childrenByParent = <String?, List<Map<String, dynamic>>>{};
    for (final node in normalized) {
      final parentId = node['parent_node_id'] as String?;
      childrenByParent
          .putIfAbsent(parentId, () => <Map<String, dynamic>>[])
          .add(node);
    }
    childrenByParent.forEach((parentId, siblings) {
      siblings.sort(
        (a, b) => ((a['position'] as num?)?.toInt() ?? 0).compareTo(
          (b['position'] as num?)?.toInt() ?? 0,
        ),
      );
      for (var i = 0; i < siblings.length; i++) {
        siblings[i]['position'] = i;
        siblings[i]['updated_at'] ??= now;
      }
    });
    return normalized;
  }
}
