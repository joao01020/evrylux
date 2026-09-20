import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
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
// Vault criptografado local (BrainStorage apenas para legado/migração)
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
// - criar nota sem Tema;
// - editar nota;
// - excluir nota;
// - consultar notas;
// - consultar conceitos;
// - alimentar o calendário.
//
// O Supabase passa a ser sincronização remota.
//
// FASE 13 — FONTES DO CONHECIMENTO:
//
// - sources vivem no BrainFile;
// - sources são persistidas no Vault criptografado;
// - BrainStorage Markdown NÃO recebe source/reference/author/note;
// - ao editar conteúdo/conceitos, sources são preservadas;
// - loadNotes/getNote hidratam sources a partir do Vault local;
// - adicionar/editar/remover fontes acontece somente no Vault;
// - alterações de sources entram na BrainSyncQueueService como
//   BrainVaultObject criptografado.
//
// EXCLUSÃO DURANTE A MIGRAÇÃO:
//
// - local/Vault continuam sendo a verdade principal;
// - tombstone E2EE continua indo para brain_objects;
// - enquanto BrainScreen ainda pesquisa brain_notes, uma exclusão
//   também registra DELETE da cópia legada;
// - ficar offline não impede apagar localmente;
// - se houver SyncQueue legada, o DELETE remoto fica pendente até
//   a conexão voltar.
//
// ============================================================

class BrainRepository {
  BrainRepository({
    SupabaseBrainService? remote,
    required BrainStorage local,
    SyncQueue? syncQueue,
    SyncService? syncService,
    BrainNoteVaultStore? noteVaultStore,
    BrainConceptVaultStore? conceptVaultStore,
    BrainSyncQueueService? brainSyncQueueService,
  }) : _remote =
           remote ??
           SupabaseBrainService(),
       _local = local,
       _legacySyncQueue = syncQueue,
       _legacySyncService = syncService,
       _noteVaultStore = noteVaultStore,
       _conceptVaultStore = conceptVaultStore,
       _brainSyncQueueService = brainSyncQueueService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseBrainService _remote;

  final BrainStorage _local;

  // ============================================================
  // LEGACY REMOTE CLEANUP
  // ============================================================
  //
  // A busca remota ainda consulta brain_notes durante a migração.
  //
  // Por isso, ao excluir uma nota, também precisamos registrar a
  // exclusão da cópia legada. A fila antiga é usada somente para
  // essa limpeza transitória; o conteúdo novo continua seguindo
  // exclusivamente pelo fluxo E2EE.
  //
  // ============================================================

  final SyncQueue? _legacySyncQueue;

  final SyncService? _legacySyncService;

  final BrainNoteVaultStore? _noteVaultStore;

  final BrainConceptVaultStore? _conceptVaultStore;

  final BrainSyncQueueService? _brainSyncQueueService;

  Future<
    void
  >?
  _legacyPlaintextMigrationFuture;

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
  // SAVE NOTE — VAULT / E2EE — FASE 09
  // ============================================================
  //
  // Tema não é mais requisito de captura.
  //
  // O parâmetro topic permanece temporariamente na assinatura por
  // compatibilidade binária/estrutural com o restante do projeto.
  //
  // Quando vazio, usamos "Sem tema" SOMENTE no mirror legado e no
  // BrainFile atual, pois BrainStorage ainda será migrado no próximo
  // bloco da Fase 09.
  //
  // A UI não deve pedir Tema ao usuário.
  //
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
    final store = _requireNoteVaultStore();

    await _ensureLegacyPlaintextMigrated();

    final rawTopic = topic.trim();
    final cleanTopic = rawTopic.isEmpty
        ? 'Sem tema'
        : rawTopic;
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

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

    final cleanId =
        id?.trim() ??
        '';

    BrainFile? previousNote;

    if (cleanId.isNotEmpty) {
      previousNote = await _findVaultNoteByAnyId(
        cleanId,
      );

      if (previousNote ==
          null) {
        final legacyPath = _localPathFromId(
          cleanId,
        );

        if (legacyPath !=
            null) {
          try {
            previousNote = await _local.openNote(
              legacyPath,
            );
          } catch (
            _
          ) {
            previousNote = null;
          }
        }
      }
    }

    final now = DateTime.now().toLocal();

    final notePath =
        previousNote?.path.trim().isNotEmpty ==
            true
        ? previousNote!.path.trim()
        : cleanId.isNotEmpty &&
              !_looksLikeUuid(
                cleanId,
              )
        ? cleanId
        : _newVaultNotePath();

