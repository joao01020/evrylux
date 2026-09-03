import '../../models/brain_review_item.dart';

import '../mappers/brain_review_vault_mapper.dart';

import '../models/brain_review_vault_entry.dart';
import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_type.dart';

import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN REVIEW VAULT STORE
// ============================================================
//
// Camada especializada em BrainReviewItem.
//
// Arquitetura:
//
// ReviewRepository
//      ↓
// BrainReviewVaultStore
//      ↓
// BrainReviewVaultMapper
//      ↓
// BrainVaultService
//      ↓
// Vault criptografado
//
// ============================================================
//
// RESPONSABILIDADES:
//
// - inicializar o Vault;
// - criar revisão;
// - atualizar revisão;
// - carregar revisões;
// - buscar revisão por ID;
// - buscar revisão por conceptId;
// - excluir revisão usando tombstone;
// - esconder objectId do ReviewRepository quando possível.
//
// ============================================================
//
// NÃO:
//
// - conhece Supabase;
// - conhece SyncQueue;
// - conhece ReviewStorage legado;
// - conhece autenticação;
// - armazena plaintext fora do Vault.
//
// ============================================================

class BrainReviewVaultStore {
  BrainReviewVaultStore({
    required BrainVaultService vaultService,
    BrainReviewVaultMapper mapper = const BrainReviewVaultMapper(),
  }) : _vaultService = vaultService,
       _mapper = mapper;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainVaultService _vaultService;

  final BrainReviewVaultMapper _mapper;

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
  // LOAD ALL
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() async {
    final entries = await loadEntries();

    final reviews = entries.map(
      (
        entry,
      ) {
        return entry.review;
      },
    ).toList();

    _sortReviews(
      reviews,
    );

    return reviews;
  }

  // ============================================================
  // LOAD ENTRIES
  // ============================================================
  //
  // Nesta primeira versão ainda não existe um índice próprio:
  //
  // review.id -> objectId
  //
  // Portanto percorremos os objetos ativos do Vault.
  //
  // Isso é proposital nesta etapa.
  //
  // Depois poderemos introduzir um índice persistente sem alterar
  // a API pública deste Store.
  //
  // ============================================================

  Future<
    List<
      BrainReviewVaultEntry
    >
  >
  loadEntries() async {
    await initialize();

    final objects = await _vaultService.loadAllEncryptedObjects();

    final entries =
        <
          BrainReviewVaultEntry
        >[];

    for (final object in objects) {
      if (object.isDeleted) {
        continue;
      }

      final entry = await _decodeReviewObject(
        object,
      );

      if (entry ==
          null) {
        continue;
      }

      entries.add(
        entry,
      );
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

    return entries;
  }

  // ============================================================
  // GET REVIEW
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

  // ============================================================
  // GET ENTRY
  // ============================================================

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

    final entries = await loadEntries();

    for (final entry in entries) {
      if (entry.review.id ==
          cleanId) {
        return entry;
      }
    }

    return null;
  }

  // ============================================================
  // GET BY CONCEPT ID
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

  // ============================================================
  // GET ENTRY BY CONCEPT ID
  // ============================================================

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

    final entries = await loadEntries();

    for (final entry in entries) {
      if (entry.review.conceptId ==
          cleanConceptId) {
        return entry;
      }
    }

    return null;
  }

  // ============================================================
  // EXISTS
  // ============================================================

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
  //
  // Upsert lógico:
  //
  // review.id já existe
  //      ↓
  // updateObject()
  //
  // review.id não existe
  //      ↓
  // createObject()
  //
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

      return normalized;
    }

    await _vaultService.updateObject(
      objectId: existing.objectId,
      type: BrainVaultObjectType.review,
      data: data,
    );

    return normalized;
  }

  // ============================================================
  // SAVE MANY
  // ============================================================

  Future<
    void
  >
  saveReviews(
    List<
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
  // DELETE
  // ============================================================
  //
  // Não apagamos fisicamente o .evobj.
  //
  // BrainVaultService.deleteObject() cria tombstone.
  //
  // Isso será importante posteriormente para sync.
  //
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

    final existing = await getEntry(
      cleanId,
    );

    if (existing ==
        null) {
      return;
    }

    await _vaultService.deleteObject(
      existing.objectId,
    );
  }

  // ============================================================
  // DELETE BY CONCEPT
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

    final entries = await loadEntries();

    final matches = entries.where(
      (
        entry,
      ) {
        return entry.review.conceptId ==
            cleanConceptId;
      },
    ).toList();

    for (final entry in matches) {
      await _vaultService.deleteObject(
        entry.objectId,
      );
    }
  }

  // ============================================================
  // DELETE BY SOURCE NOTE PATH
  // ============================================================
  //
  // sourceNotePath ainda é legado.
  //
  // Futuramente esta relação será substituída por objectId
  // estável da nota.
  //
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

    final matches = entries.where(
      (
        entry,
      ) {
        return entry.review.sourceNotePath.trim() ==
            cleanPath;
      },
    ).toList();

    for (final entry in matches) {
      await _vaultService.deleteObject(
        entry.objectId,
      );
    }
  }

  // ============================================================
  // LOAD DUE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadDueReviews({
    DateTime? now,
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return !review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // LOAD UPCOMING
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadUpcomingReviews({
    DateTime? now,
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // LOAD ACTIVE
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() async {
    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // LOAD ARCHIVED
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() async {
    final reviews = await loadReviews();

    final result = reviews.where(
      (
        review,
      ) {
        return review.archived;
      },
    ).toList();

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
  // DECODE OBJECT
  // ============================================================

  Future<
    BrainReviewVaultEntry?
  >
  _decodeReviewObject(
    BrainVaultObject object,
  ) async {
    final decoded = await _vaultService.readObject(
      object.header.objectId,
    );

    if (decoded ==
        null) {
      return null;
    }

    final data = decoded.data;

    // ==========================================================
    // FILTER OTHER OBJECT TYPES
    // ==========================================================
    //
    // O tipo lógico também existe dentro do payload
    // criptografado.
    //
    // Fazemos esta verificação ANTES do mapper para não confundir
    // um objeto que simplesmente não é review com uma review
    // corrompida.
    //
    // ==========================================================

    final model = data['model']?.toString().trim();

    if (model !=
        'brain_review') {
      return null;
    }

    // ==========================================================
    // DECODE REVIEW
    // ==========================================================
    //
    // A partir daqui sabemos que o objeto afirma ser uma review.
    //
    // Se o mapper lançar FormatException, NÃO escondemos o erro.
    //
    // Isso evita transformar corrupção de uma review em simples
    // "review inexistente".
    //
    // ==========================================================

    final review = _mapper.fromVaultData(
      data,
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

    return entry;
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

  // ============================================================
  // COMPARE
  // ============================================================

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
