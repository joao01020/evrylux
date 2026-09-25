import 'package:flutter/foundation.dart';

import '../../models/brain_concept.dart';

import '../mappers/brain_concept_vault_mapper.dart';
import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_type.dart';
import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN CONCEPT VAULT STORE
// ============================================================
//
// OTIMIZAÇÃO DE PERFORMANCE
//
// O problema anterior estava em:
//
// loadAllEncryptedObjects()
//        ↓
// for objeto por objeto
//        ↓
// await readObject(id)
//        ↓
// reabre Vault / relê objeto / obtém chave / descriptografa
//        ↓
// tudo sequencial
//
// Com ~127 objetos isso podia chegar a mais de 13 segundos.
//
// Agora:
//
// loadAllEncryptedObjects()
//        ↓
// mantém somente objetos ativos em memória
//        ↓
// decodeEncryptedObjects()
//        ↓
// abre Vault UMA vez
//        ↓
// obtém Master Key UMA vez
//        ↓
// descriptografa em lotes concorrentes
//
// SEGURANÇA PRESERVADA:
//
// - E2EE continua obrigatório;
// - verifyBinding continua executado pelo BrainVaultService;
// - keyVersion continua validada;
// - nenhum payload descriptografado é persistido aqui;
// - tombstones continuam ignorados.
//
// ============================================================

class BrainConceptVaultStore {
  BrainConceptVaultStore({
    required BrainVaultService vaultService,
    BrainConceptVaultMapper mapper = const BrainConceptVaultMapper(),
  }) : _vaultService = vaultService,
       _mapper = mapper;

  final BrainVaultService _vaultService;
  final BrainConceptVaultMapper _mapper;

  // ============================================================
  // PERFORMANCE
  // ============================================================

  static const int _decodeConcurrency = 12;

  // ============================================================
  // CACHE DE SESSÃO
  // ============================================================
  //
  // Cache somente em memória.
  //
  // Serve para evitar uma segunda varredura completa do Vault quando
  // a página é reaberta durante a mesma sessão.
  //
  // Toda operação de escrita/exclusão invalida o cache.
  //
  // ============================================================

  List<
    BrainConcept
  >?
  _conceptCache;

  Map<
    String,
    BrainVaultObject
  >?
  _conceptObjectByConceptId;

