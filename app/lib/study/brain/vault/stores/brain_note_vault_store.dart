import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';
import '../../models/brain_source.dart';

import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_type.dart';
import '../services/brain_vault_service.dart';

// ============================================================
// BRAIN NOTE VAULT STORE
// ============================================================
//
// Fonte criptografada das notas do Cérebro para sync E2EE.
//
// BrainStorage ainda pode existir como mirror/compatibilidade de
// Markdown local, mas nenhuma nota nova entra na SyncQueue em
// plaintext.
//
// FASE 13:
//
// - sources passam a ser persistidas dentro do payload criptografado;
// - payloads antigos sem sources continuam válidos;
// - referência/autor/observação não entram no mirror Markdown aqui.
//
// ============================================================
//
// OTIMIZAÇÃO DE PERFORMANCE
// ============================================================
//
// PRIMEIRA OTIMIZAÇÃO:
//
// path / legacyRemoteId passaram a utilizar índice em memória.
//
// Isso eliminou buscas repetidas que varriam o Vault inteiro.
//
// ------------------------------------------------------------
//
// SEGUNDA OTIMIZAÇÃO:
//
// Na construção inicial do índice:
//
// ANTES:
//
// loadAllEncryptedObjects()
//        ↓
// para cada objeto
//        ↓
// readObject(id)
//        ↓
// relê objeto do disco
//        ↓
// reabre Vault
//        ↓
// relê Master Key
//        ↓
// decrypt
//
// tudo sequencial.
//
// ------------------------------------------------------------
//
// AGORA:
//
// loadAllEncryptedObjects()
//        ↓
// objetos ativos já estão em memória
//        ↓
// decodeEncryptedObjects()
//        ↓
// Vault aberto uma vez
// Master Key obtida uma vez
// sem reler objeto do disco
//        ↓
// lotes de 6 objetos em paralelo
//
// ------------------------------------------------------------
//
// SEGURANÇA:
//
// - E2EE continua obrigatório;
// - nenhum conteúdo é persistido em plaintext;
// - verifyBinding continua sendo executado;
// - keyVersion continua validada;
// - tombstones continuam ignorados;
// - cache continua somente em memória.
//
// ============================================================

class BrainNoteVaultStore {
  BrainNoteVaultStore({required BrainVaultService vaultService})
    : _vaultService = vaultService;

  final BrainVaultService _vaultService;

  // ============================================================
  // PERFORMANCE
  // ============================================================

  static const int _decodeConcurrency = 6;

  // ============================================================
  // CACHE / INDEX
  // ============================================================

  bool _indexLoaded = false;

  Future<void>? _indexLoadFuture;

  final Map<String, BrainVaultObject> _objectById =
      <String, BrainVaultObject>{};

  final Map<String, String> _pathToObjectId = <String, String>{};

  final Map<String, String> _legacyRemoteIdToObjectId = <String, String>{};

  final Map<String, Map<String, dynamic>> _dataByObjectId =
      <String, Map<String, dynamic>>{};

