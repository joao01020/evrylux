import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../database/daos/sync_queue_dao.dart';
import 'sync_item.dart';

class SyncQueue {
  SyncQueue({
    SyncQueueDao? dao,
  }) : _dao =
           dao ??
           SyncQueueDao();

  // ============================================================
  // DAO
  // ============================================================

  final SyncQueueDao _dao;

  // ============================================================
  // ENQUEUE
  // ============================================================
  //
  // A fila é deduplicada por:
  //
  // entityType + entityId
  //
  // Isso significa que várias alterações consecutivas do mesmo
  // objeto viram apenas uma operação pendente.
  //
  // Exemplos:
  //
  // CREATE + UPDATE
  //   -> CREATE
  //
  // CREATE + DELETE
  //   -> cancela tudo
  //
  // UPDATE + UPDATE
  //   -> UPDATE mais recente
  //
  // UPDATE + DELETE
  //   -> DELETE
  //
  // DELETE + CREATE
  //   -> UPDATE
  //
  // ============================================================

  Future<
    SyncItem
  >
  enqueue({
    required String entityType,
    required String entityId,
    required SyncOperation operation,
    Map<
          String,
          dynamic
        >
        payload =
        const <
          String,
          dynamic
        >{},
  }) async {
    final normalizedEntityType = entityType.trim();

    final normalizedEntityId = entityId.trim();

    _validateEntity(
      normalizedEntityType,
      normalizedEntityId,
    );

    final now = DateTime.now().toUtc();

    // ==========================================================
    // OPERAÇÃO EXISTENTE
    // ==========================================================

    final existing = await _dao.findByEntity(
      entityType: normalizedEntityType,
      entityId: normalizedEntityId,
    );

    // ==========================================================
    // RESOLVE OPERAÇÃO
    // ==========================================================

    final resolvedOperation = _resolveOperation(
      existing: existing,
      incoming: operation,
    );

    // ==========================================================
    // CREATE + DELETE
    // ==========================================================
    //
    // O objeto foi criado localmente e excluído antes de ser
    // enviado para o servidor.
    //
    // Não existe motivo para transmitir nenhuma das operações.
    //
    // ==========================================================

    if (resolvedOperation ==
        null) {
      if (existing !=
          null) {
        await _dao.delete(
          existing.id,
        );

        debugPrint(
          '[SYNC QUEUE] '
          '${existing.entityType}/'
          '${existing.entityId}: '
          'CREATE + DELETE cancelados.',
        );
      }

      return SyncItem(
        id:
            existing?.id ??
            _newId(),
        entityType: normalizedEntityType,
        entityId: normalizedEntityId,
        operation: operation,
        payload:
            Map<
              String,
              dynamic
            >.from(
              payload,
            ),
        createdAt:
            existing?.createdAt ??
            now,
        updatedAt: now,
        attempts: 0,
        lastError: null,
        nextAttemptAt: null,
      );
    }

    // ==========================================================
    // MERGE PAYLOAD
    // ==========================================================
    //
    // Mantemos valores antigos que não foram enviados novamente
    // e sobrescrevemos apenas os novos.
    //
    // ==========================================================

    final resolvedPayload =
        <
          String,
          dynamic
        >{
          if (existing !=
              null)
            ...existing.payload,

          ...payload,
        };

    // ==========================================================
    // ITEM FINAL
    // ==========================================================
    //
    // Qualquer nova alteração do objeto:
    //
    // - zera attempts;
    // - remove lastError;
    // - remove nextAttemptAt.
    //
    // Assim uma alteração nova não fica esperando o backoff de
    // uma versão anterior do objeto.
    //
    // ==========================================================

    final item = SyncItem(
      id:
          existing?.id ??
          _newId(),
      entityType: normalizedEntityType,
      entityId: normalizedEntityId,
      operation: resolvedOperation,
      payload: resolvedPayload,
      createdAt:
          existing?.createdAt ??
          now,
      updatedAt: now,
      attempts: 0,
      lastError: null,
      nextAttemptAt: null,
    );

    // ==========================================================
    // PERSISTÊNCIA
    // ==========================================================

    await _dao.upsert(
      item,
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Enfileirado: '
      '$normalizedEntityType/'
      '$normalizedEntityId '
      '(${resolvedOperation.name})',
    );

    return item;
  }

  // ============================================================
  // GET PENDING
  // ============================================================
  //
  // Retorna somente itens que podem ser tentados agora.
  //
  // Itens aguardando exponential backoff não entram.
  //
  // ============================================================

  Future<
    List<
      SyncItem
    >
  >
  getPending({
    int limit = 100,
  }) async {
    if (limit <=
        0) {
      return const <
        SyncItem
      >[];
    }

    return _dao.getReady(
      limit: limit,
    );
  }

  // ============================================================
  // GET ALL
  // ============================================================

  Future<
    List<
      SyncItem
    >
  >
  getAll() async {
    return _dao.getAll();
  }

  // ============================================================
  // FIND BY ID
  // ============================================================

  Future<
    SyncItem?
  >
  findById(
    String id,
  ) async {
    return _dao.findById(
      id,
    );
  }

  // ============================================================
  // FIND BY ENTITY
  // ============================================================

