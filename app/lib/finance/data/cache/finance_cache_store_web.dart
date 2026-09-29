import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

  static const String _prefix = 'evrylux.web.finance.cache.v1';

  String _historyKey(String userId) => '$_prefix.history.$userId';
  String _objectiveKey(String userId) => '$_prefix.objective.$userId';
  static const String _pricesKey = '$_prefix.prices.brl';
  static const String _pricesUpdatedAtKey = '$_prefix.prices.brl.updated_at';

  Future<void> saveHistory(
    String userId,
    List<Map<String, dynamic>> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey(userId), jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> loadHistory(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey(userId));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey(userId));
  }

  Future<void> saveObjective(String userId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_objectiveKey(userId), jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadObjective(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_objectiveKey(userId));
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_objectiveKey(userId));
  }

  Future<void> savePrices(
    Map<String, double> prices, {
    DateTime? updatedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = (updatedAt ?? DateTime.now()).toUtc();

    await prefs.setString(_pricesKey, jsonEncode(prices));

    await prefs.setString(_pricesUpdatedAtKey, timestamp.toIso8601String());
  }

  Future<FinancePriceCacheSnapshot> loadPriceSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pricesKey);
    final rawUpdatedAt = prefs.getString(_pricesUpdatedAtKey);

    DateTime? updatedAt;

    if (rawUpdatedAt != null && rawUpdatedAt.trim().isNotEmpty) {
      updatedAt = DateTime.tryParse(rawUpdatedAt)?.toUtc();
    }

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
