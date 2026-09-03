import '../models/brain_sync_payload.dart';

abstract class BrainRemoteObjectSource {
  const BrainRemoteObjectSource();

  Future<List<BrainSyncPayload>> loadVaultObjects({required String vaultId});
}