  Future<
    List<
      BrainConcept
    >
  >?
  _loadFuture;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    await _vaultService.getOrCreateVault();
  }

  // ============================================================
  // CACHE
  // ============================================================

  void invalidateCache() {
    _conceptCache = null;
    _conceptObjectByConceptId = null;
  }

  // ============================================================
  // SAVE / UPSERT
  // ============================================================

  Future<
    BrainVaultObject
  >
  saveConcept({
    required BrainConcept concept,
    String? sourceNotePath,
  }) async {
    await initialize();

    final data = _mapper.toVaultData(
      concept: concept,
      sourceNotePath: sourceNotePath,
    );

    final existing = await findEncryptedObjectByConceptId(
      concept.id,
    );

    if (existing ==
        null) {
      final created = await _vaultService.createObject(
        type: BrainVaultObjectType.concept,
        data: data,
      );

      invalidateCache();

      return created;
    }

    final decoded = await _vaultService.decodeEncryptedObject(
      existing,
    );

    if (decoded !=
            null &&
        _deepEqual(
          decoded.data,
          data,
        )) {
      return existing;
    }

    final updated = await _vaultService.updateObject(
      objectId: existing.header.objectId,
      type: BrainVaultObjectType.concept,
      data: data,
    );

    invalidateCache();

    return updated;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadConcepts({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = _conceptCache;

      if (cached !=
          null) {
        return SynchronousFuture<
          List<
            BrainConcept
          >
        >(
          List<
            BrainConcept
          >.unmodifiable(
            cached,
          ),
        );
      }

      final running = _loadFuture;

      if (running !=
          null) {
        return running;
      }
    }

    final future = _loadConceptsFromVault();

    _loadFuture = future;

    return future.whenComplete(
      () {
        if (identical(
          _loadFuture,
          future,
        )) {
          _loadFuture = null;
        }
      },
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  _loadConceptsFromVault() async {
    await initialize();

    final totalWatch = Stopwatch()..start();

    // ==========================================================
    // 1. CARREGAR OBJETOS CRIPTOGRAFADOS
    // ==========================================================

    final rawWatch = Stopwatch()..start();

    final objects = await _vaultService.loadAllEncryptedObjects();

    rawWatch.stop();

    // Tombstones não precisam sequer entrar no batch de decrypt.
    final activeObjects = objects
        .where(
          (
            object,
          ) => !object.isDeleted,
        )
        .toList(
          growable: false,
        );

    // ==========================================================
    // 2. DECODE EM LOTE
    // ==========================================================
    //
    // Ponto principal da otimização.
    //
    // NÃO usamos:
    //
    // for (...) {
    //   await _vaultService.readObject(id);
    // }
    //
    // Isso era N chamadas sequenciais.
    //
    // ==========================================================

    final decodeWatch = Stopwatch()..start();

    final decodedObjects = await _vaultService.decodeEncryptedObjects(
      activeObjects,
      concurrency: _decodeConcurrency,
    );

    decodeWatch.stop();

    // ==========================================================
    // 3. MAPEAR SOMENTE CONCEITOS
    // ==========================================================

    final result =
        <
          BrainConcept
        >[];

    final objectIndex =
        <
          String,
          BrainVaultObject
        >{};

    for (
      var index = 0;
      index <
          activeObjects.length;
      index++
    ) {
      final decoded = decodedObjects[index];

      if (decoded ==
              null ||
          decoded.type !=
              BrainVaultObjectType.concept) {
        continue;
      }

      try {
        final concept = _mapper.fromVaultData(
          decoded.data,
        );

        result.add(
          concept,
        );

        final conceptId = concept.id.trim();

        if (conceptId.isNotEmpty) {
          objectIndex[conceptId] = activeObjects[index];
        }
      } catch (
        error
      ) {
        debugPrint(
          '[BRAIN CONCEPT VAULT] '
          'Objeto incompatível ignorado: $error',
        );
      }
    }

    totalWatch.stop();

    _conceptCache =
        List<
          BrainConcept
        >.of(
          result,
          growable: false,
        );

    _conceptObjectByConceptId = objectIndex;

    debugPrint(
      '[BRAIN CONCEPT PERF] '
      'objetos=${objects.length} '
      'ativos=${activeObjects.length} '
      'conceitos=${result.length}',
    );

    debugPrint(
      '[BRAIN CONCEPT PERF] '
      'loadAllEncryptedObjects=${rawWatch.elapsedMilliseconds}ms',
    );

    debugPrint(
      '[BRAIN CONCEPT PERF] '
      'batch decode=${decodeWatch.elapsedMilliseconds}ms '
      '(concorrencia=$_decodeConcurrency)',
    );

    debugPrint(
      '[BRAIN CONCEPT PERF] '
      'TOTAL=${totalWatch.elapsedMilliseconds}ms',
    );

    return List<
      BrainConcept
    >.unmodifiable(
      result,
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadConceptsByType(
    BrainConceptType type, {
    bool forceRefresh = false,
  }) async {
    final concepts = await loadConcepts(
      forceRefresh: forceRefresh,
    );

    return concepts
        .where(
          (
            concept,
          ) =>
              concept.type ==
              type,
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET CONCEPT
  // ============================================================

  Future<
    BrainConcept?
  >
  getConcept(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    // ==========================================================
    // CACHE HIT
    // ==========================================================

    final cached = _conceptCache;

    if (cached !=
        null) {
      for (final concept in cached) {
        if (concept.id.trim() ==
            cleanId) {
          return concept;
        }
      }
    }

    // ==========================================================
    // CACHE MISS
    // ==========================================================

    final object = await findEncryptedObjectByConceptId(
      cleanId,
    );

    if (object ==
            null ||
        object.isDeleted) {
      return null;
    }

    final decoded = await _vaultService.decodeEncryptedObject(
      object,
    );

    if (decoded ==
            null ||
        decoded.type !=
            BrainVaultObjectType.concept) {
      return null;
    }

    return _mapper.fromVaultData(
      decoded.data,
    );
  }

  // ============================================================
  // FIND RAW
  // ============================================================

  Future<
    BrainVaultObject?
  >
  findEncryptedObjectByConceptId(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    // ==========================================================
    // ÍNDICE EM MEMÓRIA
    // ==========================================================

    final indexed = _conceptObjectByConceptId?[cleanId];

    if (indexed !=
            null &&
        !indexed.isDeleted) {
      return indexed;
    }

    // ==========================================================
    // CONSTRUIR ÍNDICE
    // ==========================================================
    //
    // Se ainda não houve loadConcepts(), aproveitamos a mesma carga
    // otimizada para montar o índice inteiro uma única vez.
    //
    // ==========================================================

    await loadConcepts();

    final fromIndex = _conceptObjectByConceptId?[cleanId];

    if (fromIndex ==
            null ||
        fromIndex.isDeleted) {
      return null;
    }

    return fromIndex;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    BrainVaultObject?
  >
  deleteConcept(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final object = await findEncryptedObjectByConceptId(
      cleanId,
    );

    if (object ==
        null) {
      return null;
    }

    final deleted = await _vaultService.deleteObject(
      object.header.objectId,
    );

    invalidateCache();

    return deleted;
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  bool _deepEqual(
    dynamic first,
    dynamic second,
  ) {
    if (identical(
      first,
      second,
    )) {
      return true;
    }

    if (first
            is Map &&
        second
            is Map) {
      if (first.length !=
          second.length) {
        return false;
      }

      for (final key in first.keys) {
        if (!second.containsKey(
          key,
        )) {
          return false;
        }

        if (!_deepEqual(
          first[key],
          second[key],
        )) {
          return false;
        }
      }

      return true;
    }

    if (first
            is Iterable &&
        second
            is Iterable) {
      final firstList = first.toList();

      final secondList = second.toList();

      if (firstList.length !=
          secondList.length) {
        return false;
      }

      for (
        var index = 0;
        index <
            firstList.length;
        index++
      ) {
        if (!_deepEqual(
          firstList[index],
          secondList[index],
        )) {
          return false;
        }
      }

      return true;
    }

    return first ==
        second;
  }
}
