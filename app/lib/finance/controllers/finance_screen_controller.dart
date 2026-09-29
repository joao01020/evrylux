import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../projections/finance_projection.dart';

import '../services/history/investment_history.dart';

import '../models/crypto/crypto_balances.dart';

import '../services/crypto/crypto_balance_service.dart';
import '../services/crypto/crypto_price_service.dart';

import '../services/finance/finance_contribution_service.dart';

import '../services/persistence/finance_persistence_service.dart';

import '../services/history/finance_history_storage.dart';

import '../services/finance/finance_objective_service.dart';

// ============================================================
// FINANCE SCREEN CONTROLLER
// ============================================================
//
// Responsável por coordenar:
//
// - dados financeiros;
// - objetivo financeiro;
// - aportes;
// - histórico;
// - criptomoedas;
// - cotações;
// - persistência.
//
// Fluxo:
//
// FinanceScreen
//      ↓
// FinanceScreenActions
//      ↓
// FinanceScreenController
//      ↓
// Services
//      ↓
// Supabase / Storage / API externa
//
// A tela NÃO deve acessar Supabase ou API diretamente.
//
// ============================================================

class FinanceScreenController {
  // ==========================================================
  // CONTROLLERS LEGADOS
  // ==========================================================

  final dynamic financeController;

  final dynamic cryptoController;

  // ==========================================================
  // SERVICES
  // ==========================================================

  final FinanceContributionService _contributionService =
      const FinanceContributionService();

  late final CryptoBalanceService _cryptoBalanceService;

  late final FinancePersistenceService _persistenceService;

  late final FinanceObjectiveService _objectiveService;

  final CryptoPriceService cryptoPriceService;

  // ==========================================================
  // HISTORY
  // ==========================================================

  final List<InvestmentHistory> history = [];

  // ==========================================================
  // CRYPTO
  // ==========================================================

  CryptoBalances balances = const CryptoBalances();

  // ==========================================================
  // CRYPTO PRICES
  // ==========================================================

  Map<String, double> cryptoPricesBrl = {
    'BTC': 0,
    'ETH': 0,
    'SOL': 0,
    'USDT': 0,
  };

  bool cryptoPricesLoaded = false;

  String? cryptoPriceError;

  // ==========================================================
  // OBJECTIVE
  // ==========================================================

  String objectiveName = 'Objetivo financeiro';

  // ==========================================================
  // LOADING
  // ==========================================================

  bool isLoading = true;

  bool isRefreshing = false;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  FinanceScreenController({
    required this.financeController,
    required this.cryptoController,
    required this.cryptoPriceService,
    FinanceObjectiveService? objectiveService,
  }) {
    // ========================================================
    // CRYPTO
    // ========================================================

    _cryptoBalanceService = CryptoBalanceService(
      cryptoController: cryptoController,
    );

    // ========================================================
    // PERSISTENCE
    // ========================================================

    _persistenceService = FinancePersistenceService(
      financeController: financeController,
      historyStorage: const FinanceHistoryStorage(),
    );

    // ========================================================
    // OBJECTIVE
    // ========================================================

    _objectiveService = objectiveService ?? FinanceObjectiveService();
  }

  // ==========================================================
  // MODEL
  // ==========================================================

  dynamic get model {
    return financeController.model;
  }

  // ==========================================================
  // PROJECTION
  // ==========================================================

  FinanceProjection get projection {
    return FinanceProjection(model: model, history: history);
  }

  // ==========================================================
  // OBJECTIVE VALUE
  // ==========================================================

  double get objectiveValue {
    final value = model.investmentGoal;

    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }

  // ==========================================================
  // HAS OBJECTIVE
  // ==========================================================

  bool get hasObjective {
    return objectiveValue > 0;
  }

  // ==========================================================
  // CRYPTO PATRIMONY
  // ==========================================================

