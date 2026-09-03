import '../../settings/services/brain_data_mode_service.dart';
import '../../vault/models/brain_vault_object.dart';
import '../../vault/services/brain_vault_serializer.dart';
import '../../vault/services/brain_vault_service.dart';

import '../models/brain_sync_payload.dart';
import '../ports/brain_sync_queue_writer.dart';
import 'brain_core_sync_queue_writer.dart';

// ============================================================
// BRAIN SYNC QUEUE SERVICE
// ============================================================
//
// ÚNICA entrada permitida para a nova fila E2EE.
//
// Aceita:
//
// BrainVaultObject
//
// NÃO aceita:
//
// BrainReviewItem
// BrainFile
// Map de conteúdo lógico
// pergunta
// resposta
// título
// texto
//
// ============================================================

class BrainSyncQueueService {
  BrainSyncQueueService({
    required BrainDataModeService dataModeService,
    required BrainVaultService vaultService,
    required BrainSyncQueueWriter writer,
    BrainVaultSerializer? serializer,
  }) : _dataModeService = dataModeService,
       _vaultService = vaultService,
       _writer = writer,
       _serializer = serializer ?? const BrainVaultSerializer();

  static const String entityType = BrainSyncQueueServiceEntity.entityType;

  final BrainDataModeService _dataModeService;
  final BrainVaultService _vaultService;
  final BrainSyncQueueWriter _writer;
  final BrainVaultSerializer _serializer;

  // ============================================================
  // ENQUEUE ONE
  // ============================================================

  Future<bool> enqueueObject(BrainVaultObject object) async {
    await _ensureModeInitialized();

    if (!_dataModeService.allowsCloudSync) {
      return false;
    }

    final payload = BrainSyncPayload.fromVaultObject(
      object: object,
      serializer: _serializer,
    );

    await _writer.write(payload);

    return true;
  }

  // ============================================================
  // ENQUEUE ALL LOCAL VAULT OBJECTS
  // ============================================================
  //
  // V1:
  //
  // usado também como backfill seguro para objetos que existiam
  // antes da Fase 06.
  //
  // SyncQueue deduplica por entityType + entityId.
  //
  // ============================================================

  Future<int> enqueueAllVaultObjects() async {
    await _ensureModeInitialized();

    if (!_dataModeService.allowsCloudSync) {
      return 0;
    }

    final objects = await _vaultService.loadAllEncryptedObjects();

    var enqueued = 0;

    for (final object in objects) {
      final didEnqueue = await enqueueObject(object);

      if (didEnqueue) {
        enqueued++;
      }
    }

    return enqueued;
  }

  // ============================================================
  // MODE
  // ============================================================

  Future<void> _ensureModeInitialized() async {
    if (_dataModeService.isInitialized) {
      return;
    }

    await _dataModeService.initialize();
  }
}
