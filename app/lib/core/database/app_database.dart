import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/app_update_cache_table.dart';
import 'tables/board_attachment_table.dart';
import 'tables/board_comment_table.dart';
import 'tables/profile_cache_table.dart';
import 'tables/sync_queue_table.dart';
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
// v3
// - local_board_attachments
//
// v4
// - deduplicação da sync_queue
// - UNIQUE(entity_type, entity_id)
//
// v5
// - local_board_comments
// - local_board_comment_scopes
//
// v6
// - app_update_cache
//
// v7
// - profile_cache
//
// ============================================================

class AppDatabase {
  AppDatabase._();

  // ============================================================
  // SINGLETON
  // ============================================================

  static final AppDatabase instance = AppDatabase._();

  // ============================================================
  // CONFIG
  // ============================================================

  static const String _databaseFileName = 'ghost_core.db';

  static const int _schemaVersion = 7;

  // ============================================================
  // DATABASE
  // ============================================================

  Database? _database;

  // ============================================================
  // STATE
  // ============================================================

  bool get isOpen {
    return _database !=
        null;
  }

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

    try {
      // ========================================================
      // PRAGMAS
      // ========================================================

      database.execute(
        'PRAGMA foreign_keys = ON;',
      );

      database.execute(
        'PRAGMA journal_mode = WAL;',
      );

      database.execute(
        'PRAGMA synchronous = NORMAL;',
      );

      // ========================================================
      // MIGRATIONS
      // ========================================================

      _migrate(
        database,
      );

      // ========================================================
      // PUBLICA INSTÂNCIA
      // ========================================================
      //
      // Só disponibilizamos o banco depois que toda a migração
      // terminou corretamente.
      //
      // ========================================================

      _database = database;
    } catch (
      _
    ) {
      database.dispose();

      _database = null;

      rethrow;
    }
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
    // INVALID FUTURE VERSION
    // ==========================================================
    //
    // Evita abrir com uma versão antiga do app um banco criado
    // por uma versão futura.
    //
    // ==========================================================

    if (currentVersion >
        _schemaVersion) {
      throw StateError(
        'Banco local possui versão mais nova que o aplicativo: '
        '$currentVersion. '
        'Versão suportada: $_schemaVersion.',
      );
    }

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
    // VERSION 3
    // ==========================================================

    if (currentVersion <
        3) {
      transactionWithDatabase(
        database,
        () {
          _createVersion3(
            database,
          );

          _writeSchemaVersion(
            database,
            3,
          );
        },
      );

      currentVersion = 3;
    }

    // ==========================================================
    // VERSION 4
    // ==========================================================

    if (currentVersion <
        4) {
      transactionWithDatabase(
        database,
        () {
          _createVersion4(
            database,
          );

          _writeSchemaVersion(
            database,
            4,
          );
        },
      );

      currentVersion = 4;
    }

    // ==========================================================
    // VERSION 5
    // ==========================================================

    if (currentVersion <
        5) {
      transactionWithDatabase(
        database,
        () {
          _createVersion5(
            database,
          );

          _writeSchemaVersion(
            database,
            5,
          );
        },
      );

      currentVersion = 5;
    }

    // ==========================================================
    // VERSION 6
    // ==========================================================

    if (currentVersion <
        6) {
      transactionWithDatabase(
        database,
        () {
          _createVersion6(
            database,
          );

          _writeSchemaVersion(
            database,
            6,
          );
        },
      );

      currentVersion = 6;
    }

    // ==========================================================
    // VERSION 7
    // ==========================================================

    if (currentVersion <
        7) {
      transactionWithDatabase(
        database,
        () {
          _createVersion7(
            database,
          );

          _writeSchemaVersion(
            database,
            7,
          );
        },
      );

      currentVersion = 7;
    }

    // ==========================================================
    // FINAL VERSION CHECK
    // ==========================================================

