import 'package:flutter/foundation.dart';

import '../../settings/services/brain_data_mode_service.dart';

import '../models/brain_cloud_pull_result.dart';
import 'brain_cloud_pull_service.dart';
import 'brain_sync_queue_service.dart';

// ============================================================
// BRAIN E2EE SYNC COORDINATOR
// ============================================================
//
// Orquestra:
//
// CLOUD AUTORIZADO:
//   gate completo
//   ↓
//   pull remoto
//   ↓
//   merge por object_version
//   ↓
//   enqueue de todo estado local criptografado
//
// CLOUD NÃO AUTORIZADO:
//   NÃO faz pull remoto
//   ↓
//   estado local continua válido
//   ↓
//   objetos criptografados ainda podem permanecer/preparar fila
//   ↓
//   SyncService também aplicará seu processingGate
//
// LOCAL:
//   nenhuma operação de nuvem
//
// ============================================================

class BrainE2eeSyncCoordinator {
  BrainE2eeSyncCoordinator({
    required BrainDataModeService dataModeService,
    required BrainSyncQueueService queueService,
    required BrainCloudPullService pullService,
    required Future<
      bool
    >
    Function()
    canUseCloudOperations,
  }) : _dataModeService = dataModeService,
       _queueService = queueService,
       _pullService = pullService,
       _canUseCloudOperations = canUseCloudOperations;

  final BrainDataModeService _dataModeService;

  final BrainSyncQueueService _queueService;

  final BrainCloudPullService _pullService;

  // ============================================================
  // CLOUD SECURITY GATE
  // ============================================================
  //
  // Deve responder true somente quando:
  //
  // - modo Cloud está habilitado;
  // - usuário está autenticado;
  // - Vault local é válido;
  // - Master Key local existe;
  // - identidade local do dispositivo existe;
  // - dispositivo está authorized no backend.
  //
  // Qualquer erro deve resultar em false.
  //
  // ============================================================

  final Future<
    bool
  >
  Function()
  _canUseCloudOperations;

  // ============================================================
  // BOOTSTRAP
  // ============================================================
  //
  // Nunca derruba o modo local-first por indisponibilidade de
  // rede.
  //
  // O PULL remoto só acontece depois do gate de dispositivo.
  //
  // Mesmo quando o gate bloqueia o remoto, o estado criptografado
  // local pode ser preparado na SyncQueue. O SyncService aplicará
  // novamente o processingGate antes de transmitir.
  //
  // ============================================================

  Future<
    void
  >
  bootstrap() async {
    if (!_dataModeService.isInitialized) {
      await _dataModeService.initialize();
    }

    // ----------------------------------------------------------
    // LOCAL
    // ----------------------------------------------------------

    if (!_dataModeService.allowsCloudSync) {
      return;
    }

    // ----------------------------------------------------------
    // CLOUD REMOTE GATE
    // ----------------------------------------------------------

    final canUseRemote = await _safeCanUseCloudOperations();

    if (canUseRemote) {
      try {
        final result = await _pullService.pullCurrentVault();

        debugPrint(
          '[BRAIN E2EE] Pull: $result',
        );
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          '[BRAIN E2EE] '
          'Pull indisponível; mantendo estado local: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }
    } else {
      debugPrint(
        '[BRAIN E2EE] '
        'Pull remoto bloqueado pelo gate de dispositivo.',
      );
    }

    // ----------------------------------------------------------
    // PREPARE LOCAL ENCRYPTED QUEUE
    // ----------------------------------------------------------
    //
    // Isto NÃO é operação remota.
    //
    // Caso o dispositivo esteja pending/revoked/offline,
    // a fila pode continuar existindo localmente.
    //
    // O SyncService não transmitirá brain_e2ee_object enquanto
    // seu processingGate retornar false.
    //
    // ----------------------------------------------------------

    final enqueued = await _queueService.enqueueAllVaultObjects();

    debugPrint(
      '[BRAIN E2EE] '
      '$enqueued objetos criptografados '
      'preparados para sync.',
    );
  }

  // ============================================================
  // MANUAL PULL
  // ============================================================
  //
  // Também protegido pelo MESMO gate do Cloud.
  //
  // Não existe caminho alternativo de pull apenas por estar
  // autenticado.
  //
  // ============================================================

  Future<
    BrainCloudPullResult?
  >
  pullNow() async {
    if (!_dataModeService.isInitialized) {
      await _dataModeService.initialize();
    }

    if (!_dataModeService.allowsCloudSync) {
      return null;
    }

    final canUseRemote = await _safeCanUseCloudOperations();

    if (!canUseRemote) {
      debugPrint(
        '[BRAIN E2EE] '
        'Pull manual bloqueado pelo gate de dispositivo.',
      );

      return null;
    }

    try {
      return await _pullService.pullCurrentVault();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN E2EE] '
        'Pull manual indisponível; mantendo estado local: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ============================================================
  // QUEUE ALL
  // ============================================================
  //
  // Operação exclusivamente local.
  //
  // Não chama Supabase.
  //
  // ============================================================

  Future<
    int
  >
  queueAllLocal() {
    return _queueService.enqueueAllVaultObjects();
  }

  // ============================================================
  // SAFE CLOUD GATE
  // ============================================================
  //
  // Defesa adicional:
  //
  // mesmo que o callback do app lance uma exceção, o coordinator
  // falha fechado e não toca no remoto.
  //
  // ============================================================

  Future<
    bool
  >
  _safeCanUseCloudOperations() async {
    try {
      return await _canUseCloudOperations();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN E2EE] '
        'Gate Cloud indisponível; acesso remoto bloqueado: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    }
  }
}
