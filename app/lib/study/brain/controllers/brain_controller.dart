import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
import '../repositories/brain_repository.dart';

// ============================================================
// BRAIN CONTROLLER
// ============================================================
//
// O controller NÃO grava arquivos diretamente.
//
// Toda persistência passa por:
//
// BrainController
//      ↓
// BrainRepository
//      ↓
// BrainStorage
//      ↓
// SyncQueue / SyncService
//
// Isso evita arquivos Markdown duplicados ou órfãos.
//
// ============================================================

class BrainController extends ChangeNotifier {
  // ============================================================
  // REPOSITORY
  // ============================================================

  final BrainRepository _repository;

  BrainController({BrainRepository? repository})
    : _repository = repository ?? BrainRepository();

  // ============================================================
  // CONTROLLERS DOS CAMPOS
  // ============================================================
  //
  // FASE 09:
  //
  // topicController permanece TEMPORARIAMENTE apenas para:
  //
  // - abrir anotações antigas que ainda possuem topic;
  // - compatibilidade com telas/serviços legados;
  // - migração gradual do BrainStorage.
  //
  // Novas capturas não dependem mais de Tema.
  //
  // ============================================================

  final TextEditingController topicController = TextEditingController();

  final TextEditingController titleController = TextEditingController();

  final TextEditingController contentController = TextEditingController();

  final FocusNode contentFocusNode = FocusNode();

  // ============================================================
  // ESTADO
  // ============================================================

  List<BrainFile> _notes = <BrainFile>[];

  List<BrainConcept> _concepts = <BrainConcept>[];

  // ============================================================
  // FASE 13 — FONTES DO CONHECIMENTO
  // ============================================================

  List<BrainSource> _sources = <BrainSource>[];

  BrainFile? _selectedNote;

  bool _isLoading = false;

  bool _isSaving = false;

  bool _isInitialized = false;

  bool _isDisposed = false;

  String? _errorMessage;

  String? _successMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  List<BrainFile> get notes {
    return List<BrainFile>.unmodifiable(_notes);
  }

  List<BrainConcept> get concepts {
    return List<BrainConcept>.unmodifiable(_concepts);
  }