  double get cryptoPatrimony {
    if (kIsWeb) {
      double quantity(dynamic value) {
        final parsed = value is num ? value.toDouble() : 0.0;
        return parsed.isFinite && parsed > 0 ? parsed : 0.0;
      }

      double price(String symbol) {
        final parsed = cryptoPricesBrl[symbol] ?? 0.0;
        return parsed.isFinite && parsed > 0 ? parsed : 0.0;
      }

      return quantity(model.bitcoin) * price('BTC') +
          quantity(model.ethereum) * price('ETH') +
          quantity(model.solana) * price('SOL') +
          quantity(model.usdt) * price('USDT');
    }

    final value = cryptoController.cryptoPatrimonyBrl;

    if (value is num) {
      final result = value.toDouble();

      if (!result.isFinite || result < 0) {
        return 0;
      }

      return result;
    }

    return 0;
  }

  CryptoBalances _webBalancesFromFinanceModel() {
    double safe(dynamic value) {
      final parsed = value is num ? value.toDouble() : 0.0;
      if (!parsed.isFinite || parsed < 0) return 0.0;
      return parsed;
    }

    return CryptoBalances(
      bitcoin: safe(model.bitcoin),
      ethereum: safe(model.ethereum),
      solana: safe(model.solana),
      usdt: safe(model.usdt),
    );
  }

  void _applyWebCryptoPortfolioFromFinanceModel() {
    if (!kIsWeb) return;

    balances = _webBalancesFromFinanceModel();

    final quantities = <String, double>{
      'BTC': balances.bitcoin,
      'ETH': balances.ethereum,
      'SOL': balances.solana,
      'USDT': balances.usdt,
    };

    final values = <String, double>{};
    var total = 0.0;

    for (final entry in quantities.entries) {
      final rawPrice = cryptoPricesBrl[entry.key] ?? 0.0;
      final price = rawPrice.isFinite && rawPrice > 0 ? rawPrice : 0.0;
      final quantity = entry.value.isFinite && entry.value > 0
          ? entry.value
          : 0.0;
      final currentValue = quantity * price;

      values[entry.key] = currentValue;
      total += currentValue;
    }

    cryptoController.quantities = quantities;
    cryptoController.currentValuesBrl = values;
    cryptoController.cryptoPatrimonyBrl = total;
  }

