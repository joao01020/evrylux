import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/cache/finance_cache_store.dart';
import 'investment_history.dart';

class FinanceHistoryStorage {
  const FinanceHistoryStorage({
    this.cacheStore = const FinanceCacheStore(),
  });

  final FinanceCacheStore cacheStore;

  // ============================================================
  // TABLE
  // ============================================================

  static const String _table = 'finance_contributions';

  // ============================================================
  // CLIENT
  // ============================================================

  SupabaseClient get _client {
    return Supabase.instance.client;
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User _requireUser() {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return user;
  }

  // ============================================================
  // SAVE ALL
  // ============================================================

  Future<
    void
  >
  save(
    List<
      InvestmentHistory
    >
    history,
  ) async {
    final user = _requireUser();

    try {
      debugPrint(
        '[FINANCE HISTORY] Salvando histórico...',
      );

      // ========================================================
      // REMOVE HISTÓRICO ATUAL
      // ========================================================

      await _client
          .from(
            _table,
          )
          .delete()
          .eq(
            'user_id',
            user.id,
          );

      if (history.isEmpty) {
        await cacheStore.saveHistory(
          user.id,
          const <Map<String, dynamic>>[],
        );

        debugPrint(
          '[FINANCE HISTORY] Histórico vazio.',
        );

        return;
      }

      // ========================================================
      // PREPARAR REGISTROS
      // ========================================================

      final rows = history.map(
        (
          item,
        ) {
          return {
            'user_id': user.id,

            'value': item.safeValue,

            'contribution_date': item.date.toUtc().toIso8601String(),

            'rhythm': item.normalizedRhythm,

            'objective_progress': item.normalizedObjectiveProgress,

            'time_progress': item.normalizedTimeProgress,
          };
        },
      ).toList();

      // ========================================================
      // INSERT
      // ========================================================

      await _client
          .from(
            _table,
          )
          .insert(
            rows,
          );

      await cacheStore.saveHistory(
        user.id,
        history.map((item) => item.toJson()).toList(),
      );

      debugPrint(
        '[FINANCE HISTORY] '
        '${rows.length} registros salvos.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] '
        'Erro Supabase ao salvar.',
      );

      debugPrint(
        '[FINANCE HISTORY] '
        'Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE HISTORY] '
        'Message: ${error.message}',
      );

      debugPrint(
        '[FINANCE HISTORY] '
        'Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] '
        'Erro ao salvar: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<List<InvestmentHistory>> load() async {
    final local = await loadLocal();

    if (local.isNotEmpty) {
      return local;
    }

    return refreshFromRemote();
  }

  // ============================================================
  // LOAD LOCAL
  // ============================================================

  Future<List<InvestmentHistory>> loadLocal() async {
    final user = _requireUser();

    final rows = await cacheStore.loadHistory(
      user.id,
    );

    final history = <InvestmentHistory>[];

    for (final row in rows) {
      try {
        history.add(
          InvestmentHistory.fromJson(row),
        );
      } catch (_) {
        // Registro de cache inválido é ignorado sem bloquear a tela.
      }
    }

    _sortByDateDescending(history);

    return history;
  }

  // ============================================================
  // REFRESH FROM REMOTE
  // ============================================================

  Future<List<InvestmentHistory>> refreshFromRemote() async {
    final user = _requireUser();

    try {
      final data = await _client
          .from(
            _table,
          )
          .select(
            'value, '
            'contribution_date, '
            'created_at, '
            'rhythm, '
            'objective_progress, '
            'time_progress',
          )
          .eq(
            'user_id',
            user.id,
          )
          .order(
            'contribution_date',
            ascending: false,
          );

      final history = <InvestmentHistory>[];

      for (final item in data) {
        history.add(
          InvestmentHistory(
            value: _parseDouble(item['value']),
            date: _parseDate(item['contribution_date']),
            rhythm: item['rhythm']?.toString() ?? 'Personalizado',
            objectiveProgress: _parseDouble(item['objective_progress']),
            timeProgress: _parseDouble(item['time_progress']),
          ),
        );
      }

      _sortByDateDescending(history);

      await cacheStore.saveHistory(
        user.id,
        history.map((item) => item.toJson()).toList(),
      );

      debugPrint(
        '[FINANCE HISTORY] '
        '${history.length} registros carregados.',
      );

      return history;
    } catch (error) {
      final local = await loadLocal();

      if (local.isNotEmpty) {
        debugPrint(
          '[FINANCE HISTORY] '
          'Remoto indisponível. Usando cache local.',
        );

        return local;
      }

      rethrow;
    }
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<
    List<
      InvestmentHistory
    >
  >
  add(
    InvestmentHistory contribution,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .insert(
          {
            'user_id': user.id,

            'value': contribution.safeValue,

            'contribution_date': contribution.date.toUtc().toIso8601String(),

            'rhythm': contribution.normalizedRhythm,

            'objective_progress': contribution.normalizedObjectiveProgress,

            'time_progress': contribution.normalizedTimeProgress,
          },
        );

    return refreshFromRemote();
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<
    List<
      InvestmentHistory
    >
  >
  remove(
    InvestmentHistory contribution,
  ) async {
    final user = _requireUser();

    final date = contribution.date.toUtc().toIso8601String();

    // ========================================================
    // SEM ID NO MODEL
    // ========================================================
    //
    // Identificação:
    //
    // user_id
    // +
    // contribution_date
    // +
    // value
    //
    // ========================================================

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'user_id',
          user.id,
        )
        .eq(
          'contribution_date',
          date,
        )
        .eq(
          'value',
          contribution.safeValue,
        );

    return refreshFromRemote();
  }

  // ============================================================
  // LATEST
  // ============================================================

  Future<
    InvestmentHistory?
  >
  loadLatest() async {
    final user = _requireUser();

    final data = await _client
        .from(
          _table,
        )
        .select(
          'value, '
          'contribution_date, '
          'created_at, '
          'rhythm, '
          'objective_progress, '
          'time_progress',
        )
        .eq(
          'user_id',
          user.id,
        )
        .order(
          'contribution_date',
          ascending: false,
        )
        .limit(
          1,
        )
        .maybeSingle();

    if (data ==
        null) {
      return null;
    }

    return InvestmentHistory(
      value: _parseDouble(
        data['value'],
      ),

      date: _parseDate(
        data['contribution_date'],
      ),

      rhythm:
          data['rhythm']?.toString() ??
          'Personalizado',

      objectiveProgress: _parseDouble(
        data['objective_progress'],
      ),

      timeProgress: _parseDouble(
        data['time_progress'],
      ),
    );
  }

  // ============================================================
  // REPLACE
  // ============================================================

  Future<
    List<
      InvestmentHistory
    >
  >
  replace(
    List<
      InvestmentHistory
    >
    history,
  ) async {
    final updatedHistory =
        List<
          InvestmentHistory
        >.from(
          history,
        );

    _sortByDateDescending(
      updatedHistory,
    );

    await save(
      updatedHistory,
    );

    return updatedHistory;
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'user_id',
          user.id,
        );

    await cacheStore.clearHistory(
      user.id,
    );

    debugPrint(
      '[FINANCE HISTORY] '
      'Histórico removido.',
    );
  }

  // ============================================================
  // HAS HISTORY
  // ============================================================

  Future<
    bool
  >
  hasHistory() async {
    final history = await load();

    return history.isNotEmpty;
  }

  // ============================================================
  // COUNT
  // ============================================================

  Future<
    int
  >
  count() async {
    final user = _requireUser();

    final data = await _client
        .from(
          _table,
        )
        .select(
          'id',
        )
        .eq(
          'user_id',
          user.id,
        );

    return data.length;
  }

  // ============================================================
  // SORT DESCENDING
  // ============================================================

  void _sortByDateDescending(
    List<
      InvestmentHistory
    >
    history,
  ) {
    history.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  double _parseDouble(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    if (value
        is num) {
      final result = value.toDouble();

      if (!result.isFinite) {
        return 0;
      }

      return result;
    }

    return double.tryParse(
          value.toString().trim().replaceAll(
            ',',
            '.',
          ),
        ) ??
        0;
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  DateTime _parseDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value.toLocal();
    }

    final parsed = DateTime.tryParse(
      value?.toString() ??
          '',
    );

    if (parsed ==
        null) {
      return DateTime.now();
    }

    return parsed.toLocal();
  }
}
