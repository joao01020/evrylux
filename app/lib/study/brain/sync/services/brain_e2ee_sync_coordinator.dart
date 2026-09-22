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
//   decide se realmente precisa fazer backfill local
//
// CLOUD NÃO AUTORIZADO:
//   NÃO faz pull remoto
//   ↓
//   estado local continua válido
//   ↓
//   prepara fila local como fallback seguro
//   ↓
//   SyncService também aplicará seu processingGate
//
// LOCAL:
//   nenhuma operação de nuvem
//
// ============================================================
//
// OTIMIZAÇÃO DE STARTUP
// ============================================================
//
// Antes:
//
// toda inicialização em Cloud fazia:
//
// pull remoto
//   ↓
// enqueueAllVaultObjects()
//   ↓
// todos os objetos locais eram reenviados,
// mesmo quando o servidor já possuía a mesma versão.
//
// Agora:
//
// 1. se o pull confirmar que o remoto já possui os mesmos objetos
//    e não há objeto local mais novo, NÃO fazemos backfill completo;
//
// 2. se o remoto estiver vazio, fazemos backfill completo;
//
// 3. se o pull detectar objeto local mais novo que o remoto,
//    fazemos backfill completo para garantir o push;
//
// 4. se o pull falhar ou o gate bloquear o remoto,
//    preservamos o comportamento seguro anterior e preparamos a fila;
//
// 5. saves/updates/deletes normais continuam sendo enfileirados no
//    momento da alteração pelo BrainRepository/BrainSyncQueueService.
//
// IMPORTANTE:
//
// queueAllLocal() continua disponível como operação explícita de
// recovery/backfill.
//
// ============================================================

class BrainE2eeSyncCoordinator {
  BrainE2eeSyncCoordinator({
    required BrainDataModeService dataModeService,
    required BrainSyncQueueService queueService,
    required BrainCloudPullService pullService,
    required Future<bool> Function() canUseCloudOperations,
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

  final Future<bool> Function() _canUseCloudOperations;

  // ============================================================
  // BOOTSTRAP
  // ============================================================
  //
  // Nunca derruba o modo local-first por indisponibilidade de
  // rede.
  //
  // O PULL remoto só acontece depois do gate de dispositivo.
  //
  // A diferença desta versão é que NÃO fazemos mais
  // enqueueAllVaultObjects() incondicionalmente após um pull
  // saudável que mostrou estado remoto equivalente.
  //
  // ============================================================

  Future<void> bootstrap() async {
    if (!_dataModeService.isInitialized) {
      await _dataModeService.initialize();
    }

    // ----------------------------------------------------------
    // LOCAL
    // ----------------------------------------------------------

    if (!_dataModeService.allowsCloudSync) {
      debugPrint(
        '[BRAIN E2EE] '
        'Bootstrap Cloud ignorado: modo Local.',
      );

      return;
    }

    // ----------------------------------------------------------
    // CLOUD REMOTE GATE
    // ----------------------------------------------------------

    final canUseRemote = await _safeCanUseCloudOperations();

    BrainCloudPullResult? pullResult;

    var pullSucceeded = false;

    if (canUseRemote) {
      try {
        pullResult = await _pullService.pullCurrentVault();

        pullSucceeded = true;

        debugPrint('[BRAIN E2EE] Pull: $pullResult');
      } catch (error, stackTrace) {
        debugPrint(
          '[BRAIN E2EE] '
          'Pull indisponível; mantendo estado local: $error',
        );

        debugPrintStack(stackTrace: stackTrace);
      }
    } else {
      debugPrint(
        '[BRAIN E2EE] '
        'Pull remoto bloqueado pelo gate de dispositivo.',
      );
    }

    // ----------------------------------------------------------
    // DECIDIR BACKFILL LOCAL
    // ----------------------------------------------------------
    //
    // O fluxo normal de escrita já enfileira mudanças no instante
    // em que elas acontecem.
    //
    // Portanto, após um pull bem-sucedido, não precisamos empurrar
    // novamente todo o Vault se o remoto já estiver equivalente.
    //
    // Fazemos backfill completo somente quando existe uma razão
    // concreta para isso.
    //
    // ----------------------------------------------------------

    final shouldBackfill = _shouldBackfillLocalVault(
      canUseRemote: canUseRemote,
      pullSucceeded: pullSucceeded,
      pullResult: pullResult,
    );

    if (!shouldBackfill) {
      debugPrint(
        '[BRAIN E2EE] '
        'Backfill ignorado: estado remoto já equivalente '
        'e nenhuma versão local mais nova foi detectada.',
      );

      return;
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
  // SHOULD BACKFILL LOCAL VAULT
  // ============================================================
  //
  // Regras conservadoras:
  //
  // 1. gate bloqueado
  //    -> mantém comportamento anterior;
  //    -> prepara fila local;
  //
  // 2. pull falhou
  //    -> não sabemos o estado remoto;
  //    -> prepara fila local;
  //
  // 3. remoto vazio
  //    -> precisamos publicar o Vault local;
  //
  // 4. existe objeto local mais novo
  //    -> precisamos garantir push;
  //
  // 5. remoto respondeu e não há local mais novo
  //    -> não faz backfill completo;
  //    -> mudanças normais já estão/persistem na SyncQueue.
  //
  // ============================================================

  bool _shouldBackfillLocalVault({
    required bool canUseRemote,
    required bool pullSucceeded,
    required BrainCloudPullResult? pullResult,
  }) {
    if (!canUseRemote) {
      return true;
    }

    if (!pullSucceeded || pullResult == null) {
      return true;
    }

    if (!pullResult.hasRemoteState) {
      return true;
    }

    if (pullResult.skippedNewerLocal > 0) {
      return true;
    }

    return false;
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
  // IMPORTANTE:
  //
  // pullNow() NÃO faz backfill automático.
  //
  // O método representa apenas o pull explícito.
  //
  // Para recovery/backfill completo existe queueAllLocal().
  //
  // ============================================================

  Future<BrainCloudPullResult?> pullNow() async {
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
      final result = await _pullService.pullCurrentVault();

      debugPrint('[BRAIN E2EE] Pull manual: $result');

      return result;
    } catch (error, stackTrace) {
      debugPrint(
        '[BRAIN E2EE] '
        'Pull manual indisponível; mantendo estado local: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

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
  // Deve ser usada para:
  //
  // - recovery;
  // - backfill manual;
  // - manutenção;
  // - migração;
  // - diagnóstico.
  //
  // ============================================================

  Future<int> queueAllLocal({
    void Function(int completed, int total)? onProgress,
  }) {
    return _queueService.enqueueAllVaultObjects(onProgress: onProgress);
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

  Future<bool> _safeCanUseCloudOperations() async {
    try {
      return await _canUseCloudOperations();
    } catch (error, stackTrace) {
      debugPrint(
        '[BRAIN E2EE] '
        'Gate Cloud indisponível; acesso remoto bloqueado: $error',
      );

      debugPrintStack(stackTrace: stackTrace);

      return false;
    }
  }
}
