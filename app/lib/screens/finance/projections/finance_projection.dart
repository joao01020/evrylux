import 'finance_rhythm.dart';
import '../models/finance_model.dart';
import '../services/history/investment_history.dart';

import 'finance_projection_calculator.dart';

class FinanceProjection {
  final FinanceModel model;
  final List<
    InvestmentHistory
  >
  history;

  late final FinanceRhythm rhythm;
  late final FinanceProjectionCalculator calculator;

  FinanceProjection({
    required this.model,
    this.history = const [],
  }) {
    rhythm = FinanceRhythm(
      model,
    );

    calculator = FinanceProjectionCalculator(
      model: model,
      history: history,
    );
  }

  // =========================================================
  // PLANEJAMENTO
  // =========================================================

  /// Quantidade total de meses definidos no planejamento.
  int get totalMonths {
    return calculator.totalMonths;
  }

  /// Quanto um mês completo representa na barra.
  double get monthlyProgress {
    return calculator.monthlyProgress;
  }

  /// Quanto um mês representa em porcentagem.
  double get monthlyPercentage {
    return calculator.monthlyPercentage;
  }

  // =========================================================
  // OBJETIVO FINANCEIRO
  // =========================================================

  /// Quanto ainda falta para atingir a meta final.
  double get missingMoney {
    return calculator.missingMoney;
  }

  /// Verifica se o usuário atingiu o objetivo.
  bool get goalReached {
    return calculator.goalReached;
  }

  /// Progresso financeiro real entre 0 e 1.
  double get realFinancialProgress {
    return calculator.realFinancialProgress;
  }

  /// Progresso financeiro real em porcentagem.
  double get realFinancialPercentage {
    return calculator.realFinancialPercentage;
  }

  // =========================================================
  // HISTÓRICO
  // =========================================================

  /// Quantidade de aportes registrados.
  int get contributionCount {
    return calculator.contributionCount;
  }

  /// Soma de todos os aportes registrados.
  double get historyTotalValue {
    return calculator.historyTotalValue;
  }

  /// Média dos aportes realizados.
  double get averageContribution {
    return calculator.averageContribution;
  }

  /// Soma do progresso do objetivo registrado
  /// em todos os aportes.
  double get historyObjectiveProgress {
    return calculator.historyObjectiveProgress;
  }

  /// Soma de toda redução de tempo registrada.
  double get historyTimeProgress {
    return calculator.historyTimeProgress;
  }

  /// Último aporte registrado.
  InvestmentHistory? get lastContribution {
    return calculator.lastContribution;
  }

  // =========================================================
  // BARRAS CONGRUENTES
  // =========================================================

  /// Barra atual do objetivo entre 0 e 1.
  double get objectiveBar {
    return calculator.objectiveBar;
  }

  /// Barra do objetivo em porcentagem.
  double get objectivePercentage {
    return calculator.objectivePercentage;
  }

  /// Barra do tempo restante entre 0 e 1.
  double get timeRemainingBar {
    return calculator.timeRemainingBar;
  }

  /// Tempo restante em porcentagem.
  double get timeRemainingPercentage {
    return calculator.timeRemainingPercentage;
  }

  /// Tempo já conquistado entre 0 e 1.
  double get conqueredTimeBar {
    return calculator.conqueredTimeBar;
  }

  /// Tempo conquistado em porcentagem.
  double get conqueredTimePercentage {
    return calculator.conqueredTimePercentage;
  }

  // =========================================================
  // CÁLCULO DO APORTE
  // =========================================================

  /// Descobre o ritmo automaticamente.
  String detectRhythm(
    double contribution,
  ) {
    return rhythm.detect(
      contribution,
    );
  }

  /// Calcula o peso do aporte.
  ///
  /// Retorna um valor entre 0 e 1.
  double contributionWeight(
    double contribution,
  ) {
    return rhythm.weight(
      contribution,
    );
  }

  /// Calcula quanto um aporte avançará na barra.
  double progressIncrement(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return 0;
    }

    if (totalMonths <=
        0) {
      return 0;
    }

    final weight = contributionWeight(
      contribution,
    );

    final increment =
        monthlyProgress *
        weight;