  Future<
    SyncItem?
  >
  findByEntity({
    required String entityType,
    required String entityId,
  }) async {
    final normalizedEntityType = entityType.trim();

    final normalizedEntityId = entityId.trim();

    if (normalizedEntityType.isEmpty ||
        normalizedEntityId.isEmpty) {
      return null;
    }

    return _dao.findByEntity(
      entityType: normalizedEntityType,
      entityId: normalizedEntityId,
    );
  }

  // ============================================================
  // MARK SUCCESS
  // ============================================================

  Future<
    void
  >
  markSuccess(
    String id,
  ) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    await _dao.delete(
      normalizedId,
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Sincronização concluída: '
      '$normalizedId',
    );
  }

  // ============================================================
  // MARK FAILED
  // ============================================================
  //
  // Exponential backoff:
  //
  // tentativa 1 -> 2s
  // tentativa 2 -> 4s
  // tentativa 3 -> 8s
  // tentativa 4 -> 16s
  // ...
  //
  // Máximo:
  //
  // 300 segundos
  //
  // ============================================================

  Future<
    void
  >
  markFailed({
    required String id,
    required Object error,
  }) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    final currentAttempts = await _dao.getAttempts(
      normalizedId,
    );

    // O item pode ter sido removido enquanto a operação
    // remota estava em andamento.
    if (currentAttempts ==
        null) {
      return;
    }

    final attempts =
        currentAttempts +
        1;

    final retryDelay = _retryDelay(
      attempts,
    );

    final nextAttemptAt = DateTime.now().toUtc().add(
      retryDelay,
    );

    await _dao.markFailed(
      id: normalizedId,
      attempts: attempts,
      error: error,
      nextAttemptAt: nextAttemptAt,
    );

    debugPrint(
      '[SYNC QUEUE] '
      'Falha em $normalizedId. '
      'Tentativa $attempts. '
      'Nova tentativa em '
      '${retryDelay.inSeconds}s. '
      'Erro: $error',
    );
  }

  // ============================================================
  // RETRY DELAY
  // ============================================================

  Duration _retryDelay(
    int attempts,
  ) {
    final safeAttempts = attempts.clamp(
      1,
      8,
    );

    final seconds = pow(
      2,
      safeAttempts,
    ).toInt();

    return Duration(
      seconds: seconds.clamp(
        2,
        300,
      ),
    );
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<
    void
  >
  remove(
    String id,
  ) async {
    await _dao.delete(
      id,
    );
  }

  // ============================================================
  // REMOVE BY ENTITY
  // ============================================================

  Future<
    void
  >
  removeByEntity({
    required String entityType,
    required String entityId,
  }) async {
    await _dao.deleteByEntity(
      entityType: entityType,
      entityId: entityId,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    await _dao.clear();

    debugPrint(
      '[SYNC QUEUE] '
      'Fila limpa.',
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    return _dao.count();
  }

  // ============================================================
  // COUNT READY
  // ============================================================

  Future<
    int
  >
  countReady() async {
    return _dao.countReady();
  }

  // ============================================================
  // HAS PENDING
  // ============================================================

  Future<
    bool
  >
  get hasPending async {
    return _dao.hasPending;
  }

  // ============================================================
  // HAS READY
  // ============================================================

  Future<
    bool
  >
  get hasReady async {
    return _dao.hasReady;
  }

  // ============================================================
  // RESOLVE OPERATION
  // ============================================================
  //
  // Consolida operações repetidas para reduzir chamadas remotas.
  //
  // ============================================================

  SyncOperation? _resolveOperation({
    required SyncItem? existing,
    required SyncOperation incoming,
  }) {
    if (existing ==
        null) {
      return incoming;
    }

    switch (existing.operation) {
      // ========================================================
      // EXISTING CREATE
      // ========================================================

      case SyncOperation.create:
        switch (incoming) {
          case SyncOperation.create:
          case SyncOperation.update:
            return SyncOperation.create;

          case SyncOperation.delete:
            return null;
        }

      // ========================================================
      // EXISTING UPDATE
      // ========================================================

      case SyncOperation.update:
        switch (incoming) {
          case SyncOperation.create:
          case SyncOperation.update:
            return SyncOperation.update;

          case SyncOperation.delete:
            return SyncOperation.delete;
        }

      // ========================================================
      // EXISTING DELETE
      // ========================================================

      case SyncOperation.delete:
        switch (incoming) {
          case SyncOperation.create:
            // O objeto foi excluído e depois recriado.
            //
            // Do ponto de vista do servidor, o estado final
            // desejado é novamente um objeto existente.
            return SyncOperation.update;

          case SyncOperation.update:
          case SyncOperation.delete:
            return SyncOperation.delete;
        }
    }
  }

  // ============================================================
  // VALIDATE ENTITY
  // ============================================================

  void _validateEntity(
    String entityType,
    String entityId,
  ) {
    if (entityType.isEmpty) {
      throw ArgumentError(
        'entityType não pode ser vazio.',
      );
    }

    if (entityId.isEmpty) {
      throw ArgumentError(
        'entityId não pode ser vazio.',
      );
    }
  }

  // ============================================================
  // NEW ID
  // ============================================================

  String _newId() {
    final random = Random.secure();

    final time = DateTime.now().microsecondsSinceEpoch;

    final entropy =
        List<
          int
        >.generate(
          8,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    final suffix =
        base64UrlEncode(
          entropy,
        ).replaceAll(
          '=',
          '',
        );

    return 'sync_${time}_$suffix';
  }
}
