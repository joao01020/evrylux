import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../web_app/services/web_brain_secure_storage.dart';
import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
import '../security/crypto/brain_crypto_service.dart';
import '../security/models/brain_key_bundle.dart';
import '../security/models/brain_crypto_version.dart';
import '../sync/models/brain_sync_payload.dart';
import '../sync/services/brain_supabase_e2ee_service.dart';
import '../vault/mappers/brain_concept_vault_mapper.dart';
import '../vault/mappers/brain_file_vault_mapper.dart';
import '../vault/models/brain_vault_object.dart';
import '../vault/models/brain_vault_object_header.dart';
import '../vault/models/brain_vault_object_type.dart';
import '../vault/models/brain_vault_object_version.dart';
import '../vault/models/brain_vault_tombstone.dart';
import '../vault/services/brain_vault_id_service.dart';
import '../vault/services/brain_vault_serializer.dart';

class _DecodedWebObject {
  const _DecodedWebObject({
    required this.object,
    required this.type,
    required this.data,
  });

  final BrainVaultObject object;
  final BrainVaultObjectType type;
  final Map<String, dynamic> data;
}

/// Implementação Web do mesmo contrato público de BrainRepository usado pelo
/// BrainController. A UI não muda: somente a persistência muda de Vault em
/// filesystem para brain_objects E2EE via Supabase.
class BrainRepository {
  BrainRepository({WebBrainSecureStorage? storage, SupabaseClient? client})
    : _storage = storage ?? WebBrainSecureStorage(),
      _remote = BrainSupabaseE2eeService(
        client: client ?? Supabase.instance.client,
      );

  final WebBrainSecureStorage _storage;
  final BrainSupabaseE2eeService _remote;
  final BrainCryptoService _crypto = BrainCryptoService();
  final BrainVaultSerializer _serializer = const BrainVaultSerializer();
  final BrainFileVaultMapper _fileMapper = const BrainFileVaultMapper();
  final BrainConceptVaultMapper _conceptMapper =
      const BrainConceptVaultMapper();
  final BrainVaultIdService _ids = BrainVaultIdService();
  final Uuid _uuid = const Uuid();

  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<String> _vaultId() async {
    final value = await _storage.loadVaultId();
    if (value == null || value.trim().isEmpty) {
      throw StateError(
        'Este navegador ainda não foi conectado ao Vault do Cérebro.',
      );
    }
    return value.trim();
  }

  Future<BrainKeyBundle> _key(String vaultId) async {
    final key = await _storage.loadKeyBundle(vaultId: vaultId);
    if (key == null) {
      throw StateError(
        'A Master Key do Cérebro ainda não está disponível neste navegador.',
      );
    }
    return key;
  }

  Future<List<_DecodedWebObject>> _loadObjects() async {
    final vaultId = await _vaultId();
    final key = await _key(vaultId);
    final payloads = await _remote.loadVaultObjects(vaultId: vaultId);
    final result = <_DecodedWebObject>[];

    for (final payload in payloads) {
      if (payload.isDeleted) continue;
      try {
        final object = payload.toVaultObject(serializer: _serializer);
        final encrypted = object.encryptedPayload;
        if (encrypted == null) continue;
        final clear = await _crypto.decryptString(
          payload: encrypted,
          keyBundle: key,
        );
        final decoded = _serializer.deserializeLogicalPayload(clear);
        _serializer.verifyBinding(header: object.header, decoded: decoded);
        result.add(
          _DecodedWebObject(
            object: object,
            type: decoded.type,
            data: Map<String, dynamic>.from(decoded.data),
          ),
        );
      } catch (_) {
        // Um objeto inválido/corrompido não impede o restante do Brain de abrir.
      }
    }

    return result;
  }

