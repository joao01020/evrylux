import '../models/brain_sync_payload.dart';

abstract class BrainSyncQueueWriter {
  const BrainSyncQueueWriter();

  Future<void> write(BrainSyncPayload payload);
}
