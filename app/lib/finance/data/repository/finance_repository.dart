import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  FinanceRepository({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'finance_data';

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
  // SAVE
  // ============================================================

  Future<
    void
  >
  save(
    Map<
      String,
      dynamic
    >
    data,
  ) async {
    final user = _requireUser();

    // ----------------------------------------------------------
    // CLEAR
    // ----------------------------------------------------------

    if (data.isEmpty) {
      await clear();

      return;
    }

    try {
      debugPrint(
        '[FINANCE REPOSITORY] Salvando financeiro...',
      );

      final completedDays = _normalizeCompletedDays(
        data['completedDays'],
      );

      await _client
          .from(
            _table,
          )
          .upsert(
            {
              'user_id': user.id,

              // ================================================
              // PATRIMÔNIO
              // ================================================
              'patrimony': _double(
                data['patrimony'],
              ),

              'invested': _double(
                data['invested'],
              ),

              'monthly_goal': _double(
                data['monthlyGoal'],
              ),

              'investment_goal': _double(
                data['investmentGoal'],
              ),

              // ================================================
              // PLANEJAMENTO
              // ================================================
              'minimum_goal': _double(
                data['minimumGoal'],
              ),

              'medium_goal': _double(
                data['mediumGoal'],
              ),

              'maximum_goal': _double(
                data['maximumGoal'],
              ),

              'projection_years': _integer(
                data['projectionYears'],
                fallback: 10,
              ),

              // ================================================
              // HISTÓRICO / TOTAIS
              // ================================================
              'total_invested': _double(
                data['totalInvested'],
              ),

              'invested_months': _integer(
                data['investedMonths'],
              ),

              'average_contribution': _double(
                data['averageContribution'],
              ),

              // ================================================
              // CRYPTO
              // ================================================
              'bitcoin': _double(
                data['bitcoin'],
              ),

              'ethereum': _double(
                data['ethereum'],
              ),

              'solana': _double(
                data['solana'],
              ),

              'usdt': _double(
                data['usdt'],
              ),

              // ================================================
              // OUTROS
              // ================================================
              'completed_days': completedDays,

              'selected_day': data['selectedDay']?.toString(),

              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'user_id',
          );

      debugPrint(
        '[FINANCE REPOSITORY] Financeiro salvo.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] Erro Supabase.',
      );

      debugPrint(
        '[FINANCE REPOSITORY] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE REPOSITORY] Message: ${error.message}',
      );

      debugPrint(
        '[FINANCE REPOSITORY] Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] Erro ao salvar: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    final user = _requireUser();

    try {
      debugPrint(
        '[FINANCE REPOSITORY] Carregando financeiro...',
      );

      final data = await _client
          .from(
            _table,
          )
          .select()
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (data ==
          null) {
        debugPrint(
          '[FINANCE REPOSITORY] Nenhum dado encontrado.',
        );

        return {};
      }

      debugPrint(
        '[FINANCE REPOSITORY] Dados carregados.',
      );

      return {
        // ======================================================
        // PATRIMÔNIO
        // ======================================================
        'patrimony': _double(
          data['patrimony'],
        ),

        'invested': _double(
          data['invested'],
        ),

        'monthlyGoal': _double(
          data['monthly_goal'],
        ),

        'investmentGoal': _double(
          data['investment_goal'],
        ),

        // ======================================================
        // PLANEJAMENTO
        // ======================================================
        'minimumGoal': _double(
          data['minimum_goal'],
        ),

        'mediumGoal': _double(
          data['medium_goal'],
        ),

        'maximumGoal': _double(
          data['maximum_goal'],
        ),

        'projectionYears': _integer(
          data['projection_years'],
          fallback: 10,
        ),

        // ======================================================
        // HISTÓRICO / TOTAIS
        // ======================================================
        'totalInvested': _double(
          data['total_invested'],
        ),

        'investedMonths': _integer(
          data['invested_months'],
        ),

        'averageContribution': _double(
          data['average_contribution'],
        ),

        // ======================================================
        // CRYPTO
        // ======================================================
        'bitcoin': _double(
          data['bitcoin'],
        ),

        'ethereum': _double(
          data['ethereum'],
        ),

        'solana': _double(
          data['solana'],
        ),

        'usdt': _double(
          data['usdt'],
        ),

        // ======================================================
        // OUTROS
        // ======================================================
        'completedDays': _normalizeCompletedDays(
          data['completed_days'],
        ),

        'selectedDay': data['selected_day']?.toString(),
      };
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] Erro Supabase ao carregar.',
      );

      debugPrint(
        '[FINANCE REPOSITORY] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE REPOSITORY] Message: ${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] Erro ao carregar: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    final user = _requireUser();

    try {
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
        '[FINANCE REPOSITORY] Dados removidos.',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] Erro ao limpar: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _double(
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
          value.toString().replaceAll(
            ',',
            '.',
          ),
        ) ??
        0;
  }

  int _integer(
    dynamic value, {
    int fallback = 0,
  }) {
    if (value ==
        null) {
      return fallback;
    }

    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        fallback;
  }

  List<
    bool
  >
  _normalizeCompletedDays(
    dynamic value,
  ) {
    if (value
        is! List) {
      return List<
        bool
      >.filled(
        7,
        false,
      );
    }

    final result = value
        .map<
          bool
        >(
          (
            item,
          ) =>
              item ==
              true,
        )
        .toList();

    if (result.length >
        7) {
      return result
          .take(
            7,
          )
          .toList();
    }

    while (result.length <
        7) {
      result.add(
        false,
      );
    }

    return result;
  }
}