  Future<BrainVaultObject> _writeLogical({
    required BrainVaultObjectType type,
    required Map<String, dynamic> data,
    BrainVaultObject? previous,
  }) async {
    final vaultId = await _vaultId();
    final key = await _key(vaultId);
    final now = DateTime.now().toUtc();

    final header = previous == null
        ? BrainVaultObjectHeader(
            objectId: _ids.generateObjectId(),
            vaultId: vaultId,
            objectVersion: BrainVaultObjectVersion.initial,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: key.keyVersion,
            createdAt: now,
            updatedAt: now,
          )
        : previous.header
              .nextVersion(updatedAt: now)
              .copyWith(
                cryptoVersion: BrainCryptoVersion.current,
                keyVersion: key.keyVersion,
              );

    final logical = _serializer.serializeLogicalPayload(
      type: type,
      header: header,
      data: data,
    );
    jsonDecode(logical);

    final encrypted = await _crypto.encryptString(
      plaintext: logical,
      keyBundle: key,
    );

    final object = BrainVaultObject.active(
      header: header,
      encryptedPayload: encrypted,
    );

    await _remote.upsertPayload(
      BrainSyncPayload.fromVaultObject(object: object, serializer: _serializer),
    );

    return object;
  }

  Future<void> _deleteObject(BrainVaultObject object) async {
    final now = DateTime.now().toUtc();
    final header = object.header.nextVersion(updatedAt: now);
    final tombstone = BrainVaultTombstone(
      objectId: header.objectId,
      vaultId: header.vaultId,
      objectVersion: header.objectVersion,
      deletedAt: now,
    );
    final deleted = BrainVaultObject.deleted(
      header: header,
      tombstone: tombstone,
    );
    await _remote.upsertPayload(
      BrainSyncPayload.fromVaultObject(
        object: deleted,
        serializer: _serializer,
      ),
    );
  }

  Map<String, dynamic> _noteToRow(BrainFile note) => <String, dynamic>{
    'id': note.path,
    'remote_id': null,
    'user_id': currentUserId,
    'topic': note.topic,
    'title': note.title,
    'content': note.content,
    'concepts': note.concepts.map((concept) => concept.toJson()).toList(),
    'sources': note.sources.map((source) => source.toJson()).toList(),
    'created_at': note.createdAt.toUtc().toIso8601String(),
    'updated_at': note.updatedAt.toUtc().toIso8601String(),
  };

  Map<String, List<BrainConcept>> _conceptsBySourceNote(
    List<_DecodedWebObject> objects,
  ) {
    final grouped = <String, List<BrainConcept>>{};

    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;

      try {
        final sourceNotePath = _conceptMapper
            .sourceNotePathFromVaultData(item.data)
            ?.trim();

        if (sourceNotePath == null || sourceNotePath.isEmpty) continue;

        final concept = _conceptMapper.fromVaultData(item.data);
        grouped
            .putIfAbsent(sourceNotePath, () => <BrainConcept>[])
            .add(concept);
      } catch (_) {
        // Um conceito inválido não bloqueia as demais notas.
      }
    }

