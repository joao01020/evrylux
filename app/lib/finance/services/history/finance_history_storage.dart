import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'investment_history.dart';

class FinanceHistoryStorage {
  const FinanceHistoryStorage();

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

      // --------------------------------------------------------
      // Estratégia:
      //
      // O controller trabalha com a lista completa em memória.
      // Então, ao salvar, sincronizamos a lista inteira.
      //
      // Remove o histórico do usuário e grava novamente.
      // --------------------------------------------------------

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
        debugPrint(
          '[FINANCE HISTORY] Histórico vazio.',
        );

        return;
      }

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

      await _client
          .from(
            _table,
          )
          .insert(
            rows,
          );

      debugPrint(
        '[FINANCE HISTORY] ${rows.length} registros salvos.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] Erro Supabase ao salvar.',
      );

      debugPrint(
        '[FINANCE HISTORY] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE HISTORY] Message: ${error.message}',
      );

      debugPrint(
        '[FINANCE HISTORY] Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] Erro ao salvar: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    List<
      InvestmentHistory
    >
  >
  load() async {
    final user = _requireUser();

    try {
      final data = await _client
          .from(
            _table,
          )
          .select(
            'value, '
            'contribution_date, '
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
            ascending: true,
          );

      final history =
          <
            InvestmentHistory
          >[];

      for (final item in data) {
        history.add(
          InvestmentHistory(
            value: _parseDouble(
              item['value'],
            ),

            date: _parseDate(
              item['contribution_date'],
            ),

            rhythm:
                item['rhythm']?.toString() ??
                'Personalizado',

            objectiveProgress: _parseDouble(
              item['objective_progress'],
            ),

            timeProgress: _parseDouble(
              item['time_progress'],
            ),
          ),
        );
      }

      _sortByDate(
        history,
      );

      debugPrint(
        '[FINANCE HISTORY] ${history.length} registros carregados.',
      );

      return history;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] Erro Supabase ao carregar.',
      );

      debugPrint(
        '[FINANCE HISTORY] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE HISTORY] Message: ${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE HISTORY] Erro ao carregar: $error',
      );

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

    return load();
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

    // ----------------------------------------------------------
    // Como o modelo InvestmentHistory atual não possui ID,
    // identificamos pelo usuário + data + valor.
    // ----------------------------------------------------------

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

    return load();
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

    _sortByDate(
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

    debugPrint(
      '[FINANCE HISTORY] Histórico removido.',
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
  // SORT
  // ============================================================

  void _sortByDate(
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
        return first.date.compareTo(
          second.date,
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
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
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
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.now();
  }
}
