import 'package:flutter/foundation.dart';

import '../../models/brain_review_item.dart';

import '../mappers/brain_review_vault_mapper.dart';
import '../models/brain_review_vault_entry.dart';
import '../models/brain_vault_object_type.dart';
import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN REVIEW VAULT STORE
// ============================================================
//
// PERFORMANCE
//
// Antes:
//
// loadAllEncryptedObjects()
//      ↓
// para cada objeto
//      ↓
// await readObject(objectId)
//      ↓
// reabre Vault / relê objeto / obtém chave / decrypt
//      ↓
// processamento sequencial
//
// Agora:
//
// loadAllEncryptedObjects()
//      ↓
// remove tombstones
//      ↓
// decodeEncryptedObjects(concurrency: 12)
//      ↓
// Vault aberto uma vez
//      ↓
// Master Key obtida uma vez
//      ↓
// decrypt em lotes
//      ↓
// cache/índices somente em memória
//
// E2EE continua preservado:
// - payload não é persistido em plaintext;
// - verifyBinding continua dentro do BrainVaultService;
// - keyVersion continua validada;
// - tombstones continuam ignorados.
//
// ============================================================

class BrainReviewVaultStore {
  BrainReviewVaultStore({
    required BrainVaultService vaultService,
    BrainReviewVaultMapper mapper = const BrainReviewVaultMapper(),
  }) : _vaultService = vaultService,
       _mapper = mapper;

  final BrainVaultService _vaultService;
  final BrainReviewVaultMapper _mapper;

  static const int _decodeConcurrency = 12;

  List<
    BrainReviewVaultEntry
  >?
  _entryCache;

  Map<
    String,
    BrainReviewVaultEntry
  >?
  _entryByReviewId;

  Map<
    String,
    List<
      BrainReviewVaultEntry
    >
  >?
  _entriesByConceptId;

