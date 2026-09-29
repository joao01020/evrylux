import 'dart:convert';

import '../../../core/database/app_database.dart';

class FinancePriceCacheSnapshot {
  const FinancePriceCacheSnapshot({
    required this.prices,
    required this.updatedAt,
  });

  final Map<String, double> prices;
  final DateTime? updatedAt;

  Duration? age({DateTime? now}) {
    final timestamp = updatedAt;

    if (timestamp == null) {
      return null;
    }

    final reference = (now ?? DateTime.now()).toUtc();
    final normalized = timestamp.toUtc();

    if (normalized.isAfter(reference)) {
      return Duration.zero;
    }

    return reference.difference(normalized);
  }
}

class FinanceCacheStore {
  const FinanceCacheStore();

  static const String _historyTable = 'local_finance_history_cache';
  static const String _objectiveTable = 'local_finance_objective_cache';
  static const String _priceTable = 'local_finance_price_cache';

  Future<void> _ensureInitialized() async {
    await AppDatabase.instance.initialize();

    final db = AppDatabase.instance.db;

    db.execute('''
      CREATE TABLE IF NOT EXISTS $_historyTable (
        user_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS $_objectiveTable (
        user_id TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''');

    db.execute('''
      CREATE TABLE IF NOT EXISTS $_priceTable (
        cache_key TEXT PRIMARY KEY NOT NULL,
        payload TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );
      ''');
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

  Future<List<Map<String, dynamic>>> loadHistory(String userId) async {
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
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> clearHistory(String userId) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      'DELETE FROM $_historyTable WHERE user_id = ?',
      <Object?>[userId],
    );
  }

  Future<void> saveObjective(String userId, Map<String, dynamic> data) async {
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

  Future<Map<String, dynamic>?> loadObjective(String userId) async {
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

  Future<void> clearObjective(String userId) async {
    await _ensureInitialized();

    AppDatabase.instance.db.execute(
      'DELETE FROM $_objectiveTable WHERE user_id = ?',
      <Object?>[userId],
    );
  }

  Future<void> savePrices(
    Map<String, double> prices, {
    DateTime? updatedAt,
  }) async {
    await _ensureInitialized();

    final timestamp = (updatedAt ?? DateTime.now()).toUtc();

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
      <Object?>[jsonEncode(prices), timestamp.toIso8601String()],
    );
  }

  Future<FinancePriceCacheSnapshot> loadPriceSnapshot() async {
    await _ensureInitialized();

    final rows = AppDatabase.instance.db.select('''
      SELECT payload, updated_at
      FROM $_priceTable
      WHERE cache_key = 'brl'
      LIMIT 1
      ''');

    if (rows.isEmpty) {
      return const FinancePriceCacheSnapshot(
        prices: <String, double>{},
        updatedAt: null,
      );
    }

    final raw = rows.first['payload']?.toString();
    final rawUpdatedAt = rows.first['updated_at']?.toString();

    final updatedAt = rawUpdatedAt == null
        ? null
        : DateTime.tryParse(rawUpdatedAt)?.toUtc();

    if (raw == null || raw.trim().isEmpty) {
      return FinancePriceCacheSnapshot(
        prices: const <String, double>{},
        updatedAt: updatedAt,
      );
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return FinancePriceCacheSnapshot(
          prices: const <String, double>{},
          updatedAt: updatedAt,
        );
      }

      final result = <String, double>{};

      for (final entry in decoded.entries) {
        final value = entry.value;

        if (value is num) {
          final parsed = value.toDouble();

          if (parsed.isFinite && parsed > 0) {
            result[entry.key.toString()] = parsed;
          }
        }
      }

      return FinancePriceCacheSnapshot(prices: result, updatedAt: updatedAt);
    } catch (_) {
      return FinancePriceCacheSnapshot(
        prices: const <String, double>{},
        updatedAt: updatedAt,
      );
    }
  }

  Future<Map<String, double>> loadPrices() async {
    final snapshot = await loadPriceSnapshot();
    return snapshot.prices;
  }
}
