import '../models/brain_concept.dart';
import '../services/supabase_brain_service.dart';

class BrainRepository {
  BrainRepository({
    SupabaseBrainService? remote,
  }) : _remote =
           remote ??
           SupabaseBrainService();

  final SupabaseBrainService _remote;

  // ============================================================
  // AUTH
  // ============================================================

  bool get isAuthenticated {
    return _remote.isAuthenticated;
  }

  String? get currentUserId {
    return _remote.currentUserId;
  }

  // ============================================================
  // NOTAS
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  saveNote({
    String? id,
    required String topic,
    required String title,
    required String content,
  }) {
    return _remote.saveNote(
      id: id,
      topic: topic,
      title: title,
      content: content,
    );
  }

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  loadNotes() {
    return _remote.loadNotes();
  }

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getNote(
    String id,
  ) {
    return _remote.getNote(
      id,
    );
  }

  Future<
    void
  >
  deleteNote(
    String id,
  ) {
    return _remote.deleteNote(
      id,
    );
  }

  // ============================================================
  // CONHECIMENTOS
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  saveConcept({
    required BrainConcept concept,
    String? noteId,
  }) {
    return _remote.saveConcept(
      concept: concept,
      noteId: noteId,
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadConcepts() {
    return _remote.loadConcepts();
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadConceptsByType(
    BrainConceptType type,
  ) {
    return _remote.loadConceptsByType(
      type,
    );
  }

  Future<
    BrainConcept?
  >
  getConcept(
    String id,
  ) {
    return _remote.getConcept(
      id,
    );
  }

  Future<
    void
  >
  deleteConcept(
    String id,
  ) {
    return _remote.deleteConcept(
      id,
    );
  }

  Future<
    void
  >
  deleteConceptsByNoteId(
    String noteId,
  ) {
    return _remote.deleteConceptsByNoteId(
      noteId,
    );
  }

  // ============================================================
  // ATALHOS
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadOnlyConcepts() {
    return loadConceptsByType(
      BrainConceptType.concept,
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadQuestions() {
    return loadConceptsByType(
      BrainConceptType.question,
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadExamples() {
    return loadConceptsByType(
      BrainConceptType.example,
    );
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadWarnings() {
    return loadConceptsByType(
      BrainConceptType.warning,
    );
  }
}
