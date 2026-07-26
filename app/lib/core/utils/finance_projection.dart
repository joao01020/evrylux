import '../../models/finance/finance_model.dart';
import '../../models/finance/investment_history.dart';

import 'finance_rhythm.dart';

class FinanceProjection {
  final FinanceModel model;
  final List<
    InvestmentHistory
  >
  history;

  late final FinanceRhythm rhythm;

  FinanceProjection({
    required this.model,
    this.history = const [],
  }) {
    rhythm = FinanceRhythm(
      model,
    );
  }

  // =========================================================
  // PLANEJAMENTO
  // =========================================================

  /// Quantidade total de meses definidos no planejamento.
  ///
  /// Exemplo:
  /// 10 anos = 120 meses.
  int get totalMonths {
    if (model.projectionYears <=
        0) {
      return 0;
    }

    return model.projectionYears *
        12;
  }

  /// Quanto um mês completo representa na barra.
  ///
  /// Retorna um valor entre 0 e 1.
  ///
  /// Exemplo:
  /// 120 meses:
  /// 1 / 120 = 0.00833
  double get monthlyProgress {
    if (totalMonths <=
        0) {
      return 0;
    }

    return 1 /
        totalMonths;
  }

  /// Quanto um mês representa em porcentagem.
  double get monthlyPercentage {
    return monthlyProgress *
        100;
  }

  // =========================================================
  // OBJETIVO FINANCEIRO
  // =========================================================

  /// Quanto ainda falta para atingir a meta final.
  double get missingMoney {
    final difference =
        model.investmentGoal -
        model.patrimony;

    if (difference <=
        0) {
      return 0;
    }

    return difference;
  }

  /// Verifica se o usuário atingiu o objetivo.
  bool get goalReached {
    if (model.investmentGoal <=
        0) {
      return false;
    }

    return model.patrimony >=
        model.investmentGoal;
  }

