import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../core/storage/user_storage_scope.dart';
import '../models/brain_vault_manifest.dart';
import '../models/brain_vault_object.dart';
import '../compaction/brain_vault_compaction_ledger.dart';
import '../services/brain_vault_id_service.dart';
import '../services/brain_vault_serializer.dart';

// ============================================================
// BRAIN VAULT STORAGE
// ============================================================
//
// Responsável SOMENTE pela persistência física do Vault.
//
// Não criptografa.
// Não descriptografa.
// Não conhece BrainFile.
// Não conhece Review.
//
// Ele apenas lê/escreve:
//
// manifest.json
// *.evobj
//
// SEGURANÇA:
//
// - não recebe plaintext para criptografar;
// - BrainVaultService entrega BrainVaultObject já criptografado;
// - .evobj contém ciphertext / nonce / tag / metadata;
// - Master Key continua fora desta pasta;
// - armazenamento continua isolado por UserStorageScope.
//
// ============================================================
//
// PERFORMANCE
// ============================================================
//
// Antes:
//
// for (final file in files) {
//   await file.readAsString();
// }
//
// Todos os arquivos eram lidos sequencialmente.
//
// Agora:
//
// - lista os arquivos uma vez;
// - mantém ordenação determinística;
// - lê em lotes concorrentes;
// - desserializa e valida cada objeto;
// - preserva exatamente a ordem original.
//
// Nenhum formato de arquivo foi alterado.
//
// ============================================================

class BrainVaultStorage {
  BrainVaultStorage({
    required UserStorageScope storageScope,
    BrainVaultSerializer? serializer,
    BrainVaultIdService? idService,
    Future<
      String?
    >
    Function()?
    localRootPathProvider,
  }) : _storageScope = storageScope,
       _serializer =
           serializer ??
           const BrainVaultSerializer(),
       _idService =
           idService ??
           BrainVaultIdService(),
       _localRootPathProvider = localRootPathProvider;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final UserStorageScope _storageScope;

  final BrainVaultSerializer _serializer;

  final BrainVaultIdService _idService;

  final Future<
    String?
  >
  Function()?
  _localRootPathProvider;

  // ============================================================
  // PATH CONSTANTS
  // ============================================================

  static const String objectsDirectoryName = 'objects';

  static const String manifestFileName = 'manifest.json';

  static const String compactionLedgerFileName = 'compaction_ledger.json';

  static const String objectExtension = '.evobj';

  // ============================================================
  // PERFORMANCE
  // ============================================================
  //
  // Arquivos locais pequenos.
  //
  // 12 é um ponto inicial conservador:
  //
  // - reduz bastante latência de I/O;
  // - evita abrir centenas de arquivos simultaneamente;
  // - funciona bem em SSDs comuns.
  //
  // ============================================================

  static const int _readConcurrency = 12;

  // ============================================================
  // INITIALIZED STATE
  // ============================================================

  bool _initialized = false;

  String? _initializedUserId;

  String? _initializedVaultPath;

  int _initializationGeneration = 0;

  Directory? _vaultDirectory;

  Directory? _objectsDirectory;

  // ============================================================
  // USER
  // ============================================================

  String get userId {
    return _storageScope.userId;
  }

  // ============================================================
  // OWNERSHIP GUARD
  // ============================================================

  void _assertCurrentOwner() {
    if (!_initialized ||
        _initializedUserId ==
            null ||
        _initializedUserId !=
            _storageScope.userId) {
      throw StateError(
        'BrainVaultStorage não foi inicializado para a conta atual.',
      );
    }
  }

  // ============================================================
  // GETTERS
  // ============================================================

  Directory get vaultDirectory {
    _assertCurrentOwner();

    final value = _vaultDirectory;

    if (value ==
        null) {
      throw StateError(
        'BrainVaultStorage ainda não foi inicializado.',
      );
    }

    return value;
  }

  Directory get objectsDirectory {
    _assertCurrentOwner();

    final value = _objectsDirectory;

    if (value ==
        null) {
      throw StateError(
        'BrainVaultStorage ainda não foi inicializado.',
      );
    }

    return value;
  }

  File get manifestFile {
    return File(
      p.join(
        vaultDirectory.path,
        manifestFileName,
      ),
    );
  }

  File get compactionLedgerFile {
    return File(
      p.join(
        vaultDirectory.path,
        compactionLedgerFileName,
      ),
    );
  }

