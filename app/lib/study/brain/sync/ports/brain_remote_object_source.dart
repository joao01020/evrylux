import '../models/brain_remote_deletion_floor.dart';
import '../models/brain_sync_payload.dart';

abstract class BrainRemoteObjectSource {
  const BrainRemoteObjectSource();

  Future<List<BrainSyncPayload>> loadVaultObjects({required String vaultId});

  /// Phase 3: durable technical deletion floors that survive remote tombstone GC.
  /// Existing test fakes/alternate remotes remain compatible by defaulting empty.
  Future<List<BrainRemoteDeletionFloor>> loadDeletionFloors({
    required String vaultId,
  }) async {
    return const <BrainRemoteDeletionFloor>[];
  }
}