  /// Progresso financeiro real.
  ///
  /// Compara patrimônio atual com o objetivo.
  ///
  /// Retorna um valor entre 0 e 1.
  double get realFinancialProgress {
    if (model.investmentGoal <=
        0) {
      return 0;
    }

    final progress =
        model.patrimony /
        model.investmentGoal;

    return progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Progresso financeiro real em porcentagem.
  double get realFinancialPercentage {
    return realFinancialProgress *
        100;
  }

  // =========================================================
  // HISTÓRICO
  // =========================================================

  /// Quantidade de aportes registrados.
  int get contributionCount {
    return history.length;
  }

  /// Soma de todos os aportes.
  double get historyTotalValue {
    return history.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.value;
      },
    );
  }

  /// Média dos aportes realizados.
  double get averageContribution {
    if (history.isEmpty) {
      return 0;
    }

    return historyTotalValue /
        history.length;
  }

  /// Soma do progresso de objetivo registrado
  /// em todos os aportes.
  double get historyObjectiveProgress {
    final total =
        history.fold<
          double
        >(
          0,
          (
            progress,
            item,
          ) {
            return progress +
                item.objectiveProgress;
          },
        );

    return total
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Soma de toda redução de tempo registrada.
  double get historyTimeProgress {
    final total =
        history.fold<
          double
        >(
          0,
          (
            progress,
            item,
          ) {
            return progress +
                item.timeProgress;
          },
        );

    return total
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Último aporte registrado.
  InvestmentHistory? get lastContribution {
    if (history.isEmpty) {
      return null;
    }

    return history.last;
  }

  // =========================================================
  // BARRAS CONGRUENTES
  // =========================================================

  /// Barra do objetivo.
  ///
  /// Usa o maior valor entre:
  ///
  /// - progresso financeiro real;
  /// - progresso acumulado no histórico.
  ///
  /// Retorna entre 0 e 1.
  double get objectiveBar {
    final financial = realFinancialProgress;

    final historical = historyObjectiveProgress;

    final progress =
        financial >
            historical
        ? financial
        : historical;

    return progress
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Barra do objetivo em porcentagem.
  double get objectivePercentage {
    return objectiveBar *
        100;
  }

  /// Barra do tempo restante.
  ///
  /// É sempre o inverso da barra do objetivo.
  ///
  /// Objetivo 30%:
  /// tempo restante 70%.
  ///
  /// Objetivo 80%:
  /// tempo restante 20%.
  double get timeRemainingBar {
    return (1 -
            objectiveBar)
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Tempo restante em porcentagem.
  double get timeRemainingPercentage {
    return timeRemainingBar *
        100;
  }

  /// Tempo já conquistado.
  ///
  /// É igual à barra do objetivo.
  double get conqueredTimeBar {
    return objectiveBar;
  }

  /// Tempo conquistado em porcentagem.
  double get conqueredTimePercentage {
    return conqueredTimeBar *
        100;
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
  ///
  /// O avanço é baseado no:
  ///
  /// - tempo total do planejamento;
  /// - peso do aporte;
  /// - ritmo detectado.
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
  ///
  /// Deve ser sempre igual ao avanço da barra
  /// do objetivo.
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
    final future =
        objectiveBar +
        progressIncrement(
          contribution,
        );

    return future
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  /// Resultado da barra do tempo depois
  /// de registrar um novo aporte.
  double timeRemainingBarAfter(
    double contribution,
  ) {
    final futureObjective = objectiveBarAfter(
      contribution,
    );

    return (1 -
            futureObjective)
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
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
    if (monthlyContribution <=
        0) {
      return model.patrimony;
    }

    return model.patrimony +
        monthlyContribution *
            totalMonths;
  }

  /// Patrimônio previsto no ritmo tranquilo.
  double get tranquilFuturePatrimony {
    return futurePatrimony(
      model.minimumGoal,
    );
  }

  /// Patrimônio previsto no ritmo normal.
  double get normalFuturePatrimony {
    return futurePatrimony(
      model.mediumGoal,
    );
  }

  /// Patrimônio previsto no ritmo forte.
  double get strongFuturePatrimony {
    return futurePatrimony(
      model.maximumGoal,
    );
  }

  /// Percentual que o patrimônio futuro representa
  /// em relação ao objetivo.
  double futureObjectiveProgress(
    double monthlyContribution,
  ) {
    if (model.investmentGoal <=
        0) {
      return 0;
    }

    final future = futurePatrimony(
      monthlyContribution,
    );

    return (future /
            model.investmentGoal)
        .clamp(
          0.0,
          1.0,
        )
        .toDouble();
  }

  // =========================================================
  // TEMPO RESTANTE
  // =========================================================

  /// Quantos meses faltam para atingir o objetivo
  /// usando um aporte mensal específico.
  int remainingMonths(
    double monthlyContribution,
  ) {
    if (goalReached) {
      return 0;
    }

    if (monthlyContribution <=
        0) {
      return 0;
    }

    if (missingMoney <=
        0) {
      return 0;
    }

    return (missingMoney /
            monthlyContribution)
        .ceil();
  }

  /// Quantos anos inteiros faltam.
  int remainingYears(
    double monthlyContribution,
  ) {
    return remainingMonths(
          monthlyContribution,
        ) ~/
        12;
  }

  /// Quantos meses restam depois dos anos.
  int remainingExtraMonths(
    double monthlyContribution,
  ) {
    return remainingMonths(
          monthlyContribution,
        ) %
        12;
  }

  /// Previsão baseada na média real do histórico.
  int get estimatedRemainingMonths {
    if (goalReached) {
      return 0;
    }

    if (averageContribution >
        0) {
      return remainingMonths(
        averageContribution,
      );
    }

    if (model.minimumGoal >
        0) {
      return remainingMonths(
        model.minimumGoal,
      );
    }

    return totalMonths;
  }

  int get estimatedRemainingYears {
    return estimatedRemainingMonths ~/
        12;
  }

  int get estimatedRemainingExtraMonths {
    return estimatedRemainingMonths %
        12;
  }

  /// Tempo do ritmo tranquilo.
  int get tranquilRemainingMonths {
    return remainingMonths(
      model.minimumGoal,
    );
  }

  /// Tempo do ritmo normal.
  int get normalRemainingMonths {
    return remainingMonths(
      model.mediumGoal,
    );
  }

  /// Tempo do ritmo forte.
  int get strongRemainingMonths {
    return remainingMonths(
      model.maximumGoal,
    );
  }

  // =========================================================
  // TEXTOS DE TEMPO
  // =========================================================

  String estimatedTime(
    double monthlyContribution,
  ) {
    if (model.investmentGoal <=
        0) {
      return 'Defina um objetivo';
    }

    if (goalReached) {
      return 'Objetivo alcançado 🎉';
    }

    if (monthlyContribution <=
        0) {
      return 'Sem investimento';
    }

    final months = remainingMonths(
      monthlyContribution,
    );

    return formatMonths(
      months,
    );
  }

  String get estimatedRemainingTimeText {
    if (model.investmentGoal <=
        0) {
      return 'Defina um objetivo';
    }

    if (goalReached) {
      return 'Objetivo alcançado 🎉';
    }

    if (estimatedRemainingMonths <=
        0) {
      return 'Sem previsão';
    }

    return formatMonths(
      estimatedRemainingMonths,
    );
  }

  String get tranquilTimeText {
    return estimatedTime(
      model.minimumGoal,
    );
  }

  String get normalTimeText {
    return estimatedTime(
      model.mediumGoal,
    );
  }

  String get strongTimeText {
    return estimatedTime(
      model.maximumGoal,
    );
  }

  // =========================================================
  // DATAS DE CONCLUSÃO
  // =========================================================

  DateTime estimatedDate(
    double monthlyContribution,
  ) {
    final months = remainingMonths(
      monthlyContribution,
    );

    return addMonths(
      DateTime.now(),
      months,
    );
  }

  DateTime get estimatedCompletionDate {
    return addMonths(
      DateTime.now(),
      estimatedRemainingMonths,
    );
  }

  DateTime get tranquilCompletionDate {
    return estimatedDate(
      model.minimumGoal,
    );
  }

  DateTime get normalCompletionDate {
    return estimatedDate(
      model.mediumGoal,
    );
  }

  DateTime get strongCompletionDate {
    return estimatedDate(
      model.maximumGoal,
    );
  }

  // =========================================================
  // TEMPO CONQUISTADO
  // =========================================================

  /// Compara o aporte atual com o ritmo tranquilo.
  ///
  /// Retorna quantos meses o usuário economizou.
  int savedMonthsComparedToTranquil(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return 0;
    }

    if (model.minimumGoal <=
        0) {
      return 0;
    }

    final tranquilMonths = remainingMonths(
      model.minimumGoal,
    );

    final contributionMonths = remainingMonths(
      contribution,
    );

    final difference =
        tranquilMonths -
        contributionMonths;

    if (difference <=
        0) {
      return 0;
    }

    return difference;
  }

  /// Anos economizados em relação ao ritmo tranquilo.
  double savedYears(
    double contribution,
  ) {
    return savedMonthsComparedToTranquil(
          contribution,
        ) /
        12;
  }

  String savedTimeText(
    double contribution,
  ) {
    final months = savedMonthsComparedToTranquil(
      contribution,
    );

    if (months <=
        0) {
      return 'Você manteve seu caminho ativo.';
    }

    return 'Você conquistou aproximadamente ${formatMonths(months)}.';
  }

  // =========================================================
  // FEEDBACK
  // =========================================================

  String contributionTitle(
    double contribution,
  ) {
    final detected = detectRhythm(
      contribution,
    );

    switch (detected) {
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

  String contributionFeedback(
    double contribution,
  ) {
    if (contribution <=
        0) {
      return rhythm.feedback(
        contribution,
      );
    }

    final rhythmFeedback = rhythm.feedback(
      contribution,
    );

    final savedTime = savedTimeText(
      contribution,
    );

    return '$rhythmFeedback\n$savedTime';
  }

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

  String formatMonths(
    int totalMonths,
  ) {
    if (totalMonths <=
        0) {
      return 'Objetivo alcançado';
    }

    final years =
        totalMonths ~/
        12;

    final months =
        totalMonths %
        12;

    if (years ==
        0) {
      if (months ==
          1) {
        return '1 mês';
      }

      return '$months meses';
    }

    if (months ==
        0) {
      if (years ==
          1) {
        return '1 ano';
      }

      return '$years anos';
    }

    final yearText =
        years ==
            1
        ? '1 ano'
        : '$years anos';

    final monthText =
        months ==
            1
        ? '1 mês'
        : '$months meses';

    return '$yearText e $monthText';
  }

  String formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${date.year}';
  }

  /// Adiciona meses mantendo uma data válida.
  ///
  /// Exemplo:
  /// adicionar um mês em 31/01 resulta no último
  /// dia válido de fevereiro.
  DateTime addMonths(
    DateTime date,
    int monthsToAdd,
  ) {
    if (monthsToAdd <=
        0) {
      return date;
    }

    final monthIndex =
        date.month -
        1 +
        monthsToAdd;

    final year =
        date.year +
        monthIndex ~/
            12;

    final month =
        monthIndex %
            12 +
        1;

    final lastDayOfMonth = DateTime(
      year,
      month +
          1,
      0,
    ).day;

    final validDay =
        date.day >
            lastDayOfMonth
        ? lastDayOfMonth
        : date.day;

    return DateTime(
      year,
      month,
      validDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }
}