    final note = BrainFile(
      topic: cleanTopic,
      title: cleanTitle,
      path: notePath,
      content: cleanContent,
      concepts:
          previousNote?.concepts ??
          const <
            BrainConcept
          >[],
      sources:
          previousNote?.sources ??
          const <
            BrainSource
          >[],
      createdAt:
          previousNote?.createdAt ??
          now,
      updatedAt: now,
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
            localPath: note.path,
          );

    final encryptedObject = await store.saveNote(
      note,
      legacyRemoteId: legacyRemoteId,
    );

    await _brainSyncQueueService?.enqueueObject(
      encryptedObject,
    );

    final verified = await store.getNoteByPath(
      note.path,
    );

    if (verified ==
            null ||
        verified.title.trim() !=
            note.title.trim() ||
        verified.content !=
            note.content) {
      throw StateError(
        'A nota foi gravada no Vault, mas a verificação de integridade falhou.',
      );
    }

    await _deletePlaintextMirrorIfPresent(
      previousNote ??
          note,
    );

    debugPrint(
      '[BRAIN REPOSITORY] '
      'Nota salva somente no Vault criptografado: '
      '${encryptedObject.header.objectId}',
    );

    return _noteToRow(
      verified,
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
    final store = _requireNoteVaultStore();

    await _ensureLegacyPlaintextMigrated();

    final notes = await store.loadNotes();

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

    await _ensureLegacyPlaintextMigrated();

    final note = await _findVaultNoteByAnyId(
      cleanId,
    );

    if (note ==
        null) {
      return null;
    }

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

    final store = _requireNoteVaultStore();

    await _ensureLegacyPlaintextMigrated();

    final userId = currentUserId?.trim();
    final target = await _findVaultNoteByAnyId(
      cleanId,
    );

    if (target ==
        null) {
      if (_looksLikeUuid(
        cleanId,
      )) {
        final tombstone = await store.deleteNoteByLegacyRemoteId(
          cleanId,
        );

        if (tombstone !=
            null) {
          await _brainSyncQueueService?.enqueueObject(
            tombstone,
          );
        }

        await _deleteLegacyRemoteNote(
          cleanId,
        );

        return;
      }

      final legacyPath = _localPathFromId(
        cleanId,
      );

      if (legacyPath !=
          null) {
        final file = File(
          legacyPath,
        );

        if (await file.exists()) {
          try {
            final legacyNote = await _local.openNote(
              legacyPath,
            );
            await _local.deleteNote(
              legacyNote,
            );
          } catch (
            _
          ) {
            await file.delete();
          }
        }

        final tombstone = await store.deleteNoteByPath(
          legacyPath,
        );

        if (tombstone !=
            null) {
          await _brainSyncQueueService?.enqueueObject(
            tombstone,
          );
        }

        if (userId !=
                null &&
            userId.isNotEmpty) {
          await _deleteLegacyRemoteNote(
            _remoteNoteId(
              userId: userId,
              localPath: legacyPath,
            ),
          );
        }

        return;
      }

      throw StateError(
        'Não foi possível localizar a anotação para excluir.',
      );
    }

    final conceptIds = target.concepts
        .map(
          (
            concept,
          ) => concept.id.trim(),
        )
        .where(
          (
            conceptId,
          ) => conceptId.isNotEmpty,
        )
        .toSet();

    final legacyRemoteIds =
        <
          String
        >{};

    if (_looksLikeUuid(
      cleanId,
    )) {
      legacyRemoteIds.add(
        cleanId,
      );
    }

    if (userId !=
            null &&
        userId.isNotEmpty) {
      legacyRemoteIds.add(
        _remoteNoteId(
          userId: userId,
          localPath: target.path,
        ),
      );
    }

    final noteTombstone = await store.deleteNoteByPath(
      target.path,
    );

    if (noteTombstone !=
        null) {
      await _brainSyncQueueService?.enqueueObject(
        noteTombstone,
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

    await _deletePlaintextMirrorIfPresent(
      target,
    );

    for (final legacyRemoteId in legacyRemoteIds) {
      await _deleteLegacyRemoteNote(
        legacyRemoteId,
      );
    }

    debugPrint(
      '[BRAIN REPOSITORY] '
      'Exclusão concluída no Vault criptografado.',
    );
  }

  // ============================================================
  // DELETE LEGACY REMOTE NOTE
  // ============================================================
  //
  // Compatibilidade temporária com brain_notes.
  //
  // Prioridade:
  //
  // 1. SyncQueue legada
  //    - mantém offline-first;
  //    - retry automático;
  //
  // 2. fallback direto
  //    - usado somente se a fila não foi injetada;
  //    - falha de rede não faz a exclusão local voltar.
  //
  // ============================================================

  Future<
    void
  >
  _deleteLegacyRemoteNote(
    String remoteId,
  ) async {
    final cleanRemoteId = remoteId.trim();

    if (cleanRemoteId.isEmpty ||
        !_looksLikeUuid(
          cleanRemoteId,
        )) {
      return;
    }

    final queue = _legacySyncQueue;

    if (queue !=
        null) {
      await queue.enqueue(
        entityType: noteEntityType,
        entityId: cleanRemoteId,
        operation: SyncOperation.delete,
      );

      _legacySyncService?.requestSync();

      debugPrint(
        '[BRAIN REPOSITORY] '
        'DELETE legado enfileirado: $cleanRemoteId',
      );

      return;
    }

    if (!isAuthenticated) {
      debugPrint(
        '[BRAIN REPOSITORY] '
        'DELETE legado aguardando contexto autenticado: '
        '$cleanRemoteId',
      );

      return;
    }

    try {
      await _remote.deleteNote(
        cleanRemoteId,
      );

      debugPrint(
        '[BRAIN REPOSITORY] '
        'brain_notes legado removido diretamente: '
        '$cleanRemoteId',
      );
    } catch (
      error
    ) {
      // Não propagamos:
      //
      // a exclusão local + tombstone E2EE já foi concluída.
      debugPrint(
        '[BRAIN REPOSITORY] '
        'Falha ao limpar brain_notes legado. '
        'A exclusão local permanece válida. '
        'ID=$cleanRemoteId erro=$error',
      );
    }
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
    final results = await saveConceptsBatch(
      concepts:
          <
            BrainConcept
          >[
            concept,
          ],
      noteId: noteId,
    );

    return results.first;
  }

  // ============================================================
  // SAVE CONCEPTS BATCH — VAULT / E2EE
  // ============================================================
  //
  // Otimização do caminho crítico de salvamento:
  //
  // Antes, BrainController chamava saveConcept() para cada item.
  // Cada chamada:
  //
  // - procurava a mesma nota no Vault;
  // - regravava a mesma nota;
  // - relia a nota para validar integridade;
  // - só então persistia o conceito.
  //
  // Para um conhecimento com conceito principal + exemplo + atenção,
  // isso repetia a operação criptográfica da nota várias vezes.
  //
  // Agora o lote:
  //
  // 1. localiza a nota uma única vez;
  // 2. incorpora todos os conceitos em memória;
  // 3. grava/valida a nota criptografada uma única vez;
  // 4. grava cada BrainConcept como objeto E2EE;
  // 5. relê cada conceito e valida conteúdo antes de concluir.
  //
  // A otimização reduz I/O e criptografia repetidos sem remover
  // nenhuma verificação de integridade.
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
  saveConceptsBatch({
    required Iterable<
      BrainConcept
    >
    concepts,
    String? noteId,
  }) async {
    await _ensureLegacyPlaintextMigrated();

    final pending = concepts.toList(
      growable: false,
    );

    if (pending.isEmpty) {
      return const <
        Map<
          String,
          dynamic
        >
      >[];
    }

    final cleanNoteId = noteId?.trim();

    BrainFile? note;

    if (cleanNoteId !=
            null &&
        cleanNoteId.isNotEmpty) {
      note = await _findVaultNoteByAnyId(
        cleanNoteId,
      );
    }

    BrainFile? updatedNote = note;

    if (note !=
        null) {
      final mergedConcepts =
          List<
            BrainConcept
          >.from(
            note.concepts,
          );

      for (final concept in pending) {
        final existingIndex = mergedConcepts.indexWhere(
          (
            item,
          ) =>
              item.id ==
              concept.id,
        );

        if (existingIndex >=
            0) {
          mergedConcepts[existingIndex] = concept;
        } else {
          mergedConcepts.add(
            concept,
          );
        }
      }

      updatedNote = note.copyWith(
        concepts: mergedConcepts,
        updatedAt: DateTime.now().toLocal(),
      );

      // Uma única gravação + leitura de verificação para a nota.
      updatedNote = await _saveEncryptedNoteAndVerify(
        updatedNote,
      );
    }

    final result =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final concept in pending) {
      final encryptedConcept = await _conceptVaultStore?.saveConcept(
        concept: concept,
        sourceNotePath:
            updatedNote?.path ??
            note?.path ??
            cleanNoteId,
      );

      if (encryptedConcept ==
          null) {
        throw StateError(
          'BrainConceptVaultStore não está disponível para salvar '
          'o conhecimento ${concept.id}.',
        );
      }

      await _brainSyncQueueService?.enqueueObject(
        encryptedConcept,
      );

      // A mensagem de "integridade validada" da UI só deve ocorrer
      // depois que o objeto puder ser lido novamente do Vault.
      final verifiedConcept = await _conceptVaultStore!.getConcept(
        concept.id,
      );

      if (verifiedConcept ==
              null ||
          !_sameConceptContent(
            concept,
            verifiedConcept,
          )) {
        throw StateError(
          'O conhecimento ${concept.id} foi gravado no Vault, '
          'mas a verificação de integridade falhou.',
        );
      }

      result.add(
        <
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
        },
      );
    }

    return List<
      Map<
        String,
        dynamic
      >
    >.unmodifiable(
      result,
    );
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

    await _ensureLegacyPlaintextMigrated();

    final store = _requireNoteVaultStore();
    final notes = await store.loadNotes();

    BrainFile? sourceNote;

    for (final note in notes) {
      final containsConcept = note.concepts.any(
        (
          concept,
        ) =>
            concept.id ==
            cleanId,
      );

      if (containsConcept) {
        sourceNote = note;
        break;
      }
    }

    if (sourceNote ==
        null) {
      await deleteConcept(
        cleanId,
      );
      return;
    }

    await deleteConceptsByNoteId(
      sourceNote.path,
    );
    await deleteNote(
      sourceNote.path,
    );

    final remaining = await store.loadNotes();

    final stillExists = remaining.any(
      (
        note,
      ) => _samePath(
        note.path,
        sourceNote!.path,
      ),
    );

    if (stillExists) {
      throw StateError(
        'A anotação de origem ainda existe após a exclusão em cascata.',
      );
    }

    debugPrint(
      '[BRAIN REPOSITORY] '
      'Exclusão em cascata concluída no Vault.',
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

    await _ensureLegacyPlaintextMigrated();

    final noteStore = _requireNoteVaultStore();
    final notes = await noteStore.loadNotes();

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
          .toList(
            growable: false,
          );

      final updatedNote = note.copyWith(
        concepts: updatedConcepts,
        updatedAt: DateTime.now().toLocal(),
      );

      await _saveEncryptedNoteAndVerify(
        updatedNote,
      );
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

    await _ensureLegacyPlaintextMigrated();

    final note = await _findVaultNoteByAnyId(
      cleanNoteId,
    );

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
            conceptId,
          ) => conceptId.isNotEmpty,
        )
        .toList(
          growable: false,
        );

