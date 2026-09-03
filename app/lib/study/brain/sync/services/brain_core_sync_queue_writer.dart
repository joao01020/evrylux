import '../../../../core/sync/sync_item.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';

import '../models/brain_sync_payload.dart';
import '../ports/brain_sync_queue_writer.dart';

// ============================================================
// CORE SYNC QUEUE WRITER
// ============================================================
//
// Usa sempre SyncOperation.update.
//
// Inclusive para tombstones.
//
// Motivo:
//
// o tombstone é um BrainVaultObject versionado e precisa chegar
// inteiro ao Supabase.
//
// Nunca usamos SyncOperation.delete para brain_e2ee_object.
//
// ============================================================

class CoreBrainSyncQueueWriter extends BrainSyncQueueWriter {
  CoreBrainSyncQueueWriter({required SyncQueue queue, SyncService? syncService})
    : _queue = queue,
      _syncService = syncService;

  final SyncQueue _queue;
  final SyncService? _syncService;

  @override
  Future<void> write(BrainSyncPayload payload) async {
    payload.validate();

    await _queue.enqueue(
      entityType: BrainSyncQueueServiceEntity.entityType,
      entityId: payload.objectId,
      operation: SyncOperation.update,
      payload: payload.toQueuePayload(),
    );

    _syncService?.requestSync();
  }
}

// ============================================================
// SHARED ENTITY CONSTANT
// ============================================================

abstract final class BrainSyncQueueServiceEntity {
  static const String entityType = 'brain_e2ee_object';
}
