class FinanceModel {
  /// Patrimônio atual
  double patrimony;

  /// Valor investido
  double invested;

  /// Meta mensal de investimento
  double monthlyGoal;

  /// Meta de patrimônio
  double investmentGoal;

  double bitcoin;

  double ethereum;

  double solana;

  double usdt;

  List<
    bool
  >
  completedDays;

  String? selectedDay;

  FinanceModel({
    this.patrimony = 0.0,
    this.invested = 0.0,
    this.monthlyGoal = 0.0,
    this.investmentGoal = 0.0,
    this.bitcoin = 0.0,
    this.ethereum = 0.0,
    this.solana = 0.0,
    this.usdt = 0.0,
    List<
      bool
    >?
    completedDays,
    this.selectedDay,
  }) : completedDays =
           completedDays ??
           List.filled(
             7,
             false,
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
          List.filled(
            7,
            false,
          ),

      selectedDay: json["selectedDay"],
    );
  }
}
