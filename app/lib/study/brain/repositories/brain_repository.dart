import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../services/brain_storage.dart';
import '../services/supabase_brain_service.dart';

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
// BrainStorage local
//  ↓
// SyncQueue
//  ↓
// SyncService
//  ↓
// Supabase
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
  }) : _remote =
           remote ??
           SupabaseBrainService(),
       _local =
           local ??
           const BrainStorage(),
       _syncQueue =
           syncQueue ??
           SyncQueue(),
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseBrainService _remote;

  final BrainStorage _local;

  final SyncQueue _syncQueue;

  final SyncService? _syncService;

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
  // SAVE NOTE
  // ============================================================
  //
  // 1. salva local;
  // 2. devolve sucesso para a UI;
  // 3. registra operação na SyncQueue;
  // 4. solicita sincronização sem bloquear a tela.
  //
  // O parâmetro "id" é mantido por compatibilidade com o
  // BrainController atual.
  //
  // Nesta fase ele pode representar:
  //
  // - caminho local .md;
  // - antigo UUID remoto.
  //
  // Se for caminho .md, ele é usado para editar o mesmo arquivo.
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
    final userId = _requireUserId();

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

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

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
      '[BRAIN REPOSITORY] Nota salva localmente: ${saved.path}',
    );

    // ==========================================================
    // REMOTE ID
    // ==========================================================
    //
    // O modelo atual ainda não possui um "id" local persistido
    // dentro do BrainFile.
    //
    // Para a fila ser idempotente, geramos um UUID determinístico
    // a partir de:
    //
    // user + caminho local.
    //
    // Quando BrainFile ganhar um campo id próprio, este helper
    // pode ser removido e o ID local passa a ser usado diretamente.
    //
    // ==========================================================

    final remoteId = _resolveRemoteNoteId(
      userId: userId,
      originalId: id,
      localPath: saved.path,
    );

    final operation =
        previousNote ==
            null
        ? SyncOperation.create
        : SyncOperation.update;

    // ==========================================================
    // QUEUE
    // ==========================================================

    await _syncQueue.enqueue(
      entityType: noteEntityType,
      entityId: remoteId,
      operation: operation,
      payload:
          <
            String,
            dynamic
          >{
            'id': remoteId,
            'user_id': userId,
            'topic': saved.topic,
            'title': saved.title,
            'content': saved.content,
            'created_at': saved.createdAt.toUtc().toIso8601String(),
            'updated_at': saved.updatedAt.toUtc().toIso8601String(),
          },
    );

    _syncService?.requestSync();

    // ==========================================================
    // CONTROLLER COMPATIBILITY
    // ==========================================================
    //
    // O BrainController usa row['id'] como BrainFile.path.
    //
    // Retornamos o caminho LOCAL de propósito.
    //
    // Assim, a partir daqui, edição e exclusão continuam
    // funcionando offline.
    //
    // remote_id fica disponível separadamente para debug/migração.
    //
    // ==========================================================

    return _noteToRow(
      saved,
      remoteId: remoteId,
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
  // DELETE NOTE
  // ============================================================
  //
  // EXCLUSÃO FÍSICA OBRIGATÓRIA:
  //
  // 1. resolve a nota local pelo caminho .md;
  // 2. se necessário, resolve pelo UUID remoto determinístico;
  // 3. remove também duplicatas locais históricas da mesma nota;
  // 4. confirma com File.exists() que o arquivo realmente sumiu;
  // 5. somente depois registra DELETE na SyncQueue;
  // 6. se não conseguir apagar localmente, lança erro.
  //
  // Isso impede a interface de dizer "excluída" enquanto o
  // Markdown ainda continua no ghost_brain.
  //
  // ============================================================

  Future<
    void
  >
  deleteNote(
    String id,
  ) async {
    final userId = _requireUserId();

    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      throw const FormatException(
        'A anotação não possui um identificador válido.',
      );
    }

    // ==========================================================
    // CARREGAR ESTADO LOCAL ATUAL
    // ==========================================================

    final localNotes = await _local.loadNotes();

    BrainFile? target;

    // ==========================================================
    // 1. CAMINHO LOCAL DIRETO
    // ==========================================================

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

    // ==========================================================
    // 2. UUID REMOTO / LEGACY
    // ==========================================================

    if (target ==
        null) {
      for (final note in localNotes) {
        final remoteId = _remoteNoteId(
          userId: userId,
          localPath: note.path,
        );

        if (remoteId ==
            cleanId) {
          target = note;

          break;
        }
      }
    }

    // ==========================================================
    // REMOTE ID BASE
    // ==========================================================

    var requestedRemoteId =
        _looksLikeUuid(
          cleanId,
        )
        ? cleanId
        : '';

    if (target !=
        null) {
      requestedRemoteId = _remoteNoteId(
        userId: userId,
        localPath: target.path,
      );
    }

    // ==========================================================
    // 3. LOCAL FIRST - EXCLUSÃO FÍSICA
    // ==========================================================
    //
    // Durante a migração antiga o mesmo conteúdo podia ter sido
    // salvo mais de uma vez:
    //
    // repository.saveNote()
    // +
    // antigo cache local do BrainController
    //
    // Por isso, quando encontramos a nota alvo, apagamos também
    // cópias locais equivalentes da MESMA anotação.
    //
    // Critério:
    //
    // - mesmo caminho; OU
    // - mesmo remoteId; OU
    // - mesmo tema + título + conteúdo.
    //
    // ==========================================================

    final notesToDelete =
        <
          BrainFile
        >[];

    if (target !=
        null) {
      for (final note in localNotes) {
        final sameLocalPath = _samePath(
          note.path,
          target.path,
        );

        final sameRemoteId =
            _remoteNoteId(
              userId: userId,
              localPath: note.path,
            ) ==
            requestedRemoteId;

        final sameHistoricalCopy = _sameNoteContent(
          note,
          target,
        );

        if (sameLocalPath ||
            sameRemoteId ||
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
    }

    // ==========================================================
    // APAGAR CADA ARQUIVO E CONFIRMAR
    // ==========================================================

    final remoteIdsToDelete =
        <
          String
        >{};

    if (requestedRemoteId.isNotEmpty) {
      remoteIdsToDelete.add(
        requestedRemoteId,
      );
    }

    for (final note in notesToDelete) {
      final path = note.path.trim();

      if (path.isEmpty) {
        continue;
      }

      final remoteId = _remoteNoteId(
        userId: userId,
        localPath: path,
      );

      remoteIdsToDelete.add(
        remoteId,
      );

      final file = File(
        path,
      );

      debugPrint(
        '[BRAIN REPOSITORY] Excluindo arquivo local: $path',
      );

      await _local.deleteNote(
        note,
      );

      // ========================================================
      // CONFIRMAÇÃO FÍSICA
      // ========================================================

      if (await file.exists()) {
        // Última tentativa direta.
        await file.delete();

        if (await file.exists()) {
          throw FileSystemException(
            'Não foi possível excluir fisicamente a anotação.',
            path,
          );
        }
      }

      debugPrint(
        '[BRAIN REPOSITORY] Arquivo local removido: $path',
      );
    }

    // ==========================================================
    // NOTA LOCAL NÃO ENCONTRADA
    // ==========================================================
    //
    // Se recebemos um caminho .md e o arquivo não foi encontrado,
    // não tratamos como sucesso silencioso.
    //
    // Isso é importante para não esconder erro da UI.
    //
    // UUID remoto sem correspondente local ainda pode ser
    // removido remotamente, pois pode ser um registro legado.
    //
    // ==========================================================

    if (target ==
            null &&
        directPath !=
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

      // O caminho já não existe. Consideramos a parte local
      // concluída e ainda calculamos o ID remoto correspondente.
      remoteIdsToDelete.add(
        _remoteNoteId(
          userId: userId,
          localPath: directPath,
        ),
      );
    }

    if (target ==
            null &&
        directPath ==
            null &&
        !_looksLikeUuid(
          cleanId,
        )) {
      throw StateError(
        'Não foi possível localizar a anotação local para excluir.',
      );
    }

    // ==========================================================
    // 4. VERIFICAÇÃO FINAL NO BRAIN STORAGE
    // ==========================================================

    if (target !=
        null) {
      final remaining = await _local.loadNotes();

      final stillExists = remaining.any(
        (
          note,
        ) {
          if (_samePath(
            note.path,
            target!.path,
          )) {
            return true;
          }

          return _sameNoteContent(
            note,
            target!,
          );
        },
      );

      if (stillExists) {
        throw StateError(
          'A anotação ainda existe no armazenamento local após a exclusão.',
        );
      }
    }

    // ==========================================================
    // 5. QUEUE DELETE
    // ==========================================================
    //
    // Só chegamos aqui depois da confirmação local.
    //
    // ==========================================================

    for (final remoteId in remoteIdsToDelete) {
      if (remoteId.trim().isEmpty) {
        continue;
      }

      await _syncQueue.enqueue(
        entityType: noteEntityType,
        entityId: remoteId,
        operation: SyncOperation.delete,
        payload:
            <
              String,
              dynamic
            >{
              'id': remoteId,
              'user_id': userId,
            },
      );
    }

    _syncService?.requestSync();

    debugPrint(
      '[BRAIN REPOSITORY] Exclusão concluída e confirmada localmente.',
    );
  }

  // ============================================================
  // SAVE CONCEPT
  // ============================================================
  //
  // Também é local-first.
  //
  // Se noteId for um caminho local:
  //
  // - abre a nota;
  // - insere/atualiza o conceito;
  // - regrava o Markdown;
  // - BrainStorage sincroniza os arquivos individuais locais.
  //
  // Depois registramos o conceito na SyncQueue.
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
  }) async {
    final userId = _requireUserId();

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

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

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

      await _local.saveNote(
        topic: note.topic,
        title: note.title,
        content: note.content,
        concepts: concepts,
        existingPath: note.path,
      );
    }

    // ==========================================================
    // NOTE REMOTE ID
    // ==========================================================

    String? remoteNoteId;

    if (note !=
        null) {
      remoteNoteId = _remoteNoteId(
        userId: userId,
        localPath: note.path,
      );
    } else if (cleanNoteId !=
            null &&
        _looksLikeUuid(
          cleanNoteId,
        )) {
      remoteNoteId = cleanNoteId;
    }

    final now = DateTime.now();

    final payload =
        <
          String,
          dynamic
        >{
          'id': concept.id,
          'user_id': userId,
          'note_id': remoteNoteId,
          'title': concept.title,
          'description': concept.description,
          'type': concept.type.name,
          'updated_at': now.toUtc().toIso8601String(),
        };

    await _syncQueue.enqueue(
      entityType: conceptEntityType,
      entityId: concept.id,
      operation: SyncOperation.update,
      payload: payload,
    );

    _syncService?.requestSync();

    return payload;
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
  // DELETE CONCEPT
  // ============================================================

  Future<
    void
  >
  deleteConcept(
    String id,
  ) async {
    final userId = _requireUserId();

    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================
    //
    // Removemos o conceito de qualquer anotação local que o
    // contenha e deixamos BrainStorage regenerar os arquivos.
    //
    // ==========================================================

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

      final updated = note.concepts
          .where(
            (
              concept,
            ) =>
                concept.id !=
                cleanId,
          )
          .toList();

      await _local.saveNote(
        topic: note.topic,
        title: note.title,
        content: note.content,
        concepts: updated,
        existingPath: note.path,
      );
    }

    // ==========================================================
    // QUEUE DELETE
    // ==========================================================

    await _syncQueue.enqueue(
      entityType: conceptEntityType,
      entityId: cleanId,
      operation: SyncOperation.delete,
      payload:
          <
            String,
            dynamic
          >{
            'id': cleanId,
            'user_id': userId,
          },
    );

    _syncService?.requestSync();
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

    BrainFile? note;

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

    if (note ==
        null) {
      return;
    }

    final conceptIds = note.concepts
        .map(
          (
            concept,
          ) => concept.id,
        )
        .where(
          (
            id,
          ) => id.trim().isNotEmpty,
        )
        .toList();

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await _local.saveNote(
      topic: note.topic,
      title: note.title,
      content: note.content,
      concepts:
          const <
            BrainConcept
          >[],
      existingPath: note.path,
    );

    // ==========================================================
    // QUEUE
    // ==========================================================

    for (final conceptId in conceptIds) {
      await deleteConcept(
        conceptId,
      );
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