    return increment
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Avanço do aporte em porcentagem.
  double progressIncrementPercentage(
    double contribution,
  ) {
    return progressIncrement(
          contribution,
        ) *
        100;
  }

  /// Quanto a barra de tempo diminuirá.
  double timeReduction(
    double contribution,
  ) {
    return progressIncrement(
      contribution,
    );
  }

  /// Resultado da barra do objetivo depois
  /// de registrar um novo aporte.
  double objectiveBarAfter(
    double contribution,
  ) {
    final increment = progressIncrement(
      contribution,
    );

    return calculator.objectiveBarAfterIncrement(
      increment,
    );
  }

  /// Resultado da barra do tempo restante depois
  /// de registrar um novo aporte.
  double timeRemainingBarAfter(
    double contribution,
  ) {
    final increment = progressIncrement(
      contribution,
    );

    return calculator.timeRemainingBarAfterIncrement(
      increment,
    );
  }

  // =========================================================
  // CRIAÇÃO DO HISTÓRICO
  // =========================================================

  /// Cria um registro completo do aporte.
  InvestmentHistory createHistoryEntry({
    required double contribution,
    DateTime? date,
  }) {
    final safeContribution =
        contribution <
            0
        ? 0.0
        : contribution;

    final increment = progressIncrement(
      safeContribution,
    );

    return InvestmentHistory(
      value: safeContribution,
      date:
          date ??
          DateTime.now(),
      rhythm: detectRhythm(
        safeContribution,
      ),
      objectiveProgress: increment,
      timeProgress: increment,
    );
  }

  // =========================================================
  // PATRIMÔNIO FUTURO
  // =========================================================

  /// Patrimônio previsto ao final do planejamento,
  /// considerando um aporte mensal fixo.
  double futurePatrimony(
    double monthlyContribution,
  ) {
    return calculator.futurePatrimony(
      monthlyContribution,
    );
  }

  /// Patrimônio previsto no ritmo tranquilo.
  double get tranquilFuturePatrimony {
    return calculator.tranquilFuturePatrimony;
  }

  /// Patrimônio previsto no ritmo normal.
  double get normalFuturePatrimony {
    return calculator.normalFuturePatrimony;
  }

  /// Patrimônio previsto no ritmo forte.
  double get strongFuturePatrimony {
    return calculator.strongFuturePatrimony;
  }

  /// Percentual que o patrimônio futuro representa
  /// em relação ao objetivo.
  double futureObjectiveProgress(
    double monthlyContribution,
  ) {
    return calculator.futureObjectiveProgress(
      monthlyContribution,
    );
  }

  // =========================================================
  // TEMPO RESTANTE
  // =========================================================

  /// Quantos meses faltam para atingir o objetivo
  /// usando um aporte mensal específico.
  int remainingMonths(
    double monthlyContribution,
  ) {
    return calculator.remainingMonths(
      monthlyContribution,
    );
  }

  /// Quantos anos inteiros faltam.
  int remainingYears(
    double monthlyContribution,
  ) {
    return calculator.remainingYears(
      monthlyContribution,
    );
  }

  /// Quantos meses restam depois dos anos inteiros.
  int remainingExtraMonths(
    double monthlyContribution,
  ) {
    return calculator.remainingExtraMonths(
      monthlyContribution,
    );
  }

  /// Previsão baseada na média real do histórico.
  int get estimatedRemainingMonths {
    return calculator.estimatedRemainingMonths;
  }

  /// Quantidade de anos inteiros da previsão estimada.
  int get estimatedRemainingYears {
    return calculator.estimatedRemainingYears;
  }

  /// Quantidade de meses extras da previsão estimada.
  int get estimatedRemainingExtraMonths {
    return calculator.estimatedRemainingExtraMonths;
  }

  /// Tempo do ritmo tranquilo.
  int get tranquilRemainingMonths {
    return calculator.tranquilRemainingMonths;
  }

  /// Tempo do ritmo normal.
  int get normalRemainingMonths {
    return calculator.normalRemainingMonths;
  }

  /// Tempo do ritmo forte.
  int get strongRemainingMonths {
    return calculator.strongRemainingMonths;
  }

  // =========================================================
  // TEXTOS DE TEMPO
  // =========================================================

