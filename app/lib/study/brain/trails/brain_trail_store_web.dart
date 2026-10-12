/// The browser implementation must use the web E2EE repository before writing.
/// Explicitly fail instead of persisting sensitive trail relationships in plaintext.
class BrainTrailStore {
  Future<List<Map<String, dynamic>>> load() async => <Map<String, dynamic>>[];

  Future<Map<String, dynamic>> create(
    String rootId,
    String name,
    String? ownerId,
  ) async => throw UnsupportedError(
    'Trilhas no Web requerem integração com o Vault E2EE Web.',
  );

  Future<Map<String, dynamic>> addNode(
    Map<String, dynamic> trail,
    String parentNodeId,
    String objectId,
  ) async => throw UnsupportedError(
    'Trilhas no Web requerem integração com o Vault E2EE Web.',
  );

  Future<Map<String, dynamic>> updateTrail(
    Map<String, dynamic> trail, {
    String? name,
    List<Map<String, dynamic>>? nodes,
  }) async => throw UnsupportedError('Trilhas Web: Vault E2EE não integrado.');

  Future<Map<String, dynamic>> renameNode(
    Map<String, dynamic> trail,
    String nodeId,
    String? displayName,
  ) async => throw UnsupportedError('Trilhas Web: Vault E2EE não integrado.');

  Future<Map<String, dynamic>> removeBranch(
    Map<String, dynamic> trail,
    String nodeId,
  ) async => throw UnsupportedError('Trilhas Web: Vault E2EE não integrado.');

  Future<Map<String, dynamic>> pruneMissingObjects(
    Map<String, dynamic> trail,
    Set<String> existingObjectIds,
  ) async => trail;
}
