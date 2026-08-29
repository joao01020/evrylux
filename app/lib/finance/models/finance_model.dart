class FinanceModel {
  // ============================================================
  // PATRIMÔNIO
  // ============================================================

  /// Patrimônio atual
  double patrimony;

  /// Valor investido atualmente
  double invested;

  /// Mantido por compatibilidade
  double monthlyGoal;

  /// Objetivo final de patrimônio
  double investmentGoal;

  // ============================================================
  // PLANEJAMENTO
  // ============================================================

  /// Meta mensal mínima
  double minimumGoal;

  /// Meta mensal média
  double mediumGoal;

  /// Meta mensal máxima
  double maximumGoal;

  /// Tempo desejado para atingir o objetivo
  int projectionYears;

  // ============================================================
  // EVOLUÇÃO
  // ============================================================

  /// Quanto foi aportado até hoje
  double totalInvested;

  /// Quantos meses possuem aporte registrado
  int investedMonths;

  /// Média real dos aportes
  double averageContribution;

  // ============================================================
  // CRIPTOMOEDAS
  // ============================================================

  double bitcoin;

  double ethereum;

  double solana;

  double usdt;

  // ============================================================
  // OUTROS
  // ============================================================

  List<
    bool
  >
  completedDays;

  String? selectedDay;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

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
           List<
             bool
           >.filled(
             7,
             false,
           );

  // ============================================================
  // CRYPTO QUANTITY
  // ============================================================

  double cryptoQuantity(
    String symbol,
  ) {
    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
      case 'BITCOIN':
        return bitcoin;

      case 'ETH':
      case 'ETHEREUM':
        return ethereum;

      case 'SOL':
      case 'SOLANA':
        return solana;

      case 'USDT':
      case 'TETHER':
        return usdt;

      default:
        return 0;
    }
  }

  // ============================================================
  // UPDATE CRYPTO
  // ============================================================

  void updateCrypto({
    required String symbol,
    required double value,
  }) {
    if (!value.isFinite ||
        value <
            0) {
      throw ArgumentError.value(
        value,
        'value',
        'O saldo da criptomoeda deve ser maior ou igual a zero.',
      );
    }

    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
      case 'BITCOIN':
        bitcoin = value;
        break;

      case 'ETH':
      case 'ETHEREUM':
        ethereum = value;
        break;

      case 'SOL':
      case 'SOLANA':
        solana = value;
        break;

      case 'USDT':
      case 'TETHER':
        usdt = value;
        break;

      default:
        throw ArgumentError.value(
          symbol,
          'symbol',
          'Criptomoeda não suportada.',
        );
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  FinanceModel copyWith({
    double? patrimony,
    double? invested,
    double? monthlyGoal,
    double? investmentGoal,
    double? minimumGoal,
    double? mediumGoal,
    double? maximumGoal,
    int? projectionYears,
    double? totalInvested,
    int? investedMonths,
    double? averageContribution,
    double? bitcoin,
    double? ethereum,
    double? solana,
    double? usdt,
    List<
      bool
    >?
    completedDays,
    String? selectedDay,
    bool clearSelectedDay = false,
  }) {
    return FinanceModel(
      patrimony:
          patrimony ??
          this.patrimony,
      invested:
          invested ??
          this.invested,
      monthlyGoal:
          monthlyGoal ??
          this.monthlyGoal,
      investmentGoal:
          investmentGoal ??
          this.investmentGoal,
      minimumGoal:
          minimumGoal ??
          this.minimumGoal,
      mediumGoal:
          mediumGoal ??
          this.mediumGoal,
      maximumGoal:
          maximumGoal ??
          this.maximumGoal,
      projectionYears:
          projectionYears ??
          this.projectionYears,
      totalInvested:
          totalInvested ??
          this.totalInvested,
      investedMonths:
          investedMonths ??
          this.investedMonths,
      averageContribution:
          averageContribution ??
          this.averageContribution,
      bitcoin:
          bitcoin ??
          this.bitcoin,
      ethereum:
          ethereum ??
          this.ethereum,
      solana:
          solana ??
          this.solana,
      usdt:
          usdt ??
          this.usdt,
      completedDays:
          completedDays !=
              null
          ? List<
              bool
            >.from(
              completedDays,
            )
          : List<
              bool
            >.from(
              this.completedDays,
            ),
      selectedDay: clearSelectedDay
          ? null
          : selectedDay ??
                this.selectedDay,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'patrimony': patrimony,
      'invested': invested,
      'monthlyGoal': monthlyGoal,
      'investmentGoal': investmentGoal,
      'minimumGoal': minimumGoal,
      'mediumGoal': mediumGoal,
      'maximumGoal': maximumGoal,
      'projectionYears': projectionYears,
      'totalInvested': totalInvested,
      'investedMonths': investedMonths,
      'averageContribution': averageContribution,
      'bitcoin': bitcoin,
      'ethereum': ethereum,
      'solana': solana,
      'usdt': usdt,
      'completedDays':
          List<
            bool
          >.from(
            completedDays,
          ),
      'selectedDay': selectedDay,
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory FinanceModel.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return FinanceModel(
      patrimony: _toDouble(
        json['patrimony'],
      ),
      invested: _toDouble(
        json['invested'],
      ),
      monthlyGoal: _toDouble(
        json['monthlyGoal'],
      ),
      investmentGoal: _toDouble(
        json['investmentGoal'],
      ),
      minimumGoal: _toDouble(
        json['minimumGoal'],
      ),
      mediumGoal: _toDouble(
        json['mediumGoal'],
      ),
      maximumGoal: _toDouble(
        json['maximumGoal'],
      ),
      projectionYears: _toInt(
        json['projectionYears'],
        fallback: 10,
      ),
      totalInvested: _toDouble(
        json['totalInvested'],
      ),
      investedMonths: _toInt(
        json['investedMonths'],
      ),
      averageContribution: _toDouble(
        json['averageContribution'],
      ),
      bitcoin: _toDouble(
        json['bitcoin'],
      ),
      ethereum: _toDouble(
        json['ethereum'],
      ),
      solana: _toDouble(
        json['solana'],
      ),
      usdt: _toDouble(
        json['usdt'],
      ),
      completedDays: _parseCompletedDays(
        json['completedDays'],
      ),
      selectedDay: json['selectedDay']?.toString(),
    );
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  static double _toDouble(
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
          value.toString().trim().replaceAll(
            ',',
            '.',
          ),
        ) ??
        0;
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int _toInt(
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
  // PARSE COMPLETED DAYS
  // ============================================================

  static List<
    bool
  >
  _parseCompletedDays(
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

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'FinanceModel('
        'patrimony: $patrimony, '
        'invested: $invested, '
        'investmentGoal: $investmentGoal, '
        'bitcoin: $bitcoin, '
        'ethereum: $ethereum, '
        'solana: $solana, '
        'usdt: $usdt'
        ')';
  }
}
