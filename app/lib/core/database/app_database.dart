import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseFileName = 'ghost_core.db';
  static const int _schemaVersion = 1;

  Database? _database;

  bool get isOpen =>
      _database !=
      null;

  Database get db {
    final database = _database;

    if (database ==
        null) {
      throw StateError(
        'AppDatabase ainda não foi inicializado. '
        'Chame AppDatabase.instance.initialize() primeiro.',
      );
    }

    return database;
  }

  Future<
    void
  >
  initialize() async {
    if (_database !=
        null) {
      return;
    }

    final directory = await getApplicationSupportDirectory();

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    final databasePath = p.join(
      directory.path,
      _databaseFileName,
    );

    final database = sqlite3.open(
      databasePath,
    );

    _database = database;

    database.execute(
      'PRAGMA foreign_keys = ON;',
    );

    database.execute(
      'PRAGMA journal_mode = WAL;',
    );

    database.execute(
      'PRAGMA synchronous = NORMAL;',
    );

    _migrate(
      database,
    );
  }

  void _migrate(
    Database database,
  ) {
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS app_metadata (
        key TEXT PRIMARY KEY NOT NULL,
        value TEXT NOT NULL
      );
      ''',
    );

    var currentVersion = _readSchemaVersion(
      database,
    );

    if (currentVersion <
        1) {
      _createVersion1(
        database,
      );

      _writeSchemaVersion(
        database,
        1,
      );

      currentVersion = 1;
    }

    if (currentVersion !=
        _schemaVersion) {
      throw StateError(
        'Versão do banco local inesperada: '
        '$currentVersion. Esperado: $_schemaVersion.',
      );
    }
  }

  int _readSchemaVersion(
    Database database,
  ) {
    final result = database.select(
      '''
      SELECT value
      FROM app_metadata
      WHERE key = ?
      LIMIT 1
      ''',
      [
        'schema_version',
      ],
    );

    if (result.isEmpty) {
      return 0;
    }

    return int.tryParse(
          result.first['value'].toString(),
        ) ??
        0;
  }

  void _writeSchemaVersion(
    Database database,
    int version,
  ) {
    database.execute(
      '''
      INSERT INTO app_metadata (
        key,
        value
      )
      VALUES (?, ?)
      ON CONFLICT(key)
      DO UPDATE SET
        value = excluded.value
      ''',
      [
        'schema_version',
        version.toString(),
      ],
    );
  }

  void _createVersion1(
    Database database,
  ) {
    database.execute(
      '''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_attempt_at TEXT
      );
      ''',
    );

    database.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_sync_queue_next_attempt
      ON sync_queue (
        next_attempt_at
      );
      ''',
    );

    database.execute(
      '''
      CREATE INDEX IF NOT EXISTS
      idx_sync_queue_entity
      ON sync_queue (
        entity_type,
        entity_id
      );
      ''',
    );
  }

  T transaction<
    T
  >(
    T Function() action,
  ) {
    db.execute(
      'BEGIN IMMEDIATE TRANSACTION;',
    );

    try {
      final result = action();

      db.execute(
        'COMMIT;',
      );

      return result;
    } catch (
      _
    ) {
      db.execute(
        'ROLLBACK;',
      );

      rethrow;
    }
  }

  bool healthCheck() {
    try {
      final result = db.select(
        'SELECT 1 AS ok;',
      );

      return result.isNotEmpty &&
          result.first['ok'] ==
              1;
    } catch (
      _
    ) {
      return false;
    }
  }

  Future<
    void
  >
  close() async {
    final database = _database;

    if (database ==
        null) {
      return;
    }

    database.dispose();

    _database = null;
  }
}
