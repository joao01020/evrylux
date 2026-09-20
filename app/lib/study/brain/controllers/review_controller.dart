import 'package:flutter/foundation.dart';

import '../models/brain_concept.dart';
import '../models/brain_generated_review_question.dart';
import '../models/brain_review_item.dart';
import '../repositories/review_repository.dart';
import '../services/brain_review_generation_queue.dart';
import '../services/brain_review_question_generator.dart';

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
    required ReviewRepository repository,
  }) : _repository = repository;

  final ReviewRepository _repository;

  static const BrainReviewGenerationQueue _generationQueue = BrainReviewGenerationQueue();

  static const BrainReviewQuestionGenerator _questionGenerator = LocalBrainReviewQuestionGenerator();

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
  // INITIALIZATION STATE
  // ============================================================
  //
  // ReviewController é uma dependência global. Sem este controle,
  // initialize() recarregava o repositório toda vez que uma tela ou
  // outro fluxo pedia a inicialização.
  //
  // Mantemos uma única inicialização por sessão/conta e reutilizamos
  // o estado já carregado em memória. Chamadas explícitas a
  // loadReviews() continuam forçando uma releitura do armazenamento.
  //
  // ============================================================

  bool _initialized = false;

  Future<
    void
  >?
  _initializationFuture;

  // ============================================================
  // ACCOUNT SCOPE RESET
  // ============================================================

  void resetForAccountChange() {
    _reviews =
        <
          BrainReviewItem
        >[];
    _errorMessage = null;
    _successMessage = null;
    _initialized = false;
    _initializationFuture = null;
    notifyListeners();
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
  // FASE 10 — AGRUPAMENTOS CONSOLIDADOS POR DATA
  // ============================================================
  //
  // Estes getters são a fonte única para a UI distinguir:
  //
  // - revisões atrasadas;
  // - revisões programadas para hoje;
  // - revisões futuras.
  //
  // A tela não precisa mais duplicar essa regra.
  //
  // ============================================================

  List<
    BrainReviewItem
  >
  get overdueReviews {
    final today = _startOfDay(
      DateTime.now(),
    );

    final result = _reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return review.nextReviewAt.toLocal().isBefore(
          today,
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

  List<
    BrainReviewItem
  >
  get todayReviews {
    final now = DateTime.now();

    final result = _reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return _isSameDay(
          review.nextReviewAt,
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

  List<
    BrainReviewItem
  >
  get futureReviews {
    final tomorrow =
        _startOfDay(
          DateTime.now(),
        ).add(
          const Duration(
            days: 1,
          ),
        );

    final result = _reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return !review.nextReviewAt.toLocal().isBefore(
          tomorrow,
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

  int get overdueCount {
    return overdueReviews.length;
  }

  int get todayCount {
    return todayReviews.length;
  }

  int get futureCount {
    return futureReviews.length;
  }

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
  initialize() {
    if (_initialized) {
      return Future<
        void
      >.value();
    }

    final runningInitialization = _initializationFuture;

    if (runningInitialization !=
        null) {
      return runningInitialization;
    }

    final future = _initializeOnce();

    _initializationFuture = future;

    return future;
  }

  Future<
    void
  >
  _initializeOnce() async {
    try {
      await _loadReviews(
        showLoading: _reviews.isEmpty,
      );

      if (_errorMessage ==
          null) {
        _initialized = true;
      }
    } finally {
      _initializationFuture = null;
    }
  }

  // ============================================================
  // CARREGAR
  // ============================================================
  //
  // loadReviews() é um reload explícito. Diferente de initialize(),
  // ele sempre consulta novamente o repositório, pois é usado quando
  // a UI realmente precisa refletir alterações persistidas.
  //
  // ============================================================

  Future<
    void
  >
  loadReviews() async {
    await _loadReviews(
      showLoading: _reviews.isEmpty,
    );

    if (_errorMessage ==
        null) {
      _initialized = true;
    }
  }

  Future<
    void
  >
  _loadReviews({
    required bool showLoading,
  }) async {
    if (showLoading) {
      _setLoading(
        true,
      );
    }

    _clearError();

    try {
      final loadedReviews = await _repository.loadReviews();

      _reviews = loadedReviews;

      _sortReviews();

      if (!showLoading) {
        notifyListeners();
      }
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

      if (!showLoading) {
        notifyListeners();
      }
    } finally {
      if (showLoading) {
        _setLoading(
          false,
        );
      }
    }
  }

  // ============================================================
  // ATUALIZAR A PARTIR DO SUPABASE
  // ============================================================

  Future<
    void
  >
  refreshFromRemote() async {
    _setLoading(
      true,
    );

    _clearMessages();

    try {
      _reviews = await _repository.refreshFromRemote();

      _sortReviews();

      _successMessage = 'Revisões sincronizadas.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao atualizar revisões do Supabase.',
      );

      debugPrint(
        'ReviewController: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível atualizar as revisões da nuvem.';
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // FASE 2 — FILA DE CONHECIMENTOS PARA GERAR REVISÃO
  // ============================================================
  //
  // A fila é derivada do estado persistido. Não criamos uma segunda fonte
  // de verdade: um conceito entra quando reviewEnabled == true e ainda não
  // existe uma revisão ativa vinculada ao seu conceptId.
  //
  // A geração por IA será conectada na próxima fase.
  // ============================================================

  List<
    BrainReviewGenerationCandidate
  >
  reviewGenerationCandidates(
    Iterable<
      BrainConcept
    >
    concepts,
  ) {
    return _generationQueue.build(
      concepts: concepts,
      reviews: _reviews,
    );
  }

  bool needsGeneratedReview(
    BrainConcept concept,
  ) {
    return reviewGenerationCandidates(
      <
        BrainConcept
      >[
        concept,
      ],
    ).isNotEmpty;
  }

  int pendingGenerationCount(
    Iterable<
      BrainConcept
    >
    concepts,
  ) {
    return reviewGenerationCandidates(
      concepts,
    ).length;
  }

  // ============================================================
  // FASE 3 — GERAR RASCUNHOS DE REVISÃO
  // ============================================================
  //
  // Gera questões somente para conceitos elegíveis da fila. Nesta fase os
  // rascunhos ainda não são persistidos como BrainReviewItem. Isso evita
  // misturar a geração automática com BrainConceptType.question e prepara
  // uma fronteira limpa para o provedor de IA.
  // ============================================================

  Future<
    List<
      BrainGeneratedReviewQuestion
    >
  >
  generateReviewDrafts(
    Iterable<
      BrainConcept
    >
    concepts,
  ) async {
    final candidates = reviewGenerationCandidates(
      concepts,
    );
    final result =
        <
          BrainGeneratedReviewQuestion
        >[];

    for (final candidate in candidates) {
      final generated = await _questionGenerator.generate(
        candidate,
      );
      result.addAll(
        generated,
      );
    }

    return List<
      BrainGeneratedReviewQuestion
    >.unmodifiable(
      result,
    );
  }

  Future<
    List<
      BrainGeneratedReviewQuestion
    >
  >
  generateReviewDraftsForConcept(
    BrainConcept concept,
  ) {
    return generateReviewDrafts(
      <
        BrainConcept
      >[
        concept,
      ],
    );
  }

  // ============================================================
  // FASE 4 — GERAR E PERSISTIR REVISÕES AUTOMÁTICAS
  // ============================================================
  //
  // Um conhecimento marcado com reviewEnabled pode originar várias
  // BrainReviewItem. As perguntas automáticas continuam fora de
  // BrainConceptType.question: elas pertencem somente ao domínio Review.
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  generateAndSaveReviewsForConcept({
    required BrainConcept concept,
    required String sourceNotePath,
    String sourceNoteTitle = '',
    DateTime? firstReviewAt,
  }) async {
    await initialize();

    final cleanPath = sourceNotePath.trim();
    if (cleanPath.isEmpty) {
      _errorMessage = 'Não foi possível gerar a revisão porque a anotação não possui caminho local.';
      notifyListeners();
      return const <
        BrainReviewItem
      >[];
    }

    // A fila impede gerar novamente para um conceito que já possui
    // revisão ativa. Importante: geramos TODOS os rascunhos primeiro e
    // somente depois persistimos, permitindo várias perguntas por conceito.
    final drafts = await generateReviewDraftsForConcept(
      concept,
    );
    if (drafts.isEmpty) {
      return const <
        BrainReviewItem
      >[];
    }

    final now = DateTime.now();
    final dueAt =
        firstReviewAt ??
        now;
    final savedReviews =
        <
          BrainReviewItem
        >[];

    for (final draft in drafts) {
      final question = draft.question.trim();
      final answer = draft.answer.trim();

      if (question.isEmpty ||
          answer.isEmpty) {
        continue;
      }

      // IDs do gerador local são determinísticos por conceito + unidade.
      // Isso também protege contra duplicação se este método for chamado
      // novamente antes da lista local ser atualizada.
      final alreadyExists = _reviews.any(
        (
          review,
        ) =>
            review.id ==
            draft.id,
      );
      if (alreadyExists) {
        continue;
      }

      final review = BrainReviewItem(
        id: draft.id,
        conceptId: concept.id,
        question: question,
        answer: answer,
        sourceNotePath: cleanPath,
        sourceNoteTitle: sourceNoteTitle.trim(),
        createdAt: now,
        nextReviewAt: dueAt,
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

      if (_errorMessage !=
          null) {
        break;
      }

      savedReviews.add(
        review,
      );
    }

    if (savedReviews.isNotEmpty) {
      _successMessage =
          savedReviews.length ==
              1
          ? '1 pergunta de revisão foi criada automaticamente.'
          : '${savedReviews.length} perguntas de revisão foram criadas automaticamente.';
      notifyListeners();
    }

    return List<
      BrainReviewItem
    >.unmodifiable(
      savedReviews,
    );
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
    required String sourceNotePath,
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

    final cleanSourceNotePath = sourceNotePath.trim();

    final cleanSourceNoteTitle = sourceNoteTitle.trim();

    if (cleanSourceNotePath.isEmpty) {
      _errorMessage = 'Não foi possível criar a revisão porque a anotação de origem não possui caminho local.';

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

      sourceNotePath: cleanSourceNotePath,

      sourceNoteTitle: cleanSourceNoteTitle,

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
      final saved = await _repository.saveReview(
        review,
      );

      final index = _reviews.indexWhere(
        (
          item,
        ) {
          return item.id ==
              saved.id;
        },
      );

      if (index >=
          0) {
        _reviews[index] = saved;
      } else {
        _reviews.add(
          saved,
        );
      }

      _sortReviews();

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

      final saved = await _repository.saveReview(
        review,
      );

      _reviews[index] = saved;

      _sortReviews();

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

      clearArchivedAt: true,

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
      await _repository.deleteReview(
        review.id,
      );

      _reviews.removeWhere(
        (
          item,
        ) {
          return item.id ==
              review.id;
        },
      );

      _sortReviews();

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
  // EXCLUIR PELO CONCEITO
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

    _setSaving(
      true,
    );

    _clearMessages();

    try {
      final matches = _reviews.where(
        (
          review,
        ) {
          return review.conceptId ==
              cleanConceptId;
        },
      ).toList();

      if (matches.isEmpty) {
        _successMessage = 'Nenhuma revisão vinculada ao conceito.';
        return;
      }

      await _repository.deleteReviewByConceptId(
        cleanConceptId,
      );

      _reviews.removeWhere(
        (
          review,
        ) {
          return review.conceptId ==
              cleanConceptId;
        },
      );

      _sortReviews();

      _successMessage = 'Revisão do conceito excluída.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao excluir revisão pelo conceito.',
      );

      debugPrint(
        'ReviewController: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível excluir a revisão vinculada ao conceito.';
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
  // ENCONTRAR PELO CAMINHO DA ANOTAÇÃO DE ORIGEM
  // ============================================================

  BrainReviewItem? findBySourceNotePath(
    String sourceNotePath,
  ) {
    final cleanPath = sourceNotePath.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    for (final review in _reviews) {
      if (review.sourceNotePath.trim() ==
          cleanPath) {
        return review;
      }
    }

    return null;
  }

  // ============================================================
  // REMOVER REVISÕES DA MESMA ANOTAÇÃO
  // ============================================================
  //
  // Útil quando a anotação principal é apagada pelo módulo Brain.
  // Impede uma revisão órfã de permanecer no armazenamento local.
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

    _setSaving(
      true,
    );

    _clearMessages();

    try {
      final matches = _reviews.where(
        (
          review,
        ) {
          return review.sourceNotePath.trim() ==
              cleanPath;
        },
      ).toList();

      if (matches.isEmpty) {
        _successMessage = 'Nenhuma revisão vinculada à anotação.';
        return;
      }

      await _repository.deleteReviewsBySourceNotePath(
        cleanPath,
      );

      _reviews.removeWhere(
        (
          review,
        ) {
          return review.sourceNotePath.trim() ==
              cleanPath;
        },
      );

      _sortReviews();

      _successMessage = 'Revisões vinculadas à anotação excluídas.';
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewController: erro ao excluir revisões da anotação de origem.',
      );

      debugPrint(
        'ReviewController: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      _errorMessage = 'Não foi possível excluir as revisões vinculadas à anotação.';
    } finally {
      _setSaving(
        false,
      );
    }
  }

  // ============================================================
  // HELPERS DE DATA
  // ============================================================

  DateTime _startOfDay(
    DateTime value,
  ) {
    final local = value.toLocal();

    return DateTime(
      local.year,
      local.month,
      local.day,
    );
  }

  bool _isSameDay(
    DateTime first,
    DateTime second,
  ) {
    final a = first.toLocal();

    final b = second.toLocal();

    return a.year ==
            b.year &&
        a.month ==
            b.month &&
        a.day ==
            b.day;
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