  // ============================================================
  // RESOLVE VAULT DIRECTORY
  // ============================================================
  //
  // 1. root personalizado:
  //
  // <brain-root>/vault
  //
  // 2. padrão:
  //
  // UserStorageScope.vaultDirectory
  //
  // ============================================================

  Future<
    Directory
  >
  _resolveVaultDirectory() async {
    final provider = _localRootPathProvider;

    if (provider !=
        null) {
      final configuredPath = await provider();

      final cleanPath =
          configuredPath?.trim() ??
          '';

      if (cleanPath.isNotEmpty) {
        final brainRoot = Directory(
          p.normalize(
            cleanPath,
          ),
        );

        if (!await brainRoot.exists()) {
          await brainRoot.create(
            recursive: true,
          );
        }

        return Directory(
          p.join(
            brainRoot.path,
            'vault',
          ),
        );
      }
    }

    return _storageScope.vaultDirectory;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    final requestedUserId = _storageScope.userId;

    final requestedVault = await _resolveVaultDirectory();

    final requestedVaultPath = p.normalize(
      requestedVault.absolute.path,
    );

    if (_initialized &&
        _initializedUserId ==
            requestedUserId &&
        _initializedVaultPath ==
            requestedVaultPath) {
      return;
    }

    final generation = ++_initializationGeneration;

    _initialized = false;

    _initializedUserId = null;

    _initializedVaultPath = null;

    _vaultDirectory = null;

    _objectsDirectory = null;

    if (_initializationGeneration !=
            generation ||
        _storageScope.userId !=
            requestedUserId) {
      throw StateError(
        'A conta mudou durante a inicialização do Vault.',
      );
    }

    final vault = Directory(
      requestedVaultPath,
    );

    final objects = Directory(
      p.join(
        vault.path,
        objectsDirectoryName,
      ),
    );

    await objects.create(
      recursive: true,
    );

    if (_initializationGeneration !=
            generation ||
        _storageScope.userId !=
            requestedUserId) {
      throw StateError(
        'A conta mudou durante a inicialização do Vault.',
      );
    }

    _vaultDirectory = vault;

    _objectsDirectory = objects;

    _initializedUserId = requestedUserId;

    _initializedVaultPath = requestedVaultPath;

    _initialized = true;
  }

  // ============================================================
  // HAS MANIFEST
  // ============================================================

  Future<
    bool
  >
  hasManifest() async {
    await initialize();

    return manifestFile.exists();
  }

  // ============================================================
  // SAVE MANIFEST
  // ============================================================

  Future<
    void
  >
  saveManifest(
    BrainVaultManifest manifest,
  ) async {
    await initialize();

    manifest.validate();

    await _atomicWriteString(
      file: manifestFile,
      content: manifest.toJsonString(),
    );
  }

  // ============================================================
  // LOAD MANIFEST
  // ============================================================

  Future<
    BrainVaultManifest?
  >
  loadManifest() async {
    await initialize();

    final file = manifestFile;

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    return BrainVaultManifest.fromJsonString(
      content,
    );
  }

  // ============================================================
  // OBJECT FILE
  // ============================================================

  File objectFile(
    String objectId,
  ) {
    _assertValidObjectId(
      objectId,
    );

    return File(
      p.join(
        objectsDirectory.path,
        '$objectId$objectExtension',
      ),
    );
  }

  // ============================================================
  // OBJECT EXISTS
  // ============================================================

  Future<
    bool
  >
  containsObject(
    String objectId,
  ) async {
    await initialize();

    return objectFile(
      objectId,
    ).exists();
  }

  // ============================================================
  // SAVE OBJECT
  // ============================================================

  Future<
    void
  >
  saveObject(
    BrainVaultObject object,
  ) async {
    await initialize();

    object.validate();

    _assertValidObjectId(
      object.header.objectId,
    );

    final content = _serializer.serializeObject(
      object,
    );

    await _atomicWriteString(
      file: objectFile(
        object.header.objectId,
      ),
      content: content,
    );
  }

  // ============================================================
  // LOAD OBJECT
  // ============================================================

  Future<
    BrainVaultObject?
  >
  loadObject(
    String objectId,
  ) async {
    await initialize();

    final file = objectFile(
      objectId,
    );

    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();

    final object = _serializer.deserializeObject(
      content,
    );

    if (object.header.objectId !=
        objectId) {
      throw const FormatException(
        'objectId interno não corresponde ao nome do arquivo.',
      );
    }

    return object;
  }

