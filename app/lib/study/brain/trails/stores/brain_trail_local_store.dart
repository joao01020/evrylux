import '../brain_trail_store.dart';
import '../models/brain_trail.dart';
import '../models/brain_trail_node.dart';

/// Contrato tipado entre o domínio de Trilhas e a persistência existente.
///
/// Nesta etapa o adaptador continua delegando para BrainTrailStore, preservando
/// exatamente o formato `brain_trail_v1` e o mecanismo de persistência atual de
/// cada plataforma. A UI e o domínio deixam de depender de Map<String, dynamic>.
abstract interface class BrainTrailLocalStore {
  Future<List<BrainTrail>> load();

  Future<BrainTrail> create(String rootId, String name, String? ownerId);

  Future<BrainTrail> updateTrail(
    BrainTrail trail, {
    String? name,
    List<BrainTrailNode>? nodes,
  });

  Future<BrainTrail> addNode(
    BrainTrail trail,
    String parentNodeId,
    String objectId,
  );

  Future<BrainTrail> renameNode(
    BrainTrail trail,
    String nodeId,
    String? displayName,
  );

  Future<BrainTrail> removeBranch(BrainTrail trail, String nodeId);

  Future<BrainTrail> pruneMissingObjects(
    BrainTrail trail,
    Set<String> existingObjectIds,
  );
}

class BrainTrailLocalStoreAdapter implements BrainTrailLocalStore {
  BrainTrailLocalStoreAdapter({BrainTrailStore? legacyStore})
    : _legacyStore = legacyStore ?? BrainTrailStore();

  final BrainTrailStore _legacyStore;

  @override
  Future<List<BrainTrail>> load() async {
    final trails = await _legacyStore.load();
    return trails.map(BrainTrail.fromMap).toList(growable: false);
  }

  @override
  Future<BrainTrail> create(String rootId, String name, String? ownerId) async {
    final trail = await _legacyStore.create(rootId, name, ownerId);
    return BrainTrail.fromMap(trail);
  }

  @override
  Future<BrainTrail> updateTrail(
    BrainTrail trail, {
    String? name,
    List<BrainTrailNode>? nodes,
  }) async {
    final result = await _legacyStore.updateTrail(
      trail.toMap(),
      name: name,
      nodes: nodes?.map((node) => node.toMap()).toList(growable: false),
    );
    return BrainTrail.fromMap(result);
  }

  @override
  Future<BrainTrail> addNode(
    BrainTrail trail,
    String parentNodeId,
    String objectId,
  ) async {
    final result = await _legacyStore.addNode(
      trail.toMap(),
      parentNodeId,
      objectId,
    );
    return BrainTrail.fromMap(result);
  }

  @override
  Future<BrainTrail> renameNode(
    BrainTrail trail,
    String nodeId,
    String? displayName,
  ) async {
    final result = await _legacyStore.renameNode(
      trail.toMap(),
      nodeId,
      displayName,
    );
    return BrainTrail.fromMap(result);
  }

  @override
  Future<BrainTrail> removeBranch(BrainTrail trail, String nodeId) async {
    final result = await _legacyStore.removeBranch(trail.toMap(), nodeId);
    return BrainTrail.fromMap(result);
  }

  @override
  Future<BrainTrail> pruneMissingObjects(
    BrainTrail trail,
    Set<String> existingObjectIds,
  ) async {
    final result = await _legacyStore.pruneMissingObjects(
      trail.toMap(),
      existingObjectIds,
    );
    return BrainTrail.fromMap(result);
  }
}