  Future<
    List<
      BrainReviewVaultEntry
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
    _entryCache = null;
    _entryByReviewId = null;
    _entriesByConceptId = null;
  }

  // ============================================================
  // LOAD REVIEWS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews({
    bool forceRefresh = false,
  }) async {
    final entries = await loadEntries(
      forceRefresh: forceRefresh,
    );

    final reviews = entries
        .map(
          (
            entry,
          ) => entry.review,
        )
        .toList(
          growable: false,
        );

    _sortReviews(
      reviews,
    );

    return reviews;
  }

  // ============================================================
  // LOAD ENTRIES
  // ============================================================

  Future<
    List<
      BrainReviewVaultEntry
    >
  >
  loadEntries({
    bool forceRefresh = false,
  }) {
    if (!forceRefresh) {
      final cached = _entryCache;

      if (cached !=
          null) {
        return SynchronousFuture<
          List<
            BrainReviewVaultEntry
          >
        >(
          List<
            BrainReviewVaultEntry
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

    final future = _loadEntriesFromVault();

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
      BrainReviewVaultEntry
    >
  >
  _loadEntriesFromVault() async {
    await initialize();

    final totalWatch = Stopwatch()..start();

    final rawWatch = Stopwatch()..start();

    final objects = await _vaultService.loadAllEncryptedObjects();

    rawWatch.stop();

    final activeObjects = objects
        .where(
          (
            object,
          ) => !object.isDeleted,
        )
        .toList(
          growable: false,
        );

    final decodeWatch = Stopwatch()..start();

    final decodedObjects = await _vaultService.decodeEncryptedObjects(
      activeObjects,
      concurrency: _decodeConcurrency,
    );

    decodeWatch.stop();

    final entries =
        <
          BrainReviewVaultEntry
        >[];

    final byReviewId =
        <
          String,
          BrainReviewVaultEntry
        >{};

    final byConceptId =
        <
          String,
          List<
            BrainReviewVaultEntry
          >
        >{};

    for (
      var index = 0;
      index <
          activeObjects.length;
      index++
    ) {
      final object = activeObjects[index];

      final decoded = decodedObjects[index];

      if (decoded ==
          null) {
        continue;
      }

      // Compatibilidade:
      // alguns payloads antigos podem ter model=brain_review.
      final model = decoded.data['model']?.toString().trim();

      final claimsReview =
          decoded.type ==
              BrainVaultObjectType.review ||
          model ==
              'brain_review';

      if (!claimsReview) {
        continue;
      }

      try {
        final review = _normalizeReview(
          _mapper.fromVaultData(
            decoded.data,
          ),
        );

        final entry = BrainReviewVaultEntry(
          objectId: object.header.objectId,
          review: review,
        );

        if (!entry.isValid) {
          throw const FormatException(
            'BrainReviewVaultEntry inválida.',
          );
        }

        entries.add(
          entry,
        );

        byReviewId[review.id] = entry;

        byConceptId
            .putIfAbsent(
              review.conceptId,
              () =>
                  <
                    BrainReviewVaultEntry
                  >[],
            )
            .add(
              entry,
            );
      } catch (
        error
      ) {
        debugPrint(
          '[BRAIN REVIEW VAULT] '
          'Review inválida ignorada: $error',
        );
      }
    }

    entries.sort(
      (
        first,
        second,
      ) {
        return _compareReviews(
          first.review,
          second.review,
        );
      },
    );

    totalWatch.stop();

    _entryCache =
        List<
          BrainReviewVaultEntry
        >.of(
          entries,
          growable: false,
        );

    _entryByReviewId = byReviewId;

    _entriesByConceptId = byConceptId;

    debugPrint(
      '[BRAIN REVIEW PERF] '
      'objetos=${objects.length} '
      'ativos=${activeObjects.length} '
      'reviews=${entries.length}',
    );

    debugPrint(
      '[BRAIN REVIEW PERF] '
      'loadAllEncryptedObjects=${rawWatch.elapsedMilliseconds}ms',
    );

    debugPrint(
      '[BRAIN REVIEW PERF] '
      'batch decode=${decodeWatch.elapsedMilliseconds}ms '
      '(concorrencia=$_decodeConcurrency)',
    );

    debugPrint(
      '[BRAIN REVIEW PERF] '
      'TOTAL=${totalWatch.elapsedMilliseconds}ms',
    );

    return List<
      BrainReviewVaultEntry
    >.unmodifiable(
      entries,
    );
  }

  // ============================================================
  // GET REVIEW BY ID
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReview(
    String id,
  ) async {
    final entry = await getEntry(
      id,
    );

    return entry?.review;
  }

  Future<
    BrainReviewVaultEntry?
  >
  getEntry(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    await loadEntries();

    return _entryByReviewId?[cleanId];
  }

  // ============================================================
  // GET REVIEW BY CONCEPT
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReviewByConceptId(
    String conceptId,
  ) async {
    final entry = await getEntryByConceptId(
      conceptId,
    );

    return entry?.review;
  }

  Future<
    BrainReviewVaultEntry?
  >
  getEntryByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return null;
    }

    await loadEntries();

    final entries = _entriesByConceptId?[cleanConceptId];

    if (entries ==
            null ||
        entries.isEmpty) {
      return null;
    }

    return entries.first;
  }

  Future<
    bool
  >
  hasReviewForConcept(
    String conceptId,
  ) async {
    final review = await getReviewByConceptId(
      conceptId,
    );

    return review !=
        null;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) async {
    await initialize();

    final normalized = _normalizeReview(
      review,
    );

    final existing = await getEntry(
      normalized.id,
    );

    final data = _mapper.toVaultData(
      normalized,
    );

    if (existing ==
        null) {
      await _vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: data,
      );
    } else {
      await _vaultService.updateObject(
        objectId: existing.objectId,
        type: BrainVaultObjectType.review,
        data: data,
      );
    }

    invalidateCache();

    return normalized;
  }

  Future<
    void
  >
  saveReviews(
    Iterable<
      BrainReviewItem
    >
    reviews,
  ) async {
    for (final review in reviews) {
      await saveReview(
        review,
      );
    }
  }

  // ============================================================
  // DELETE BY ID
  // ============================================================

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    final entry = await getEntry(
      cleanId,
    );

    if (entry ==
        null) {
      return;
    }

    await _vaultService.deleteObject(
      entry.objectId,
    );

    invalidateCache();
  }

  // ============================================================
  // DELETE BY CONCEPT ID
  // ============================================================

  Future<
    void
  >
  deleteReviewByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return;
    }

    await loadEntries();

    final matches =
        List<
          BrainReviewVaultEntry
        >.of(
          _entriesByConceptId?[cleanConceptId] ??
              const <
                BrainReviewVaultEntry
              >[],
        );

    if (matches.isEmpty) {
      return;
    }

    for (final entry in matches) {
      await _vaultService.deleteObject(
        entry.objectId,
      );
    }

    invalidateCache();
  }

  // ============================================================
  // DELETE BY SOURCE NOTE PATH
  // ============================================================

  Future<
    void
  >
  deleteReviewsBySourceNotePath(
    String sourceNotePath,
  ) async {
    final cleanPath = sourceNotePath.trim();

    if (cleanPath.isEmpty) {
      return;
    }

    final entries = await loadEntries();

    final matches = entries
        .where(
          (
            entry,
          ) {
            return entry.review.sourceNotePath.trim() ==
                cleanPath;
          },
        )
        .toList(
          growable: false,
        );

    if (matches.isEmpty) {
      return;
    }

    for (final entry in matches) {
      await _vaultService.deleteObject(
        entry.objectId,
      );
    }

    invalidateCache();
  }

  // ============================================================
  // DUE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadDueReviews({
    DateTime? now,
  }) async {
    final reference =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews
        .where(
          (
            review,
          ) {
            if (review.archived) {
              return false;
            }

            return !review.nextReviewAt.isAfter(
              reference,
            );
          },
        )
        .toList(
          growable: false,
        );

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // UPCOMING
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadUpcomingReviews({
    DateTime? now,
  }) async {
    final reference =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews
        .where(
          (
            review,
          ) {
            if (review.archived) {
              return false;
            }

            return review.nextReviewAt.isAfter(
              reference,
            );
          },
        )
        .toList(
          growable: false,
        );

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // ACTIVE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() async {
    final reviews = await loadReviews();

    final result = reviews
        .where(
          (
            review,
          ) => !review.archived,
        )
        .toList(
          growable: false,
        );

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // ARCHIVED
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() async {
    final reviews = await loadReviews();

    final result = reviews
        .where(
          (
            review,
          ) => review.archived,
        )
        .toList(
          growable: false,
        );

    result.sort(
      (
        first,
        second,
      ) {
        final firstDate =
            first.archivedAt ??
            first.createdAt;

        final secondDate =
            second.archivedAt ??
            second.createdAt;

        return secondDate.compareTo(
          firstDate,
        );
      },
    );

    return result;
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    final reviews = await loadReviews();

    return reviews.length;
  }

  // ============================================================
  // NORMALIZE
  // ============================================================

  BrainReviewItem _normalizeReview(
    BrainReviewItem review,
  ) {
    final id = review.id.trim();

    final conceptId = review.conceptId.trim();

    final question = review.question.trim();

    final answer = review.answer.trim();

    final sourceNotePath = review.sourceNotePath.trim();

    final sourceNoteTitle = review.sourceNoteTitle.trim();

    if (id.isEmpty) {
      throw StateError(
        'Revisão sem ID.',
      );
    }

    if (conceptId.isEmpty) {
      throw StateError(
        'Revisão sem conceptId.',
      );
    }

    if (question.isEmpty) {
      throw StateError(
        'Revisão sem pergunta.',
      );
    }

    if (answer.isEmpty) {
      throw StateError(
        'Revisão sem resposta.',
      );
    }

    if (sourceNotePath.isEmpty) {
      throw StateError(
        'Revisão sem caminho da anotação de origem.',
      );
    }

    return review.copyWith(
      id: id,
      conceptId: conceptId,
      question: question,
      answer: answer,
      sourceNotePath: sourceNotePath,
      sourceNoteTitle: sourceNoteTitle,
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sortReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) {
    reviews.sort(
      _compareReviews,
    );
  }

  int _compareReviews(
    BrainReviewItem first,
    BrainReviewItem second,
  ) {
    if (first.archived !=
        second.archived) {
      return first.archived
          ? 1
          : -1;
    }

    return first.nextReviewAt.compareTo(
      second.nextReviewAt,
    );
  }
}
