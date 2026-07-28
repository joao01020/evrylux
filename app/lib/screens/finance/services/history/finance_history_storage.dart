import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../models/finance/investment_history.dart';

class FinanceHistoryStorage {
  static const String _storageKey = 'finance_investment_history';

  const FinanceHistoryStorage();

  // =========================================================
  // SALVAR HISTÓRICO
  // =========================================================

  Future<void> save(List<InvestmentHistory> history) async {
    final preferences = await SharedPreferences.getInstance();

    final jsonHistory = history.map((item) {
      return item.toJson();
    }).toList();

    final encodedHistory = jsonEncode(jsonHistory);

    final saved = await preferences.setString(_storageKey, encodedHistory);

    if (!saved) {
      throw Exception('Não foi possível salvar o histórico financeiro.');
    }
  }

  // =========================================================
  // CARREGAR HISTÓRICO
  // =========================================================

  Future<List<InvestmentHistory>> load() async {
    final preferences = await SharedPreferences.getInstance();

    final encodedHistory = preferences.getString(_storageKey);

    if (encodedHistory == null || encodedHistory.trim().isEmpty) {
      return [];
    }

    try {
      final decodedHistory = jsonDecode(encodedHistory);

      if (decodedHistory is! List) {
        return [];
      }

      final history = <InvestmentHistory>[];

      for (final item in decodedHistory) {
        if (item is! Map) {
          continue;
        }

        final json = Map<String, dynamic>.from(item);

        history.add(InvestmentHistory.fromJson(json));
      }

      _sortByDate(history);

      return history;
    } on FormatException {
      return [];
    } catch (_) {
      return [];
    }
  }

  // =========================================================
  // ADICIONAR APORTE
  // =========================================================

  Future<List<InvestmentHistory>> add(InvestmentHistory contribution) async {
    final history = await load();

    history.add(contribution);

    _sortByDate(history);

    await save(history);

    return history;
  }

  // =========================================================
  // REMOVER APORTE
  // =========================================================

  Future<List<InvestmentHistory>> remove(InvestmentHistory contribution) async {
    final history = await load();

    history.remove(contribution);

    await save(history);

    return history;
  }

  // =========================================================
  // ÚLTIMO APORTE
  // =========================================================

  Future<InvestmentHistory?> loadLatest() async {
    final history = await load();

    if (history.isEmpty) {
      return null;
    }

    return history.last;
  }

  // =========================================================
  // SUBSTITUIR HISTÓRICO
  // =========================================================

  Future<List<InvestmentHistory>> replace(
    List<InvestmentHistory> history,
  ) async {
    final updatedHistory = List<InvestmentHistory>.from(history);

    _sortByDate(updatedHistory);

    await save(updatedHistory);

    return updatedHistory;
  }

  // =========================================================
  // LIMPAR HISTÓRICO
  // =========================================================

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();

    final removed = await preferences.remove(_storageKey);

    if (!removed) {
      final stillExists = preferences.containsKey(_storageKey);

      if (stillExists) {
        throw Exception('Não foi possível limpar o histórico financeiro.');
      }
    }
  }

  // =========================================================
  // VERIFICAÇÕES
  // =========================================================

  Future<bool> hasHistory() async {
    final history = await load();

    return history.isNotEmpty;
  }

  Future<int> count() async {
    final history = await load();

    return history.length;
  }

  // =========================================================
  // ORDENAÇÃO
  // =========================================================

  void _sortByDate(List<InvestmentHistory> history) {
    history.sort((first, second) {
      return first.date.compareTo(second.date);
    });
  }
}