    final updatedNote = note.copyWith(
      concepts:
          const <
            BrainConcept
          >[],
      updatedAt: DateTime.now().toLocal(),
    );

    await _saveEncryptedNoteAndVerify(
      updatedNote,
    );

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
  // GET SOURCES BY NOTE
  // ============================================================
  //
  // FASE 13 — FONTES DO CONHECIMENTO
  //
  // Retorna as fontes da nota a partir do Vault criptografado.
  //
  // BrainStorage Markdown continua sem persistir:
  //
  // - reference;
  // - author;
  // - note;
  // - source metadata.
  //
  // ============================================================

  Future<
    List<
      BrainSource
    >
  >
  getSourcesByNote(
    String noteId,
  ) async {
    final note = await _findNoteWithSources(
      noteId,
    );

    if (note ==
        null) {
      return const <
        BrainSource
      >[];
    }

    return List<
      BrainSource
    >.unmodifiable(
      note.sources,
    );
  }

  // ============================================================
  // ADD SOURCE TO NOTE
  // ============================================================

  Future<
    BrainFile
  >
  addSourceToNote({
    required String noteId,
    required BrainSource source,
  }) async {
    if (!source.isValid) {
      throw const FormatException(
        'A fonte informada é inválida.',
      );
    }

    final note = await _requireNoteWithSources(
      noteId,
    );

    final updatedNote = note.addSource(
      source,
    );

    // Se addSource detectou duplicação, não criamos uma nova
    // versão criptografada desnecessariamente.
    if (identical(
      updatedNote,
      note,
    )) {
      return note;
    }

    await _persistSourceUpdatedNote(
      updatedNote,
    );

    return updatedNote;
  }

