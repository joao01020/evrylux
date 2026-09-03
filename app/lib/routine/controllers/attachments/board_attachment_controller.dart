import 'package:flutter/foundation.dart';

import '../../data/attachments/board_attachment_repository.dart';
import '../../models/attachments/board_attachment.dart';

class BoardAttachmentController
    extends
        ChangeNotifier {
  BoardAttachmentController({
    required BoardAttachmentRepository repository,
  }) : _repository = repository;

  // ============================================================
  // REPOSITORY
  // ============================================================

  final BoardAttachmentRepository _repository;

  // ============================================================
  // STATE
  // ============================================================

  final List<
    BoardAttachment
  >
  _attachments =
      <
        BoardAttachment
      >[];

  bool _isLoading = false;

  bool _isImporting = false;

  bool _isSaving = false;

  bool _isDeleting = false;

  String? _currentBoardId;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    BoardAttachment
  >
  get attachments {
    return List.unmodifiable(
      _attachments,
    );
  }

  bool get isLoading => _isLoading;

  bool get isImporting => _isImporting;

  bool get isSaving => _isSaving;

  bool get isDeleting => _isDeleting;

  bool get isBusy =>
      _isLoading ||
      _isImporting ||
      _isSaving ||
      _isDeleting;

  String? get currentBoardId => _currentBoardId;

  String? get errorMessage => _errorMessage;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    _errorMessage = null;

    try {
      await _repository.initialize();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao inicializar anexos da lousa.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // LOAD BOARD
  // ============================================================

  Future<
    void
  >
  loadBoard(
    String boardId,
  ) async {
    final normalizedBoardId = boardId.trim();

    if (normalizedBoardId.isEmpty) {
      _setErrorMessage(
        'boardId não pode estar vazio.',
      );

      return;
    }

    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final loaded = await _repository.loadByBoardId(
        normalizedBoardId,
      );

      _currentBoardId = normalizedBoardId;

      _attachments
        ..clear()
        ..addAll(
          loaded.where(
            (
              attachment,
            ) => !attachment.isDeleted,
          ),
        );

      _sort();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao carregar documentos da lousa.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  Future<
    void
  >
  loadAll() async {
    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final loaded = await _repository.loadAll();

      _currentBoardId = null;

      _attachments
        ..clear()
        ..addAll(
          loaded.where(
            (
              attachment,
            ) => !attachment.isDeleted,
          ),
        );

      _sort();
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao carregar documentos.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SET ATTACHMENTS
  // ============================================================

  void setAttachments(
    Iterable<
      BoardAttachment
    >
    attachments,
  ) {
    _attachments
      ..clear()
      ..addAll(
        attachments.where(
          (
            attachment,
          ) => !attachment.isDeleted,
        ),
      );

    _sort();

    notifyListeners();
  }

  // ============================================================
  // IMPORT
  // ============================================================

  Future<
    BoardAttachment?
  >
  importAttachment({
    required String boardId,
    required String blockId,
    required String sourcePath,
  }) async {
    if (_isImporting) {
      return null;
    }

    final normalizedBoardId = boardId.trim();

    final normalizedBlockId = blockId.trim();

    final normalizedSourcePath = sourcePath.trim();

    if (normalizedBoardId.isEmpty) {
      _setErrorMessage(
        'boardId não pode estar vazio.',
      );

      return null;
    }

    if (normalizedBlockId.isEmpty) {
      _setErrorMessage(
        'blockId não pode estar vazio.',
      );

      return null;
    }

    if (normalizedSourcePath.isEmpty) {
      _setErrorMessage(
        'sourcePath não pode estar vazio.',
      );

      return null;
    }

    _isImporting = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final attachment = await _repository.importAttachment(
        boardId: normalizedBoardId,
        blockId: normalizedBlockId,
        sourcePath: normalizedSourcePath,
      );

      _currentBoardId = normalizedBoardId;

      _replace(
        attachment,
        notify: false,
      );

      return attachment;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao importar arquivo.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return null;
    } finally {
      _isImporting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // READ TEXT
  // ============================================================

  Future<
    String?
  >
  readText(
    BoardAttachment attachment,
  ) async {
    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      return await _repository.readText(
        attachment,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao abrir arquivo.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return null;
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SAVE TEXT
  // ============================================================

  Future<
    BoardAttachment?
  >
  saveText({
    required BoardAttachment attachment,
    required String content,
  }) async {
    if (_isSaving) {
      return null;
    }

    _isSaving = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final updated = await _repository.saveText(
        attachment: attachment,
        content: content,
      );

      _replace(
        updated,
        notify: false,
      );

      return updated;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao salvar arquivo.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return null;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SAVE METADATA
  // ============================================================

  Future<
    BoardAttachment?
  >
  saveMetadata(
    BoardAttachment attachment,
  ) async {
    if (_isSaving) {
      return null;
    }

    _isSaving = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final updated = await _repository.saveMetadata(
        attachment,
      );

      _replace(
        updated,
        notify: false,
      );

      return updated;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao salvar metadados do documento.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return null;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    bool
  >
  deleteAttachment(
    BoardAttachment attachment,
  ) async {
    if (_isDeleting) {
      return false;
    }

    _isDeleting = true;

    _errorMessage = null;

    notifyListeners();

    try {
      await _repository.delete(
        attachment,
      );

      _attachments.removeWhere(
        (
          item,
        ) =>
            item.id ==
            attachment.id,
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao remover documento.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return false;
    } finally {
      _isDeleting = false;

      notifyListeners();
    }
  }

  // ============================================================
  // DELETE BY ID
  // ============================================================

  Future<
    bool
  >
  deleteById(
    String id,
  ) async {
    final attachment =
        getById(
          id,
        ) ??
        await _repository.getById(
          id,
        );

    if (attachment ==
        null) {
      return true;
    }

    return deleteAttachment(
      attachment,
    );
  }

  // ============================================================
  // REMOVE LOCAL - COMPATIBILITY
  // ============================================================
  //
  // Mantemos o nome antigo para não quebrar widgets que ainda
  // chamam removeLocal().
  //
  // Agora a operação passa pelo Repository:
  //
  // soft delete SQLite
  //      ↓
  // SyncQueue
  //      ↓
  // remoção do arquivo local
  //
  // ============================================================

  Future<
    bool
  >
  removeLocal(
    BoardAttachment attachment,
  ) {
    return deleteAttachment(
      attachment,
    );
  }

  // ============================================================
  // RESTORE
  // ============================================================

  Future<
    BoardAttachment?
  >
  restore(
    String id,
  ) async {
    _errorMessage = null;

    try {
      final restored = await _repository.restore(
        id,
      );

      if (restored !=
          null) {
        _replace(
          restored,
        );
      }

      return restored;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao restaurar documento.',
        error: error,
        stackTrace: stackTrace,
      );

      return null;
    }
  }

  // ============================================================
  // LOCAL FILE EXISTS
  // ============================================================

  Future<
    bool
  >
  localFileExists(
    BoardAttachment attachment,
  ) async {
    _errorMessage = null;

    try {
      return await _repository.localFileExists(
        attachment,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao verificar arquivo local.',
        error: error,
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // ============================================================
  // GET BY ID - MEMORY
  // ============================================================

  BoardAttachment? getById(
    String id,
  ) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final attachment in _attachments) {
      if (attachment.id ==
          normalizedId) {
        return attachment;
      }
    }

    return null;
  }

  // ============================================================
  // GET BY ID - LOCAL DATABASE
  // ============================================================

  Future<
    BoardAttachment?
  >
  getByIdFromStorage(
    String id,
  ) {
    return _repository.getById(
      id,
    );
  }

  // ============================================================
  // GET BY BLOCK
  // ============================================================

  List<
    BoardAttachment
  >
  getByBlockId(
    String blockId,
  ) {
    final normalizedBlockId = blockId.trim();

    if (normalizedBlockId.isEmpty) {
      return const <
        BoardAttachment
      >[];
    }

    final result = _attachments
        .where(
          (
            attachment,
          ) =>
              attachment.blockId ==
                  normalizedBlockId &&
              !attachment.isDeleted,
        )
        .toList(
          growable: false,
        );

    result.sort(
      (
        first,
        second,
      ) => second.createdAt.compareTo(
        first.createdAt,
      ),
    );

    return result;
  }

  // ============================================================
  // LOAD BLOCK FROM DATABASE
  // ============================================================

  Future<
    List<
      BoardAttachment
    >
  >
  loadByBlockId({
    required String boardId,
    required String blockId,
  }) async {
    _isLoading = true;

    _errorMessage = null;

    notifyListeners();

    try {
      final loaded = await _repository.loadByBlockId(
        boardId: boardId,
        blockId: blockId,
      );

      for (final attachment in loaded) {
        _replace(
          attachment,
          notify: false,
        );
      }

      return loaded;
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao carregar documentos do bloco.',
        error: error,
        stackTrace: stackTrace,
        notify: false,
      );

      return const <
        BoardAttachment
      >[];
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // COUNT BY BOARD
  // ============================================================

  Future<
    int
  >
  countByBoard(
    String boardId,
  ) async {
    try {
      return await _repository.countByBoard(
        boardId,
      );
    } catch (
      error,
      stackTrace
    ) {
      _setError(
        message: 'Erro ao contar documentos da lousa.',
        error: error,
        stackTrace: stackTrace,
      );

      return 0;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    _attachments.clear();

    _currentBoardId = null;

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // REPLACE
  // ============================================================

  void _replace(
    BoardAttachment attachment, {
    bool notify = true,
  }) {
    final index = _attachments.indexWhere(
      (
        item,
      ) =>
          item.id ==
          attachment.id,
    );

    if (attachment.isDeleted) {
      if (index >=
          0) {
        _attachments.removeAt(
          index,
        );
      }
    } else if (index <
        0) {
      _attachments.add(
        attachment,
      );
    } else {
      _attachments[index] = attachment;
    }

    _sort();

    if (notify) {
      notifyListeners();
    }
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sort() {
    _attachments.sort(
      (
        first,
        second,
      ) => second.createdAt.compareTo(
        first.createdAt,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _setErrorMessage(
    String message,
  ) {
    _errorMessage = message;

    debugPrint(
      '[BOARD ATTACHMENT] '
      '$message',
    );

    notifyListeners();
  }

  void _setError({
    required String message,
    required Object error,
    required StackTrace stackTrace,
    bool notify = true,
  }) {
    _errorMessage = '$message $error';

    debugPrint(
      '[BOARD ATTACHMENT] '
      '$message '
      '$error',
    );

    debugPrint(
      stackTrace.toString(),
    );

    if (notify) {
      notifyListeners();
    }
  }
}
