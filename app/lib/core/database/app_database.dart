import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/training_activity_plan_table.dart';

// ============================================================
// APP DATABASE
// ============================================================
//
// Banco SQLite principal do app.
//
// Versões:
//
// v1
// - app_metadata
// - sync_queue
//
// v2
// - training_activity_plans
//
// ============================================================

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseFileName = 'ghost_core.db';

  static const int _schemaVersion = 2;

  Database? _database;

  // ============================================================
  // STATE
  // ============================================================

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

  // ============================================================
  // INITIALIZE
  // ============================================================

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

  // ============================================================
  // MIGRATIONS
  // ============================================================

  void _migrate(
    Database database,
  ) {
    _createMetadataTable(
      database,
    );

    var currentVersion = _readSchemaVersion(
      database,
    );

    // ==========================================================
    // VERSION 1
    // ==========================================================

    if (currentVersion <
        1) {
      transactionWithDatabase(
        database,
        () {
          _createVersion1(
            database,
          );

          _writeSchemaVersion(
            database,
            1,
          );
        },
      );

      currentVersion = 1;
    }

    // ==========================================================
    // VERSION 2
    // ==========================================================

    if (currentVersion <
        2) {
      transactionWithDatabase(
        database,
        () {
          _createVersion2(
            database,
          );

          _writeSchemaVersion(
            database,
            2,
          );
        },
      );

      currentVersion = 2;
    }

    // ==========================================================
    // FINAL VERSION CHECK
    // ==========================================================

    if (currentVersion !=
        _schemaVersion) {
      throw StateError(
        'Versão do banco local inesperada: '
        '$currentVersion. Esperado: $_schemaVersion.',
      );
    }
  }

  // ============================================================
  // METADATA TABLE
  // ============================================================

  void _createMetadataTable(
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
  }

  // ============================================================
  // READ SCHEMA VERSION
  // ============================================================

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
      <
        Object?
      >[
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

  // ============================================================
  // WRITE SCHEMA VERSION
  // ============================================================

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
      <
        Object?
      >[
        'schema_version',
        version.toString(),
      ],
    );
  }

  // ============================================================
  // VERSION 1
  // ============================================================

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

  // ============================================================
  // VERSION 2
  // ============================================================
  //
  // Adiciona a tabela local do planejamento de atividades.
  //
  // ============================================================

  void _createVersion2(
    Database database,
  ) {
    for (final statement in TrainingActivityPlanTable.createStatements) {
      database.execute(
        statement,
      );
    }
  }

  // ============================================================
  // TRANSACTION
  // ============================================================

  T transaction<
    T
  >(
    T Function() action,
  ) {
    return transactionWithDatabase(
      db,
      action,
    );
  }

  // ============================================================
  // INTERNAL TRANSACTION
  // ============================================================

  T transactionWithDatabase<
    T
  >(
    Database database,
    T Function() action,
  ) {
    database.execute(
      'BEGIN IMMEDIATE TRANSACTION;',
    );

    try {
      final result = action();

      database.execute(
        'COMMIT;',
      );

      return result;
    } catch (
      _
    ) {
      try {
        database.execute(
          'ROLLBACK;',
        );
      } catch (
        _
      ) {
        // Evita esconder o erro original.
      }

      rethrow;
    }
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

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

  // ============================================================
  // DATABASE PATH
  // ============================================================

  Future<
    String
  >
  getDatabasePath() async {
    final directory = await getApplicationSupportDirectory();

    return p.join(
      directory.path,
      _databaseFileName,
    );
  }

  // ============================================================
  // FILE EXISTS
  // ============================================================

  Future<
    bool
  >
  databaseFileExists() async {
    final path = await getDatabasePath();

    return File(
      path,
    ).exists();
  }

  // ============================================================
  // CLOSE
  // ============================================================

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
