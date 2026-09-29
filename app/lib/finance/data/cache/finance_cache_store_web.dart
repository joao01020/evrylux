import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FinanceCacheStore {
  const FinanceCacheStore();

  static const String _prefix = 'evrylux.web.finance.cache.v1';

  String _historyKey(String userId) => '$_prefix.history.$userId';
  String _objectiveKey(String userId) => '$_prefix.objective.$userId';
  static const String _pricesKey = '$_prefix.prices.brl';

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

  Future<void> saveObjective(
    String userId,
    Map<String, dynamic> data,
  ) async {
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

  Future<void> savePrices(Map<String, double> prices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pricesKey, jsonEncode(prices));
  }

  Future<Map<String, double>> loadPrices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pricesKey);
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