    if (currentVersion !=
        _schemaVersion) {
      throw StateError(
        'Versão do banco local inesperada: '
        '$currentVersion. '
        'Esperado: $_schemaVersion.',
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
  //
  // Cria a SyncQueue.
  //
  // Para instalações novas usamos diretamente SyncQueueTable,
  // mantendo schema e índices centralizados em um único local.
  //
  // ============================================================

  void _createVersion1(
    Database database,
  ) {
    for (final statement in SyncQueueTable.createStatements) {
      database.execute(
        statement,
      );
    }
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
  // VERSION 3
  // ============================================================
  //
  // Adiciona a tabela local dos documentos/anexos da lousa.
  //
  // A tabela é criada via BoardAttachmentTable para manter:
  //
  // - nomes de colunas centralizados;
  // - índices centralizados;
  // - compatibilidade com BoardAttachmentDao.
  //
  // ============================================================

  void _createVersion3(
    Database database,
  ) {
    for (final statement in BoardAttachmentTable.createStatements) {
      database.execute(
        statement,
      );
    }
  }

  // ============================================================
  // VERSION 4
  // ============================================================
  //
  // OBJETIVO:
  //
  // Garantir no próprio SQLite que exista no máximo uma operação
  // pendente para:
  //
  // entity_type + entity_id
  //
  // A SyncQueue já faz deduplicação em memória/regra de negócio,
  // mas o banco também precisa garantir essa invariável.
  //
  // MIGRAÇÃO SEGURA:
  //
  // 1. encontra registros duplicados;
  // 2. mantém somente a versão mais recentemente alterada;
  // 3. cria índice UNIQUE;
  // 4. cria índice otimizado para ready/retry.
  //
  // ============================================================

  void _createVersion4(
    Database database,
  ) {
    // ==========================================================
    // DEDUPLICATE EXISTING QUEUE
    // ==========================================================
    //
    // Mantemos o registro mais recente segundo:
    //
    // updated_at DESC
    // created_at DESC
    // id DESC
    //
    // O id funciona como desempate determinístico.
    //
    // ==========================================================

    database.execute(
      '''
DELETE FROM ${SyncQueueTable.tableName}
WHERE ${SyncQueueTable.id} IN (
  SELECT duplicate.${SyncQueueTable.id}
  FROM ${SyncQueueTable.tableName} AS duplicate
  WHERE EXISTS (
    SELECT 1
    FROM ${SyncQueueTable.tableName} AS preferred
    WHERE
      preferred.${SyncQueueTable.entityType} =
        duplicate.${SyncQueueTable.entityType}
      AND
      preferred.${SyncQueueTable.entityId} =
        duplicate.${SyncQueueTable.entityId}
      AND (
        preferred.${SyncQueueTable.updatedAt} >
          duplicate.${SyncQueueTable.updatedAt}

        OR (
          preferred.${SyncQueueTable.updatedAt} =
            duplicate.${SyncQueueTable.updatedAt}
          AND
          preferred.${SyncQueueTable.createdAt} >
            duplicate.${SyncQueueTable.createdAt}
        )

        OR (
          preferred.${SyncQueueTable.updatedAt} =
            duplicate.${SyncQueueTable.updatedAt}
          AND
          preferred.${SyncQueueTable.createdAt} =
            duplicate.${SyncQueueTable.createdAt}
          AND
          preferred.${SyncQueueTable.id} >
            duplicate.${SyncQueueTable.id}
        )
      )
  )
);
''',
    );

    // ==========================================================
    // UNIQUE ENTITY INDEX
    // ==========================================================
    //
    // Depois da limpeza, o SQLite passa a impedir duplicidades
    // mesmo em caso de corrida ou código legado.
    //
    // ==========================================================

    database.execute(
      '''
CREATE UNIQUE INDEX IF NOT EXISTS
idx_sync_queue_entity_unique
ON ${SyncQueueTable.tableName} (
  ${SyncQueueTable.entityType},
  ${SyncQueueTable.entityId}
);
''',
    );

    // ==========================================================
    // READY / RETRY INDEX
    // ==========================================================
    //
    // A consulta mais importante do SyncService é:
    //
    // next_attempt_at <= now
    // ORDER BY created_at
    //
    // ==========================================================

    database.execute(
      '''
CREATE INDEX IF NOT EXISTS
idx_sync_queue_ready
ON ${SyncQueueTable.tableName} (
  ${SyncQueueTable.nextAttemptAt},
  ${SyncQueueTable.createdAt}
);
''',
    );
  }

  // ============================================================
  // VERSION 5
  // ============================================================
  //
  // Persistência offline-first dos comentários da lousa.
  //
  // ============================================================

  void _createVersion5(
    Database database,
  ) {
    for (final statement in BoardCommentTable.createStatements) {
      database.execute(
        statement,
      );
    }
  }

  // ============================================================
  // VERSION 6
  // ============================================================
  //
  // Cache local da notificação de atualização do aplicativo.
  //
  // ============================================================

  void _createVersion6(
    Database database,
  ) {
    for (final statement in AppUpdateCacheTable.createStatements) {
      database.execute(
        statement,
      );
    }
  }

  // ============================================================
  // VERSION 7
  // ============================================================
  //
  // Cache local do perfil básico e preferências.
  //
  // ============================================================

  void _createVersion7(
    Database database,
  ) {
    for (final statement in ProfileCacheTable.createStatements) {
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
