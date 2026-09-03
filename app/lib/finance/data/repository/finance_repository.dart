import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/sync/sync_status.dart';
import '../datasources/finance_local_data_source.dart';

class FinanceRepository {
  FinanceRepository({
    SupabaseClient? client,
    FinanceLocalDataSource? localDataSource,
    required SyncQueue syncQueue,
    SyncService? syncService,
  }) : _client =
           client ??
           Supabase.instance.client,
       _localDataSource =
           localDataSource ??
           FinanceLocalDataSource(),
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final FinanceLocalDataSource _localDataSource;

  final SyncQueue _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // TABLE / ENTITY
  // ============================================================

  static const String _table = 'finance_data';

  static const String _entityType = 'finance';

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
  //
  // OFFLINE-FIRST:
  //
  // 1. salva primeiro no SQLite;
  // 2. adiciona a alteração à fila persistente;
  // 3. solicita sincronização;
  // 4. se estiver offline, o dado continua seguro localmente.
  //
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

    final normalized = _normalizeLocalData(
      data,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Salvando primeiro no banco local...',
    );

    await _localDataSource.save(
      userId: user.id,
      data: normalized,
      syncStatus: SyncStatus.pendingUpdate,
    );

    final remotePayload = _toRemotePayload(
      userId: user.id,
      data: normalized,
    );

    await _syncQueue.enqueue(
      entityType: _entityType,
      entityId: user.id,
      operation: SyncOperation.update,
      payload: remotePayload,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Financeiro salvo localmente.',
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // LOAD
  // ============================================================
  //
  // Prioridade:
  //
  // 1. banco local;
  // 2. Supabase, somente quando não há alteração local pendente;
  // 3. se o Supabase falhar, retorna o cache local.
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    final user = _requireUser();

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Carregando financeiro...',
    );

    final local = await _localDataSource.load(
      user.id,
    );

    final localStatus = await _localDataSource.getSyncStatus(
      user.id,
    );

    final hasPendingLocal =
        localStatus !=
            null &&
        localStatus !=
            SyncStatus.synced;

    if (local !=
            null &&
        hasPendingLocal) {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Usando dados locais pendentes.',
      );

      _syncService?.requestSync();

