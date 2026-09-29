import 'dart:convert';

import '../../../core/database/app_database.dart';

class FinanceCacheStore {
  const FinanceCacheStore();

  static const String _historyTable = 'local_finance_history_cache';
  static const String _objectiveTable = 'local_finance_objective_cache';
  static const String _priceTable = 'local_finance_price_cache';

  Future<void> _ensureInitialized() async {
    await AppDatabase.instance.initialize();

    final db = AppDatabase.instance.db;

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS $_historyTable (
        user_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''',
    );

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS $_objectiveTable (
        user_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''',
    );

    db.execute(
      '''
      CREATE TABLE IF NOT EXISTS $_priceTable (
        cache_key TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''',
    );
  }

  Future<void> saveHistory(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      '''
      INSERT INTO $_historyTable (
        user_id,
        payload,
        updated_at
      )
      VALUES (?, ?, ?)
      ON CONFLICT(user_id)
      DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        userId,
        jsonEncode(items),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> loadHistory(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = AppDatabase.instance.db.select(
      '''
      SELECT payload
      FROM $_historyTable
      WHERE user_id = ?
      LIMIT 1
      ''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    final raw = rows.first['payload']?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> clearHistory(
    String userId,
  ) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      'DELETE FROM $_historyTable WHERE user_id = ?',
      <Object?>[userId],
    );
  }

  Future<void> saveObjective(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      '''
      INSERT INTO $_objectiveTable (
        user_id,
        payload,
        updated_at
      )
      VALUES (?, ?, ?)
      ON CONFLICT(user_id)
      DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        userId,
        jsonEncode(data),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<Map<String, dynamic>?> loadObjective(
    String userId,
  ) async {
    await _ensureInitialized();

    final rows = AppDatabase.instance.db.select(
      '''
      SELECT payload
      FROM $_objectiveTable
      WHERE user_id = ?
      LIMIT 1
      ''',
      <Object?>[userId],
    );

    if (rows.isEmpty) {
      return null;
    }

    final raw = rows.first['payload']?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return null;
      }

      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearObjective(
    String userId,
  ) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      'DELETE FROM $_objectiveTable WHERE user_id = ?',
      <Object?>[userId],
    );
  }

  Future<void> savePrices(
    Map<String, double> prices,
  ) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      '''
      INSERT INTO $_priceTable (
        cache_key,
        payload,
        updated_at
      )
      VALUES ('brl', ?, ?)
      ON CONFLICT(cache_key)
      DO UPDATE SET
        payload = excluded.payload,
        updated_at = excluded.updated_at
      ''',
      <Object?>[
        jsonEncode(prices),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  Future<Map<String, double>> loadPrices() async {
    await _ensureInitialized();

    final rows = AppDatabase.instance.db.select(
      '''
      SELECT payload
      FROM $_priceTable
      WHERE cache_key = 'brl'
      LIMIT 1
      ''',
    );

    if (rows.isEmpty) {
      return const <String, double>{};
    }

    final raw = rows.first['payload']?.toString();

    if (raw == null || raw.trim().isEmpty) {
      return const <String, double>{};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return const <String, double>{};
      }

      final result = <String, double>{};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is num) {
          result[entry.key.toString()] = value.toDouble();
        }
      }

      return result;
    } catch (_) {
      return const <String, double>{};
    }
  }
}
