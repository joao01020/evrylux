import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
// ============================================================

class BrainVaultStorage {
  BrainVaultStorage({
    BrainVaultSerializer? serializer,
    BrainVaultIdService? idService,
    Future<
      Directory
    >
    Function()?
    documentsDirectoryProvider,
  }) : _serializer =
           serializer ??
           const BrainVaultSerializer(),
       _idService =
           idService ??
           BrainVaultIdService(),
       _documentsDirectoryProvider =
           documentsDirectoryProvider ??
           getApplicationDocumentsDirectory;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainVaultSerializer _serializer;

  final BrainVaultIdService _idService;

  final Future<
    Directory
  >
  Function()
  _documentsDirectoryProvider;

  // ============================================================
  // PATH CONSTANTS
  // ============================================================

  static const String rootDirectoryName = 'evrylux_brain';

  static const String vaultDirectoryName = 'vault';

  static const String objectsDirectoryName = 'objects';

  static const String manifestFileName = 'manifest.json';

  static const String objectExtension = '.evobj';

  // ============================================================
  // INITIALIZED
  // ============================================================

  bool _initialized = false;

  Directory? _vaultDirectory;

  Directory? _objectsDirectory;

  // ============================================================
  // GETTERS
  // ============================================================

  Directory get vaultDirectory {
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
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    if (_initialized) {
      return;
    }

    final documents = await _documentsDirectoryProvider();

    final root = Directory(
      p.join(
        documents.path,
        rootDirectoryName,
      ),
    );

    final vault = Directory(
      p.join(
        root.path,
        vaultDirectoryName,
      ),
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

    _vaultDirectory = vault;

    _objectsDirectory = objects;

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