  // ============================================================
  // UPDATE SOURCE IN NOTE
  // ============================================================

  Future<
    BrainFile
  >
  updateSourceInNote({
    required String noteId,
    required BrainSource source,
  }) async {
    if (!source.isValid) {
      throw const FormatException(
        'A fonte informada é inválida.',
      );
    }

    final note = await _requireNoteWithSources(
      noteId,
    );

    if (!note.hasSourceId(
      source.id,
    )) {
      throw StateError(
        'A fonte não existe nesta anotação.',
      );
    }

    final updatedSource = source.touch();

    final updatedNote = note.updateSource(
      updatedSource,
    );

    await _persistSourceUpdatedNote(
      updatedNote,
    );

    return updatedNote;
  }

  // ============================================================
  // REMOVE SOURCE FROM NOTE
  // ============================================================

  Future<
    BrainFile
  >
  removeSourceFromNote({
    required String noteId,
    required String sourceId,
  }) async {
    final cleanSourceId = sourceId.trim();

    if (cleanSourceId.isEmpty) {
      throw const FormatException(
        'A fonte não possui um identificador válido.',
      );
    }

    final note = await _requireNoteWithSources(
      noteId,
    );

    if (!note.hasSourceId(
      cleanSourceId,
    )) {
      return note;
    }

    final updatedNote = note.removeSourceById(
      cleanSourceId,
    );

    await _persistSourceUpdatedNote(
      updatedNote,
    );

    return updatedNote;
  }