  // ============================================================
  // LOAD ALL OBJECTS
  // ============================================================
  //
  // PERFORMANCE CRITICAL.
  //
  // Antes:
  //
  // arquivo 1
  //   ↓
  // await readAsString
  //
  // arquivo 2
  //   ↓
  // await readAsString
  //
  // ...
  //
  // Agora:
  //
  // [1..12]
  //   ↓
  // Future.wait
  //
  // [13..24]
  //   ↓
  // Future.wait
  //
  // mantendo:
  //
  // - validação individual;
  // - ordem determinística;
  // - erro explícito para arquivo corrompido;
  // - nenhuma alteração no formato .evobj.
  //
  // ============================================================

  Future<
    List<
      BrainVaultObject
    >
  >
  loadAllObjects() async {
    final totalWatch = Stopwatch()..start();

    await initialize();

    // ==========================================================
    // LIST DIRECTORY
    // ==========================================================

    final listWatch = Stopwatch()..start();

    final entities = await objectsDirectory
        .list(
          followLinks: false,
        )
        .toList();

    final files = entities
        .whereType<
          File
        >()
        .where(
          (
            file,
          ) {
            return file.path.endsWith(
              objectExtension,
            );
          },
        )
        .toList();

    files.sort(
      (
        first,
        second,
      ) {
        return first.path.compareTo(
          second.path,
        );
      },
    );

    listWatch.stop();

    // ==========================================================
    // PARALLEL READ
    // ==========================================================

    final readWatch = Stopwatch()..start();

    final objects =
        List<
          BrainVaultObject?
        >.filled(
          files.length,
          null,
          growable: false,
        );

    for (
      var start = 0;
      start <
          files.length;
      start += _readConcurrency
    ) {
      final calculatedEnd =
          start +
          _readConcurrency;

      final end =
          calculatedEnd >
              files.length
          ? files.length
          : calculatedEnd;

      final futures =
          <
            Future<
              void
            >
          >[];

      for (
        var index = start;
        index <
            end;
        index++
      ) {
        futures.add(
          _readObjectFileIntoIndex(
            file: files[index],
            index: index,
            destination: objects,
          ),
        );
      }

      await Future.wait(
        futures,
      );
    }

    readWatch.stop();

    // ==========================================================
    // FINAL LIST
    // ==========================================================

    final result =
        <
          BrainVaultObject
        >[];

    for (final object in objects) {
      if (object ==
          null) {
        throw StateError(
          'Um objeto do Vault não foi carregado corretamente.',
        );
      }

      result.add(
        object,
      );
    }

    totalWatch.stop();

    // ==========================================================
    // PERF
    // ==========================================================

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainVaultStorage arquivos=${files.length}',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainVaultStorage list = '
      '${listWatch.elapsedMilliseconds} ms',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainVaultStorage batch read = '
      '${readWatch.elapsedMilliseconds} ms '
      '(concorrencia=$_readConcurrency)',
    );

    // ignore: avoid_print
    print(
      '[BRAIN PERF] '
      'BrainVaultStorage loadAllObjects TOTAL = '
      '${totalWatch.elapsedMilliseconds} ms',
    );

