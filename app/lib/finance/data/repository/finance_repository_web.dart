import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/sync/sync_status.dart';
import 'finance_repository_contract.dart';

class FinanceRepository implements FinanceRepositoryContract {
  FinanceRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const String _table = 'finance_data';
  static const String _cachePrefix = 'evrylux.web.finance.v1';

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user;
  }

  String _cacheKey(String userId) => '$_cachePrefix.$userId.data';
  String _statusKey(String userId) => '$_cachePrefix.$userId.status';

  Future<void> _saveLocal(
    String userId,
    Map<String, dynamic> data,
    SyncStatus status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey(userId),
      jsonEncode(_normalizeLocalData(data)),
    );
    await prefs.setString(_statusKey(userId), status.value);
  }

  Future<Map<String, dynamic>?> _loadLocalRaw(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey(userId));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return _normalizeLocalData(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<SyncStatus?> _loadStatus(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusKey(userId));
    if (raw == null) {
      return null;
    }
    return SyncStatus.fromValue(raw);
  }

  @override
  Future<void> save(Map<String, dynamic> data) async {
    final user = _requireUser();

    if (data.isEmpty) {
      await clear();
      return;
    }

    final normalized = _normalizeLocalData(data);
    await _saveLocal(user.id, normalized, SyncStatus.pendingUpdate);

    try {
      await _client
          .from(_table)
          .upsert(
            _toRemotePayload(userId: user.id, data: normalized),
            onConflict: 'user_id',
          );
      await _saveLocal(user.id, normalized, SyncStatus.synced);
    } catch (error) {
      debugPrint('[FINANCE][WEB] Salvamento remoto pendente: $error');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> load() async {
    final user = _requireUser();
    final local = await _loadLocalRaw(user.id);

    try {
      // No Web, o Supabase é a fonte de verdade entre dispositivos.
      // Não deixe um cache local "pending" e zerado bloquear a leitura remota.
      final remote = await _client
          .from(_table)
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (remote == null) {
        debugPrint(
          '[FINANCE][WEB] Nenhuma linha remota em finance_data '
          'para o usuário autenticado.',
        );
        return local ?? <String, dynamic>{};
      }

      final data = _fromRemoteRow(remote);

      debugPrint(
        '[FINANCE][WEB] REMOTE LOAD '
        'invested=${data['invested']} '
        'BTC=${data['bitcoin']} '
        'ETH=${data['ethereum']} '
        'SOL=${data['solana']} '
        'USDT=${data['usdt']}',
      );

      await _saveLocal(user.id, data, SyncStatus.synced);
      return data;
    } catch (error) {
      debugPrint('[FINANCE][WEB] Falha ao carregar remoto: $error');

      // Offline fallback somente se a consulta remota realmente falhar.
      if (local != null) {
        return local;
      }

      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> refreshFromRemote() async {
    final user = _requireUser();

    final remote = await _client
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (remote == null) {
      debugPrint(
        '[FINANCE][WEB] REMOTE REFRESH: finance_data vazio '
        'para o usuário autenticado.',
      );
      return <String, dynamic>{};
    }

    final data = _fromRemoteRow(remote);

    debugPrint(
      '[FINANCE][WEB] REMOTE REFRESH '
      'invested=${data['invested']} '
      'BTC=${data['bitcoin']} '
      'ETH=${data['ethereum']} '
      'SOL=${data['solana']} '
      'USDT=${data['usdt']}',
    );

    await _saveLocal(user.id, data, SyncStatus.synced);
    return data;
  }

  @override
  Future<Map<String, dynamic>?> loadLocal() async {
    final user = _requireUser();
    return _loadLocalRaw(user.id);
  }

  @override
  Future<SyncStatus?> getLocalSyncStatus() async {
    final user = _requireUser();
    return _loadStatus(user.id);
  }

  @override
  Future<void> clear() async {
    final user = _requireUser();
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cacheKey(user.id));
    await prefs.setString(_statusKey(user.id), SyncStatus.pendingDelete.value);

    try {
      await _client.from(_table).delete().eq('user_id', user.id);
      await prefs.remove(_statusKey(user.id));
    } catch (error) {
      debugPrint('[FINANCE][WEB] Exclusão remota pendente: $error');
      rethrow;
    }
  }

  @override
  Future<void> updateCryptoBalance({
    required String symbol,
    required double value,
  }) async {
    _validateNonNegativeFinite(
      value,
      'value',
      'O saldo deve ser maior ou igual a zero.',
    );
    final data = await load();
    data[_cryptoLocalKey(symbol)] = value;
    await save(data);
  }

  @override
  Future<void> updateCryptoBalances({
    double? bitcoin,
    double? ethereum,
    double? solana,
    double? usdt,
  }) async {
    for (final entry in <String, double?>{
      'bitcoin': bitcoin,
      'ethereum': ethereum,
      'solana': solana,
      'usdt': usdt,
    }.entries) {
      final value = entry.value;
      if (value != null) {
        _validateNonNegativeFinite(
          value,
          entry.key,
          'O saldo deve ser maior ou igual a zero.',
        );
      }
    }

    final data = await load();
    if (bitcoin != null) data['bitcoin'] = bitcoin;
    if (ethereum != null) data['ethereum'] = ethereum;
    if (solana != null) data['solana'] = solana;
    if (usdt != null) data['usdt'] = usdt;
    await save(data);
  }

  @override
  Future<void> updatePatrimony(double value) async {
    _validateNonNegativeFinite(
      value,
      'value',
      'O patrimônio deve ser maior ou igual a zero.',
    );
    final data = await load();
    data['patrimony'] = value;
    await save(data);
  }

  @override
  Future<void> updateInvested(double value) async {
    _validateNonNegativeFinite(
      value,
      'value',
      'O valor investido deve ser maior ou igual a zero.',
    );
    final data = await load();
    data['invested'] = value;
    await save(data);
  }

  Map<String, dynamic> _toRemotePayload({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    return <String, dynamic>{
      'user_id': userId,
      'patrimony': _double(data['patrimony']),
      'invested': _double(data['invested']),
      'monthly_goal': _double(data['monthlyGoal']),
      'investment_goal': _double(data['investmentGoal']),
      'minimum_goal': _double(data['minimumGoal']),
      'medium_goal': _double(data['mediumGoal']),
      'maximum_goal': _double(data['maximumGoal']),
      'projection_years': _integer(data['projectionYears'], fallback: 10),
      'total_invested': _double(data['totalInvested']),
      'invested_months': _integer(data['investedMonths']),
      'average_contribution': _double(data['averageContribution']),
      'bitcoin': _double(data['bitcoin']),
      'ethereum': _double(data['ethereum']),
      'solana': _double(data['solana']),
      'usdt': _double(data['usdt']),
      'completed_days': _normalizeCompletedDays(data['completedDays']),
      'selected_day': data['selectedDay']?.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _fromRemoteRow(Map<String, dynamic> data) {
    return <String, dynamic>{
      'patrimony': _double(data['patrimony']),
      'invested': _double(data['invested']),
      'monthlyGoal': _double(data['monthly_goal']),
      'investmentGoal': _double(data['investment_goal']),
      'minimumGoal': _double(data['minimum_goal']),
      'mediumGoal': _double(data['medium_goal']),
      'maximumGoal': _double(data['maximum_goal']),
      'projectionYears': _integer(data['projection_years'], fallback: 10),
      'totalInvested': _double(data['total_invested']),
      'investedMonths': _integer(data['invested_months']),
      'averageContribution': _double(data['average_contribution']),
      'bitcoin': _double(data['bitcoin']),
      'ethereum': _double(data['ethereum']),
      'solana': _double(data['solana']),
      'usdt': _double(data['usdt']),
      'completedDays': _normalizeCompletedDays(data['completed_days']),
      'selectedDay': data['selected_day']?.toString(),
    };
  }

  Map<String, dynamic> _normalizeLocalData(Map<String, dynamic> data) {
    return <String, dynamic>{
      'patrimony': _double(data['patrimony']),
      'invested': _double(data['invested']),
      'monthlyGoal': _double(data['monthlyGoal']),
      'investmentGoal': _double(data['investmentGoal']),
      'minimumGoal': _double(data['minimumGoal']),
      'mediumGoal': _double(data['mediumGoal']),
      'maximumGoal': _double(data['maximumGoal']),
      'projectionYears': _integer(data['projectionYears'], fallback: 10),
      'totalInvested': _double(data['totalInvested']),
      'investedMonths': _integer(data['investedMonths']),
      'averageContribution': _double(data['averageContribution']),
      'bitcoin': _double(data['bitcoin']),
      'ethereum': _double(data['ethereum']),
      'solana': _double(data['solana']),
      'usdt': _double(data['usdt']),
      'completedDays': _normalizeCompletedDays(data['completedDays']),
      'selectedDay': data['selectedDay']?.toString(),
    };
  }

  String _cryptoLocalKey(String symbol) {
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

  void _validateNonNegativeFinite(double value, String name, String message) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, message);
    }
  }

  double _double(dynamic value) {
    if (value == null) return 0;
    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : 0;
    }
    return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
  }

  int _integer(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  List<bool> _normalizeCompletedDays(dynamic value) {
    if (value is! List) {
      return List<bool>.filled(7, false);
    }

    final result = value.map<bool>((item) => item == true).toList();

    if (result.length > 7) {
      return result.take(7).toList();
    }

    while (result.length < 7) {
      result.add(false);
    }

    return result;
  }
}