  // ============================================================
  // CLEAR SOURCES FROM NOTE
  // ============================================================

  Future<
    BrainFile
  >
  clearSourcesFromNote(
    String noteId,
  ) async {
    final note = await _requireNoteWithSources(
      noteId,
    );

    if (!note.hasSources) {
      return note;
    }

    final updatedNote = note.clearSources();

    await _persistSourceUpdatedNote(
      updatedNote,
    );

    return updatedNote;
  }

  // ============================================================
  // REQUIRE NOTE WITH SOURCES
  // ============================================================

  Future<
    BrainFile
  >
  _requireNoteWithSources(
    String noteId,
  ) async {
    final note = await _findNoteWithSources(
      noteId,
    );

    if (note ==
        null) {
      throw StateError(
        'Não foi possível localizar a anotação.',
      );
    }

    return note;
  }

  // ============================================================
  // FIND NOTE WITH SOURCES
  // ============================================================
  //
  // Aceita:
  //
  // - path Markdown local;
  // - UUID remoto legado.
  //
  // ============================================================

  Future<
    BrainFile?
  >
  _findNoteWithSources(
    String noteId,
  ) async {
    final cleanId = noteId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    await _ensureLegacyPlaintextMigrated();

    return _findVaultNoteByAnyId(
      cleanId,
    );
  }

  // ============================================================
  // PERSIST SOURCE UPDATED NOTE
  // ============================================================
  //
  // Fonte é persistida apenas no Vault.
  //
  // Não chamamos BrainStorage.saveNote() aqui porque isso faria
  // a source atravessar o mirror Markdown legado.
  //
  // O BrainFile criptografado completo é salvo no Vault e o
  // BrainVaultObject resultante entra na BrainSyncQueueService.
  //
  // ============================================================

