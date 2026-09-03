import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../services/brain_storage.dart';
import '../services/supabase_brain_service.dart';
import '../sync/services/brain_sync_queue_service.dart';
import '../vault/stores/brain_concept_vault_store.dart';
import '../vault/stores/brain_note_vault_store.dart';

// ============================================================
// BRAIN REPOSITORY
// ============================================================
//
// Arquitetura OFFLINE-FIRST:
//
// UI
//  ↓
// BrainController
//  ↓
// BrainRepository
//  ↓
// BrainStorage local mirror + Vault criptografado
//  ↓
// BrainSyncQueueService
//  ↓
// brain_e2ee_object
//  ↓
// Supabase brain_objects
//
// REGRA PRINCIPAL:
//
// A tela considera o salvamento concluído assim que o arquivo
// local foi persistido.
//
// A internet NÃO é requisito para:
//
// - criar nota;
// - editar nota;
// - excluir nota;
// - consultar notas;
// - consultar conceitos;
// - alimentar o calendário.
//
// O Supabase passa a ser sincronização remota.
//
// ============================================================

class BrainRepository {
  BrainRepository({
    SupabaseBrainService? remote,
    BrainStorage? local,
    SyncQueue? syncQueue,
    SyncService? syncService,
    BrainNoteVaultStore? noteVaultStore,
    BrainConceptVaultStore? conceptVaultStore,
    BrainSyncQueueService? brainSyncQueueService,
  }) : _remote =
           remote ??
           SupabaseBrainService(),
       _local =
           local ??
           const BrainStorage(),
       _noteVaultStore = noteVaultStore,
       _conceptVaultStore = conceptVaultStore,
       _brainSyncQueueService = brainSyncQueueService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseBrainService _remote;

  final BrainStorage _local;

  final BrainNoteVaultStore? _noteVaultStore;

  final BrainConceptVaultStore? _conceptVaultStore;

  final BrainSyncQueueService? _brainSyncQueueService;

  // ============================================================
  // SYNC ENTITY TYPES
  // ============================================================

  static const String noteEntityType = 'brain_note';

