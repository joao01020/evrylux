import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceRepository {
  FinanceRepository({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  // ============================================================
  // CLIENT
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // TABLE
  // ============================================================

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
              // ====================================================
              // USER
              // ====================================================
              'user_id': user.id,

              // ====================================================
              // PATRIMÔNIO
              // ====================================================
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

              // ====================================================
              // PLANEJAMENTO
              // ====================================================
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

              // ====================================================
              // HISTÓRICO / TOTAIS
              // ====================================================
              'total_invested': _double(
                data['totalInvested'],
              ),

              'invested_months': _integer(
                data['investedMonths'],
              ),

              'average_contribution': _double(
                data['averageContribution'],
              ),

              // ====================================================
              // CRYPTO
              // ====================================================
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

              // ====================================================
              // OUTROS
              // ====================================================
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

      debugPrint(
        '[FINANCE REPOSITORY] Details: ${error.details}',
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
  // UPDATE CRYPTO BALANCE
  // ============================================================
  //
  // Atualiza somente o saldo atual de UMA criptomoeda.
  //
  // Exemplo:
  //
  // await repository.updateCryptoBalance(
  //   symbol: 'BTC',
  //   value: 0.00124567,
  // );
  //
  // Não altera:
  //
  // - patrimônio
  // - valor investido
  // - metas
  // - histórico
  //
  // ============================================================

  Future<
    void
  >
  updateCryptoBalance({
    required String symbol,
    required double value,
  }) async {
    final user = _requireUser();

    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        'value',
        'O saldo da criptomoeda deve ser maior ou igual a zero.',
      );
    }

    final column = _cryptoColumn(
      symbol,
    );

    try {
      debugPrint(
        '[FINANCE REPOSITORY] Atualizando saldo '
        '${symbol.toUpperCase()} para $value...',
      );

      // Primeiro garante que exista um registro para o usuário.
      await _ensureFinanceRow(
        user.id,
      );

      await _client
          .from(
            _table,
          )
          .update(
            {
              column: value,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            user.id,
          );

      debugPrint(
        '[FINANCE REPOSITORY] Saldo '
        '${symbol.toUpperCase()} atualizado.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Erro Supabase.',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Message: ${error.message}',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] '
        'Erro ao atualizar saldo: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE ALL CRYPTO BALANCES
  // ============================================================
  //
  // Permite atualizar todos os saldos de uma vez.
  //
  // Parâmetros nulos não são modificados.
  //
  // ============================================================

  Future<
    void
  >
  updateCryptoBalances({
    double? bitcoin,
    double? ethereum,
    double? solana,
    double? usdt,
  }) async {
    final user = _requireUser();

    final updates =
        <
          String,
          dynamic
        >{};

    if (bitcoin !=
        null) {
      _validateCryptoValue(
        bitcoin,
        'bitcoin',
      );

      updates['bitcoin'] = bitcoin;
    }

    if (ethereum !=
        null) {
      _validateCryptoValue(
        ethereum,
        'ethereum',
      );

      updates['ethereum'] = ethereum;
    }

    if (solana !=
        null) {
      _validateCryptoValue(
        solana,
        'solana',
      );

      updates['solana'] = solana;
    }

    if (usdt !=
        null) {
      _validateCryptoValue(
        usdt,
        'usdt',
      );

      updates['usdt'] = usdt;
    }

    if (updates.isEmpty) {
      return;
    }

    updates['updated_at'] = DateTime.now().toUtc().toIso8601String();

    try {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Atualizando saldos de criptomoedas...',
      );

      await _ensureFinanceRow(
        user.id,
      );

      await _client
          .from(
            _table,
          )
          .update(
            updates,
          )
          .eq(
            'user_id',
            user.id,
          );

      debugPrint(
        '[FINANCE REPOSITORY] '
        'Saldos de criptomoedas atualizados.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Erro Supabase.',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Message: ${error.message}',
      );

      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY][CRYPTO] '
        'Erro ao atualizar saldos: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE PATRIMONY
  // ============================================================

  Future<
    void
  >
  updatePatrimony(
    double value,
  ) async {
    final user = _requireUser();

    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        'value',
        'O patrimônio deve ser maior ou igual a zero.',
      );
    }

    try {
      await _ensureFinanceRow(
        user.id,
      );

      await _client
          .from(
            _table,
          )
          .update(
            {
              'patrimony': value,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            user.id,
          );

      debugPrint(
        '[FINANCE REPOSITORY] Patrimônio atualizado: $value',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Erro ao atualizar patrimônio: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE INVESTED
  // ============================================================

  Future<
    void
  >
  updateInvested(
    double value,
  ) async {
    final user = _requireUser();

    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        'value',
        'O valor investido deve ser maior ou igual a zero.',
      );
    }

    try {
      await _ensureFinanceRow(
        user.id,
      );

      await _client
          .from(
            _table,
          )
          .update(
            {
              'invested': value,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'user_id',
            user.id,
          );

      debugPrint(
        '[FINANCE REPOSITORY] Valor investido atualizado: $value',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Erro ao atualizar valor investido: $error',
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
  // ENSURE FINANCE ROW
  // ============================================================
  //
  // Garante que finance_data possua uma linha para o usuário
  // antes dos updates específicos.
  //
  // ============================================================

  Future<
    void
  >
  _ensureFinanceRow(
    String userId,
  ) async {
    final existing = await _client
        .from(
          _table,
        )
        .select(
          'user_id',
        )
        .eq(
          'user_id',
          userId,
        )
        .maybeSingle();

    if (existing !=
        null) {
      return;
    }

    await _client
        .from(
          _table,
        )
        .insert(
          {
            'user_id': userId,
            'patrimony': 0,
            'invested': 0,
            'monthly_goal': 0,
            'investment_goal': 0,
            'minimum_goal': 0,
            'medium_goal': 0,
            'maximum_goal': 0,
            'projection_years': 10,
            'total_invested': 0,
            'invested_months': 0,
            'average_contribution': 0,
            'bitcoin': 0,
            'ethereum': 0,
            'solana': 0,
            'usdt': 0,
            'completed_days':
                List<
                  bool
                >.filled(
                  7,
                  false,
                ),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        );
  }

  // ============================================================
  // CRYPTO COLUMN
  // ============================================================

  String _cryptoColumn(
    String symbol,
  ) {
    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
      case 'BITCOIN':
        return 'bitcoin';

      case 'ETH':
      case 'ETHEREUM':
        return 'ethereum';

      case 'SOL':
      case 'SOLANA':
        return 'solana';

      case 'USDT':
      case 'TETHER':
        return 'usdt';

      default:
        throw ArgumentError.value(
          symbol,
          'symbol',
          'Criptomoeda não suportada.',
        );
    }
  }

  // ============================================================
  // VALIDATE CRYPTO VALUE
  // ============================================================

  void _validateCryptoValue(
    double value,
    String name,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        name,
        'O saldo deve ser maior ou igual a zero.',
      );
    }
  }

  // ============================================================
  // DOUBLE
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

  // ============================================================
  // INTEGER
  // ============================================================

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

  // ============================================================
  // COMPLETED DAYS
  // ============================================================

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
