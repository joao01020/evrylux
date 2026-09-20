import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../../core/storage/user_storage_scope.dart';
import '../models/brain_vault_manifest.dart';
import '../models/brain_vault_object.dart';
import '../services/brain_vault_id_service.dart';
import '../services/brain_vault_serializer.dart';

// ============================================================
// BRAIN VAULT STORAGE
// ============================================================
//
// Responsável SOMENTE pela persistência física do Vault.
//
// Não criptografa.
//
// Não descriptografa.
//
// Não conhece BrainFile.
//
// Não conhece Review.
//
// Ele apenas lê/escreve:
//
// manifest.json
// *.evobj
//
// IMPORTANTE SOBRE SEGURANÇA:
//
// - BrainVaultStorage NÃO recebe plaintext para criptografar;
// - BrainVaultService entrega BrainVaultObject já criptografado;
// - os arquivos .evobj persistem ciphertext/nonce/tag/metadata;
// - a Master Key continua fora desta pasta, no Keychain/Keyring.
//
// IMPORTANTE:
//
// O armazenamento físico é obrigatoriamente isolado pela conta
// atual através de UserStorageScope.
//
// Estrutura padrão:
//
// Documents/
//   evrylux/
//     users/
//       <user_id>/
//         brain/
//           vault/
//             manifest.json
//             objects/
//               *.evobj
//
// Quando o usuário escolhe outro local para o Brain:
//
// <brain-root-escolhido>/
//   vault/
//     manifest.json
//     objects/
//       *.evobj
//
// Portanto:
//
// Conta A -> Vault A
// Conta B -> Vault B
//
// Uma conta nunca deve compartilhar o diretório físico do Vault
// com outra conta.
//
// ============================================================

class BrainVaultStorage {
  BrainVaultStorage({
    required UserStorageScope storageScope,
    BrainVaultSerializer? serializer,
    BrainVaultIdService? idService,

    // ========================================================
    // CUSTOM BRAIN ROOT PROVIDER
    // ========================================================
    //
    // Retorna o ROOT FINAL do Brain escolhido pelo usuário.
    //
    // Exemplo:
    //
    // Linux:
    // /home/joao/Documentos/EVRYLUX/Brain
    //
    // macOS:
    // /Users/brenda/Documents/EVRYLUX/Brain
    //
    // Quando houver um caminho configurado, o Vault será:
    //
    // <brain-root>/vault
    //
    // Se não houver caminho personalizado, mantemos o diretório
    // isolado por conta fornecido pelo UserStorageScope.
    //
    // ========================================================
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

  static const String objectExtension = '.evobj';

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

  // ============================================================
  // RESOLVE VAULT DIRECTORY
  // ============================================================
  //
  // Regra:
  //
  // 1. se o usuário escolheu um Brain root personalizado:
  //      <brain-root>/vault
  //
  // 2. caso contrário:
  //      UserStorageScope.vaultDirectory
  //
  // O caminho personalizado representa o ROOT FINAL do Brain.
  // Portanto NÃO adicionamos EVRYLUX/Brain novamente.
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
  //
  // A inicialização é sensível a:
  //
  // - usuário atual;
  // - caminho físico atual do Brain.
  //
  // Isso é importante porque o usuário pode alterar a pasta local
  // nas Configurações sem trocar de conta.
  //
  // Se o root mudar, o cache anterior é invalidado e o Vault passa
  // a apontar imediatamente para a nova localização.
  //
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

    // Invalidate cached paths before resolving a different account/path.
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

  Future<
    List<
      BrainVaultObject
    >
  >
  loadAllObjects() async {
    await initialize();

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

    final objects =
        <
          BrainVaultObject
        >[];

    for (final file in files) {
      final content = await file.readAsString();

      final object = _serializer.deserializeObject(
        content,
      );

      final expectedFileName = '${object.header.objectId}$objectExtension';

      if (p.basename(
            file.path,
          ) !=
          expectedFileName) {
        throw FormatException(
          'Arquivo do Vault não corresponde ao objectId interno.',
        );
      }

      objects.add(
        object,
      );
    }

    return List<
      BrainVaultObject
    >.unmodifiable(
      objects,
    );
  }

  // ============================================================
  // PHYSICAL DELETE
  // ============================================================
  //
  // NÃO é a exclusão normal do Cérebro.
  //
  // Exclusão normal deve produzir tombstone.
  //
  // Este método existe para:
  //
  // - rollback;
  // - testes;
  // - limpeza controlada;
  // - manutenção futura.
  //
  // ============================================================

  Future<
    void
  >
  deleteObjectFile(
    String objectId,
  ) async {
    await initialize();

    final file = objectFile(
      objectId,
    );

    if (await file.exists()) {
      await file.delete();
    }
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
  //
  // Útil durante os testes Conta A / Conta B.
  //
  // Nunca imprime:
  //
  // - Master Key;
  // - conteúdo;
  // - objetos;
  //
  // Apenas o caminho físico usado pelo Vault.
  //
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
