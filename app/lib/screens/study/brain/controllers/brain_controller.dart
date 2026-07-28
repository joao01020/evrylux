import 'package:flutter/material.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../services/brain_storage.dart';

class BrainController extends ChangeNotifier {
  final BrainStorage _storage;

  BrainController({BrainStorage storage = const BrainStorage()})
    : _storage = storage;

  // =========================================================
  // CONTROLLERS DOS CAMPOS
  // =========================================================

  final TextEditingController topicController = TextEditingController();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController contentController = TextEditingController();

  final FocusNode contentFocusNode = FocusNode();

  // =========================================================
  // ESTADO
  // =========================================================

  List<BrainFile> _notes = [];

  List<BrainConcept> _concepts = [];

  BrainFile? _selectedNote;

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isDisposed = false;

  String? _errorMessage;

  String? _successMessage;

  // =========================================================
  // GETTERS
  // =========================================================

  List<BrainFile> get notes {
    return List<BrainFile>.unmodifiable(_notes);
  }

  List<BrainConcept> get concepts {
    return List<BrainConcept>.unmodifiable(_concepts);
  }

  BrainFile? get selectedNote {
    return _selectedNote;
  }

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

  bool get hasSelectedNote {
    return _selectedNote != null;
  }

  bool get hasNotes {
    return _notes.isNotEmpty;
  }

  bool get hasConcepts {
    return _concepts.isNotEmpty;
  }

  // =========================================================
  // INICIALIZAÇÃO
  // =========================================================

  Future<void> initialize() async {
    await loadNotes();
  }

  // =========================================================
  // CARREGAR NOTAS
  // =========================================================

  Future<void> loadNotes() async {
    _setLoading(true);

    _clearMessages();

    try {
      final loadedNotes = await _storage.loadNotes();

      _notes = loadedNotes;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar suas anotações.';
    } finally {
      _setLoading(false);
    }
  }

  // =========================================================
  // NOVA NOTA
  // =========================================================

  void createNewNote() {
    _selectedNote = null;

    topicController.clear();
    titleController.clear();
    contentController.clear();

    _concepts = [];

    _clearMessages();

    _safeNotifyListeners();

    contentFocusNode.requestFocus();
  }

  // =========================================================
  // ABRIR NOTA
  // =========================================================

  Future<bool> openNote(BrainFile note) async {
    _clearMessages();

    try {
      final loadedNote = await _storage.openNote(note.path);

      _selectedNote = loadedNote;

      topicController.text = loadedNote.topic;

      titleController.text = loadedNote.title;

      contentController.text = loadedNote.content;

      _concepts = List<BrainConcept>.from(loadedNote.concepts);

      _safeNotifyListeners();

      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível abrir a anotação.';

      _safeNotifyListeners();

      return false;
    }
  }

  // =========================================================
  // VALIDAR NOTA
  // =========================================================

  String? validateNote() {
    final topic = topicController.text.trim();

    final title = titleController.text.trim();

    final content = contentController.text.trim();

    if (topic.isEmpty) {
      return 'Informe um tema, por exemplo: Programação C++.';
    }

    if (title.isEmpty) {
      return 'Informe o título da anotação.';
    }

    if (content.isEmpty) {
      return 'Escreva algum conteúdo antes de salvar.';
    }

    return null;
  }

  // =========================================================
  // SALVAR NOTA
  // =========================================================

  Future<bool> saveNote() async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    final validationMessage = validateNote();

    if (validationMessage != null) {
      _errorMessage = validationMessage;

      _safeNotifyListeners();

      return false;
    }

    final topic = topicController.text.trim();

    final title = titleController.text.trim();

    final content = contentController.text.trim();

    _setSaving(true);

    try {
      final savedNote = await _storage.saveNote(
        topic: topic,
        title: title,
        content: content,
        concepts: List<BrainConcept>.from(_concepts),
        existingPath: _selectedNote?.path,
      );

      final updatedNotes = await _storage.loadNotes();

      _selectedNote = savedNote;

      _notes = updatedNotes;

      _concepts = List<BrainConcept>.from(savedNote.concepts);

      _successMessage = 'Anotação salva em arquivo Markdown ✅';

      return true;
    } on FormatException catch (error) {
      _errorMessage = error.message;

      return false;
    } catch (_) {
      _errorMessage = 'Não foi possível salvar a anotação.';

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // =========================================================
  // EXCLUIR NOTA
  // =========================================================

  Future<bool> deleteNote(BrainFile note) async {
    _clearMessages();

    try {
      await _storage.deleteNote(note);

      final updatedNotes = await _storage.loadNotes();

      _notes = updatedNotes;

      final isSelectedNote = _selectedNote?.path == note.path;

      if (isSelectedNote) {
        _clearSelectedNote();
      }

      _successMessage = 'Anotação excluída.';

      _safeNotifyListeners();

      return true;
    } catch (_) {
      _errorMessage = 'Não foi possível excluir a anotação.';

      _safeNotifyListeners();

      return false;
    }
  }

  // =========================================================
  // ADICIONAR CONCEITO
  // =========================================================

  void addConcept(BrainConcept concept) {
    _concepts = [..._concepts, concept];

    _successMessage = 'Conceito adicionado.';

    _errorMessage = null;

    _safeNotifyListeners();
  }

  // =========================================================
  // ATUALIZAR CONCEITO
  // =========================================================

  void updateConcept({required int index, required BrainConcept concept}) {
    if (index < 0 || index >= _concepts.length) {
      return;
    }

    final updatedConcepts = List<BrainConcept>.from(_concepts);

    updatedConcepts[index] = concept;

    _concepts = updatedConcepts;

    _successMessage = 'Conceito atualizado.';

    _errorMessage = null;

    _safeNotifyListeners();
  }

  // =========================================================
  // REMOVER CONCEITO
  // =========================================================

  void removeConcept(int index) {
    if (index < 0 || index >= _concepts.length) {
      return;
    }

    final updatedConcepts = List<BrainConcept>.from(_concepts);

    updatedConcepts.removeAt(index);

    _concepts = updatedConcepts;

    _successMessage = 'Conceito removido.';

    _errorMessage = null;

    _safeNotifyListeners();
  }

  // =========================================================
  // LIMPAR CONCEITOS
  // =========================================================

  void clearConcepts() {
    _concepts = [];

    _safeNotifyListeners();
  }

  // =========================================================
  // SELEÇÃO
  // =========================================================

  void clearSelection() {
    _clearSelectedNote();

    _clearMessages();

    _safeNotifyListeners();
  }

  void _clearSelectedNote() {
    _selectedNote = null;

    topicController.clear();
    titleController.clear();
    contentController.clear();

    _concepts = [];
  }

  // =========================================================
  // MENSAGENS
  // =========================================================

  void clearMessages() {
    _clearMessages();

    _safeNotifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;

    _successMessage = null;
  }

  // =========================================================
  // ESTADOS INTERNOS
  // =========================================================

  void _setLoading(bool value) {
    _isLoading = value;

    _safeNotifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;

    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  // =========================================================
  // FINALIZAÇÃO
  // =========================================================

  @override
  void dispose() {
    _isDisposed = true;

    topicController.dispose();
    titleController.dispose();
    contentController.dispose();
    contentFocusNode.dispose();

    super.dispose();
  }
}