      return _normalizeLocalData(
        local,
      );
    }

    try {
      final remote = await _client
          .from(
            _table,
          )
          .select()
          .eq(
            'user_id',
            user.id,
          )
          .maybeSingle();

      if (remote ==
          null) {
        if (local !=
            null) {
          debugPrint(
            '[FINANCE REPOSITORY] '
            'Sem registro remoto. '
            'Usando cache local.',
          );

          return _normalizeLocalData(
            local,
          );
        }

        debugPrint(
          '[FINANCE REPOSITORY] '
          'Nenhum dado financeiro encontrado.',
        );

        return {};
      }

      final remoteData = _fromRemoteRow(
        remote,
      );

      await _localDataSource.save(
        userId: user.id,
        data: remoteData,
        syncStatus: SyncStatus.synced,
      );

      debugPrint(
        '[FINANCE REPOSITORY] '
        'Dados carregados do Supabase '
        'e atualizados no cache local.',
      );

      return remoteData;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Supabase indisponível ao carregar.',
      );

      debugPrint(
        '[FINANCE REPOSITORY] '
        'Code: ${error.code}',
      );

      debugPrint(
        '[FINANCE REPOSITORY] '
        'Message: ${error.message}',
      );

      if (local !=
          null) {
        debugPrint(
          '[FINANCE REPOSITORY] '
          'Retornando cache local.',
        );

        return _normalizeLocalData(
          local,
        );
      }

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[FINANCE REPOSITORY] '
        'Erro ao carregar: $error',
      );

      if (local !=
          null) {
        return _normalizeLocalData(
          local,
        );
      }

      rethrow;
    }
  }

  // ============================================================
  // UPDATE CRYPTO BALANCE
  // ============================================================

  Future<
    void
  >
  updateCryptoBalance({
    required String symbol,
    required double value,
  }) async {
    _validateCryptoValue(
      value,
      'value',
    );

    final key = _cryptoLocalKey(
      symbol,
    );

    final data = await load();

    data[key] = value;

    await save(
      data,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      '${symbol.toUpperCase()} atualizado '
      'localmente para $value.',
    );
  }

  // ============================================================
  // UPDATE ALL CRYPTO BALANCES
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
    if (bitcoin !=
        null) {
      _validateCryptoValue(
        bitcoin,
        'bitcoin',
      );
    }

    if (ethereum !=
        null) {
      _validateCryptoValue(
        ethereum,
        'ethereum',
      );
    }

    if (solana !=
        null) {
      _validateCryptoValue(
        solana,
        'solana',
      );
    }

    if (usdt !=
        null) {
      _validateCryptoValue(
        usdt,
        'usdt',
      );
    }

    if (bitcoin ==
            null &&
        ethereum ==
            null &&
        solana ==
            null &&
        usdt ==
            null) {
      return;
    }

    final data = await load();

    if (bitcoin !=
        null) {
      data['bitcoin'] = bitcoin;
    }

    if (ethereum !=
        null) {
      data['ethereum'] = ethereum;
    }

    if (solana !=
        null) {
      data['solana'] = solana;
    }

    if (usdt !=
        null) {
      data['usdt'] = usdt;
    }

    await save(
      data,
    );
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
    _validateNonNegativeFinite(
      value,
      'value',
      'O patrimônio deve ser maior ou igual a zero.',
    );

    final data = await load();

    data['patrimony'] = value;

    await save(
      data,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Patrimônio atualizado localmente: $value',
    );
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
    _validateNonNegativeFinite(
      value,
      'value',
      'O valor investido deve ser maior ou igual a zero.',
    );

    final data = await load();

    data['invested'] = value;

    await save(
      data,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Valor investido atualizado localmente: $value',
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================
  //
  // A remoção também é offline-first.
  //
  // O registro fica marcado localmente como excluído até que
  // a operação DELETE seja sincronizada com o Supabase.
  //
  // ============================================================

  Future<
    void
  >
  clear() async {
    final user = _requireUser();

    final exists = await _localDataSource.exists(
      user.id,
    );

    if (exists) {
      await _localDataSource.markDeleted(
        user.id,
      );
    }

    await _syncQueue.enqueue(
      entityType: _entityType,
      entityId: user.id,
      operation: SyncOperation.delete,
    );

    debugPrint(
      '[FINANCE REPOSITORY] '
      'Exclusão financeira registrada localmente.',
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // REFRESH FROM REMOTE
  // ============================================================
  //
  // Use quando quiser forçar uma atualização a partir do
  // Supabase.
  //
  // Não sobrescreve alterações locais pendentes.
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  refreshFromRemote() async {
    final user = _requireUser();

    final localStatus = await _localDataSource.getSyncStatus(
      user.id,
    );

    if (localStatus !=
            null &&
        localStatus !=
            SyncStatus.synced) {
      final local = await _localDataSource.load(
        user.id,
      );

      _syncService?.requestSync();

      return local ==
              null
          ? {}
          : _normalizeLocalData(
              local,
            );
    }

    final remote = await _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .maybeSingle();

    if (remote ==
        null) {
      return {};
    }

    final data = _fromRemoteRow(
      remote,
    );

    await _localDataSource.save(
      userId: user.id,
      data: data,
      syncStatus: SyncStatus.synced,
    );

    return data;
  }

  // ============================================================
  // LOCAL CACHE
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  loadLocal() async {
    final user = _requireUser();

    final data = await _localDataSource.load(
      user.id,
    );

    if (data ==
        null) {
      return null;
    }

    return _normalizeLocalData(
      data,
    );
  }

  Future<
    SyncStatus?
  >
  getLocalSyncStatus() async {
    final user = _requireUser();

    return _localDataSource.getSyncStatus(
      user.id,
    );
  }

  // ============================================================
  // REMOTE PAYLOAD
  // ============================================================

  Map<
    String,
    dynamic
  >
  _toRemotePayload({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
  }) {
    return {
      'user_id': userId,

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

      'total_invested': _double(
        data['totalInvested'],
      ),

      'invested_months': _integer(
        data['investedMonths'],
      ),

      'average_contribution': _double(
        data['averageContribution'],
      ),

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

      'completed_days': _normalizeCompletedDays(
        data['completedDays'],
      ),

      'selected_day': data['selectedDay']?.toString(),

      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // REMOTE -> LOCAL
  // ============================================================

  Map<
    String,
    dynamic
  >
  _fromRemoteRow(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return {
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

      'totalInvested': _double(
        data['total_invested'],
      ),

      'investedMonths': _integer(
        data['invested_months'],
      ),

      'averageContribution': _double(
        data['average_contribution'],
      ),

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

      'completedDays': _normalizeCompletedDays(
        data['completed_days'],
      ),

      'selectedDay': data['selected_day']?.toString(),
    };
  }

  // ============================================================
  // NORMALIZE LOCAL DATA
  // ============================================================

  Map<
    String,
    dynamic
  >
  _normalizeLocalData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    return {
      'patrimony': _double(
        data['patrimony'],
      ),

      'invested': _double(
        data['invested'],
      ),

      'monthlyGoal': _double(
        data['monthlyGoal'],
      ),

      'investmentGoal': _double(
        data['investmentGoal'],
      ),

      'minimumGoal': _double(
        data['minimumGoal'],
      ),

      'mediumGoal': _double(
        data['mediumGoal'],
      ),

      'maximumGoal': _double(
        data['maximumGoal'],
      ),

      'projectionYears': _integer(
        data['projectionYears'],
        fallback: 10,
      ),

      'totalInvested': _double(
        data['totalInvested'],
      ),

      'investedMonths': _integer(
        data['investedMonths'],
      ),

      'averageContribution': _double(
        data['averageContribution'],
      ),

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

      'completedDays': _normalizeCompletedDays(
        data['completedDays'],
      ),

      'selectedDay': data['selectedDay']?.toString(),
    };
  }

  // ============================================================
  // CRYPTO KEY
  // ============================================================

  String _cryptoLocalKey(
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
  // VALIDATION
  // ============================================================

  void _validateCryptoValue(
    double value,
    String name,
  ) {
    _validateNonNegativeFinite(
      value,
      name,
      'O saldo deve ser maior ou igual a zero.',
    );
  }

  void _validateNonNegativeFinite(
    double value,
    String name,
    String message,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        name,
        message,
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