    return grouped;
  }

  List<BrainConcept> _mergeConcepts(
    Iterable<BrainConcept> embedded,
    Iterable<BrainConcept> standalone,
  ) {
    final byId = <String, BrainConcept>{};

    for (final concept in embedded) {
      final key = concept.id.trim().isEmpty
          ? '${concept.type.name}:${concept.title}:${concept.description}'
          : concept.id.trim();
      byId[key] = concept;
    }

    // O objeto de conceito independente é a fonte mais recente e vence
    // uma cópia embutida antiga da nota quando possuem o mesmo id.
    for (final concept in standalone) {
      final key = concept.id.trim().isEmpty
          ? '${concept.type.name}:${concept.title}:${concept.description}'
          : concept.id.trim();
      byId[key] = concept;
    }

    return List<BrainConcept>.unmodifiable(byId.values);
  }

  BrainFile _hydrateNoteConcepts(
    BrainFile note,
    Map<String, List<BrainConcept>> conceptsByNote,
  ) {
    final standalone =
        conceptsByNote[note.path.trim()] ?? const <BrainConcept>[];
    final merged = _mergeConcepts(note.concepts, standalone);

    if (merged.length == note.concepts.length && standalone.isEmpty) {
      return note;
    }

    return note.copyWith(concepts: merged);
  }

  // ============================================================
  // NOTA LÓGICA MAIS RECENTE
  // ============================================================
  //
  // O Vault usa objectId como identidade física, mas o Brain ainda
  // mantém legacy_path como identidade lógica da nota para controllers
  // e telas antigas.
  //
  // Em instalações que passaram por migrações/sincronizações antigas
  // pode existir mais de um BrainVaultObject apontando para o mesmo
  // legacy_path. Nessa situação:
  //
  // - a busca podia receber a versão mais nova;
  // - getNote() podia devolver a primeira versão encontrada por objectId;
  // - abrir o resultado mostrava conteúdo antigo.
  //
  // Toda leitura Web passa agora a escolher deterministicamente a
  // versão lógica mais recente da nota.
  // ============================================================

  bool _isNewerNoteCandidate({
    required _DecodedWebObject candidateObject,
    required BrainFile candidateNote,
    required _DecodedWebObject currentObject,
    required BrainFile currentNote,
  }) {
    final noteUpdatedComparison = candidateNote.updatedAt.compareTo(
      currentNote.updatedAt,
    );

    if (noteUpdatedComparison != 0) {
      return noteUpdatedComparison > 0;
    }

    final objectVersionComparison = candidateObject
        .object
        .header
        .objectVersion
        .value
        .compareTo(currentObject.object.header.objectVersion.value);

    if (objectVersionComparison != 0) {
      return objectVersionComparison > 0;
    }

    final headerUpdatedComparison = candidateObject.object.header.updatedAt
        .compareTo(currentObject.object.header.updatedAt);

    if (headerUpdatedComparison != 0) {
      return headerUpdatedComparison > 0;
    }

    // Desempate estável para evitar depender da ordem retornada pelo banco.
    return candidateObject.object.header.objectId.compareTo(
          currentObject.object.header.objectId,
        ) >
        0;
  }

  ({_DecodedWebObject object, BrainFile note})? _latestMatchingNote({
    required List<_DecodedWebObject> objects,
    required String id,
    Map<String, List<BrainConcept>>? conceptsByNote,
  }) {
    final clean = id.trim();

    if (clean.isEmpty) {
      return null;
    }

    ({_DecodedWebObject object, BrainFile note})? latest;

    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) {
        continue;
      }

      try {
        var note = _fileMapper.fromVaultData(item.data);

        if (conceptsByNote != null) {
          note = _hydrateNoteConcepts(note, conceptsByNote);
        }

        final matches =
            note.path.trim() == clean ||
            item.object.header.objectId.trim() == clean;

        if (!matches) {
          continue;
        }

        if (latest == null ||
            _isNewerNoteCandidate(
              candidateObject: item,
              candidateNote: note,
              currentObject: latest.object,
              currentNote: latest.note,
            )) {
          latest = (object: item, note: note);
        }
      } catch (_) {
        // Objeto inválido não impede a procura pela versão válida.
      }
    }

    return latest;
  }

  List<({_DecodedWebObject object, BrainFile note})> _latestLogicalNotes({
    required List<_DecodedWebObject> objects,
    required Map<String, List<BrainConcept>> conceptsByNote,
  }) {
    final byLogicalPath =
        <String, ({_DecodedWebObject object, BrainFile note})>{};

    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) {
        continue;
      }

      try {
        final note = _hydrateNoteConcepts(
          _fileMapper.fromVaultData(item.data),
          conceptsByNote,
        );

        final logicalPath = note.path.trim();

        // Payloads antigos sem path não devem colidir entre si.
        final key = logicalPath.isEmpty
            ? 'object:${item.object.header.objectId}'
            : 'path:$logicalPath';

        final current = byLogicalPath[key];

        if (current == null ||
            _isNewerNoteCandidate(
              candidateObject: item,
              candidateNote: note,
              currentObject: current.object,
              currentNote: current.note,
            )) {
          byLogicalPath[key] = (object: item, note: note);
        }
      } catch (_) {
        // Uma nota inválida não bloqueia as demais.
      }
    }

    return byLogicalPath.values.toList(growable: false);
  }

  List<BrainFile> _orphanConceptSearchNotes({
    required List<_DecodedWebObject> objects,
    required Iterable<BrainFile> hydratedNotes,
  }) {
    // Alguns conhecimentos antigos existem como objetos `concept`
    // independentes, mas não possuem source_note_path. A tela Conceitos
    // consegue exibi-los porque usa loadConcepts() diretamente; já a busca
    // principal trabalha somente com BrainFile em BrainController.notes.
    //
    // Para que esses conhecimentos também participem da busca sem alterar
    // seus dados persistidos, criamos BrainFile sintéticos somente em memória.
    final knownConceptIds = <String>{};

    for (final note in hydratedNotes) {
      for (final concept in note.concepts) {
        final id = concept.id.trim();
        if (id.isNotEmpty) {
          knownConceptIds.add(id);
        }
      }
    }

    final synthetic = <BrainFile>[];

    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;

      try {
        final concept = _conceptMapper.fromVaultData(item.data);
        final conceptId = concept.id.trim();

        // Já está associado/hidratado em uma nota real.
        if (conceptId.isNotEmpty && knownConceptIds.contains(conceptId)) {
          continue;
        }

        // O objeto sintético existe apenas para busca/visualização.
        // O id recebe prefixo próprio para não colidir com notas reais.
        final stableId = conceptId.isNotEmpty
            ? conceptId
            : item.object.header.objectId;

        synthetic.add(
          BrainFile(
            topic: 'Conceitos',
            title: concept.title.trim().isEmpty
                ? concept.label
                : concept.title.trim(),
            path: 'vault://concept-search/$stableId',
            content: concept.description,
            concepts: <BrainConcept>[concept],
            sources: const <BrainSource>[],
            createdAt: item.object.header.createdAt.toLocal(),
            updatedAt: item.object.header.updatedAt.toLocal(),
          ),
        );

        if (conceptId.isNotEmpty) {
          knownConceptIds.add(conceptId);
        }
      } catch (_) {
        // Conceito inválido não bloqueia os demais resultados.
      }
    }

    return List<BrainFile>.unmodifiable(synthetic);
  }

  Future<List<Map<String, dynamic>>> loadNotes() async {
    final objects = await _loadObjects();
    final conceptsByNote = _conceptsBySourceNote(objects);

    // Uma única nota lógica pode ter mais de um objeto físico legado.
    // A lista pública expõe somente a versão mais recente de cada path.
    final latestLogicalNotes = _latestLogicalNotes(
      objects: objects,
      conceptsByNote: conceptsByNote,
    );

    final notes = latestLogicalNotes
        .map((item) => item.note)
        .toList(growable: true);

    // A busca principal usa somente BrainController.notes. Portanto,
    // conhecimentos standalone sem source_note_path precisam entrar nessa
    // visão de leitura. Eles NÃO são gravados como notas no Vault.
    final orphanConceptNotes = _orphanConceptSearchNotes(
      objects: objects,
      hydratedNotes: notes,
    );

    notes.addAll(orphanConceptNotes);

    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return notes.map(_noteToRow).toList(growable: false);
  }

  Future<Map<String, dynamic>?> getNote(String id) async {
    final clean = id.trim();

    if (clean.isEmpty) {
      return null;
    }

    final objects = await _loadObjects();
    final conceptsByNote = _conceptsBySourceNote(objects);

    final latest = _latestMatchingNote(
      objects: objects,
      id: clean,
      conceptsByNote: conceptsByNote,
    );

    if (latest == null) {
      return null;
    }

    return _noteToRow(latest.note);
  }

  Future<Map<String, dynamic>> saveNote({
    String? id,
    required String topic,
    required String title,
    required String content,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty) {
      throw const FormatException('Informe o título da anotação.');
    }
    if (cleanContent.isEmpty) {
      throw const FormatException('Escreva algum conteúdo.');
    }

    _DecodedWebObject? previousObject;
    BrainFile? previousNote;
    final cleanId = id?.trim() ?? '';

    if (cleanId.isNotEmpty) {
      final objects = await _loadObjects();
      final latest = _latestMatchingNote(objects: objects, id: cleanId);

      previousObject = latest?.object;
      previousNote = latest?.note;
    }

    // Um ID informado significa edição, nunca criação implícita.
    if (cleanId.isNotEmpty &&
        (previousNote == null || previousObject == null)) {
      throw StateError(
        'A anotação original não foi encontrada no Vault Web. '
        'Salvamento cancelado para evitar uma cópia duplicada.',
      );
    }

    final now = DateTime.now().toLocal();
    final path = previousNote?.path ?? 'vault://note/${_uuid.v4()}';
    final note = BrainFile(
      topic: topic.trim().isEmpty ? 'Sem tema' : topic.trim(),
      title: cleanTitle,
      path: path,
      content: cleanContent,
      concepts: previousNote?.concepts ?? const <BrainConcept>[],
      sources: previousNote?.sources ?? const <BrainSource>[],
      createdAt: previousNote?.createdAt ?? now,
      updatedAt: now,
    );

    await _writeLogical(
      type: BrainVaultObjectType.note,
      data: _fileMapper.toVaultData(note),
      previous: previousObject?.object,
    );
    return _noteToRow(note);
  }

  Future<void> deleteNote(String id) async {
    final clean = id.trim();

    if (clean.isEmpty) {
      return;
    }

    final objects = await _loadObjects();

    // Se o caller passou objectId, removemos exatamente aquele objeto.
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) {
        continue;
      }

      if (item.object.header.objectId.trim() == clean) {
        await _deleteObject(item.object);
        return;
      }
    }

    // Se o caller passou o path lógico, tombstonamos TODAS as cópias
    // físicas daquele path. Isso impede uma versão legada antiga de
    // reaparecer depois que a versão mais nova for excluída.
    final matches = <_DecodedWebObject>[];

    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) {
        continue;
      }

      try {
        final note = _fileMapper.fromVaultData(item.data);

        if (note.path.trim() == clean) {
          matches.add(item);
        }
      } catch (_) {
        // Ignora objeto inválido.
      }
    }

    for (final item in matches) {
      await _deleteObject(item.object);
    }
  }

  Future<List<BrainConcept>> loadConcepts() async {
    final objects = await _loadObjects();
    final concepts = <BrainConcept>[];
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;
      try {
        concepts.add(_conceptMapper.fromVaultData(item.data));
      } catch (_) {}
    }
    return List<BrainConcept>.unmodifiable(concepts);
  }

  Future<List<BrainConcept>> loadConceptsByType(BrainConceptType type) async {
    final all = await loadConcepts();
    return all.where((item) => item.type == type).toList(growable: false);
  }

  Future<List<BrainConcept>> loadOnlyConcepts() =>
      loadConceptsByType(BrainConceptType.concept);
  Future<List<BrainConcept>> loadQuestions() =>
      loadConceptsByType(BrainConceptType.question);
  Future<List<BrainConcept>> loadExamples() =>
      loadConceptsByType(BrainConceptType.example);
  Future<List<BrainConcept>> loadWarnings() =>
      loadConceptsByType(BrainConceptType.warning);

  Future<BrainConcept?> getConcept(String id) async {
    final clean = id.trim();
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;
      try {
        final concept = _conceptMapper.fromVaultData(item.data);
        if (concept.id == clean || item.object.header.objectId == clean) {
          return concept;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<Map<String, dynamic>> saveConcept({
    required BrainConcept concept,
    String? noteId,
  }) async {
    final result = await saveConceptsBatch(
      concepts: <BrainConcept>[concept],
      noteId: noteId,
    );
    return result.first;
  }

  Future<List<Map<String, dynamic>>> saveConceptsBatch({
    required Iterable<BrainConcept> concepts,
    String? noteId,
  }) async {
    final pending = concepts.toList(growable: false);
    if (pending.isEmpty) return const <Map<String, dynamic>>[];

    final objects = await _loadObjects();
    final result = <Map<String, dynamic>>[];

    for (final concept in pending) {
      _DecodedWebObject? previous;
      for (final item in objects) {
        if (item.type != BrainVaultObjectType.concept) continue;
        try {
          final existing = _conceptMapper.fromVaultData(item.data);
          if (existing.id == concept.id) {
            previous = item;
            break;
          }
        } catch (_) {}
      }

      await _writeLogical(
        type: BrainVaultObjectType.concept,
        data: _conceptMapper.toVaultData(
          concept: concept,
          sourceNotePath: noteId,
        ),
        previous: previous?.object,
      );

      result.add(<String, dynamic>{
        'id': concept.id,
        'note_id': noteId,
        'title': concept.title,
        'description': concept.description,
        'type': concept.type.name,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    }

    // Mantém os conceitos embutidos na nota, como no Vault desktop.
    if (noteId != null && noteId.trim().isNotEmpty) {
      final noteRow = await getNote(noteId);
      if (noteRow != null) {
        final currentObjects = await _loadObjects();
        for (final item in currentObjects) {
          if (item.type != BrainVaultObjectType.note) continue;
          try {
            final note = _fileMapper.fromVaultData(item.data);
            if (note.path != noteId) continue;
            final merged = <BrainConcept>[...note.concepts];
            for (final concept in pending) {
              final index = merged.indexWhere((e) => e.id == concept.id);
              if (index >= 0) {
                merged[index] = concept;
              } else {
                merged.add(concept);
              }
            }
            final updated = note.copyWith(
              concepts: merged,
              updatedAt: DateTime.now().toLocal(),
            );
            await _writeLogical(
              type: BrainVaultObjectType.note,
              data: _fileMapper.toVaultData(updated),
              previous: item.object,
            );
            break;
          } catch (_) {}
        }
      }
    }

    return List<Map<String, dynamic>>.unmodifiable(result);
  }

  Future<void> deleteConcept(String id) async {
    final clean = id.trim();
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;
      try {
        final concept = _conceptMapper.fromVaultData(item.data);
        if (concept.id == clean || item.object.header.objectId == clean) {
          await _deleteObject(item.object);
          return;
        }
      } catch (_) {}
    }
  }

  Future<void> deleteConceptAndSourceNote(String id) async {
    final clean = id.trim();
    final objects = await _loadObjects();
    String? sourcePath;
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;
      try {
        final concept = _conceptMapper.fromVaultData(item.data);
        if (concept.id == clean || item.object.header.objectId == clean) {
          sourcePath = _conceptMapper.sourceNotePathFromVaultData(item.data);
          await _deleteObject(item.object);
          break;
        }
      } catch (_) {}
    }
    if (sourcePath != null && sourcePath.trim().isNotEmpty) {
      await deleteNote(sourcePath);
    }
  }

  Future<void> deleteConceptsByNoteId(String noteId) async {
    final clean = noteId.trim();
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.concept) continue;
      final sourcePath = _conceptMapper.sourceNotePathFromVaultData(item.data);
      if (sourcePath == clean) await _deleteObject(item.object);
    }
  }

  Future<List<BrainSource>> getSourcesByNote(String noteId) async {
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) continue;
      try {
        final note = _fileMapper.fromVaultData(item.data);
        if (note.path == noteId || item.object.header.objectId == noteId) {
          return List<BrainSource>.unmodifiable(note.sources);
        }
      } catch (_) {}
    }
    return const <BrainSource>[];
  }

  Future<BrainFile> _requireNote(String noteId) async {
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) continue;
      final note = _fileMapper.fromVaultData(item.data);
      if (note.path == noteId || item.object.header.objectId == noteId) {
        return note;
      }
    }
    throw StateError('Anotação não encontrada.');
  }

  Future<BrainFile> _saveSourceNote(BrainFile updated) async {
    final objects = await _loadObjects();
    for (final item in objects) {
      if (item.type != BrainVaultObjectType.note) continue;
      final note = _fileMapper.fromVaultData(item.data);
      if (note.path == updated.path) {
        await _writeLogical(
          type: BrainVaultObjectType.note,
          data: _fileMapper.toVaultData(updated),
          previous: item.object,
        );
        return updated;
      }
    }
    throw StateError('Anotação não encontrada.');
  }

  Future<BrainFile> addSourceToNote({
    required String noteId,
    required BrainSource source,
  }) async {
    if (!source.isValid) {
      throw const FormatException('A fonte informada é inválida.');
    }
    final note = await _requireNote(noteId);
    return _saveSourceNote(
      note.addSource(source).copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<BrainFile> updateSourceInNote({
    required String noteId,
    required BrainSource source,
  }) async {
    if (!source.isValid) {
      throw const FormatException('A fonte informada é inválida.');
    }
    final note = await _requireNote(noteId);
    return _saveSourceNote(
      note.updateSource(source.touch()).copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<BrainFile> removeSourceFromNote({
    required String noteId,
    required String sourceId,
  }) async {
    final note = await _requireNote(noteId);
    return _saveSourceNote(
      note
          .removeSourceById(sourceId.trim())
          .copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<BrainFile> clearSourcesFromNote(String noteId) async {
    final note = await _requireNote(noteId);
    return _saveSourceNote(
      note.clearSources().copyWith(updatedAt: DateTime.now()),
    );
  }

  Future<List<Map<String, dynamic>>> loadRemoteNotes() => loadNotes();
  Future<void> migrateLegacyPlaintextIfNeeded() async {}

  /// Metadados genéricos criptografados (ex.: Trilhas e recibos de importação).
  /// Nunca são gravados em tabelas públicas nem em armazenamento plaintext.
  Future<List<Map<String, dynamic>>> loadImportMetadata(String model) async {
    final objects = await _loadObjects();
    return objects
        .where(
          (item) =>
              item.type == BrainVaultObjectType.generic &&
              item.data['model'] == model,
        )
        .map(
          (item) => <String, dynamic>{
            ...item.data,
            '_vault_object_id': item.object.header.objectId,
          },
        )
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> saveImportMetadata(
    Map<String, dynamic> metadata, {
    String? vaultObjectId,
  }) async {
    final model = metadata['model'];
    if (model is! String || model.trim().isEmpty) {
      throw const FormatException('Modelo de metadados inválido.');
    }
    BrainVaultObject? previous;
    if (vaultObjectId != null) {
      final objects = await _loadObjects();
      for (final item in objects) {
        if (item.object.header.objectId == vaultObjectId &&
            item.type == BrainVaultObjectType.generic &&
            item.data['model'] == model) {
          previous = item.object;
          break;
        }
      }
      if (previous == null) {
        throw StateError('Objeto E2EE de metadados não encontrado.');
      }
    }
    final data = Map<String, dynamic>.from(metadata)
      ..remove('_vault_object_id');
    final saved = await _writeLogical(
      type: BrainVaultObjectType.generic,
      data: data,
      previous: previous,
    );
    return <String, dynamic>{
      ...data,
      '_vault_object_id': saved.header.objectId,
    };
  }
}
