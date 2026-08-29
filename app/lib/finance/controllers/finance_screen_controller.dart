import '../projections/finance_projection.dart';

import '../services/history/investment_history.dart';

import '../models/crypto/crypto_balances.dart';

import '../services/crypto/crypto_balance_service.dart';

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
// Supabase / Storage
//
// A tela NÃO deve acessar Supabase diretamente.
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

  final FinanceContributionService _contributionService = const FinanceContributionService();

  late final CryptoBalanceService _cryptoBalanceService;

  late final FinancePersistenceService _persistenceService;

  late final FinanceObjectiveService _objectiveService;

  // ==========================================================
  // HISTORY
  // ==========================================================

  final List<
    InvestmentHistory
  >
  history = [];

  // ==========================================================
  // CRYPTO
  // ==========================================================

  CryptoBalances balances = const CryptoBalances();

  // ==========================================================
  // OBJECTIVE
  // ==========================================================

  String objectiveName = 'Objetivo financeiro';

  // ==========================================================
  // LOADING
  // ==========================================================

  bool isLoading = true;

  // ==========================================================
  // CONSTRUCTOR
  // ==========================================================

  FinanceScreenController({
    required this.financeController,
    required this.cryptoController,
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

    _objectiveService =
        objectiveService ??
        FinanceObjectiveService();
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
    return FinanceProjection(
      model: model,
      history: history,
    );
  }

  // ==========================================================
  // OBJECTIVE VALUE
  // ==========================================================

  double get objectiveValue {
    final value = model.investmentGoal;

    if (value
        is num) {
      return value.toDouble();
    }

    return 0;
  }

  // ==========================================================
  // HAS OBJECTIVE
  // ==========================================================

  bool get hasObjective {
    return objectiveValue >
        0;
  }

  // ==========================================================
  // LOAD
  // ==========================================================

  Future<
    void
  >
  load() async {
    isLoading = true;

    try {
      // ======================================================
      // FINANCE MODEL
      // ======================================================
      //
      // Carregamos primeiro o model principal.
      //
      // Depois carregamos o objetivo.
      //
      // Caso exista um objetivo salvo no Supabase,
      // target_value terá prioridade sobre o valor legado.
      // ======================================================

      await financeController.loadData();

      // ======================================================
      // DADOS COMPLEMENTARES
      // ======================================================

      final results =
          await Future.wait<
            dynamic
          >(
            [
              _cryptoBalanceService.loadBalances(),

              _persistenceService.loadHistory(),

              _objectiveService.load(),
            ],
          );

      // ======================================================
      // CRYPTO
      // ======================================================

      balances =
          results[0]
              as CryptoBalances;

      // ======================================================
      // HISTORY
      // ======================================================

      final storedHistory =
          results[1]
              as List<
                InvestmentHistory
              >;

      history
        ..clear()
        ..addAll(
          storedHistory,
        );

      // ======================================================
      // OBJECTIVE
      // ======================================================

      final objective =
          results[2]
              as FinanceObjective?;

      if (objective !=
          null) {
        objectiveName = objective.name;

        model.investmentGoal = objective.targetValue;
      }
    } finally {
      isLoading = false;
    }
  }

  // ==========================================================
  // LOAD OBJECTIVE
  // ==========================================================

  Future<
    void
  >
  loadObjective() async {
    final objective = await _objectiveService.load();

    if (objective ==
        null) {
      objectiveName = 'Objetivo financeiro';

      return;
    }

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;
  }

  // ==========================================================
  // REFRESH CRYPTO
  // ==========================================================

  Future<
    void
  >
  refreshCryptoBalances() async {
    balances = await _cryptoBalanceService.loadBalances();
  }

  // ==========================================================
  // APPLY PLANNING
  // ==========================================================

  void applyPlanning(
    dynamic planning,
  ) {
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

  InvestmentHistory addContribution(
    double contribution,
  ) {
    final entry = projection.createHistoryEntry(
      contribution: contribution,
    );

    history.add(
      entry,
    );

    history.sort(
      (
        a,
        b,
      ) {
        return a.date.compareTo(
          b.date,
        );
      },
    );

    _contributionService.addContribution(
      model: model,
      contribution: contribution,
    );

    return entry;
  }

  // ==========================================================
  // REMOVE CONTRIBUTION
  // ==========================================================

  bool removeContribution(
    InvestmentHistory contribution,
  ) {
    final removed = history.remove(
      contribution,
    );

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

  void updatePatrimony(
    double value,
  ) {
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

  void updateInvestmentGoal(
    double value,
  ) {
    model.investmentGoal = value;
  }

  // ==========================================================
  // UPDATE OBJECTIVE NAME
  // ==========================================================

  Future<
    FinanceObjective
  >
  updateObjectiveName(
    String name,
  ) async {
    final normalized = name.trim();

    if (normalized.isEmpty) {
      throw ArgumentError(
        'O nome do objetivo não pode ficar vazio.',
      );
    }

    if (normalized.length >
        60) {
      throw ArgumentError(
        'O nome do objetivo pode ter no máximo 60 caracteres.',
      );
    }

    // ========================================================
    // SAVE SUPABASE
    // ========================================================

    final objective = await _objectiveService.save(
      name: normalized,
      targetValue: objectiveValue,
    );

    // ========================================================
    // UPDATE LOCAL STATE
    // ========================================================

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    return objective;
  }

  // ==========================================================
  // UPDATE OBJECTIVE VALUE
  // ==========================================================

  Future<
    FinanceObjective
  >
  updateObjectiveValue(
    double value,
  ) async {
    // ========================================================
    // VALIDATION
    // ========================================================

    if (value.isNaN ||
        value.isInfinite) {
      throw ArgumentError(
        'O valor do objetivo é inválido.',
      );
    }

    if (value <=
        0) {
      throw ArgumentError(
        'O valor do objetivo precisa ser maior que zero.',
      );
    }

    // ========================================================
    // SAVE OBJECTIVE
    // ========================================================

    final objective = await _objectiveService.save(
      name: objectiveName,
      targetValue: value,
    );

    // ========================================================
    // UPDATE MODEL
    // ========================================================

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    // ========================================================
    // SAVE LEGACY FINANCE MODEL
    // ========================================================
    //
    // investmentGoal ainda é usado pelo restante do Finance.
    //
    // Portanto mantemos o model financeiro principal
    // sincronizado.
    // ========================================================

    await saveModel();

    return objective;
  }

  // ==========================================================
  // UPDATE COMPLETE OBJECTIVE
  // ==========================================================

  Future<
    FinanceObjective
  >
  updateObjective({
    required String name,
    required double value,
  }) async {
    final normalizedName = name.trim();

    if (normalizedName.isEmpty) {
      throw ArgumentError(
        'O nome do objetivo não pode ficar vazio.',
      );
    }

    if (normalizedName.length >
        60) {
      throw ArgumentError(
        'O nome do objetivo pode ter no máximo 60 caracteres.',
      );
    }

    if (value.isNaN ||
        value.isInfinite ||
        value <=
            0) {
      throw ArgumentError(
        'O valor do objetivo é inválido.',
      );
    }

    // ========================================================
    // SUPABASE
    // ========================================================

    final objective = await _objectiveService.save(
      name: normalizedName,
      targetValue: value,
    );

    // ========================================================
    // LOCAL STATE
    // ========================================================

    objectiveName = objective.name;

    model.investmentGoal = objective.targetValue;

    // ========================================================
    // LEGACY MODEL
    // ========================================================

    await saveModel();

    return objective;
  }

  // ==========================================================
  // DELETE OBJECTIVE
  // ==========================================================

  Future<
    void
  >
  deleteObjective() async {
    await _objectiveService.delete();

    objectiveName = 'Objetivo financeiro';

    model.investmentGoal = 0;

    await saveModel();
  }

  // ==========================================================
  // OBJECTIVE EXISTS
  // ==========================================================

  Future<
    bool
  >
  objectiveExists() {
    return _objectiveService.exists();
  }

  // ==========================================================
  // SAVE MODEL
  // ==========================================================

  Future<
    void
  >
  saveModel() async {
    await financeController.saveData();
  }

  // ==========================================================
  // SAVE ALL
  // ==========================================================

  Future<
    void
  >
  saveAll() async {
    await _persistenceService.save(
      history: history,
    );
  }
}
