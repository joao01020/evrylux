import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/repositories/comments/board_comment_repository.dart';
import '../../models/comments/board_comment.dart';

class BoardCommentController
    extends
        ChangeNotifier {
  BoardCommentController({
    required BoardCommentRepository repository,
  }) : _repository = repository;

  // ============================================================
  // REPOSITORY
  // ============================================================

  final BoardCommentRepository _repository;

  // ============================================================
  // COMENTÁRIOS
  // ============================================================

  final List<
    BoardComment
  >
  _comments = [];

  // ============================================================
  // STATE
  // ============================================================

  bool _commentMode = false;

  bool _loading = false;

  bool _saving = false;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get commentMode => _commentMode;

  bool get loading => _loading;

  bool get saving => _saving;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage !=
          null &&
      _errorMessage!.trim().isNotEmpty;

  List<
    BoardComment
  >
  get comments {
    return List.unmodifiable(
      _comments,
    );
  }

  int get totalComments {
    return _comments.length;
  }

  int get unresolvedComments {
    return _comments
        .where(
          (
            comment,
          ) => !comment.resolved,
        )
        .length;
  }

  bool get hasComments {
    return _comments.isNotEmpty;
  }

  // ============================================================
  // ERRO
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  void _setError(
    Object error,
  ) {
    _errorMessage = error.toString();

    notifyListeners();
  }

  // ============================================================
  // MODO COMENTÁRIO
  // ============================================================

  void enableCommentMode() {
    if (_commentMode) {
      return;
    }

    _commentMode = true;

    notifyListeners();
  }

  void disableCommentMode() {
    if (!_commentMode) {
      return;
    }

    _commentMode = false;

    notifyListeners();
  }

  void toggleCommentMode() {
    _commentMode = !_commentMode;

    notifyListeners();
  }

  // ============================================================
  // CARREGAR COMENTÁRIOS DO DIA
  // ============================================================

  Future<
    void
  >
  loadByDay(
    String dayId, {
    bool includeResolved = false,
  }) async {
    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      return;
    }

    _loading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final loaded = await _repository.fetchByDay(
        dayId: normalizedDayId,
        includeResolved: includeResolved,
      );

      _comments.removeWhere(
        (
          comment,
        ) =>
            comment.dayId ==
            normalizedDayId,
      );

      _comments.addAll(
        loaded,
      );

      _sortComments();
    } catch (
      error
    ) {
      _setError(
        error,
      );
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CARREGAR TODOS
  // ============================================================

  Future<
    void
  >
  loadAll({
    bool includeResolved = false,
  }) async {
    _loading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final loaded = await _repository.fetchAll(
        includeResolved: includeResolved,
      );

      _comments
        ..clear()
        ..addAll(
          loaded,
        );

      _sortComments();
    } catch (
      error
    ) {
      _setError(
        error,
      );
    } finally {
      _loading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CRIAR COMENTÁRIO
  // ============================================================

  Future<
    BoardComment?
  >
  create({
    required String dayId,
    required String message,
    required Offset position,
    String authorName = 'Você',
  }) async {
    final normalizedMessage = message.trim();

    if (normalizedMessage.isEmpty) {
      _setError(
        ArgumentError(
          'A mensagem do comentário não pode estar vazia.',
        ),
      );

      return null;
    }

    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      _setError(
        ArgumentError(
          'O ID do dia não pode estar vazio.',
        ),
      );

      return null;
    }

    final normalizedAuthor = authorName.trim();

    final draft = BoardComment(
      // UUID v4 definitivo criado antes de qualquer acesso remoto.
      // O mesmo ID é usado no SQLite, SyncQueue e Supabase.
      id: _createStableId(),
      dayId: normalizedDayId,
      message: normalizedMessage,
      position: position,
      createdAt: DateTime.now(),
      authorName: normalizedAuthor.isEmpty
          ? 'Você'
          : normalizedAuthor,
      resolved: false,
    );

    _saving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final saved = await _repository.create(
        draft,
      );

      _comments.add(
        saved,
      );

      _sortComments();

      _commentMode = false;

      notifyListeners();

      return saved;
    } catch (
      error
    ) {
      _setError(
        error,
      );

      return null;
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // ADICIONAR COMENTÁRIO EXISTENTE
  // ============================================================

  void addLocal(
    BoardComment comment,
  ) {
    final exists = _comments.any(
      (
        item,
      ) =>
          item.id ==
          comment.id,
    );

    if (exists) {
      return;
    }

    _comments.add(
      comment,
    );

    _sortComments();

    notifyListeners();
  }

  // ============================================================
  // SUBSTITUIR LISTA LOCAL
  // ============================================================

  void setComments(
    Iterable<
      BoardComment
    >
    comments,
  ) {
    _comments
      ..clear()
      ..addAll(
        comments,
      );

    _sortComments();

    notifyListeners();
  }

  // ============================================================
  // LIMPAR LISTA LOCAL
  // ============================================================

  void clear() {
    if (_comments.isEmpty) {
      return;
    }

    _comments.clear();

    notifyListeners();
  }

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  BoardComment? findById(
    String id,
  ) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final comment in _comments) {
      if (comment.id ==
          normalizedId) {
        return comment;
      }
    }

    return null;
  }

  // ============================================================
  // COMENTÁRIOS DO DIA
  // ============================================================

  List<
    BoardComment
  >
  commentsForDay(
    String dayId, {
    bool includeResolved = false,
  }) {
    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      return const [];
    }

    final result = _comments.where(
      (
        comment,
      ) {
        if (comment.dayId !=
            normalizedDayId) {
          return false;
        }

        if (!includeResolved &&
            comment.resolved) {
          return false;
        }

        return true;
      },
    ).toList();

    result.sort(
      (
        a,
        b,
      ) {
        return a.createdAt.compareTo(
          b.createdAt,
        );
      },
    );

    return result;
  }

  // ============================================================
  // QUANTIDADE POR DIA
  // ============================================================

  int countForDay(
    String dayId, {
    bool includeResolved = false,
  }) {
    return commentsForDay(
      dayId,
      includeResolved: includeResolved,
    ).length;
  }

  // ============================================================
  // ATUALIZAR MENSAGEM
  // ============================================================

  Future<
    void
  >
  updateMessage(
    BoardComment comment,
    String message,
  ) async {
    final normalized = message.trim();

    if (normalized.isEmpty) {
      return;
    }

    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return;
    }

    _saving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final updated = await _repository.updateMessage(
        commentId: stored.id,
        message: normalized,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      _setError(
        error,
      );
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // MOVER COMENTÁRIO
  // ============================================================
  //
  // move() continua disponível para casos em que você deseja
  // mover e persistir imediatamente no fluxo local-first.
  //
  // Para arrastar pela lousa, prefira:
  //
  // moveLocal()
  // moveLocalBy()
  // persistPosition()
  //
  // Dessa forma o mouse fica fluido e o banco recebe apenas
  // um UPDATE quando o usuário solta o comentário.
  //
  // ============================================================

  Future<
    void
  >
  move(
    BoardComment comment,
    Offset position,
  ) async {
    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return;
    }

    final oldPosition = stored.position;

    stored.position = position;

    notifyListeners();

    try {
      final updated = await _repository.updatePosition(
        commentId: stored.id,
        position: position,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      stored.position = oldPosition;

      _setError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // MOVER APENAS LOCALMENTE
  // ============================================================
  //
  // Usado durante onPanUpdate.
  //
  // NÃO persiste durante o movimento contínuo.
  //
  // ============================================================

  void moveLocal(
    BoardComment comment,
    Offset position,
  ) {
    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return;
    }

    stored.position = position;

    notifyListeners();
  }

  // ============================================================
  // MOVER LOCALMENTE COM DELTA
  // ============================================================
  //
  // Ideal para:
  //
  // onPanUpdate: (details) {
  //   controller.moveLocalBy(
  //     comment,
  //     details.delta,
  //   );
  // }
  //
  // ============================================================

  void moveLocalBy(
    BoardComment comment,
    Offset delta,
  ) {
    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return;
    }

    stored.position =
        stored.position +
        delta;

    notifyListeners();
  }

  // ============================================================
  // SALVAR POSIÇÃO ATUAL
  // ============================================================
  //
  // Usado no onPanEnd.
  //
  // Só aqui persistimos no SQLite e enfileiramos o sync.
  //
  // ============================================================

  Future<
    void
  >
  persistPosition(
    BoardComment comment,
  ) async {
    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return;
    }

    _saving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final updated = await _repository.updatePosition(
        commentId: stored.id,
        position: stored.position,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      _setError(
        error,
      );
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // MOVER COM DELTA + SALVAR IMEDIATAMENTE
  // ============================================================
  //
  // Mantido por compatibilidade.
  //
  // Para drag contínuo, use moveLocalBy() + persistPosition().
  //
  // ============================================================

  Future<
    void
  >
  moveBy(
    BoardComment comment,
    Offset delta,
  ) {
    final stored = findById(
      comment.id,
    );

    if (stored ==
        null) {
      return Future.value();
    }

    return move(
      stored,
      stored.position +
          delta,
    );
  }

  // ============================================================
  // RESOLVER
  // ============================================================

  Future<
    void
  >
  resolve(
    BoardComment comment,
  ) async {
    final stored = findById(
      comment.id,
    );

    if (stored ==
            null ||
        stored.resolved) {
      return;
    }

    final oldResolved = stored.resolved;

    stored.resolved = true;

    notifyListeners();

    try {
      final updated = await _repository.resolve(
        stored,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      stored.resolved = oldResolved;

      _setError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // REABRIR
  // ============================================================

  Future<
    void
  >
  reopen(
    BoardComment comment,
  ) async {
    final stored = findById(
      comment.id,
    );

    if (stored ==
            null ||
        !stored.resolved) {
      return;
    }

    final oldResolved = stored.resolved;

    stored.resolved = false;

    notifyListeners();

    try {
      final updated = await _repository.reopen(
        stored,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      stored.resolved = oldResolved;

      _setError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // ALTERNAR RESOLVIDO
  // ============================================================

  Future<
    void
  >
  toggleResolved(
    BoardComment comment,
  ) {
    if (comment.resolved) {
      return reopen(
        comment,
      );
    }

    return resolve(
      comment,
    );
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  remove(
    BoardComment comment,
  ) {
    return removeById(
      comment.id,
    );
  }

  Future<
    void
  >
  removeById(
    String id,
  ) async {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return;
    }

    final index = _comments.indexWhere(
      (
        comment,
      ) =>
          comment.id ==
          normalizedId,
    );

    if (index <
        0) {
      return;
    }

    final removed = _comments[index];

    // Remoção otimista.
    _comments.removeAt(
      index,
    );

    notifyListeners();

    try {
      await _repository.deleteById(
        normalizedId,
      );
    } catch (
      error
    ) {
      _comments.insert(
        index,
        removed,
      );

      _setError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // REMOVER COMENTÁRIOS DO DIA
  // ============================================================

  Future<
    void
  >
  removeAllForDay(
    String dayId,
  ) async {
    final normalizedDayId = dayId.trim();

    if (normalizedDayId.isEmpty) {
      return;
    }

    final removed = _comments
        .where(
          (
            comment,
          ) =>
              comment.dayId ==
              normalizedDayId,
        )
        .toList();

    if (removed.isEmpty) {
      return;
    }

    _comments.removeWhere(
      (
        comment,
      ) =>
          comment.dayId ==
          normalizedDayId,
    );

    notifyListeners();

    try {
      await _repository.deleteByDay(
        normalizedDayId,
      );
    } catch (
      error
    ) {
      _comments.addAll(
        removed,
      );

      _sortComments();

      _setError(
        error,
      );

      notifyListeners();
    }
  }

  // ============================================================
  // ATUALIZAR COMENTÁRIO COMPLETO
  // ============================================================

  Future<
    void
  >
  update(
    BoardComment comment,
  ) async {
    _saving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final updated = await _repository.update(
        comment,
      );

      _replaceLocal(
        updated,
      );
    } catch (
      error
    ) {
      _setError(
        error,
      );
    } finally {
      _saving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _replaceLocal(
    BoardComment comment,
  ) {
    final index = _comments.indexWhere(
      (
        item,
      ) =>
          item.id ==
          comment.id,
    );

    if (index <
        0) {
      _comments.add(
        comment,
      );
    } else {
      _comments[index] = comment;
    }

    _sortComments();

    notifyListeners();
  }

  void _sortComments() {
    _comments.sort(
      (
        a,
        b,
      ) {
        return a.createdAt.compareTo(
          b.createdAt,
        );
      },
    );
  }

  String _createStableId() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    );

    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int value) {
      return value.toRadixString(16).padLeft(2, '0');
    }

    final value = bytes.map(hex).join();

    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20, 32)}';
  }
}
