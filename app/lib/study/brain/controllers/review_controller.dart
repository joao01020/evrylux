import 'package:flutter/foundation.dart';

import '../models/brain_concept.dart';
import '../models/brain_review_item.dart';
import '../services/review_storage.dart';

// ============================================================
// RESULTADO DA REVISÃO
// ============================================================

enum ReviewAnswer {
  again,
  hard,
  good,
  easy,
}

// ============================================================
// EXTENSÃO
// ============================================================

extension ReviewAnswerExtension
    on
        ReviewAnswer {
  String get label {
    switch (this) {
      case ReviewAnswer.again:
        return 'Errei';

      case ReviewAnswer.hard:
        return 'Difícil';

      case ReviewAnswer.good:
        return 'Acertei';

      case ReviewAnswer.easy:
        return 'Fácil';
    }
  }
}

// ============================================================
// CONTROLLER
// ============================================================

class ReviewController
    extends
        ChangeNotifier {
  ReviewController({
    ReviewStorage storage = const ReviewStorage(),
  }) : _storage = storage;

  final ReviewStorage _storage;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = false;

  bool _isSaving = false;

  String? _errorMessage;

  String? _successMessage;

  List<
    BrainReviewItem
  >
  _reviews = [];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoading {
    return _isLoading;
  }

  bool get isSaving {
    return _isSaving;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  String? get successMessage {
    return _successMessage;
  }

  List<
    BrainReviewItem
  >
  get reviews {
    return List.unmodifiable(
      _reviews,
    );
  }

  // ============================================================
  // ATIVAS
  // ============================================================

  List<
    BrainReviewItem
  >
  get activeReviews {
    return _reviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();
  }

  // ============================================================
  // ARQUIVADAS
  // ============================================================

  List<
    BrainReviewItem
  >
  get archivedReviews {
    return _reviews.where(
      (
        review,
      ) {
        return review.archived;
      },
    ).toList();
  }

  // ============================================================
  // REVISÕES DEVIDAS
  // ============================================================

  List<
    BrainReviewItem
  >
  get dueReviews {
    final now = DateTime.now();

    final result = _reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return !review.nextReviewAt.isAfter(
          now,
        );
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // PRÓXIMAS
  // ============================================================

  List<
    BrainReviewItem
  >
  get upcomingReviews {
    final now = DateTime.now();

    final result = _reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return review.nextReviewAt.isAfter(
          now,
        );
      },
    ).toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // CONTADORES
  // ============================================================

  int get totalCount {
    return _reviews.length;
  }

  int get activeCount {
    return activeReviews.length;
  }

  int get archivedCount {
    return archivedReviews.length;
  }

  int get dueCount {
    return dueReviews.length;
  }

  int get upcomingCount {
    return upcomingReviews.length;
  }

  // ============================================================
  // PRÓXIMA REVISÃO
  // ============================================================

  BrainReviewItem? get nextReview {
    final due = dueReviews;

    if (due.isEmpty) {
      return null;
    }

    return due.first;
  }

  // ============================================================
  // INICIALIZAR
  // ============================================================

  Future<
    void
  >
  initialize() async {
    await loadReviews();
  }

  // ============================================================
  // CARREGAR
  // ============================================================

  Future<
    void
  >
  loadReviews() async {
    _setLoading(
      true,
    );

    _clearError();

    try {
      _reviews = await _storage.loadReviews();

      _sortReviews();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao carregar revisões.',
      );

      debugPrint(
        'ReviewController: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível carregar as revisões.';
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // CRIAR REVISÃO A PARTIR DE UMA PERGUNTA
  // ============================================================

  Future<
    BrainReviewItem?
  >
  createFromConcept({
    required BrainConcept concept,
    required String answer,
    String sourceNotePath = '',
    String sourceNoteTitle = '',
    DateTime? firstReviewAt,
  }) async {
    if (concept.type !=
        BrainConceptType.question) {
      _errorMessage = 'Somente perguntas podem entrar no sistema de revisão.';

      notifyListeners();

      return null;
    }

    final cleanAnswer = answer.trim();

    if (cleanAnswer.isEmpty) {
      _errorMessage = 'Informe a resposta da pergunta.';

      notifyListeners();

      return null;
    }

    final existing = _reviews.where(
      (
        review,
      ) {
        return review.conceptId ==
            concept.id;
      },
    );

    if (existing.isNotEmpty) {
      _errorMessage = 'Esta pergunta já está no sistema de revisão.';

      notifyListeners();

      return existing.first;
    }

    final now = DateTime.now();

    final review = BrainReviewItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),

      conceptId: concept.id,

      question: concept.title,

      answer: cleanAnswer,

      sourceNotePath: sourceNotePath,

      sourceNoteTitle: sourceNoteTitle,

      createdAt: now,

      nextReviewAt:
          firstReviewAt ??
          now,

      reviewCount: 0,

      correctCount: 0,

      wrongCount: 0,

      streak: 0,

      archived: false,

      archivedAt: null,

      lastReviewedAt: null,
    );

    await addReview(
      review,
    );

    return review;
  }

  // ============================================================
  // ADICIONAR
  // ============================================================

  Future<
    void
  >
  addReview(
    BrainReviewItem review,
  ) async {
    _setSaving(
      true,
    );

    _clearMessages();

    try {
      final index = _reviews.indexWhere(
        (
          item,
        ) {
          return item.id ==
              review.id;
        },
      );

      if (index >=
          0) {
        _reviews[index] = review;
      } else {
        _reviews.add(
          review,
        );
      }

      _sortReviews();

      await _storage.saveReviews(
        _reviews,
      );

      _successMessage = 'Pergunta adicionada às revisões.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao salvar revisão.',
      );

      debugPrint(
        'ReviewController: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível salvar a revisão.';
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ============================================================
  // ATUALIZAR
  // ============================================================

  Future<
    void
  >
  updateReview(
    BrainReviewItem review,
  ) async {
    _setSaving(
      true,
    );

    _clearMessages();

    try {
      final index = _reviews.indexWhere(
        (
          item,
        ) {
          return item.id ==
              review.id;
        },
      );

      if (index <
          0) {
        throw StateError(
          'Revisão não encontrada.',
        );
      }

      _reviews[index] = review;

      _sortReviews();

      await _storage.saveReviews(
        _reviews,
      );

      _successMessage = 'Revisão atualizada.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao atualizar revisão.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível atualizar a revisão.';
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ============================================================
  // RESPONDER
  // ============================================================

  Future<
    void
  >
  answerReview({
    required BrainReviewItem review,
    required ReviewAnswer answer,
  }) async {
    final now = DateTime.now();

    final nextDate = _calculateNextReviewDate(
      review: review,
      answer: answer,
      now: now,
    );

    final isCorrect =
        answer ==
            ReviewAnswer.good ||
        answer ==
            ReviewAnswer.easy;

    final isWrong =
        answer ==
        ReviewAnswer.again;

    final nextStreak = isCorrect
        ? review.streak +
              1
        : answer ==
              ReviewAnswer.again
        ? 0
        : review.streak;

    final updated = review.copyWith(
      nextReviewAt: nextDate,

      reviewCount:
          review.reviewCount +
          1,

      correctCount:
          review.correctCount +
          (isCorrect
              ? 1
              : 0),

      wrongCount:
          review.wrongCount +
          (isWrong
              ? 1
              : 0),

      streak: nextStreak,

      lastReviewedAt: now,
    );

    await updateReview(
      updated,
    );
  }

  // ============================================================
  // CALCULAR PRÓXIMA REVISÃO
  // ============================================================

  DateTime _calculateNextReviewDate({
    required BrainReviewItem review,
    required ReviewAnswer answer,
    required DateTime now,
  }) {
    switch (answer) {
      // ========================================================
      // ERROU
      // ========================================================

      case ReviewAnswer.again:
        return now.add(
          const Duration(
            minutes: 15,
          ),
        );

      // ========================================================
      // DIFÍCIL
      // ========================================================

      case ReviewAnswer.hard:
        return now.add(
          const Duration(
            days: 1,
          ),
        );

      // ========================================================
      // ACERTOU
      // ========================================================

      case ReviewAnswer.good:
        return now.add(
          Duration(
            days: _goodInterval(
              review,
            ),
          ),
        );

      // ========================================================
      // FÁCIL
      // ========================================================

      case ReviewAnswer.easy:
        return now.add(
          Duration(
            days: _easyInterval(
              review,
            ),
          ),
        );
    }
  }

  // ============================================================
  // INTERVALO "ACERTEI"
  // ============================================================

  int _goodInterval(
    BrainReviewItem review,
  ) {
    final streak = review.streak;

    if (streak <=
        0) {
      return 3;
    }

    if (streak ==
        1) {
      return 7;
    }

    if (streak ==
        2) {
      return 14;
    }

    if (streak ==
        3) {
      return 30;
    }

    if (streak ==
        4) {
      return 60;
    }

    return 90;
  }

  // ============================================================
  // INTERVALO "FÁCIL"
  // ============================================================

  int _easyInterval(
    BrainReviewItem review,
  ) {
    final streak = review.streak;

    if (streak <=
        0) {
      return 7;
    }

    if (streak ==
        1) {
      return 14;
    }

    if (streak ==
        2) {
      return 30;
    }

    if (streak ==
        3) {
      return 60;
    }

    return 120;
  }

  // ============================================================
  // ARQUIVAR
  // ============================================================

  Future<
    void
  >
  archiveReview(
    BrainReviewItem review,
  ) async {
    final updated = review.copyWith(
      archived: true,

      archivedAt: DateTime.now(),
    );

    await updateReview(
      updated,
    );

    _successMessage = 'Pergunta arquivada.';

    notifyListeners();
  }

  // ============================================================
  // RESTAURAR
  // ============================================================

  Future<
    void
  >
  restoreReview(
    BrainReviewItem review,
  ) async {
    final updated = review.copyWith(
      archived: false,

      archivedAt: null,

      nextReviewAt: DateTime.now(),
    );

    await updateReview(
      updated,
    );

    _successMessage = 'Pergunta restaurada.';

    notifyListeners();
  }

  // ============================================================
  // ADIAR
  // ============================================================

  Future<
    void
  >
  postponeReview(
    BrainReviewItem review, {
    Duration duration = const Duration(
      days: 1,
    ),
  }) async {
    final updated = review.copyWith(
      nextReviewAt: DateTime.now().add(
        duration,
      ),
    );

    await updateReview(
      updated,
    );

    _successMessage = 'Revisão adiada.';

    notifyListeners();
  }

  // ============================================================
  // DEFINIR DATA MANUALMENTE
  // ============================================================

  Future<
    void
  >
  setNextReviewDate(
    BrainReviewItem review,
    DateTime date,
  ) async {
    final updated = review.copyWith(
      nextReviewAt: date,
    );

    await updateReview(
      updated,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  deleteReview(
    BrainReviewItem review,
  ) async {
    _setSaving(
      true,
    );

    _clearMessages();

    try {
      _reviews.removeWhere(
        (
          item,
        ) {
          return item.id ==
              review.id;
        },
      );

      await _storage.saveReviews(
        _reviews,
      );

      _successMessage = 'Revisão excluída.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao excluir revisão.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível excluir a revisão.';
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ============================================================
  // ENCONTRAR PELO ID
  // ============================================================

  BrainReviewItem? findById(
    String id,
  ) {
    for (final review in _reviews) {
      if (review.id ==
          id) {
        return review;
      }
    }

    return null;
  }

  // ============================================================
  // ENCONTRAR PELO CONCEPT ID
  // ============================================================

  BrainReviewItem? findByConceptId(
    String conceptId,
  ) {
    for (final review in _reviews) {
      if (review.conceptId ==
          conceptId) {
        return review;
      }
    }

    return null;
  }

  // ============================================================
  // ORDENAR
  // ============================================================

  void _sortReviews() {
    _reviews.sort(
      (
        first,
        second,
      ) {
        if (first.archived &&
            !second.archived) {
          return 1;
        }

        if (!first.archived &&
            second.archived) {
          return -1;
        }

        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    _isLoading = value;

    notifyListeners();
  }

  // ============================================================
  // SAVING
  // ============================================================

  void _setSaving(
    bool value,
  ) {
    _isSaving = value;

    notifyListeners();
  }

  // ============================================================
  // MENSAGENS
  // ============================================================

  void clearMessages() {
    _clearMessages();

    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;

    _successMessage = null;
  }

  void _clearError() {
    _errorMessage = null;
  }
}
