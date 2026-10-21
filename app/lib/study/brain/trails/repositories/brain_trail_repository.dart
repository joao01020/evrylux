import '../models/brain_trail.dart';
import '../stores/brain_trail_local_store.dart';

/// Ponto único de acesso do domínio de Trilhas à persistência.
///
/// A etapa 1 mantém a persistência atual intacta. Nas próximas etapas, sync,
/// cache e remoto entram atrás deste Repository sem voltar a contaminar a UI.
class BrainTrailRepository {
  BrainTrailRepository({BrainTrailLocalStore? localStore})
    : _localStore = localStore ?? BrainTrailLocalStoreAdapter();

  final BrainTrailLocalStore _localStore;

  Future<BrainTrail?> loadForObject(
    String objectId,
    Set<String> existingObjectIds,
  ) async {
    final trails = await _localStore.load();
    BrainTrail? found;
    for (final trail in trails) {
      if (trail.containsObject(objectId)) {
        found = trail;
        break;
      }
    }
    if (found == null) return null;

    final pruned = await _localStore.pruneMissingObjects(
      found,
      existingObjectIds,
    );
    return pruned.containsObject(objectId) ? pruned : null;
  }

  Future<BrainTrail> create({
    required String rootObjectId,
    required String name,
    String? ownerId,
  }) {
    return _localStore.create(rootObjectId, name, ownerId);
  }

  Future<BrainTrail> renameTrail(BrainTrail trail, String name) {
    return _localStore.updateTrail(trail, name: name);
  }

  Future<BrainTrail> addNode(
    BrainTrail trail, {
    required String parentNodeId,
    required String objectId,
  }) {
    return _localStore.addNode(trail, parentNodeId, objectId);
  }

  Future<BrainTrail> renameNode(
    BrainTrail trail, {
    required String nodeId,
    String? displayName,
  }) {
    return _localStore.renameNode(trail, nodeId, displayName);
  }

  Future<BrainTrail> removeBranch(BrainTrail trail, {required String nodeId}) {
    return _localStore.removeBranch(trail, nodeId);
  }
}