  List<BrainSource> get sources {
    return List<BrainSource>.unmodifiable(_sources);
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

  bool get isInitialized {
    return _isInitialized;
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

  bool get hasSources {
    return _sources.isNotEmpty;
  }

  int get sourcesCount {
    return _sources.length;
  }

  bool get isAuthenticated {
    return _repository.isAuthenticated;
  }

  String? get currentUserId {
    return _repository.currentUserId;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);

    _clearMessages();

    try {
      await _loadNotesInternal();

      _isInitialized = true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao inicializar.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível carregar o Cérebro.';
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================

  Future<void> loadNotes() async {
    if (_isLoading) {
      return;
    }

    _setLoading(true);

    _clearMessages();

    try {
      await _loadNotesInternal();
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao carregar anotações.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível carregar suas anotações.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadNotesInternal() async {
    final rows = await _repository.loadNotes();

    _notes = rows.map((row) {
      return _brainFileFromDatabase(row);
    }).toList();
  }

  // ============================================================
  // CREATE NEW NOTE
  // ============================================================

  void createNewNote() {
    _selectedNote = null;

    topicController.clear();

    titleController.clear();

    contentController.clear();

    _concepts = <BrainConcept>[];

    _sources = <BrainSource>[];

    _clearMessages();

    _safeNotifyListeners();

    Future<void>.delayed(Duration.zero, () {
      if (_isDisposed) {
        return;
      }

      if (!contentFocusNode.canRequestFocus) {
        return;
      }

      contentFocusNode.requestFocus();
    });
  }

  // ============================================================
  // OPEN NOTE
  // ============================================================

  Future<bool> openNote(BrainFile note) async {
    _clearMessages();

    try {
      final noteId = note.path.trim();

      Map<String, dynamic>? row;

      if (noteId.isNotEmpty) {
        row = await _repository.getNote(noteId);
      }

      final loadedNote = row == null ? note : _brainFileFromDatabase(row);

      _selectedNote = loadedNote;

      topicController.text = loadedNote.topic;

      titleController.text = loadedNote.title;

      contentController.text = loadedNote.content;

      _concepts = List<BrainConcept>.from(loadedNote.concepts);

      _sources = List<BrainSource>.from(loadedNote.sources);

      _safeNotifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao abrir anotação.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível abrir a anotação.';

      _safeNotifyListeners();

      return false;
    }
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  String? validateNote() {
    final title = titleController.text.trim();

    final content = contentController.text.trim();

    if (title.isEmpty) {
      return 'Informe o título da anotação.';
    }

    if (content.isEmpty) {
      return 'Escreva algum conteúdo antes de salvar.';
    }

    return null;
  }

  // ============================================================
  // SAVE NOTE
  // ============================================================

  Future<bool> saveNote({
    String successMessage = 'Conhecimento salvo neste dispositivo ✅',
  }) async {
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

    // ========================================================
    // FASE 09 — TOPIC É APENAS LEGADO
    // ========================================================
    //
    // Pode estar vazio.
    //
    // BrainRepository faz a normalização temporária necessária
    // para o BrainStorage legado sem exigir Tema da UI.
    //
    // ========================================================

    final topic = topicController.text.trim();

    final title = titleController.text.trim();

    final content = contentController.text.trim();

    _setSaving(true);

    try {
      final currentNoteId = _selectedNote?.path.trim();

      // ========================================================
      // SAVE NOTE
      // ========================================================

      final savedRow = await _repository.saveNote(
        id: currentNoteId != null && currentNoteId.isNotEmpty
            ? currentNoteId
            : null,
        topic: topic,
        title: title,
        content: content,
      );

      final noteId = savedRow['id']?.toString().trim() ?? '';

      if (noteId.isEmpty) {
        throw StateError(
          'O repositório não retornou o caminho local da anotação.',
        );
      }

      // ========================================================
      // SAVE KNOWLEDGE
      // ========================================================

      for (final concept in _concepts) {
        await _repository.saveConcept(concept: concept, noteId: noteId);
      }

      // ========================================================
      // IMPORTANTE: NÃO SALVAR NOVAMENTE NO BRAIN STORAGE
      // ========================================================
      //
      // O BrainRepository já fez:
      //
      // BrainStorage.saveNote()
      //      ↓
      // arquivo .md local
      //      ↓
      // SyncQueue
      //
      // Salvar novamente aqui criava uma SEGUNDA responsabilidade
      // de persistência e podia deixar arquivos órfãos quando
      // metadados ou título eram alterados.
      //
      // O calendário lê o mesmo arquivo criado pelo repository.
      //
      // ========================================================

      // ========================================================
      // UPDATE LOCAL STATE
      // ========================================================

      _selectedNote = BrainFile(
        topic: topic,

        title: title,

        // BrainFile.path guarda o caminho LOCAL do .md.
        //
        // O remote_id pertence apenas à camada de sincronização.
        path: noteId,

        content: content,

        concepts: List<BrainConcept>.from(_concepts),

        sources: List<BrainSource>.from(_sources),

        createdAt:
            _parseDate(savedRow['created_at']) ??
            _selectedNote?.createdAt ??
            DateTime.now(),

        updatedAt: _parseDate(savedRow['updated_at']) ?? DateTime.now(),
      );

      await _loadNotesInternal();

      _successMessage = successMessage;

      return true;
    } on FormatException catch (error) {
      _errorMessage = error.message;

      return false;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao salvar anotação.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível salvar a anotação neste dispositivo.';

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // DELETE NOTE
  // ============================================================
  //
  // Fluxo:
  //
  // Controller
  //      ↓
  // Repository
  //      ↓
  // remove conceitos relacionados
  //      ↓
  // remove fisicamente o .md
  //      ↓
  // confirma exclusão local
  //      ↓
  // SyncQueue recebe DELETE
  //
  // Depois recarregamos as notas DO DISCO.
  //
  // A UI não remove apenas um item da lista em memória.
  // O estado exibido passa a refletir exatamente o que ainda
  // existe no BrainStorage.
  //
  // ============================================================

  Future<bool> deleteNote(BrainFile note) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    _setSaving(true);

    try {
      final notePath = note.path.trim();

      if (notePath.isEmpty) {
        throw StateError('A anotação não possui um caminho local válido.');
      }

      // ========================================================
      // DELETE CONCEPTS
      // ========================================================
      //
      // Isso remove os conhecimentos relacionados localmente e
      // registra os DELETEs correspondentes para sincronização.
      //
      // ========================================================

      await _repository.deleteConceptsByNoteId(notePath);

      // ========================================================
      // DELETE NOTE
      // ========================================================
      //
      // O repository atual só conclui se a exclusão física local
      // tiver sido confirmada.
      //
      // ========================================================

      await _repository.deleteNote(notePath);

      // ========================================================
      // RECARREGAR ESTADO REAL DO DISCO
      // ========================================================

      await _loadNotesInternal();

      // ========================================================
      // VERIFICAÇÃO EXTRA DO CONTROLLER
      // ========================================================

      final stillExists = _notes.any((item) {
        return item.path.trim() == notePath;
      });

      if (stillExists) {
        throw StateError('A anotação ainda existe localmente após a exclusão.');
      }

      // ========================================================
      // LIMPAR SELEÇÃO
      // ========================================================

      if (_selectedNote?.path.trim() == notePath) {
        _clearSelectedNote();
      }

      _successMessage = 'Anotação excluída deste dispositivo.';

      _safeNotifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao excluir anotação.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível excluir a anotação localmente.';

      _safeNotifyListeners();

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // ADD CONCEPT
  // ============================================================

  Future<bool> addConcept(BrainConcept concept) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    // ========================================================
    // DUPLICATE BY ID
    // ========================================================

    final exists = _concepts.any((item) {
      return item.id == concept.id;
    });

    if (exists) {
      return true;
    }

    _concepts = [..._concepts, concept];

    _successMessage = '${concept.label} preparado para salvar.';

    _safeNotifyListeners();

    return true;
  }

  // ============================================================
  // UPDATE CONCEPT
  // ============================================================

  Future<bool> updateConcept({
    required int index,
    required BrainConcept concept,
  }) async {
    if (_isSaving) {
      return false;
    }

    if (index < 0 || index >= _concepts.length) {
      return false;
    }

    _clearMessages();

    final updated = List<BrainConcept>.from(_concepts);

    updated[index] = concept;

    _concepts = updated;

    _safeNotifyListeners();

    final noteId = _selectedNote?.path.trim();

    if (noteId != null && noteId.isNotEmpty) {
      try {
        await _repository.saveConcept(concept: concept, noteId: noteId);
      } catch (error, stackTrace) {
        debugPrint('BrainController: erro ao atualizar conhecimento.');

        debugPrint('BrainController: $error');

        debugPrintStack(stackTrace: stackTrace);

        _errorMessage = 'Não foi possível atualizar o conhecimento.';

        _safeNotifyListeners();

        return false;
      }
    }

    _successMessage = '${concept.label} atualizado.';

    _safeNotifyListeners();

    return true;
  }

  // ============================================================
  // REMOVE CONCEPT
  // ============================================================

  Future<bool> removeConcept(int index) async {
    if (_isSaving) {
      return false;
    }

    if (index < 0 || index >= _concepts.length) {
      return false;
    }

    _clearMessages();

    final concept = _concepts[index];

    final updated = List<BrainConcept>.from(_concepts);

    updated.removeAt(index);

    _concepts = updated;

    _safeNotifyListeners();

    try {
      await _repository.deleteConcept(concept.id);
    } catch (error) {
      debugPrint(
        'BrainController: conhecimento ainda não estava salvo remotamente: $error',
      );
    }

    _successMessage = '${concept.label} removido.';

    _safeNotifyListeners();

    return true;
  }

  // ============================================================
  // REMOVE CONCEPT BY ID
  // ============================================================

  Future<bool> removeConceptById(String conceptId) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    try {
      await _repository.deleteConcept(conceptId);

      _concepts.removeWhere((item) {
        return item.id == conceptId;
      });

      _successMessage = 'Conhecimento removido.';

      _safeNotifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao remover conhecimento.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível remover o conhecimento.';

      _safeNotifyListeners();

      return false;
    }
  }

  // ============================================================
  // CLEAR CONCEPTS
  // ============================================================

  Future<bool> clearConcepts() async {
    if (_isSaving) {
      return false;
    }

    if (_concepts.isEmpty) {
      return true;
    }

    _clearMessages();

    final previous = List<BrainConcept>.from(_concepts);

    _concepts = <BrainConcept>[];

    _safeNotifyListeners();

    for (final concept in previous) {
      try {
        await _repository.deleteConcept(concept.id);
      } catch (error) {
        debugPrint(
          'BrainController: conceito não removido remotamente: $error',
        );
      }
    }

    _successMessage = 'Conhecimentos removidos.';

    _safeNotifyListeners();

    return true;
  }

  // ============================================================
  // LOAD SOURCES
  // ============================================================
  //
  // FASE 13 — FONTES DO CONHECIMENTO
  //
  // Fontes são persistidas no Vault criptografado.
  //
  // ============================================================

  Future<List<BrainSource>> loadSourcesForSelectedNote() async {
    final noteId = _selectedNote?.path.trim();

    if (noteId == null || noteId.isEmpty) {
      _sources = <BrainSource>[];

      _safeNotifyListeners();

      return const <BrainSource>[];
    }

    try {
      final loaded = await _repository.getSourcesByNote(noteId);

      _sources = List<BrainSource>.from(loaded);

      _syncSelectedNoteSources();

      _safeNotifyListeners();

      return List<BrainSource>.unmodifiable(_sources);
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao carregar fontes.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível carregar as fontes da anotação.';

      _safeNotifyListeners();

      return const <BrainSource>[];
    }
  }

  // ============================================================
  // ADD SOURCE
  // ============================================================

  Future<bool> addSource(BrainSource source) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    final noteId = _selectedNote?.path.trim();

    if (noteId == null || noteId.isEmpty) {
      _errorMessage = 'Salve a anotação antes de adicionar uma fonte.';

      _safeNotifyListeners();

      return false;
    }

    _setSaving(true);

    try {
      final updatedNote = await _repository.addSourceToNote(
        noteId: noteId,
        source: source,
      );

      _sources = List<BrainSource>.from(updatedNote.sources);

      _selectedNote = updatedNote;

      await _loadNotesInternal();

      _successMessage = 'Fonte adicionada.';

      _safeNotifyListeners();

      return true;
    } on FormatException catch (error) {
      _errorMessage = error.message;

      _safeNotifyListeners();

      return false;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao adicionar fonte.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível adicionar a fonte.';

      _safeNotifyListeners();

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // UPDATE SOURCE
  // ============================================================

  Future<bool> updateSource(BrainSource source) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    final noteId = _selectedNote?.path.trim();

    if (noteId == null || noteId.isEmpty) {
      _errorMessage = 'A anotação não possui um identificador válido.';

      _safeNotifyListeners();

      return false;
    }

    _setSaving(true);

    try {
      final updatedNote = await _repository.updateSourceInNote(
        noteId: noteId,
        source: source,
      );

      _sources = List<BrainSource>.from(updatedNote.sources);

      _selectedNote = updatedNote;

      await _loadNotesInternal();

      _successMessage = 'Fonte atualizada.';

      _safeNotifyListeners();

      return true;
    } on FormatException catch (error) {
      _errorMessage = error.message;

      _safeNotifyListeners();

      return false;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao atualizar fonte.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível atualizar a fonte.';

      _safeNotifyListeners();

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // REMOVE SOURCE
  // ============================================================

  Future<bool> removeSource(String sourceId) async {
    if (_isSaving) {
      return false;
    }

    _clearMessages();

    final noteId = _selectedNote?.path.trim();

    if (noteId == null || noteId.isEmpty) {
      _errorMessage = 'A anotação não possui um identificador válido.';

      _safeNotifyListeners();

      return false;
    }

    _setSaving(true);

    try {
      final updatedNote = await _repository.removeSourceFromNote(
        noteId: noteId,
        sourceId: sourceId,
      );

      _sources = List<BrainSource>.from(updatedNote.sources);

      _selectedNote = updatedNote;

      await _loadNotesInternal();

      _successMessage = 'Fonte removida.';

      _safeNotifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao remover fonte.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível remover a fonte.';

      _safeNotifyListeners();

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // CLEAR SOURCES
  // ============================================================

  Future<bool> clearSources() async {
    if (_isSaving) {
      return false;
    }

    final noteId = _selectedNote?.path.trim();

    if (noteId == null || noteId.isEmpty) {
      return false;
    }

    if (_sources.isEmpty) {
      return true;
    }

    _clearMessages();

    _setSaving(true);

    try {
      final updatedNote = await _repository.clearSourcesFromNote(noteId);

      _sources = List<BrainSource>.from(updatedNote.sources);

      _selectedNote = updatedNote;

      await _loadNotesInternal();

      _successMessage = 'Fontes removidas.';

      _safeNotifyListeners();

      return true;
    } catch (error, stackTrace) {
      debugPrint('BrainController: erro ao remover fontes.');

      debugPrint('BrainController: $error');

      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = 'Não foi possível remover as fontes.';

      _safeNotifyListeners();

      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // SYNC SELECTED NOTE SOURCES
  // ============================================================

  void _syncSelectedNoteSources() {
    final selected = _selectedNote;

    if (selected == null) {
      return;
    }

    _selectedNote = selected.copyWith(
      sources: List<BrainSource>.from(_sources),
    );
  }

  // ============================================================
  // LOAD ALL KNOWLEDGE
  // ============================================================

  Future<List<BrainConcept>> loadAllConcepts() {
    return _repository.loadConcepts();
  }

  // ============================================================
  // LOAD BY TYPE
  // ============================================================

  Future<List<BrainConcept>> loadConceptsByType(BrainConceptType type) {
    return _repository.loadConceptsByType(type);
  }

  // ============================================================
  // CONCEPTS
  // ============================================================

  Future<List<BrainConcept>> loadOnlyConcepts() {
    return _repository.loadOnlyConcepts();
  }

  // ============================================================
  // QUESTIONS
  // ============================================================

  Future<List<BrainConcept>> loadQuestions() {
    return _repository.loadQuestions();
  }

  // ============================================================
  // EXAMPLES
  // ============================================================

  Future<List<BrainConcept>> loadExamples() {
    return _repository.loadExamples();
  }

  // ============================================================
  // WARNINGS
  // ============================================================

  Future<List<BrainConcept>> loadWarnings() {
    return _repository.loadWarnings();
  }

  // ============================================================
  // CLEAR SELECTION
  // ============================================================

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

    _concepts = <BrainConcept>[];

    _sources = <BrainSource>[];
  }

  // ============================================================
  // DATABASE → BRAIN FILE
  // ============================================================

  BrainFile _brainFileFromDatabase(Map<String, dynamic> row) {
    return BrainFile(
      // Topic é legado na Fase 09.
      //
      // Anotações antigas preservam o valor existente.
      // Registros novos/sem topic recebem um valor neutro somente
      // para manter BrainFile compatível enquanto o modelo ainda
      // possui esse campo.
      topic: () {
        final value = row['topic']?.toString().trim() ?? '';

        return value.isEmpty ? 'Sem tema' : value;
      }(),

      title: row['title']?.toString().trim() ?? '',

      // ========================================================
      // O BrainFile ainda possui "path" por compatibilidade
      // com a versão antiga baseada em Markdown.
      //
      // Agora guardamos aqui o ID da linha no Supabase.
      // ========================================================
      path: row['id']?.toString().trim() ?? '',

      content: row['content']?.toString() ?? '',

      concepts: const <BrainConcept>[],

      sources: _parseSources(row['sources']),

      createdAt:
          _parseDate(row['created_at']) ??
          _parseDate(row['updated_at']) ??
          DateTime.now(),

      updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
    );
  }

  // ============================================================
  // PARSE SOURCES
  // ============================================================

  List<BrainSource> _parseSources(dynamic raw) {
    if (raw == null) {
      return const <BrainSource>[];
    }

    if (raw is! Iterable) {
      return const <BrainSource>[];
    }

    final result = <BrainSource>[];

    for (final item in raw) {
      if (item is! Map) {
        continue;
      }

      try {
        final source = BrainSource.fromJson(Map<String, dynamic>.from(item));

        if (!source.isValid) {
          continue;
        }

        result.add(source);
      } catch (_) {
        // Ignora apenas a fonte inválida.
      }
    }

    return List<BrainSource>.unmodifiable(result);
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }

  // ============================================================
  // MESSAGES
  // ============================================================

  void clearMessages() {
    _clearMessages();

    _safeNotifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;

    _successMessage = null;
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(bool value) {
    _isLoading = value;

    _safeNotifyListeners();
  }

  // ============================================================
  // SAVING
  // ============================================================

  void _setSaving(bool value) {
    _isSaving = value;

    _safeNotifyListeners();
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotifyListeners() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

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