  /// Retorna a previsão de tempo usando
  /// um aporte mensal específico.
  String estimatedTime(
    double monthlyContribution,
  ) {
    return calculator.estimatedTime(
      monthlyContribution,
    );
  }

  /// Texto da previsão baseada no histórico.
  String get estimatedRemainingTimeText {
    return calculator.estimatedRemainingTimeText;
  }

  /// Texto do tempo no ritmo tranquilo.
  String get tranquilTimeText {
    return calculator.tranquilTimeText;
  }

  /// Texto do tempo no ritmo normal.
  String get normalTimeText {
    return calculator.normalTimeText;
  }

  /// Texto do tempo no ritmo forte.
  String get strongTimeText {
    return calculator.strongTimeText;
  }

  // =========================================================
  // DATAS DE CONCLUSÃO
  // =========================================================

  /// Data prevista usando um aporte mensal específico.
  DateTime estimatedDate(
    double monthlyContribution, {
    DateTime? referenceDate,
  }) {
    return calculator.estimatedDate(
      monthlyContribution,
      referenceDate: referenceDate,
    );
  }

  /// Data prevista baseada no histórico.
  ///
  /// Mantido como getter para não quebrar o código existente.
  DateTime get estimatedCompletionDate {
    return calculator.estimatedCompletionDate();
  }

  /// Data prevista no ritmo tranquilo.
  ///
  /// Mantido como getter para não quebrar o código existente.
  DateTime get tranquilCompletionDate {
    return calculator.tranquilCompletionDate();
  }

  /// Data prevista no ritmo normal.
  ///
  /// Mantido como getter para não quebrar o código existente.
  DateTime get normalCompletionDate {
    return calculator.normalCompletionDate();
  }

  /// Data prevista no ritmo forte.
  ///
  /// Mantido como getter para não quebrar o código existente.
  DateTime get strongCompletionDate {
    return calculator.strongCompletionDate();
  }

  // =========================================================
  // TEMPO CONQUISTADO
  // =========================================================

  /// Compara o aporte informado com o ritmo tranquilo.
  int savedMonthsComparedToTranquil(
    double contribution,
  ) {
    return calculator.savedMonthsComparedToTranquil(
      contribution,
    );
  }

  /// Anos economizados em relação ao ritmo tranquilo.
  double savedYears(
    double contribution,
  ) {
    return calculator.savedYears(
      contribution,
    );
  }

  /// Texto sobre o tempo conquistado.
  String savedTimeText(
    double contribution,
  ) {
    return calculator.savedTimeText(
      contribution,
    );
  }

  // =========================================================
  // FEEDBACK
  // =========================================================

  /// Título correspondente ao ritmo do aporte.
  String contributionTitle(
    double contribution,
  ) {
    final detectedRhythm = detectRhythm(
      contribution,
    );

    switch (detectedRhythm) {
      case 'Tranquilo':
        return 'Ritmo tranquilo';

      case 'Normal':
        return 'Ritmo normal';

      case 'Forte':
        return 'Ritmo forte';

      case 'Personalizado':
        return 'Ritmo personalizado';

      default:
        return 'Sem aporte';
    }
  }

  /// Retorna o feedback completo do aporte.
  String contributionFeedback(
    double contribution,
  ) {
    final rhythmFeedback = rhythm.feedback(
      contribution,
    );

    if (contribution <=
        0) {
      return rhythmFeedback;
    }

    final savedTime = savedTimeText(
      contribution,
    );

    return '$rhythmFeedback\n$savedTime';
  }

  /// Atalho para o feedback completo.
  String feedback(
    double contribution,
  ) {
    return contributionFeedback(
      contribution,
    );
  }

  // =========================================================
  // FORMATAÇÃO
  // =========================================================

  /// Converte uma quantidade de meses em texto.
  String formatMonths(
    int totalMonths,
  ) {
    return calculator.formatMonths(
      totalMonths,
    );
  }

  /// Converte uma data para o formato DD/MM/AAAA.
  String formatDate(
    DateTime date,
  ) {
    return calculator.formatDate(
      date,
    );
  }

  /// Adiciona meses mantendo uma data válida.
  DateTime addMonths(
    DateTime date,
    int monthsToAdd,
  ) {
    return calculator.addMonths(
      date,
      monthsToAdd,
    );
  }
}