  final Map<String, BrainFile> _noteByObjectId = <String, BrainFile>{};

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await _vaultService.getOrCreateVault();
  }

  // ============================================================
  // CACHE — INVALIDAR
  // ============================================================

  void invalidateCache() {
    _clearIndex();
  }

  // ============================================================
  // CACHE — REFRESH
  // ============================================================

  Future<void> refreshCache() async {
    _clearIndex();

    await _ensureIndexLoaded();
  }

  // ============================================================
  // CACHE — CLEAR
  // ============================================================

  void _clearIndex() {
    _indexLoaded = false;

    _objectById.clear();

    _pathToObjectId.clear();

    _legacyRemoteIdToObjectId.clear();

    _dataByObjectId.clear();

    _noteByObjectId.clear();
  }

  // ============================================================
  // CACHE — ENSURE
  // ============================================================

  Future<void> _ensureIndexLoaded() {
    if (_indexLoaded) {
      return Future<void>.value();
    }

    final existingFuture = _indexLoadFuture;

    if (existingFuture != null) {
      return existingFuture;
    }

    final future = _buildIndex();

    _indexLoadFuture = future;

    return future.whenComplete(() {
      if (identical(_indexLoadFuture, future)) {
        _indexLoadFuture = null;
      }
    });
  }

  // ============================================================
  // CACHE — BUILD
  // ============================================================

  Future<void> _buildIndex() async {
    final totalWatch = Stopwatch()..start();

    await initialize();

    // ==========================================================
    // LOAD RAW OBJECTS
    // ==========================================================

    final listWatch = Stopwatch()..start();

    final objects = await _vaultService.loadAllEncryptedObjects();

    listWatch.stop();

    // ==========================================================
    // RESET CACHE
    // ==========================================================

    _objectById.clear();

    _pathToObjectId.clear();

    _legacyRemoteIdToObjectId.clear();

    _dataByObjectId.clear();

    _noteByObjectId.clear();

    // ==========================================================
    // FILTER ACTIVE OBJECTS
    // ==========================================================
    //
    // Não enviamos tombstones para decrypt.
    //
    // Também ignoramos objectId inválido.
    //
    // ==========================================================

    var deletedObjects = 0;

    var invalidObjectIds = 0;

    final activeObjects = <BrainVaultObject>[];

    for (final object in objects) {
      if (object.isDeleted) {
        deletedObjects++;

        continue;
      }

      final objectId = object.header.objectId.trim();

      if (objectId.isEmpty) {
        invalidObjectIds++;

        continue;
      }

      activeObjects.add(object);
    }

    // ==========================================================
    // BATCH DECODE
    // ==========================================================
    //
    // Esta é a mudança principal.
    //
    // Não fazemos mais:
    //
    // for (...) {
    //   await readObject(id);
    // }
    //
    // readObject() releria o objeto do disco e reabriria o Vault.
    //
    // Os objetos já estão carregados.
    //
    // ==========================================================

    final decodeWatch = Stopwatch()..start();

    final decodedObjects = await _vaultService.decodeEncryptedObjects(
      activeObjects,
      concurrency: _decodeConcurrency,
    );

    decodeWatch.stop();

    // ==========================================================
    // BUILD NOTE INDEX
    // ==========================================================

    var decodedNotes = 0;

    var invalidNotes = 0;

    var nonNoteObjects = 0;

    for (var index = 0; index < activeObjects.length; index++) {
      final object = activeObjects[index];

      final decoded = decodedObjects[index];

      if (decoded == null) {
        continue;
      }

      if (decoded.type != BrainVaultObjectType.note) {
        nonNoteObjects++;

        continue;
      }

      final objectId = object.header.objectId.trim();

      final data = Map<String, dynamic>.from(decoded.data);

      _objectById[objectId] = object;

      _dataByObjectId[objectId] = data;

      // ========================================================
      // PATH INDEX
      // ========================================================

      final path = data['path']?.toString().trim() ?? '';

      if (path.isNotEmpty) {
        _pathToObjectId.putIfAbsent(path, () => objectId);
      }

      // ========================================================
      // LEGACY REMOTE ID INDEX
      // ========================================================

      final legacyRemoteId = data['legacy_remote_id']?.toString().trim() ?? '';

      if (legacyRemoteId.isNotEmpty) {
        _legacyRemoteIdToObjectId.putIfAbsent(legacyRemoteId, () => objectId);
      }

      // ========================================================
      // BRAIN FILE
      // ========================================================

      try {
        final note = _fromVaultData(data);

        _noteByObjectId[objectId] = note;

        decodedNotes++;
      } catch (_) {
        invalidNotes++;
      }
    }

    _indexLoaded = true;

    totalWatch.stop();

    // ==========================================================
    // PERF
    // ==========================================================

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'Vault objetos=${objects.length} '
      'ativos=${activeObjects.length} '
      'deleted=$deletedObjects '
      'objectIdsInvalidos=$invalidObjectIds '
      'naoNotas=$nonNoteObjects '
      'notas=$decodedNotes '
      'invalidas=$invalidNotes',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'loadAllEncryptedObjects = '
      '${listWatch.elapsedMilliseconds} ms',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'Vault batch decode/index = '
      '${decodeWatch.elapsedMilliseconds} ms '
      '(concorrencia=$_decodeConcurrency)',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainNoteVaultStore INDEX TOTAL = '
      '${totalWatch.elapsedMilliseconds} ms',
    );
  }

  // ============================================================
  // SAVE / UPSERT
  // ============================================================

  Future<BrainVaultObject> saveNote(
    BrainFile note, {
    String? legacyRemoteId,
  }) async {
    await _ensureIndexLoaded();

    final data = _toVaultData(note, legacyRemoteId: legacyRemoteId);

    final existing = _findEncryptedObjectByPathFromIndex(note.path);

    // ==========================================================
    // CREATE
    // ==========================================================

    if (existing == null) {
      final created = await _vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: data,
      );

      _upsertCachedNote(object: created, data: data, note: note);

      return created;
    }

    final objectId = existing.header.objectId.trim();

    // ==========================================================
    // CACHE HIT
    // ==========================================================

    final cachedData = _dataByObjectId[objectId];

    if (cachedData != null && _mapsEquivalent(cachedData, data)) {
      return existing;
    }

    // ==========================================================
    // DEFENSIVE SINGLE READ
    // ==========================================================

    if (cachedData == null) {
      final decoded = await _vaultService.readObject(objectId);

      if (decoded != null &&
          decoded.type == BrainVaultObjectType.note &&
          _mapsEquivalent(decoded.data, data)) {
        _upsertCachedNote(
          object: existing,
          data: Map<String, dynamic>.from(decoded.data),
          note: note,
        );

        return existing;
      }
    }

    // ==========================================================
    // UPDATE
    // ==========================================================

    final updated = await _vaultService.updateObject(
      objectId: objectId,
      type: BrainVaultObjectType.note,
      data: data,
    );

    _upsertCachedNote(object: updated, data: data, note: note);

    return updated;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<List<BrainFile>> loadNotes() async {
    final totalWatch = Stopwatch()..start();

    await _ensureIndexLoaded();

    final result = List<BrainFile>.from(_noteByObjectId.values);

    result.sort((first, second) {
      return second.updatedAt.compareTo(first.updatedAt);
    });

    totalWatch.stop();

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainNoteVaultStore.loadNotes CACHE = '
      '${totalWatch.elapsedMilliseconds} ms '
      '(${result.length} notas)',
    );

    return result;
  }

  // ============================================================
  // GET NOTE BY PATH
  // ============================================================

  Future<BrainFile?> getNoteByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    await _ensureIndexLoaded();

    final objectId = _pathToObjectId[cleanPath];

    if (objectId == null || objectId.isEmpty) {
      return null;
    }

    final object = _objectById[objectId];

    if (object == null || object.isDeleted) {
      return null;
    }

    final cachedNote = _noteByObjectId[objectId];

    if (cachedNote != null) {
      return cachedNote;
    }

    final cachedData = _dataByObjectId[objectId];

    if (cachedData != null) {
      return _fromVaultData(cachedData);
    }

    // ==========================================================
    // FALLBACK SINGLE OBJECT
    // ==========================================================

    final decoded = await _vaultService.readObject(objectId);

    if (decoded == null || decoded.type != BrainVaultObjectType.note) {
      return null;
    }

    final data = Map<String, dynamic>.from(decoded.data);

    final note = _fromVaultData(data);

    _dataByObjectId[objectId] = data;

    _noteByObjectId[objectId] = note;

    return note;
  }

  // ============================================================
  // FIND RAW — PATH
  // ============================================================

  Future<BrainVaultObject?> findEncryptedObjectByPath(String path) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    await _ensureIndexLoaded();

    return _findEncryptedObjectByPathFromIndex(cleanPath);
  }

  // ============================================================
  // FIND RAW — PATH — INDEX ONLY
  // ============================================================

  BrainVaultObject? _findEncryptedObjectByPathFromIndex(String path) {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return null;
    }

    final objectId = _pathToObjectId[cleanPath];

    if (objectId == null || objectId.isEmpty) {
      return null;
    }

    final object = _objectById[objectId];

    if (object == null || object.isDeleted) {
      return null;
    }

    return object;
  }

  // ============================================================
  // FIND RAW — LEGACY REMOTE ID
  // ============================================================

  Future<BrainVaultObject?> findEncryptedObjectByLegacyRemoteId(
    String remoteId,
  ) async {
    final cleanId = remoteId.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    await _ensureIndexLoaded();

    final objectId = _legacyRemoteIdToObjectId[cleanId];

    if (objectId == null || objectId.isEmpty) {
      return null;
    }

    final object = _objectById[objectId];

    if (object == null || object.isDeleted) {
      return null;
    }

    return object;
  }

  // ============================================================
  // DELETE / TOMBSTONE — PATH
  // ============================================================

  Future<BrainVaultObject?> deleteNoteByPath(String path) async {
    final object = await findEncryptedObjectByPath(path);

    if (object == null) {
      return null;
    }

    final objectId = object.header.objectId.trim();

    final tombstone = await _vaultService.deleteObject(objectId);

    _removeCachedObject(objectId);

    return tombstone;
  }

  // ============================================================
  // DELETE / TOMBSTONE — LEGACY REMOTE ID
  // ============================================================

  Future<BrainVaultObject?> deleteNoteByLegacyRemoteId(String remoteId) async {
    final object = await findEncryptedObjectByLegacyRemoteId(remoteId);

    if (object == null) {
      return null;
    }

    final objectId = object.header.objectId.trim();

    final tombstone = await _vaultService.deleteObject(objectId);

    _removeCachedObject(objectId);

    return tombstone;
  }

  // ============================================================
  // CACHE — UPSERT
  // ============================================================

  void _upsertCachedNote({
    required BrainVaultObject object,
    required Map<String, dynamic> data,
    required BrainFile note,
  }) {
    final objectId = object.header.objectId.trim();

    if (objectId.isEmpty) {
      invalidateCache();

      return;
    }

    _removeCachedObject(objectId);

    _objectById[objectId] = object;

    final copiedData = Map<String, dynamic>.from(data);

    _dataByObjectId[objectId] = copiedData;

    _noteByObjectId[objectId] = note;

    final path = copiedData['path']?.toString().trim() ?? '';

    if (path.isNotEmpty) {
      _pathToObjectId[path] = objectId;
    }

    final legacyRemoteId =
        copiedData['legacy_remote_id']?.toString().trim() ?? '';

    if (legacyRemoteId.isNotEmpty) {
      _legacyRemoteIdToObjectId[legacyRemoteId] = objectId;
    }

    _indexLoaded = true;
  }

  // ============================================================
  // CACHE — REMOVE OBJECT
  // ============================================================

  void _removeCachedObject(String objectId) {
    final cleanObjectId = objectId.trim();

    if (cleanObjectId.isEmpty) {
      return;
    }

    final data = _dataByObjectId[cleanObjectId];

    if (data != null) {
      final path = data['path']?.toString().trim() ?? '';

      if (path.isNotEmpty && _pathToObjectId[path] == cleanObjectId) {
        _pathToObjectId.remove(path);
      }

      final legacyRemoteId = data['legacy_remote_id']?.toString().trim() ?? '';

      if (legacyRemoteId.isNotEmpty &&
          _legacyRemoteIdToObjectId[legacyRemoteId] == cleanObjectId) {
        _legacyRemoteIdToObjectId.remove(legacyRemoteId);
      }
    }

    _pathToObjectId.removeWhere((_, value) => value == cleanObjectId);

    _legacyRemoteIdToObjectId.removeWhere((_, value) => value == cleanObjectId);

    _objectById.remove(cleanObjectId);

    _dataByObjectId.remove(cleanObjectId);

    _noteByObjectId.remove(cleanObjectId);
  }

  // ============================================================
  // MAPPER — NOTE -> VAULT
  // ============================================================

  Map<String, dynamic> _toVaultData(BrainFile note, {String? legacyRemoteId}) {
    final concepts = note.concepts
        .map((concept) {
          return <String, dynamic>{
            'id': concept.id,
            'title': concept.title,
            'description': concept.description,
            'type': concept.type.name,
            'review_enabled': concept.reviewEnabled,
          };
        })
        .toList(growable: false);

    final sources = note.sources
        .map((source) {
          return source.toJson();
        })
        .toList(growable: false);

    final cleanLegacyRemoteId = legacyRemoteId?.trim();

    return <String, dynamic>{
      'model': 'brain_note',

      'topic': note.topic.trim(),

      'title': note.title.trim(),

      'path': note.path.trim(),

      'content': note.content,

      'concepts': concepts,

      'sources': sources,

      'legacy_remote_id':
          cleanLegacyRemoteId == null || cleanLegacyRemoteId.isEmpty
          ? null
          : cleanLegacyRemoteId,

      'created_at': note.createdAt.toUtc().toIso8601String(),

      'updated_at': note.updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // MAPPER — VAULT -> NOTE
  // ============================================================

  BrainFile _fromVaultData(Map<String, dynamic> data) {
    final topic = data['topic']?.toString().trim() ?? '';

    final title = data['title']?.toString().trim() ?? '';

    final path = data['path']?.toString().trim() ?? '';

    final content = data['content']?.toString() ?? '';

    final createdAt = DateTime.tryParse(
      data['created_at']?.toString().trim() ?? '',
    )?.toLocal();

    final updatedAt = DateTime.tryParse(
      data['updated_at']?.toString().trim() ?? '',
    )?.toLocal();

    if (title.isEmpty ||
        path.isEmpty ||
        content.trim().isEmpty ||
        updatedAt == null) {
      throw const FormatException('Nota do Vault inválida.');
    }

    // ==========================================================
    // CONCEPTS
    // ==========================================================

    final concepts = <BrainConcept>[];

    final rawConcepts = data['concepts'];

    if (rawConcepts is Iterable) {
      for (final raw in rawConcepts) {
        if (raw is! Map) {
          continue;
        }

        final map = Map<String, dynamic>.from(raw);

        final id = map['id']?.toString().trim() ?? '';

        final conceptTitle = map['title']?.toString().trim() ?? '';

        final description = map['description']?.toString().trim() ?? '';

        final typeName = map['type']?.toString().trim() ?? '';

        if (id.isEmpty || conceptTitle.isEmpty || description.isEmpty) {
          continue;
        }

        final type = BrainConceptType.values.firstWhere(
          (value) {
            return value.name == typeName;
          },
          orElse: () {
            return BrainConceptType.concept;
          },
        );

        concepts.add(
          BrainConcept(
            id: id,
            title: conceptTitle,
            description: description,
            type: type,
            reviewEnabled: BrainConcept.parseReviewEnabled(
              map['review_enabled'],
            ),
          ),
        );
      }
    }

    // ==========================================================
    // SOURCES
    // ==========================================================

    final sources = <BrainSource>[];

    final rawSources = data['sources'];

    if (rawSources != null) {
      if (rawSources is! Iterable) {
        throw const FormatException(
          'Campo sources da nota do Vault é inválido.',
        );
      }

      for (final raw in rawSources) {
        if (raw is! Map) {
          throw const FormatException(
            'BrainSource inválida dentro da nota do Vault.',
          );
        }

        final source = BrainSource.fromJson(Map<String, dynamic>.from(raw));

        if (!source.isValid) {
          throw const FormatException(
            'BrainSource inválida dentro da nota do Vault.',
          );
        }

        sources.add(source);
      }
    }

    // ==========================================================
    // NOTE
    // ==========================================================

    return BrainFile(
      topic: topic,
      title: title,
      path: path,
      content: content,
      concepts: List<BrainConcept>.unmodifiable(concepts),
      sources: List<BrainSource>.unmodifiable(sources),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // MAP EQUIVALENCE
  // ============================================================

  bool _mapsEquivalent(
    Map<String, dynamic> first,
    Map<String, dynamic> second,
  ) {
    return _deepEqual(first, second);
  }

  // ============================================================
  // DEEP EQUAL
  // ============================================================

  bool _deepEqual(dynamic first, dynamic second) {
    if (identical(first, second)) {
      return true;
    }

    // ==========================================================
    // MAP
    // ==========================================================

    if (first is Map && second is Map) {
      if (first.length != second.length) {
        return false;
      }

      for (final key in first.keys) {
        if (!second.containsKey(key)) {
          return false;
        }

        if (!_deepEqual(first[key], second[key])) {
          return false;
        }
      }

      return true;
    }

    // ==========================================================
    // ITERABLE
    // ==========================================================

    if (first is Iterable && second is Iterable) {
      final firstList = first.toList();

      final secondList = second.toList();

      if (firstList.length != secondList.length) {
        return false;
      }

      for (var index = 0; index < firstList.length; index++) {
        if (!_deepEqual(firstList[index], secondList[index])) {
          return false;
        }
      }

      return true;
    }

    return first == second;
  }
}