    return List<
      BrainVaultObject
    >.unmodifiable(
      result,
    );
  }

  // ============================================================
  // READ ONE FILE INTO POSITION
  // ============================================================
  //
  // Mantém cada resultado na posição original da lista ordenada.
  //
  // Assim Future.wait não altera a ordem lógica do Vault.
  //
  // ============================================================

  Future<
    void
  >
  _readObjectFileIntoIndex({
    required File file,
    required int index,
    required List<
      BrainVaultObject?
    >
    destination,
  }) async {
    final content = await file.readAsString();

    final object = _serializer.deserializeObject(
      content,
    );

    final expectedFileName =
        '${object.header.objectId}'
        '$objectExtension';

    if (p.basename(
          file.path,
        ) !=
        expectedFileName) {
      throw FormatException(
        'Arquivo do Vault não corresponde '
        'ao objectId interno. '
        'Arquivo=${p.basename(file.path)} '
        'objectId=${object.header.objectId}',
      );
    }

    destination[index] = object;
  }

  // ============================================================
  // COMPACTION LEDGER
  // ============================================================
  //
  // Contém somente metadata técnica mínima de exclusão.
  // Nunca contém plaintext lógico nem ciphertext da nota.
  //
  // ============================================================

  Future<BrainVaultCompactionLedger> loadCompactionLedger({
    required String vaultId,
  }) async {
    await initialize();

    final file = compactionLedgerFile;
    if (!await file.exists()) {
      return BrainVaultCompactionLedger.empty(vaultId: vaultId);
    }

    final ledger = BrainVaultCompactionLedger.fromJsonString(
      await file.readAsString(),
    );

    if (ledger.vaultId != vaultId) {
      throw StateError('Compaction ledger pertence a outro Vault.');
    }

    return ledger;
  }

  Future<void> saveCompactionLedger(
    BrainVaultCompactionLedger ledger,
  ) async {
    await initialize();
    ledger.validate();
    await _atomicWriteString(
      file: compactionLedgerFile,
      content: ledger.toJsonString(),
    );
  }

  // ============================================================
  // PHYSICAL DELETE
  // ============================================================
  //
  // NÃO é exclusão normal.
  //
  // Exclusão normal deve produzir tombstone.
  //
  // ============================================================

  Future<bool> purgeObjectPermanently({
    required String objectId,
    required int expectedObjectVersion,
    required DateTime expectedDeletedAt,
  }) async {
    await initialize();

    final current = await loadObject(objectId);
    if (current == null) {
      return false;
    }

    final tombstone = current.tombstone;
    if (!current.isDeleted || tombstone == null) {
      return false;
    }

    if (current.header.objectVersion.value != expectedObjectVersion ||
        tombstone.deletedAt.toUtc() != expectedDeletedAt.toUtc()) {
      return false;
    }

    final file = objectFile(objectId);
    if (!await file.exists()) {
      return false;
    }

    await file.delete();
    return true;
  }

  /// Phase 3: remove um objeto local coberto por um deletion floor remoto.
  ///
  /// O deletion floor remoto é autoritativo porque o Brain atual não possui
  /// undelete. A precondição de versão observada protege contra TOCTOU: se o
  /// arquivo mudou entre leitura e purge, nada é removido.
  Future<bool> purgeObjectCoveredByDeletionFloor({
    required String objectId,
    required int expectedCurrentObjectVersion,
  }) async {
    await initialize();

    if (expectedCurrentObjectVersion <= 0) {
      throw ArgumentError.value(
        expectedCurrentObjectVersion,
        'expectedCurrentObjectVersion',
        'A versão deve ser maior que zero.',
      );
    }

    final current = await loadObject(objectId);
    if (current == null) {
      return false;
    }

    if (current.header.objectVersion.value != expectedCurrentObjectVersion) {
      return false;
    }

    final file = objectFile(objectId);
    if (!await file.exists()) {
      return false;
    }

    await file.delete();
    return true;
  }

  @Deprecated('Use purgeObjectPermanently com precondições explícitas.')
  Future<void> deleteObjectFile(String objectId) async {
    throw UnsupportedError(
      'deleteObjectFile não pode ser usado para exclusão normal. '
      'Use purgeObjectPermanently pela compaction.',
    );
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  countObjects() async {
    final objects = await loadAllObjects();

    return objects.length;
  }

  // ============================================================
  // DEBUG PATH
  // ============================================================

  Future<
    String
  >
  getVaultDirectoryPath() async {
    await initialize();

    return vaultDirectory.path;
  }

  // ============================================================
  // ATOMIC WRITE
  // ============================================================

  Future<
    void
  >
  _atomicWriteString({
    required File file,
    required String content,
  }) async {
    await file.parent.create(
      recursive: true,
    );

    final temp = File(
      '${file.path}.tmp',
    );

    if (await temp.exists()) {
      await temp.delete();
    }

    final sink = temp.openWrite(
      mode: FileMode.writeOnly,
    );

    try {
      sink.write(
        content,
      );

      await sink.flush();
    } finally {
      await sink.close();
    }

    try {
      await temp.rename(
        file.path,
      );
    } on FileSystemException {
      if (await file.exists()) {
        await file.delete();
      }

      await temp.rename(
        file.path,
      );
    }
  }

  // ============================================================
  // VALIDATE OBJECT ID
  // ============================================================

  void _assertValidObjectId(
    String objectId,
  ) {
    if (!_idService.isValidObjectId(
      objectId,
    )) {
      throw ArgumentError(
        'objectId inválido para o Vault.',
      );
    }
  }
}
