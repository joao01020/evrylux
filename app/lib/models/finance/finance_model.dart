class FinanceModel {
  /// Patrimônio atual
  double patrimony;

  /// Valor investido atualmente
  double invested;

  /// Mantido por compatibilidade
  double monthlyGoal;

  /// Objetivo final de patrimônio
  double investmentGoal;

  // ===============================
  // Planejamento
  // ===============================

  /// Meta mensal mínima
  double minimumGoal;

  /// Meta mensal média
  double mediumGoal;

  /// Meta mensal máxima
  double maximumGoal;

  /// Tempo desejado para atingir o objetivo
  int projectionYears;

  // ===============================
  // Evolução
  // ===============================

  /// Quanto foi aportado até hoje
  double totalInvested;

  /// Quantos meses possuem aporte registrado
  int investedMonths;

  /// Média real dos aportes
  double averageContribution;

  // ===============================
  // Criptomoedas
  // ===============================

  double bitcoin;

  double ethereum;

  double solana;

  double usdt;

  // ===============================
  // Outros
  // ===============================

  List<
    bool
  >
  completedDays;

  String? selectedDay;

  FinanceModel({
    this.patrimony = 0,
    this.invested = 0,
    this.monthlyGoal = 0,
    this.investmentGoal = 0,

    this.minimumGoal = 0,
    this.mediumGoal = 0,
    this.maximumGoal = 0,

    this.projectionYears = 10,

    this.totalInvested = 0,
    this.investedMonths = 0,
    this.averageContribution = 0,

    this.bitcoin = 0,
    this.ethereum = 0,
    this.solana = 0,
    this.usdt = 0,

    List<
      bool
    >?
    completedDays,
    this.selectedDay,
  }) : completedDays =
           completedDays ??
           List.generate(
             7,
             (
               _,
             ) => false,
           );

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      "patrimony": patrimony,
      "invested": invested,
      "monthlyGoal": monthlyGoal,
      "investmentGoal": investmentGoal,

      "minimumGoal": minimumGoal,
      "mediumGoal": mediumGoal,
      "maximumGoal": maximumGoal,

      "projectionYears": projectionYears,

      "totalInvested": totalInvested,
      "investedMonths": investedMonths,
      "averageContribution": averageContribution,

      "bitcoin": bitcoin,
      "ethereum": ethereum,
      "solana": solana,
      "usdt": usdt,

      "completedDays": completedDays,
      "selectedDay": selectedDay,
    };
  }

  factory FinanceModel.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return FinanceModel(
      patrimony:
          (json["patrimony"] ??
                  0)
              .toDouble(),

      invested:
          (json["invested"] ??
                  0)
              .toDouble(),

      monthlyGoal:
          (json["monthlyGoal"] ??
                  0)
              .toDouble(),

      investmentGoal:
          (json["investmentGoal"] ??
                  0)
              .toDouble(),

      minimumGoal:
          (json["minimumGoal"] ??
                  0)
              .toDouble(),

      mediumGoal:
          (json["mediumGoal"] ??
                  0)
              .toDouble(),

      maximumGoal:
          (json["maximumGoal"] ??
                  0)
              .toDouble(),

      projectionYears:
          json["projectionYears"] ??
          10,

      totalInvested:
          (json["totalInvested"] ??
                  0)
              .toDouble(),

      investedMonths:
          json["investedMonths"] ??
          0,

      averageContribution:
          (json["averageContribution"] ??
                  0)
              .toDouble(),

      bitcoin:
          (json["bitcoin"] ??
                  0)
              .toDouble(),

      ethereum:
          (json["ethereum"] ??
                  0)
              .toDouble(),

      solana:
          (json["solana"] ??
                  0)
              .toDouble(),

      usdt:
          (json["usdt"] ??
                  0)
              .toDouble(),

      completedDays:
          (json["completedDays"]
                  as List?)
              ?.map(
                (
                  e,
                ) =>
                    e
                        as bool,
              )
              .toList() ??
          List.generate(
            7,
            (
              _,
            ) => false,
          ),

      selectedDay: json["selectedDay"],
    );
  }
}
