import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_concept.dart';

// ============================================================
// SUPABASE BRAIN SERVICE
// ============================================================
//
// Papel atual:
//
// SyncQueue / SyncService
//          ↓
// SupabaseBrainService
//          ↓
// Supabase
//
// Este service NÃO é mais a fonte principal para salvar na UI.
// Ele funciona como destino remoto da sincronização e também
// como fonte para hidratação/recuperação remota quando necessário.
//
// ============================================================

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

  String _requireUserId() {
    final userId = currentUserId?.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return userId;
  }

  // ============================================================
  // SALVAR NOTA
  // ============================================================
  //
  // Este service é o ALVO REMOTO da sincronização.
  //
  // O salvamento principal já aconteceu localmente antes de
  // chegar aqui.
  //
  // Requisitos desta operação:
  //
  // - aceitar um ID criado localmente;
  // - inserir se ainda não existir;
  // - atualizar se já existir;
  // - preservar created_at em edições;
  // - ser idempotente para retries da SyncQueue.
  //
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final userId = _requireUserId();

    final cleanTopic = topic.trim();

    final cleanTitle = title.trim();

    final cleanContent = content.trim();

    if (cleanTopic.isEmpty) {
      throw const FormatException(
        'O tema da anotação não pode estar vazio.',
      );
    }

    if (cleanTitle.isEmpty) {
      throw const FormatException(
        'O título da anotação não pode estar vazio.',
      );
    }

    if (cleanContent.isEmpty) {
      throw const FormatException(
        'O conteúdo da anotação não pode estar vazio.',
      );
    }

    final now = DateTime.now().toUtc();

    final normalizedId = id?.trim();

    try {
      // ========================================================
      // SEM ID
      // ========================================================
      //
      // Compatibilidade com chamadas antigas.
      //
      // O fluxo offline-first novo sempre deve enviar um ID
      // estável criado antes da sincronização.
      //
      // ========================================================

      if (normalizedId ==
              null ||
          normalizedId.isEmpty) {
        final response = await _client
            .from(
              notesTable,
            )
            .insert(
              {
                'user_id': userId,
                'topic': cleanTopic,
                'title': cleanTitle,
                'content': cleanContent,
                'created_at':
                    (createdAt ??
                            now)
                        .toUtc()
                        .toIso8601String(),
                'updated_at':
                    (updatedAt ??
                            now)
                        .toUtc()
                        .toIso8601String(),
              },
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
      // VERIFICAR EXISTÊNCIA
      // ========================================================
      //
      // Fazemos isso para preservar created_at quando a mesma
      // nota for sincronizada novamente.
      //
      // ========================================================

      final existing = await _client
          .from(
            notesTable,
          )
          .select(
            'id, created_at',
          )
          .eq(
            'id',
            normalizedId,
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      final existingCreatedAt =
          existing ==
              null
          ? null
          : _parseDate(
              existing['created_at'],
            );

      final effectiveCreatedAt =
          existingCreatedAt ??
          createdAt?.toUtc() ??
          now;

      final effectiveUpdatedAt =
          updatedAt?.toUtc() ??
          now;

      // ========================================================
      // UPSERT
      // ========================================================
      //
      // CREATE e UPDATE usam o mesmo caminho.
      //
      // Isso é importante porque a SyncQueue pode repetir uma
      // operação após queda de conexão sem duplicar a nota.
      //
      // ========================================================

      final response = await _client
          .from(
            notesTable,
          )
          .upsert(
            {
              'id': normalizedId,
              'user_id': userId,
              'topic': cleanTopic,
              'title': cleanTitle,
              'content': cleanContent,
              'created_at': effectiveCreatedAt.toIso8601String(),
              'updated_at': effectiveUpdatedAt.toIso8601String(),
            },
            onConflict: 'id',
          )
          .select()
          .single();

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
        'SupabaseBrainService: erro ao sincronizar nota.',
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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            notesTable,
          )
          .select();

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            notesTable,
          )
          .select()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            notesTable,
          )
          .delete()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
  //
  // Assim como as notas, conceitos chegam aqui depois de já
  // terem sido persistidos localmente.
  //
  // A operação é idempotente para suportar retry automático.
  //
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) async {
    final userId = _requireUserId();

    final conceptId = concept.id.trim();

    final title = concept.title.trim();

    final description = concept.description.trim();

    if (conceptId.isEmpty) {
      throw const FormatException(
        'O ID do conhecimento não pode estar vazio.',
      );
    }

    if (title.isEmpty) {
      throw const FormatException(
        'O título do conhecimento não pode estar vazio.',
      );
    }

    if (description.isEmpty) {
      throw const FormatException(
        'A descrição do conhecimento não pode estar vazia.',
      );
    }

    final normalizedNoteId = noteId?.trim();

    final now = DateTime.now().toUtc();

    try {
      // ========================================================
      // CREATED AT EXISTENTE
      // ========================================================

      final existing = await _client
          .from(
            conceptsTable,
          )
          .select(
            'id, created_at',
          )
          .eq(
            'id',
            conceptId,
          )
          .eq(
            'user_id',
            userId,
          )
          .maybeSingle();

      final existingCreatedAt =
          existing ==
              null
          ? null
          : _parseDate(
              existing['created_at'],
            );

      final effectiveCreatedAt =
          existingCreatedAt ??
          createdAt?.toUtc() ??
          now;

      final effectiveUpdatedAt =
          updatedAt?.toUtc() ??
          now;

      // ========================================================
      // UPSERT
      // ========================================================

      final response = await _client
          .from(
            conceptsTable,
          )
          .upsert(
            {
              'id': conceptId,
              'user_id': userId,
              'note_id':
                  normalizedNoteId ==
                          null ||
                      normalizedNoteId.isEmpty
                  ? null
                  : normalizedNoteId,
              'title': title,
              'description': description,
              'type': concept.type.name,
              'created_at': effectiveCreatedAt.toIso8601String(),
              'updated_at': effectiveUpdatedAt.toIso8601String(),
            },
            onConflict: 'id',
          )
          .select()
          .single();

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
        'SupabaseBrainService: erro ao sincronizar conhecimento.',
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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select();

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select()
          .eq(
            'type',
            type.name,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .select()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .delete()
          .eq(
            'id',
            id,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
      final userId = _requireUserId();

      dynamic query = _client
          .from(
            conceptsTable,
          )
          .delete()
          .eq(
            'note_id',
            noteId,
          );

      query = query.eq(
        'user_id',
        userId,
      );

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
  // PARSE DATE
  // ============================================================

  DateTime? _parseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    )?.toUtc();
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
