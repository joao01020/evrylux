import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_concept.dart';

class SupabaseBrainService {
  SupabaseBrainService({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // TABELAS
  // ============================================================

  static const String notesTable = 'brain_notes';

  static const String conceptsTable = 'brain_concepts';

  // ============================================================
  // CLIENT
  // ============================================================

  SupabaseClient get client {
    return _client;
  }

  // ============================================================
  // AUTH
  // ============================================================

  String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  bool get isAuthenticated {
    return currentUserId !=
        null;
  }

  // ============================================================
  // SALVAR NOTA
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
  }) async {
    final now = DateTime.now().toUtc();

    final data =
        <
          String,
          dynamic
        >{
          'topic': topic.trim(),
          'title': title.trim(),
          'content': content.trim(),
          'updated_at': now.toIso8601String(),
        };

    final userId = currentUserId;

    if (userId !=
        null) {
      data['user_id'] = userId;
    }

    try {
      // ========================================================
      // INSERT
      // ========================================================

      if (id ==
              null ||
          id.trim().isEmpty) {
        data['created_at'] = now.toIso8601String();

        final response = await _client
            .from(
              notesTable,
            )
            .insert(
              data,
            )
            .select()
            .single();

        return Map<
          String,
          dynamic
        >.from(
          response,
        );
      }

      // ========================================================
      // UPDATE
      // ========================================================

      var query = _client
          .from(
            notesTable,
          )
          .update(
            data,
          )
          .eq(
            'id',
            id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.select().single();

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao salvar nota.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // CARREGAR NOTAS
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  loadNotes() async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            notesTable,
          )
          .select();

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.order(
        'updated_at',
        ascending: false,
      );

      return List<
        Map<
          String,
          dynamic
        >
      >.from(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao carregar notas.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR NOTA
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getNote(
    String id,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            notesTable,
          )
          .select()
          .eq(
            'id',
            id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao buscar nota.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR NOTA
  // ============================================================

  Future<
    void
  >
  deleteNote(
    String id,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            notesTable,
          )
          .delete()
          .eq(
            'id',
            id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      await query;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao excluir nota.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // SALVAR CONCEITO
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
  }) async {
    final now = DateTime.now().toUtc();

    final data =
        <
          String,
          dynamic
        >{
          'id': concept.id,
          'note_id': noteId,
          'title': concept.title.trim(),
          'description': concept.description.trim(),
          'type': concept.type.name,
          'updated_at': now.toIso8601String(),
        };

    final userId = currentUserId;

    if (userId !=
        null) {
      data['user_id'] = userId;
    }

    try {
      // ========================================================
      // VERIFICAR SE JÁ EXISTE
      // ========================================================

      final existing = await getConcept(
        concept.id,
      );

      // ========================================================
      // INSERT
      // ========================================================

      if (existing ==
          null) {
        data['created_at'] = now.toIso8601String();

        final response = await _client
            .from(
              conceptsTable,
            )
            .insert(
              data,
            )
            .select()
            .single();

        return Map<
          String,
          dynamic
        >.from(
          response,
        );
      }

      // ========================================================
      // UPDATE
      // ========================================================

      final updateData =
          Map<
            String,
            dynamic
          >.from(
            data,
          );

      updateData.remove(
        'id',
      );

      var query = _client
          .from(
            conceptsTable,
          )
          .update(
            updateData,
          )
          .eq(
            'id',
            concept.id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.select().single();

      return Map<
        String,
        dynamic
      >.from(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao salvar conhecimento.',
      );

      debugPrint(
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // CARREGAR TODOS OS CONCEITOS
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadConcepts() async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select();

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return _mapConceptList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao carregar conhecimentos.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // CARREGAR POR TIPO
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadConceptsByType(
    BrainConceptType type,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select()
          .eq(
            'type',
            type.name,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.order(
        'created_at',
        ascending: false,
      );

      return _mapConceptList(
        response,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao carregar ${type.name}.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // BUSCAR CONCEITO
  // ============================================================

  Future<
    BrainConcept?
  >
  getConcept(
    String id,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select()
          .eq(
            'id',
            id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      final response = await query.maybeSingle();

      if (response ==
          null) {
        return null;
      }

      return _mapConcept(
        Map<
          String,
          dynamic
        >.from(
          response,
        ),
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao buscar conhecimento.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR CONCEITO
  // ============================================================

  Future<
    void
  >
  deleteConcept(
    String id,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .delete()
          .eq(
            'id',
            id,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      await query;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao excluir conhecimento.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // EXCLUIR CONCEITOS DE UMA NOTA
  // ============================================================

  Future<
    void
  >
  deleteConceptsByNoteId(
    String noteId,
  ) async {
    try {
      final userId = currentUserId;

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .delete()
          .eq(
            'note_id',
            noteId,
          );

      if (userId !=
          null) {
        query = query.eq(
          'user_id',
          userId,
        );
      }

      await query;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'SupabaseBrainService: erro ao excluir conhecimentos da nota.',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // MAP CONCEPT
  // ============================================================

  BrainConcept _mapConcept(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return BrainConcept(
      id:
          json['id']?.toString() ??
          '',
      title:
          json['title']?.toString() ??
          '',
      description:
          json['description']?.toString() ??
          '',
      type: BrainConceptTypeExtension.fromString(
        json['type']?.toString(),
      ),
    );
  }

  // ============================================================
  // MAP LIST
  // ============================================================

  List<
    BrainConcept
  >
  _mapConceptList(
    dynamic response,
  ) {
    if (response
        is! List) {
      return [];
    }

    return response.map(
      (
        item,
      ) {
        return _mapConcept(
          Map<
            String,
            dynamic
          >.from(
            item,
          ),
        );
      },
    ).toList();
  }
}