  static const String conceptEntityType = 'brain_concept';

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
  // SAVE NOTE — VAULT / E2EE
  // ============================================================
  //
  // Fluxo atual:
  //
  // BrainStorage (mirror Markdown local)
  //      ↓
  // BrainNoteVaultStore
  //      ↓
  // BrainVaultObjectType.note
  //      ↓
  // BrainSyncQueueService
  //      ↓
  // brain_e2ee_object
  //
  // Nenhum title/content entra na SyncQueue antiga.
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
  }) async {
    final cleanTopic = topic.trim();
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTopic.isEmpty) {
      throw const FormatException(
        'Informe o tema da anotação.',
      );
    }

    if (cleanTitle.isEmpty) {
      throw const FormatException(
        'Informe o título da anotação.',
      );
    }

    if (cleanContent.isEmpty) {
      throw const FormatException(
        'Escreva algum conteúdo.',
      );
    }

    final existingLocalPath = _localPathFromId(
      id,
    );

    BrainFile? previousNote;

    if (existingLocalPath !=
        null) {
      try {
        previousNote = await _local.openNote(
          existingLocalPath,
        );
      } catch (
        _
      ) {
        previousNote = null;
      }
    }

    final saved = await _local.saveNote(
      topic: cleanTopic,
      title: cleanTitle,
      content: cleanContent,
      concepts:
          previousNote?.concepts ??
          const <
            BrainConcept
          >[],
      existingPath: existingLocalPath,
    );

    debugPrint(
      '[BRAIN REPOSITORY] '
      'Nota salva no mirror local: ${saved.path}',
    );

    final userId = currentUserId?.trim();

    final legacyRemoteId =
        userId ==
                null ||
            userId.isEmpty
        ? null
        : _resolveRemoteNoteId(
            userId: userId,
            originalId: id,
            localPath: saved.path,
          );

    final noteStore = _noteVaultStore;

    if (noteStore !=
        null) {
      final encryptedObject = await noteStore.saveNote(
        saved,
        legacyRemoteId: legacyRemoteId,
      );

      await _brainSyncQueueService?.enqueueObject(
        encryptedObject,
      );

      debugPrint(
        '[BRAIN REPOSITORY] '
        'Nota salva no Vault criptografado: '
        '${encryptedObject.header.objectId}',
      );
    }

    return _noteToRow(
      saved,
      remoteId: legacyRemoteId,
      userId: userId,
    );
  }

  // ============================================================
  // LOAD NOTES
  // ============================================================
  //
  // Sempre local.
  //
  // Não fazemos uma chamada de rede antes de abrir a tela.
  //
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
    final notes = await _local.loadNotes();

    final userId = currentUserId?.trim();

    return notes
        .map(
          (
            note,
          ) {
            final remoteId =
                userId ==
                        null ||
                    userId.isEmpty
                ? null
                : _remoteNoteId(
                    userId: userId,
                    localPath: note.path,
                  );

            return _noteToRow(
              note,
              remoteId: remoteId,
              userId: userId,
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // GET NOTE
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
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    // ==========================================================
    // LOCAL PATH
    // ==========================================================

    final directPath = _localPathFromId(
      cleanId,
    );

    if (directPath !=
        null) {
      try {
        final note = await _local.openNote(
          directPath,
        );

        final userId = currentUserId?.trim();

        final remoteId =
            userId ==
                    null ||
                userId.isEmpty
            ? null
            : _remoteNoteId(
                userId: userId,
                localPath: note.path,
              );

        return _noteToRow(
          note,
          remoteId: remoteId,
          userId: userId,
        );
      } catch (
        _
      ) {
        return null;
      }
    }

    // ==========================================================
    // LEGACY REMOTE ID
    // ==========================================================
    //
    // Procura se algum arquivo local corresponde ao UUID remoto.
    //
    // ==========================================================

    final userId = currentUserId?.trim();

    if (userId !=
            null &&
        userId.isNotEmpty) {
      final notes = await _local.loadNotes();

      for (final note in notes) {
        final remoteId = _remoteNoteId(
          userId: userId,
          localPath: note.path,
        );

        if (remoteId ==
            cleanId) {
          return _noteToRow(
            note,
            remoteId: remoteId,
            userId: userId,
          );
        }
      }
    }

    return null;
  }

  // ============================================================
  // DELETE NOTE — TOMBSTONE E2EE
  // ============================================================

  Future<
    void
  >
  deleteNote(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw const FormatException(
        'A anotação não possui um identificador válido.',
      );
    }

    final localNotes = await _local.loadNotes();

    BrainFile? target;

    final directPath = _localPathFromId(
      cleanId,
    );

    if (directPath !=
        null) {
      for (final note in localNotes) {
        if (_samePath(
          note.path,
          directPath,
        )) {
          target = note;
          break;
        }
      }

      if (target ==
          null) {
        try {
          target = await _local.openNote(
            directPath,
          );
        } catch (
          _
        ) {
          target = null;
        }
      }
    }

    final userId = currentUserId?.trim();

    if (target ==
            null &&
        userId !=
            null &&
        userId.isNotEmpty) {
      for (final note in localNotes) {
        final legacyId = _remoteNoteId(
          userId: userId,
          localPath: note.path,
        );

        if (legacyId ==
            cleanId) {
          target = note;
          break;
        }
      }
    }

    if (target ==
        null) {
      if (directPath !=
          null) {
        final file = File(
          directPath,
        );

        if (await file.exists()) {
          await file.delete();
        }

        if (await file.exists()) {
          throw FileSystemException(
            'O arquivo local continuou existindo após a exclusão.',
            directPath,
          );
        }

        final tombstone = await _noteVaultStore?.deleteNoteByPath(
          directPath,
        );

        if (tombstone !=
            null) {
          await _brainSyncQueueService?.enqueueObject(
            tombstone,
          );
        }

        return;
      }

      if (_looksLikeUuid(
        cleanId,
      )) {
        final tombstone = await _noteVaultStore?.deleteNoteByLegacyRemoteId(
          cleanId,
        );

        if (tombstone !=
            null) {
          await _brainSyncQueueService?.enqueueObject(
            tombstone,
          );
        }

        return;
      }

      throw StateError(
        'Não foi possível localizar a anotação local para excluir.',
      );
    }

    final notesToDelete =
        <
          BrainFile
        >[];

    for (final note in localNotes) {
      final sameLocalPath = _samePath(
        note.path,
        target.path,
      );

      final sameHistoricalCopy = _sameNoteContent(
        note,
        target,
      );

      if (sameLocalPath ||
          sameHistoricalCopy) {
        if (!notesToDelete.any(
          (
            item,
          ) => _samePath(
            item.path,
            note.path,
          ),
        )) {
          notesToDelete.add(
            note,
          );
        }
      }
    }

    if (!notesToDelete.any(
      (
        item,
      ) => _samePath(
        item.path,
        target!.path,
      ),
    )) {
      notesToDelete.add(
        target,
      );
    }

    // Tombstone conceitos pertencentes às cópias removidas.
    final conceptIds =
        <
          String
        >{};

    for (final note in notesToDelete) {
      for (final concept in note.concepts) {
        if (concept.id.trim().isNotEmpty) {
          conceptIds.add(
            concept.id.trim(),
          );
        }
      }
    }

    for (final note in notesToDelete) {
      final path = note.path.trim();

      if (path.isEmpty) {
        continue;
      }

      final file = File(
        path,
      );

      debugPrint(
        '[BRAIN REPOSITORY] '
        'Excluindo arquivo local: $path',
      );

      await _local.deleteNote(
        note,
      );

      if (await file.exists()) {
        await file.delete();
      }

      if (await file.exists()) {
        throw FileSystemException(
          'Não foi possível excluir fisicamente a anotação.',
          path,
        );
      }

      final noteTombstone = await _noteVaultStore?.deleteNoteByPath(
        path,
      );

      if (noteTombstone !=
          null) {
        await _brainSyncQueueService?.enqueueObject(
          noteTombstone,
        );
      }

      debugPrint(
        '[BRAIN REPOSITORY] '
        'Arquivo local removido: $path',
      );
    }

    for (final conceptId in conceptIds) {
      final conceptTombstone = await _conceptVaultStore?.deleteConcept(
        conceptId,
      );

      if (conceptTombstone !=
          null) {
        await _brainSyncQueueService?.enqueueObject(
          conceptTombstone,
        );
      }
    }

    debugPrint(
      '[BRAIN REPOSITORY] '
      'Exclusão concluída com tombstones E2EE.',
    );
  }

  // ============================================================
  // SAVE CONCEPT — VAULT / E2EE
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
    final cleanNoteId = noteId?.trim();

    BrainFile? note;

    if (cleanNoteId !=
            null &&
        cleanNoteId.isNotEmpty) {
      final localPath = _localPathFromId(
        cleanNoteId,
      );

      if (localPath !=
          null) {
        try {
          note = await _local.openNote(
            localPath,
          );
        } catch (
          _
        ) {
          note = null;
        }
      }
    }

    BrainFile? updatedNote;

    if (note !=
        null) {
      final concepts =
          List<
            BrainConcept
          >.from(
            note.concepts,
          );

      final existingIndex = concepts.indexWhere(
        (
          item,
        ) =>
            item.id ==
            concept.id,
      );

      if (existingIndex >=
          0) {
        concepts[existingIndex] = concept;
      } else {
        concepts.add(
          concept,
        );
      }

      updatedNote = await _local.saveNote(
        topic: note.topic,
        title: note.title,
        content: note.content,
        concepts: concepts,
        existingPath: note.path,
      );

      final userId = currentUserId?.trim();

      final legacyRemoteId =
          userId ==
                  null ||
              userId.isEmpty
          ? null
          : _remoteNoteId(
              userId: userId,
              localPath: updatedNote.path,
            );

      final encryptedNote = await _noteVaultStore?.saveNote(
        updatedNote,
        legacyRemoteId: legacyRemoteId,
      );

      if (encryptedNote !=
          null) {
        await _brainSyncQueueService?.enqueueObject(
          encryptedNote,
        );
      }
    }

    final encryptedConcept = await _conceptVaultStore?.saveConcept(
      concept: concept,
      sourceNotePath:
          updatedNote?.path ??
          note?.path ??
          cleanNoteId,
    );

    if (encryptedConcept !=
        null) {
      await _brainSyncQueueService?.enqueueObject(
        encryptedConcept,
      );
    }

    return <
      String,
      dynamic
    >{
      'id': concept.id,
      'note_id':
          updatedNote?.path ??
          note?.path ??
          cleanNoteId,
      'title': concept.title,
      'description': concept.description,
      'type': concept.type.name,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // LOAD CONCEPTS
  // ============================================================

  Future<
    List<
      BrainConcept
    >
  >
  loadConcepts() {
    final store = _conceptVaultStore;

    if (store !=
        null) {
      return store.loadConcepts();
    }

    return _local.loadAllConcepts();
  }

  Future<
    List<
      BrainConcept
    >
  >
  loadConceptsByType(
    BrainConceptType type,
  ) {
    final store = _conceptVaultStore;

    if (store !=
        null) {
      return store.loadConceptsByType(
        type,
      );
    }

    return _local.loadConceptsByType(
      type,
    );
  }

  // ============================================================
  // GET CONCEPT
  // ============================================================

  Future<
    BrainConcept?
  >
  getConcept(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final store = _conceptVaultStore;

    if (store !=
        null) {
      final fromVault = await store.getConcept(
        cleanId,
      );

      if (fromVault !=
          null) {
        return fromVault;
      }
    }

    final concepts = await _local.loadAllConcepts();

    for (final concept in concepts) {
      if (concept.id ==
          cleanId) {
        return concept;
      }
    }

    return null;
  }

  // ============================================================
  // DELETE CONCEPT + SOURCE NOTE
  // ============================================================
  //
  // Use este método nas telas:
  //
  // - Conceitos;
  // - Perguntas;
  // - Exemplos;
  // - Atenções.
  //
  // Regra:
  //
  // ao excluir uma classificação, a anotação que originou essa
  // classificação também é excluída.
  //
  // Assim o mesmo conteúdo desaparece de:
  //
  // - tela da categoria;
  // - Cérebro;
  // - calendário;
  // - arquivos Markdown locais;
  // - Supabase, via SyncQueue.
  //
  // Se a anotação possuir outras classificações, elas também são
  // removidas, pois pertencem à mesma anotação que está sendo
  // excluída.
  //
  // ============================================================

  Future<
    void
  >
  deleteConceptAndSourceNote(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    // ==========================================================
    // LOCALIZAR ANOTAÇÃO DE ORIGEM ANTES DE ALTERAR CONCEITOS
    // ==========================================================

    final notes = await _local.loadNotes();

    BrainFile? sourceNote;

    for (final note in notes) {
      final containsConcept = note.concepts.any(
        (
          concept,
        ) =>
            concept.id ==
            cleanId,
      );

      if (!containsConcept) {
        continue;
      }

      sourceNote = note;

      break;
    }

    // ==========================================================
    // SEM NOTA DE ORIGEM
    // ==========================================================
    //
    // Pode acontecer com conceito legado/orfão.
    //
    // Nesse caso apagamos somente o conceito.
    //
    // ==========================================================

    if (sourceNote ==
        null) {
      await deleteConcept(
        cleanId,
      );

      return;
    }

    final sourcePath = sourceNote.path.trim();

    if (sourcePath.isEmpty) {
      throw StateError(
        'A anotação de origem não possui um caminho local válido.',
      );
    }

    debugPrint(
      '[BRAIN REPOSITORY] Exclusão em cascata iniciada.',
    );

    debugPrint(
      '[BRAIN REPOSITORY] Conceito: $cleanId',
    );

    debugPrint(
      '[BRAIN REPOSITORY] Nota de origem: $sourcePath',
    );

    // ==========================================================
    // 1. EXCLUIR TODAS AS CLASSIFICAÇÕES DA NOTA
    // ==========================================================
    //
    // Isso limpa os arquivos de _concepts e registra DELETE para
    // cada classificação na SyncQueue.
    //
    // ==========================================================

    await deleteConceptsByNoteId(
      sourcePath,
    );

    // ==========================================================
    // 2. EXCLUIR A ANOTAÇÃO FÍSICA
    // ==========================================================
    //
    // deleteNote() já confirma File.exists() antes de concluir.
    //
    // ==========================================================

    await deleteNote(
      sourcePath,
    );

    // ==========================================================
    // 3. CONFIRMAÇÃO FINAL
    // ==========================================================

    final remaining = await _local.loadNotes();

    final stillExists = remaining.any(
      (
        note,
      ) => _samePath(
        note.path,
        sourcePath,
      ),
    );

    if (stillExists) {
      throw StateError(
        'A anotação de origem ainda existe após a exclusão em cascata.',
      );
    }

    debugPrint(
      '[BRAIN REPOSITORY] Exclusão em cascata concluída.',
    );
  }

  // ============================================================
  // DELETE CONCEPT — TOMBSTONE E2EE
  // ============================================================

  Future<
    void
  >
  deleteConcept(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    final notes = await _local.loadNotes();

    for (final note in notes) {
      final contains = note.concepts.any(
        (
          concept,
        ) =>
            concept.id ==
            cleanId,
      );

      if (!contains) {
        continue;
      }

      final updatedConcepts = note.concepts
          .where(
            (
              concept,
            ) =>
                concept.id !=
                cleanId,
          )
          .toList();

      final updatedNote = await _local.saveNote(
        topic: note.topic,
        title: note.title,
        content: note.content,
        concepts: updatedConcepts,
        existingPath: note.path,
      );

      final userId = currentUserId?.trim();

      final legacyRemoteId =
          userId ==
                  null ||
              userId.isEmpty
          ? null
          : _remoteNoteId(
              userId: userId,
              localPath: updatedNote.path,
            );

      final encryptedNote = await _noteVaultStore?.saveNote(
        updatedNote,
        legacyRemoteId: legacyRemoteId,
      );

      if (encryptedNote !=
          null) {
        await _brainSyncQueueService?.enqueueObject(
          encryptedNote,
        );
      }
    }

    final tombstone = await _conceptVaultStore?.deleteConcept(
      cleanId,
    );

    if (tombstone !=
        null) {
      await _brainSyncQueueService?.enqueueObject(
        tombstone,
      );
    }
  }

  // ============================================================
  // DELETE CONCEPTS BY NOTE
  // ============================================================

  Future<
    void
  >
  deleteConceptsByNoteId(
    String noteId,
  ) async {
    final cleanNoteId = noteId.trim();

    if (cleanNoteId.isEmpty) {
      return;
    }

    final localPath = _localPathFromId(
      cleanNoteId,
    );

    if (localPath ==
        null) {
      return;
    }

    BrainFile? note;

    try {
      note = await _local.openNote(
        localPath,
      );
    } catch (
      _
    ) {
      note = null;
    }

    if (note ==
        null) {
      return;
    }

    final conceptIds = note.concepts
        .map(
          (
            concept,
          ) => concept.id.trim(),
        )
        .where(
          (
            id,
          ) => id.isNotEmpty,
        )
        .toList(
          growable: false,
        );

    final updatedNote = await _local.saveNote(
      topic: note.topic,
      title: note.title,
      content: note.content,
      concepts:
          const <
            BrainConcept
          >[],
      existingPath: note.path,
    );

    final userId = currentUserId?.trim();

    final legacyRemoteId =
        userId ==
                null ||
            userId.isEmpty
        ? null
        : _remoteNoteId(
            userId: userId,
            localPath: updatedNote.path,
          );

    final encryptedNote = await _noteVaultStore?.saveNote(
      updatedNote,
      legacyRemoteId: legacyRemoteId,
    );

    if (encryptedNote !=
        null) {
      await _brainSyncQueueService?.enqueueObject(
        encryptedNote,
      );
    }

    for (final conceptId in conceptIds) {
      final tombstone = await _conceptVaultStore?.deleteConcept(
        conceptId,
      );

      if (tombstone !=
          null) {
        await _brainSyncQueueService?.enqueueObject(
          tombstone,
        );
      }
    }
  }

  // ============================================================
  // SHORTCUTS
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

  // ============================================================
  // OPTIONAL REMOTE HYDRATION
  // ============================================================
  //
  // Não é chamada automaticamente por loadNotes().
  //
  // Serve para uma etapa futura de:
  //
  // Supabase -> cache local
  //
  // em login novo / outro dispositivo.
  //
  // Mantemos aqui o acesso explícito à fonte remota sem tornar
  // a abertura normal da tela dependente da rede.
  //
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  loadRemoteNotes() {
    return _remote.loadNotes();
  }

  // ============================================================
  // NOTE -> CONTROLLER ROW
  // ============================================================

  Map<
    String,
    dynamic
  >
  _noteToRow(
    BrainFile note, {
    String? remoteId,
    String? userId,
  }) {
    return <
      String,
      dynamic
    >{
      // BrainController.path recebe o caminho local.
      'id': note.path,

      'remote_id': remoteId,

      'user_id': userId,

      'topic': note.topic,

      'title': note.title,

      'content': note.content,

      'created_at': note.createdAt.toUtc().toIso8601String(),

      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // SAME PATH
  // ============================================================

  bool _samePath(
    String first,
    String second,
  ) {
    final firstPath = File(
      first,
    ).absolute.path;

    final secondPath = File(
      second,
    ).absolute.path;

    return firstPath ==
        secondPath;
  }

  // ============================================================
  // SAME NOTE CONTENT
  // ============================================================
  //
  // Usado apenas para remover duplicatas históricas geradas
  // durante a migração para offline-first.
  //
  // Não usa createdAt/updatedAt porque cópias antigas podem ter
  // timestamps diferentes mesmo contendo a mesma anotação.
  //
  // ============================================================

  bool _sameNoteContent(
    BrainFile first,
    BrainFile second,
  ) {
    return first.topic.trim() ==
            second.topic.trim() &&
        first.title.trim() ==
            second.title.trim() &&
        first.content.trim() ==
            second.content.trim();
  }

  // ============================================================
  // LOCAL PATH
  // ============================================================

  String? _localPathFromId(
    String? value,
  ) {
    final clean = value?.trim();

    if (clean ==
            null ||
        clean.isEmpty) {
      return null;
    }

    if (!clean.toLowerCase().endsWith(
      '.md',
    )) {
      return null;
    }

    return clean;
  }

  // ============================================================
  // REMOTE ID
  // ============================================================

  String _resolveRemoteNoteId({
    required String userId,
    required String? originalId,
    required String localPath,
  }) {
    final cleanOriginal = originalId?.trim();

    // Preserva UUID remoto antigo durante migração.
    if (cleanOriginal !=
            null &&
        _looksLikeUuid(
          cleanOriginal,
        )) {
      return cleanOriginal;
    }

    return _remoteNoteId(
      userId: userId,
      localPath: localPath,
    );
  }

  String _remoteNoteId({
    required String userId,
    required String localPath,
  }) {
    return _deterministicUuid(
      '$userId|$localPath',
    );
  }

  // ============================================================
  // DETERMINISTIC UUID
  // ============================================================
  //
  // Solução transitória enquanto BrainFile ainda não possui
  // um campo "id" persistido.
  //
  // Gera sempre o mesmo UUID para o mesmo user/path.
  //
  // ============================================================

  String _deterministicUuid(
    String seed,
  ) {
    final a = _fnv32(
      'a|$seed',
    );

    final b = _fnv32(
      'b|$seed',
    );

    final c = _fnv32(
      'c|$seed',
    );

    final d = _fnv32(
      'd|$seed',
    );

    final hex =
        '${_hex32(a)}'
        '${_hex32(b)}'
        '${_hex32(c)}'
        '${_hex32(d)}';

    // UUID version 4 / variant RFC 4122 visualmente válido.
    final versioned =
        '${hex.substring(0, 12)}'
        '4'
        '${hex.substring(13, 16)}'
        '${_variantNibble(hex[16])}'
        '${hex.substring(17)}';

    return '${versioned.substring(0, 8)}-'
        '${versioned.substring(8, 12)}-'
        '${versioned.substring(12, 16)}-'
        '${versioned.substring(16, 20)}-'
        '${versioned.substring(20, 32)}';
  }

  int _fnv32(
    String value,
  ) {
    var hash = 0x811C9DC5;

    for (final unit in value.codeUnits) {
      hash ^= unit;

      hash =
          (hash *
              0x01000193) &
          0xFFFFFFFF;
    }

    return hash;
  }

  String _hex32(
    int value,
  ) {
    return value
        .toRadixString(
          16,
        )
        .padLeft(
          8,
          '0',
        );
  }

  String _variantNibble(
    String original,
  ) {
    final value =
        int.tryParse(
          original,
          radix: 16,
        ) ??
        0;

    final variant =
        (value &
            0x3) |
        0x8;

    return variant.toRadixString(
      16,
    );
  }

  bool _looksLikeUuid(
    String value,
  ) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{4}-'
      r'[0-9a-fA-F]{12}$',
    ).hasMatch(
      value.trim(),
    );
  }
}