  Future<void> _syncNativeCryptoBalancesToFinanceData() async {
    if (kIsWeb) return;

    double safe(dynamic value) {
      final parsed = value is num ? value.toDouble() : 0.0;
      if (!parsed.isFinite || parsed < 0) return 0.0;
      return parsed;
    }

    final quantities = cryptoController.quantities;

    final bitcoin = safe(quantities['BTC']);
    final ethereum = safe(quantities['ETH']);
    final solana = safe(quantities['SOL']);
    final usdt = safe(quantities['USDT']);

    model.bitcoin = bitcoin;
    model.ethereum = ethereum;
    model.solana = solana;
    model.usdt = usdt;

    // Primeiro preserva o fluxo offline-first normal do aplicativo.
    await financeController.saveData();

    // Em seguida faz um backfill remoto explícito das quantidades
    // consolidadas. Isso evita depender do tempo da SyncQueue para que um
    // navegador novo consiga reconstruir a carteira.
    //
    // Importante: enviamos SOMENTE os campos de cripto. Assim não sobrescreve
    // planejamento, patrimônio, objetivo ou demais dados financeiros.
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await Supabase.instance.client
          .from('finance_data')
          .upsert(<String, dynamic>{
            'user_id': user.id,
            'bitcoin': bitcoin,
            'ethereum': ethereum,
            'solana': solana,
            'usdt': usdt,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id');

      debugPrint(
        '[FINANCE][CRYPTO BACKFILL] '
        'Quantidades publicadas diretamente em finance_data: '
        'BTC=$bitcoin ETH=$ethereum SOL=$solana USDT=$usdt',
      );
    } on PostgrestException catch (error) {
      // O save offline-first acima já deixou a alteração na fila.
      // Portanto uma falha remota aqui não perde dados.
      debugPrint(
        '[FINANCE][CRYPTO BACKFILL] '
        'Backfill remoto pendente (${error.code}): ${error.message}',
      );
    } catch (error) {
      debugPrint(
        '[FINANCE][CRYPTO BACKFILL] '
        'Backfill remoto pendente: $error',
      );
    }
  }

  // ==========================================================
  // TOTAL PATRIMONY
  // ==========================================================
  //
  // Patrimônio base/manual
  // +
  // valor atual das criptomoedas
  //
  // ==========================================================

  double get totalPatrimony {
    final baseValue = model.patrimony;

    final base = baseValue is num ? baseValue.toDouble() : 0.0;

    final safeBase = !base.isFinite || base < 0 ? 0.0 : base;

    return safeBase + cryptoPatrimony;
  }

  // ==========================================================
  // INVESTED + CRYPTO
  // ==========================================================
  //
  // Se sua regra de negócio for:
  //
  // patrimônio =
  // valor investido
  // +
  // valor atual das criptos
  //
  // use este getter.
  //
  // ==========================================================

  double get investedPlusCrypto {
    final investedValue = model.invested;

    final invested = investedValue is num ? investedValue.toDouble() : 0.0;

    final safeInvested = !invested.isFinite || invested < 0 ? 0.0 : invested;

    return safeInvested + cryptoPatrimony;
  }

  // ==========================================================
  // LOAD
  // ==========================================================
  //
  // Compatibilidade para callers antigos.
  //
  // ==========================================================

  Future<void> load() async {
    await loadCached();
    await refreshFromRemote();
  }

  // ==========================================================
  // LOAD CACHED
  // ==========================================================
  //
  // Primeiro frame do Finance:
  //
  // - FinanceModel -> SQLite;
  // - cripto -> LocalStorage;
  // - histórico -> SQLite cache;
  // - objetivo -> SQLite cache;
  // - cotações -> SQLite cache.
  //
  // Nenhuma rede é necessária neste caminho.
  //
  // ==========================================================

  Future<void> loadCached() async {
    isLoading = true;

    try {
      if (kIsWeb) {
        // No Web, carregue a fonte remota já no primeiro carregamento.
        // Isso impede cache antigo/zerado do navegador de virar fonte de verdade.
        await financeController.refreshRemoteData();
      } else {
        await financeController.loadLocalData();
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        if (!kIsWeb) _cryptoBalanceService.loadBalances(),
        _persistenceService.loadCachedHistory(),
        _objectiveService.loadLocal(),
        cryptoPriceService.getCachedPricesBrl(),
      ]);

      var resultIndex = 0;

      if (kIsWeb) {
        balances = _webBalancesFromFinanceModel();
      } else {
        balances = results[resultIndex++] as CryptoBalances;
      }

      _applyHistory(results[resultIndex++] as List<InvestmentHistory>);

      _applyObjective(results[resultIndex++] as FinanceObjective?);

      final cachedPrices = Map<String, double>.from(
        results[resultIndex] as Map<String, double>,
      );

      if (cachedPrices.isNotEmpty) {
        cryptoPricesBrl = cachedPrices;

        cryptoController.setPrices(cryptoPricesBrl, notify: false);

        if (kIsWeb) {
          _applyWebCryptoPortfolioFromFinanceModel();
        } else {
          await cryptoController.loadPortfolio();
          await _syncNativeCryptoBalancesToFinanceData();
        }

        cryptoPricesLoaded = true;
        cryptoPriceError = null;
      }
    } finally {
      isLoading = false;
    }
  }

  // ==========================================================
  // REFRESH FROM REMOTE
  // ==========================================================
  //
  // Executado depois que a UI cacheada já está visível.
  //
  // ==========================================================

