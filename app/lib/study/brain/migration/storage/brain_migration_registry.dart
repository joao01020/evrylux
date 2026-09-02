import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/brain_migration_record.dart';
import '../services/brain_object_link_service.dart';

// ============================================================
// BRAIN MIGRATION REGISTRY
// ============================================================
//
// Implementação persistente de:
//
// BrainMigrationLinkStore
//
// Salva:
//
// legacyFingerprint
// entityType
// objectId
// status
// datas
// tentativas
//
// IMPORTANTE:
//
// NÃO salva:
//
// - path legado;
// - título;
// - conteúdo;
// - pergunta;
// - resposta.
//
// O registry contém apenas metadados técnicos necessários
// para tornar a migração idempotente.
//
// ============================================================

class BrainMigrationRegistry
    implements
        BrainMigrationLinkStore {
  BrainMigrationRegistry({
    Future<
      Directory
    >
    Function()?
    documentsDirectoryProvider,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ??
           getApplicationDocumentsDirectory;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _rootDirectoryName = 'evrylux_brain';

  static const String _migrationDirectoryName = 'migration';

  static const String _registryFileName = 'migration_registry.json';

  static const String _tempSuffix = '.tmp';

  static const String _format = 'evrylux-brain-migration-registry';

  static const int _formatVersion = 1;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final Future<
    Directory
  >
  Function()
  _documentsDirectoryProvider;

  // ============================================================
  // STATE
  // ============================================================

  Directory? _cachedRootDirectory;

  File? _cachedRegistryFile;

  bool _initialized = false;

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

    final documentsDirectory = await _documentsDirectoryProvider();

    final rootDirectory = Directory(
      p.join(
        documentsDirectory.path,
        _rootDirectoryName,
        _migrationDirectoryName,
      ),
    );

    if (!await rootDirectory.exists()) {
      await rootDirectory.create(
        recursive: true,
      );
    }

    final registryFile = File(
      p.join(
        rootDirectory.path,
        _registryFileName,
      ),
    );

    _cachedRootDirectory = rootDirectory;

    _cachedRegistryFile = registryFile;

    _initialized = true;
  }

  // ============================================================
  // ROOT DIRECTORY
  // ============================================================

  Future<
    Directory
  >
  getRootDirectory() async {
    await initialize();

    return _cachedRootDirectory!;
  }

  // ============================================================
  // REGISTRY FILE
  // ============================================================

  Future<
    File
  >
  getRegistryFile() async {
    await initialize();

    return _cachedRegistryFile!;
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  exists() async {
    final file = await getRegistryFile();

    return file.exists();
  }

  // ============================================================
  // LOAD ALL
  // ============================================================

  @override
  Future<
    List<
      BrainMigrationRecord
    >
  >
  loadAll() async {
    final file = await getRegistryFile();

    if (!await file.exists()) {
      return <
        BrainMigrationRecord
      >[];
    }

    final raw = await file.readAsString();

    if (raw.trim().isEmpty) {
      return <
        BrainMigrationRecord
      >[];
    }

    final dynamic decoded;

    try {
      decoded = jsonDecode(
        raw,
      );
    } on FormatException catch (
      error
    ) {
      throw FormatException(
        'Registry de migração contém JSON inválido: '
        '${error.message}',
      );
    }

    if (decoded
        is! Map) {
      throw const FormatException(
        'Registry de migração inválido: raiz deve ser um objeto JSON.',
      );
    }

    final root =
        Map<
          String,
          dynamic
        >.from(
          decoded,
        );

    _validateRoot(
      root,
    );

    final rawRecords = root['records'];

    if (rawRecords
        is! List) {
      throw const FormatException(
        'Registry de migração inválido: records deve ser uma lista.',
      );
    }

    final records =
        <
          BrainMigrationRecord
        >[];

    final fingerprints =
        <
          String
        >{};

    for (final item in rawRecords) {
      if (item
          is! Map) {
        throw const FormatException(
          'Registry de migração contém registro inválido.',
        );
      }

      final record = BrainMigrationRecord.fromJson(
        Map<
          String,
          dynamic
        >.from(
          item,
        ),
      );

      if (!fingerprints.add(
        record.legacyFingerprint,
      )) {
        throw FormatException(
          'Registry contém fingerprint duplicado: '
          '${record.legacyFingerprint}',
        );
      }

      records.add(
        record,
      );
    }

    return List<
      BrainMigrationRecord
    >.unmodifiable(
      records,
    );
  }

  // ============================================================
  // SAVE ALL
  // ============================================================

  @override
  Future<
    void
  >
  saveAll(
    List<
      BrainMigrationRecord
    >
    records,
  ) async {
    final file = await getRegistryFile();

    final validatedRecords = _validateRecords(
      records,
    );

    final document =
        <
          String,
          dynamic
        >{
          'format': _format,

          'format_version': _formatVersion,

          'updated_at': DateTime.now().toUtc().toIso8601String(),

          'records': validatedRecords
              .map(
                (
                  record,
                ) => record.toJson(),
              )
              .toList(
                growable: false,
              ),
        };

    final encoded =
        const JsonEncoder.withIndent(
          '  ',
        ).convert(
          document,
        );

    await _atomicWrite(
      file: file,
      content: encoded,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    final file = await getRegistryFile();

    if (await file.exists()) {
      await file.delete();
    }

    final tempFile = File(
      '${file.path}$_tempSuffix',
    );

    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    final records = await loadAll();

    return records.length;
  }

  // ============================================================
  // FIND BY FINGERPRINT
  // ============================================================

  Future<
    BrainMigrationRecord?
  >
  findByFingerprint(
    String legacyFingerprint,
  ) async {
    final normalized = legacyFingerprint.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'legacyFingerprint não pode estar vazio.',
      );
    }

    final records = await loadAll();

    for (final record in records) {
      if (record.legacyFingerprint ==
          normalized) {
        return record;
      }
    }

    return null;
  }

  // ============================================================
  // CONTAINS
  // ============================================================

  Future<
    bool
  >
  contains(
    String legacyFingerprint,
  ) async {
    return await findByFingerprint(
          legacyFingerprint,
        ) !=
        null;
  }

  // ============================================================
  // VALIDATE ROOT
  // ============================================================

  void _validateRoot(
    Map<
      String,
      dynamic
    >
    root,
  ) {
    final format = root['format']?.toString().trim();

    if (format !=
        _format) {
      throw FormatException(
        'Formato de registry não suportado: $format',
      );
    }

    final rawVersion = root['format_version'];

    final int? version;

    if (rawVersion
        is int) {
      version = rawVersion;
    } else {
      version = int.tryParse(
        rawVersion?.toString().trim() ??
            '',
      );
    }

    if (version ==
        null) {
      throw const FormatException(
        'format_version inválido no registry.',
      );
    }

    if (version !=
        _formatVersion) {
      throw FormatException(
        'Versão de registry não suportada: $version',
      );
    }
  }

  // ============================================================
  // VALIDATE RECORDS
  // ============================================================

  List<
    BrainMigrationRecord
  >
  _validateRecords(
    List<
      BrainMigrationRecord
    >
    records,
  ) {
    final fingerprints =
        <
          String
        >{};

    final validated =
        <
          BrainMigrationRecord
        >[];

    for (final record in records) {
      record.validate();

      if (!fingerprints.add(
        record.legacyFingerprint,
      )) {
        throw FormatException(
          'Não é possível salvar fingerprints duplicados: '
          '${record.legacyFingerprint}',
        );
      }

      validated.add(
        record,
      );
    }

    validated.sort(
      (
        a,
        b,
      ) {
        final fingerprintCompare = a.legacyFingerprint.compareTo(
          b.legacyFingerprint,
        );

        if (fingerprintCompare !=
            0) {
          return fingerprintCompare;
        }

        return a.entityType.compareTo(
          b.entityType,
        );
      },
    );

    return validated;
  }

  // ============================================================
  // ATOMIC WRITE
  // ============================================================

  Future<
    void
  >
  _atomicWrite({
    required File file,
    required String content,
  }) async {
    final parent = file.parent;

    if (!await parent.exists()) {
      await parent.create(
        recursive: true,
      );
    }

    final tempFile = File(
      '${file.path}$_tempSuffix',
    );

    // ==========================================================
    // LIMPEZA DE TEMP ANTIGO
    // ==========================================================

    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    RandomAccessFile? handle;

    try {
      handle = await tempFile.open(
        mode: FileMode.write,
      );

      await handle.writeString(
        content,
      );

      await handle.flush();

      await handle.close();

      handle = null;

      // ========================================================
      // RENAME ATÔMICO
      // ========================================================

      try {
        await tempFile.rename(
          file.path,
        );
      } on FileSystemException {
        // ======================================================
        // FALLBACK
        // ======================================================
        //
        // Alguns ambientes não permitem substituir diretamente
        // um arquivo existente via rename.
        //
        // ======================================================

        if (await file.exists()) {
          await file.delete();
        }

        await tempFile.rename(
          file.path,
        );
      }
    } catch (
      _
    ) {
      try {
        await handle?.close();
      } catch (
        _
      ) {
        // Ignore cleanup failure.
      }

      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (
          _
        ) {
          // Ignore cleanup failure.
        }
      }

      rethrow;
    }
  }
}