  Future<
    void
  >
  _persistSourceUpdatedNote(
    BrainFile note,
  ) async {
    await _saveEncryptedNoteAndVerify(
      note.copyWith(
        updatedAt: DateTime.now().toLocal(),
      ),
    );
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
  // HYDRATE SOURCES FROM VAULT
  // ============================================================
  //
  // FASE 13 — FONTES DO CONHECIMENTO
  //
  // BrainStorage continua sendo apenas o mirror Markdown legado.
  //
  // Para não escrever referência/autor/observação em plaintext,
  // sources não são persistidas nesse mirror.
  //
  // Ao carregar ou regravar uma nota, buscamos as sources no
  // BrainNoteVaultStore e as recolocamos no BrainFile antes de:
  //
  // - devolver a nota ao controller;
  // - atualizar o Vault;
  // - enfileirar o objeto E2EE.
  //
  // Se o Vault ainda não possuir a nota, a lista local é mantida.
  //
  // ============================================================

  Future<
    BrainFile
  >
  _hydrateSourcesFromVault(
    BrainFile note,
  ) async {
    final store = _noteVaultStore;

    if (store ==
        null) {
      return note;
    }

    final path = note.path.trim();

    if (path.isEmpty) {
      return note;
    }

    try {
      final vaultNote = await store.getNoteByPath(
        path,
      );

      if (vaultNote ==
          null) {
        return note;
      }

      return note.copyWith(
        sources: vaultNote.sources,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[BRAIN REPOSITORY] '
        'Não foi possível hidratar fontes do Vault: $error',
      );

      return note;
    }
  }

  // ============================================================
  // VAULT-ONLY NOTE STORAGE
  // ============================================================

  BrainNoteVaultStore _requireNoteVaultStore() {
    final store = _noteVaultStore;

    if (store ==
        null) {
      throw StateError(
        'BrainNoteVaultStore não está disponível. '
        'O Brain não pode salvar conteúdo sensível sem o Vault.',
      );
    }

    return store;
  }

  // ============================================================
  // PUBLIC LEGACY PLAINTEXT MIGRATION
  // ============================================================
  //
  // Chamado pelo startup da aplicação para garantir que:
  //
  // - notas Markdown legadas sejam migradas para o Vault;
  // - conceitos Markdown em legacy/_concepts sejam migrados;
  // - cada conceito seja validado no Vault antes da exclusão;
  // - nenhum plaintext seja removido quando a validação falhar.
  //
  // ============================================================

  Future<
    void
  >
  migrateLegacyPlaintextIfNeeded() {
    return _ensureLegacyPlaintextMigrated();
  }

  // ============================================================
  // INTERNAL LEGACY PLAINTEXT MIGRATION
  // ============================================================

  Future<
    void
  >
  _ensureLegacyPlaintextMigrated() {
    return _legacyPlaintextMigrationFuture ??= _migrateLegacyPlaintextNotes();
  }

  Future<
    void
  >
  _migrateLegacyPlaintextNotes() async {
    final store = _requireNoteVaultStore();

    List<
      BrainFile
    >
    legacyNotes;

    try {
      legacyNotes = await _local.loadNotes();
    } catch (
      error
    ) {
      debugPrint(
        '[BRAIN SECURITY] '
        'Falha ao enumerar mirror legado: $error',
      );

      rethrow;
    }

    if (legacyNotes.isEmpty) {
      await _migrateLegacyPlaintextConcepts();
      return;
    }

    debugPrint(
      '[BRAIN SECURITY] '
      'Migrando ${legacyNotes.length} nota(s) plaintext para o Vault.',
    );

    for (final legacyNote in legacyNotes) {
      final path = legacyNote.path.trim();

      if (path.isEmpty) {
        continue;
      }

      BrainFile secureNote = legacyNote;

      final existing = await store.getNoteByPath(
        path,
      );

      if (existing ==
          null) {
        final encrypted = await store.saveNote(
          legacyNote,
        );

        await _brainSyncQueueService?.enqueueObject(
          encrypted,
        );

        final verified = await store.getNoteByPath(
          path,
        );

        if (verified ==
                null ||
            verified.title.trim() !=
                legacyNote.title.trim() ||
            verified.content !=
                legacyNote.content) {
          throw StateError(
            'Migração segura falhou para $path. '
            'O plaintext foi preservado.',
          );
        }

        secureNote = verified;
      } else {
        secureNote = existing;
      }

      for (final concept in secureNote.concepts) {
        final encryptedConcept = await _conceptVaultStore?.saveConcept(
          concept: concept,
          sourceNotePath: secureNote.path,
        );

        if (encryptedConcept !=
            null) {
          await _brainSyncQueueService?.enqueueObject(
            encryptedConcept,
          );
        }
      }

      await _deletePlaintextMirrorIfPresent(
        legacyNote,
      );
    }

    await _migrateLegacyPlaintextConcepts();

    debugPrint(
      '[BRAIN SECURITY] '
      'Migração plaintext -> Vault concluída.',
    );
  }

  // ============================================================
  // MIGRATE LEGACY PLAINTEXT CONCEPTS
  // ============================================================
  //
  // Migra os espelhos Markdown antigos existentes em:
  //
  // legacy/_concepts/concepts
  // legacy/_concepts/questions
  // legacy/_concepts/examples
  // legacy/_concepts/warnings
  //
  // Regra de segurança:
  //
  // 1. lê o BrainConcept legado;
  // 2. grava no BrainConceptVaultStore quando necessário;
  // 3. lê novamente do Vault;
  // 4. valida id/title/description/type/reviewEnabled;
  // 5. somente então remove o .md correspondente.
  //
  // Se qualquer validação falhar, o plaintext permanece no disco.
  //
  // ============================================================

  Future<
    void
  >
  _migrateLegacyPlaintextConcepts() async {
    final store = _conceptVaultStore;

    if (store ==
        null) {
      throw StateError(
        'BrainConceptVaultStore não está disponível. '
        'Os conceitos legados não podem ser removidos com segurança.',
      );
    }

    var discovered = 0;
    var migrated = 0;
    var removed = 0;

    for (final type in BrainConceptType.values) {
      final legacyConcepts = await _local.loadConceptsByType(
        type,
      );

      if (legacyConcepts.isEmpty) {
        continue;
      }

      final byId =
          <
            String,
            BrainConcept
          >{
            for (final concept in legacyConcepts)
              if (concept.id.trim().isNotEmpty) concept.id.trim(): concept,
          };

      final directory = await _local.getConceptTypeDirectory(
        type,
      );

      if (!await directory.exists()) {
        continue;
      }

      await for (final entity in directory.list(
        recursive: false,
        followLinks: false,
      )) {
        if (entity
                is! File ||
            !entity.path.toLowerCase().endsWith(
              '.md',
            )) {
          continue;
        }

        discovered++;

        final markdown = await entity.readAsString();
        final legacyId = _legacyConceptMetadataValue(
          markdown,
          'id',
        ).trim();

        if (legacyId.isEmpty) {
          debugPrint(
            '[BRAIN SECURITY] '
            'Conceito legado sem id; plaintext preservado: '
            '${entity.path}',
          );
          continue;
        }

        final legacyConcept = byId[legacyId];

        if (legacyConcept ==
            null) {
          debugPrint(
            '[BRAIN SECURITY] '
            'Não foi possível reconstruir o conceito $legacyId; '
            'plaintext preservado: ${entity.path}',
          );
          continue;
        }

        var verified = await store.getConcept(
          legacyId,
        );

        if (verified ==
            null) {
          final sourceNotePath = _legacyConceptSourceNotePath(
            markdown,
          );

          final encrypted = await store.saveConcept(
            concept: legacyConcept,
            sourceNotePath: sourceNotePath,
          );

          await _brainSyncQueueService?.enqueueObject(
            encrypted,
          );

          migrated++;
          verified = await store.getConcept(
            legacyId,
          );
        }

        if (verified ==
                null ||
            !_sameConceptContent(
              legacyConcept,
              verified,
            )) {
          throw StateError(
            'Falha ao validar o conceito legado $legacyId no Vault. '
            'O plaintext foi preservado em ${entity.path}.',
          );
        }

        await entity.delete();

        if (await entity.exists()) {
          throw FileSystemException(
            'O conceito plaintext continuou existindo após '
            'a validação segura.',
            entity.path,
          );
        }

        removed++;
      }
    }

    if (discovered >
        0) {
      debugPrint(
        '[BRAIN SECURITY] '
        'Conceitos legados: encontrados=$discovered, '
        'gravados_no_vault=$migrated, removidos=$removed.',
      );
    }
  }

  String _legacyConceptMetadataValue(
    String markdown,
    String key,
  ) {
    var normalized = markdown;

    if (normalized.startsWith(
      '\uFEFF',
    )) {
      normalized = normalized.substring(
        1,
      );
    }

    normalized = normalized
        .replaceAll(
          '\r\n',
          '\n',
        )
        .replaceAll(
          '\r',
          '\n',
        );

    final metadataExpression = RegExp(
      r'^\s*---\s*\n([\s\S]*?)\n---\s*\n?',
    );

    final metadataMatch = metadataExpression.firstMatch(
      normalized,
    );

    if (metadataMatch ==
        null) {
      return '';
    }

    final metadata =
        metadataMatch.group(
          1,
        ) ??
        '';

    for (final line in metadata.split(
      '\n',
    )) {
      final separator = line.indexOf(
        ':',
      );

      if (separator <=
          0) {
        continue;
      }

      final currentKey = line
          .substring(
            0,
            separator,
          )
          .trim();

      if (currentKey !=
          key) {
        continue;
      }

      return line
          .substring(
            separator +
                1,
          )
          .trim();
    }

    return '';
  }

  String? _legacyConceptSourceNotePath(
    String markdown,
  ) {
    final encoded = _legacyConceptMetadataValue(
      markdown,
      'origem',
    ).trim();

    if (encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = utf8
          .decode(
            base64Url.decode(
              base64Url.normalize(
                encoded,
              ),
            ),
          )
          .trim();

      return decoded.isEmpty
          ? null
          : decoded;
    } catch (
      error
    ) {
      debugPrint(
        '[BRAIN SECURITY] '
        'Origem legada do conceito não pôde ser decodificada: $error',
      );

      return null;
    }
  }

  bool _sameConceptContent(
    BrainConcept first,
    BrainConcept second,
  ) {
    return first.id.trim() ==
            second.id.trim() &&
        first.title.trim() ==
            second.title.trim() &&
        first.description.trim() ==
            second.description.trim() &&
        first.type ==
            second.type &&
        first.reviewEnabled ==
            second.reviewEnabled;
  }

  Future<
    BrainFile?
  >
  _findVaultNoteByAnyId(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final store = _requireNoteVaultStore();

    final direct = await store.getNoteByPath(
      cleanId,
    );

    if (direct !=
        null) {
      return direct;
    }

    final userId = currentUserId?.trim();
    final notes = await store.loadNotes();

    if (userId !=
            null &&
        userId.isNotEmpty) {
      for (final note in notes) {
        final generatedRemoteId = _remoteNoteId(
          userId: userId,
          localPath: note.path,
        );

        if (generatedRemoteId ==
            cleanId) {
          return note;
        }
      }
    }

    return null;
  }

  Future<
    BrainFile
  >
  _saveEncryptedNoteAndVerify(
    BrainFile note,
  ) async {
    final store = _requireNoteVaultStore();

    final userId = currentUserId?.trim();

    final legacyRemoteId =
        userId ==
                null ||
            userId.isEmpty
        ? null
        : _remoteNoteId(
            userId: userId,
            localPath: note.path,
          );

    final encrypted = await store.saveNote(
      note,
      legacyRemoteId: legacyRemoteId,
    );

    await _brainSyncQueueService?.enqueueObject(
      encrypted,
    );

    final verified = await store.getNoteByPath(
      note.path,
    );

    if (verified ==
            null ||
        verified.title.trim() !=
            note.title.trim() ||
        verified.content !=
            note.content) {
      throw StateError(
        'Falha ao verificar a nota criptografada no Vault.',
      );
    }

    await _deletePlaintextMirrorIfPresent(
      note,
    );

    return verified;
  }

  Future<
    void
  >
  _deletePlaintextMirrorIfPresent(
    BrainFile note,
  ) async {
    final path = note.path.trim();

    if (path.isEmpty ||
        _isVaultNotePath(
          path,
        )) {
      return;
    }

    final legacyPath = _localPathFromId(
      path,
    );

    if (legacyPath ==
        null) {
      return;
    }

    final file = File(
      legacyPath,
    );

    if (!await file.exists()) {
      return;
    }

    try {
      await _local.deleteNote(
        note,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[BRAIN SECURITY] '
        'BrainStorage.deleteNote falhou; tentando remover o arquivo '
        'plaintext diretamente: $error',
      );

      if (await file.exists()) {
        await file.delete();
      }
    }

    if (await file.exists()) {
      throw FileSystemException(
        'O arquivo plaintext continuou existindo após a migração segura.',
        legacyPath,
      );
    }
  }

  String _newVaultNotePath() {
    final now = DateTime.now().toUtc();

    final seed =
        '${now.microsecondsSinceEpoch}|'
        '${now.toIso8601String()}|'
        '${identityHashCode(this)}';

    return 'vault://note/${_deterministicUuid(seed)}';
  }

  bool _isVaultNotePath(
    String value,
  ) {
    return value.trim().toLowerCase().startsWith(
      'vault://note/',
    );
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

      // Campo legado mantido durante a Fase 09.
      'topic': note.topic,

      'title': note.title,

      'content': note.content,

      // ========================================================
      // FASE 13 — FONTES DO CONHECIMENTO
      // ========================================================
      //
      // As fontes vêm do Vault local criptografado.
      //
      // Não são persistidas pelo BrainStorage Markdown.
      //
      // ========================================================
      'sources': note.sources
          .map(
            (
              source,
            ) {
              return source.toJson();
            },
          )
          .toList(
            growable: false,
          ),

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
    final a = first.trim();
    final b = second.trim();

    if (a.isEmpty ||
        b.isEmpty) {
      return a ==
          b;
    }

    if (_isVaultNotePath(
          a,
        ) ||
        _isVaultNotePath(
          b,
        )) {
      return a ==
          b;
    }

    return File(
          a,
        ).absolute.path ==
        File(
          b,
        ).absolute.path;
  }

  // ============================================================
  // SAME NOTE CONTENT
  // ============================================================
  //
  // Usado apenas para remover duplicatas históricas geradas
  // durante a migração para offline-first.
  //
  // Topic ainda participa desta comparação somente para não mudar
  // silenciosamente a regra de limpeza de arquivos antigos.
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