  Future<void> refreshFromRemote() async {
    if (isRefreshing) {
      return;
    }

    isRefreshing = true;

    try {
      await financeController.refreshRemoteData();

      if (kIsWeb) {
        balances = _webBalancesFromFinanceModel();
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _persistenceService.refreshHistory(),
        _objectiveService.refreshFromRemote(),
      ]);

      _applyHistory(results[0] as List<InvestmentHistory>);

      _applyObjective(results[1] as FinanceObjective?);

      await _refreshCryptoPricesFromRemote();
    } finally {
      isRefreshing = false;
    }
  }

  // ==========================================================
  // APPLY HISTORY
  // ==========================================================

  void _applyHistory(List<InvestmentHistory> storedHistory) {
    history
      ..clear()
      ..addAll(storedHistory);

    history.sort((first, second) {
      return first.date.compareTo(second.date);
    });
  }

  // ==========================================================
  // APPLY OBJECTIVE
  // ==========================================================

  void _applyObjective(FinanceObjective? objective) {
    if (objective == null) {
      return;
    }

    objectiveName = objective.name;
    model.investmentGoal = objective.targetValue;
  }

  // ==========================================================
  // LOAD CRYPTO PRICES
  // ==========================================================

  Future<void> _loadCryptoPrices() async {
    cryptoPriceError = null;

    try {
      final prices = await cryptoPriceService.refreshPricesBrl();

      cryptoPricesBrl = Map<String, double>.from(prices);

      cryptoController.setPrices(cryptoPricesBrl, notify: false);

      if (kIsWeb) {
        // No navegador, a fonte persistente das quantidades é finance_data.
        // Nunca reconstruir a carteira a partir do LocalStorage vazio.
        _applyWebCryptoPortfolioFromFinanceModel();
      } else {
        await cryptoController.loadPortfolio();
        await _syncNativeCryptoBalancesToFinanceData();
      }

      cryptoPricesLoaded = true;
    } catch (error, stackTrace) {
      cryptoPricesLoaded = false;

      cryptoPriceError = error.toString();

      // Mantém os saldos e demais dados financeiros
      // funcionando mesmo se a cotação falhar.
      //
      // Apenas o valor atual das criptos ficará zerado
      // até a próxima atualização.

      // ignore: avoid_print
      print(
        '[FINANCE][CRYPTO PRICE] '
        '$error',
      );

      // ignore: avoid_print
      print(stackTrace);
    }
  }

  Future<void> _refreshCryptoPricesFromRemote() async {
    await _loadCryptoPrices();
  }

  // ==========================================================
  // REFRESH CRYPTO PRICES
  // ==========================================================

  Future<void> refreshCryptoPrices() async {
    await _loadCryptoPrices();
  }

  // ==========================================================
  // LOAD OBJECTIVE
  // ==========================================================

  Future<void> loadObjective() async {
    final objective = await _objectiveService.load();

    if (objective == null) {
      objectiveName = 'Objetivo financeiro';

      return;
    }

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;
  }

  // ==========================================================
  // REFRESH CRYPTO
  // ==========================================================

  Future<void> refreshCryptoBalances() async {
    if (kIsWeb) {
      balances = _webBalancesFromFinanceModel();
      _applyWebCryptoPortfolioFromFinanceModel();
      return;
    }

    balances = await _cryptoBalanceService.loadBalances();

    await cryptoController.loadPortfolio();
    await _syncNativeCryptoBalancesToFinanceData();
  }

  // ==========================================================
  // REFRESH ALL CRYPTO
  // ==========================================================

  Future<void> refreshCrypto() async {
    await Future.wait([refreshCryptoBalances(), refreshCryptoPrices()]);
  }

  // ==========================================================
  // APPLY PLANNING
  // ==========================================================

  void applyPlanning(dynamic planning) {
    model.invested = planning.invested;

    model.minimumGoal = planning.minimumGoal;

    model.mediumGoal = planning.mediumGoal;

    model.maximumGoal = planning.maximumGoal;

    model.projectionYears = planning.projectionYears;

    model.monthlyGoal = planning.mediumGoal;
  }

  // ==========================================================
  // ADD CONTRIBUTION
  // ==========================================================

  InvestmentHistory addContribution(double contribution) {
    final entry = projection.createHistoryEntry(contribution: contribution);

    history.add(entry);

    history.sort((a, b) {
      return a.date.compareTo(b.date);
    });

    _contributionService.addContribution(
      model: model,
      contribution: contribution,
    );

    return entry;
  }

  // ==========================================================
  // REMOVE CONTRIBUTION
  // ==========================================================

  bool removeContribution(InvestmentHistory contribution) {
    final removed = history.remove(contribution);

    if (!removed) {
      return false;
    }

    _contributionService.removeContribution(
      model: model,
      contribution: contribution,
    );

    return true;
  }

  // ==========================================================
  // UPDATE PATRIMONY
  // ==========================================================

  void updatePatrimony(double value) {
    if (!value.isFinite || value < 0) {
      return;
    }

    model.patrimony = value;
  }

  // ==========================================================
  // UPDATE INVESTMENT GOAL - LOCAL
  // ==========================================================
  //
  // Mantido para compatibilidade com código antigo.
  //
  // Este método NÃO salva sozinho.
  //
  // Para salvar no Supabase, use:
  //
  // updateObjectiveValue(...)
  //
  // ==========================================================

  void updateInvestmentGoal(double value) {
    if (!value.isFinite || value < 0) {
      return;
    }

    model.investmentGoal = value;
  }

  // ==========================================================
  // UPDATE OBJECTIVE NAME
  // ==========================================================

  Future<FinanceObjective> updateObjectiveName(String name) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError('O nome do objetivo não pode ficar vazio.');
    }

    if (normalized.length > 60) {
      throw ArgumentError(
        'O nome do objetivo pode ter no máximo 60 caracteres.',
      );
    }

    final objective = await _objectiveService.save(
      name: normalized,
      targetValue: objectiveValue,
    );

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    return objective;
  }

  // ==========================================================
  // UPDATE OBJECTIVE VALUE
  // ==========================================================

  Future<FinanceObjective> updateObjectiveValue(double value) async {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError('O valor do objetivo é inválido.');
    }

    if (value <= 0) {
      throw ArgumentError('O valor do objetivo precisa ser maior que zero.');
    }

    final objective = await _objectiveService.save(
      name: objectiveName,
      targetValue: value,
    );

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    await saveModel();

    return objective;
  }

  // ==========================================================
  // UPDATE COMPLETE OBJECTIVE
  // ==========================================================

  Future<FinanceObjective> updateObjective({
    required String name,
    required double value,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError('O nome do objetivo não pode ficar vazio.');
    }

    if (normalizedName.length > 60) {
      throw ArgumentError(
        'O nome do objetivo pode ter no máximo 60 caracteres.',
      );
    }

    if (value.isNaN || value.isInfinite || value <= 0) {
      throw ArgumentError('O valor do objetivo é inválido.');
    }

    final objective = await _objectiveService.save(
      name: normalizedName,
      targetValue: value,
    );

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    await saveModel();

    return objective;
  }

  // ==========================================================
  // DELETE OBJECTIVE
  // ==========================================================

  Future<void> deleteObjective() async {
    await _objectiveService.delete();

    objectiveName = 'Objetivo financeiro';

    model.investmentGoal = 0;

    await saveModel();
  }

  // ==========================================================
  // OBJECTIVE EXISTS
  // ==========================================================

  Future<bool> objectiveExists() {
    return _objectiveService.exists();
  }

  // ==========================================================
  // SAVE MODEL
  // ==========================================================

  Future<void> saveModel() async {
    await financeController.saveData();
  }

  // ==========================================================
  // SAVE ALL
  // ==========================================================

  Future<void> saveAll() async {
    await _persistenceService.save(history: history);
  }
}
