class CryptoBalances {
  const CryptoBalances({
    this.bitcoin = 0,
    this.ethereum = 0,
    this.solana = 0,
    this.usdt = 0,
  });

  // ============================================================
  // SALDOS
  // ============================================================

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  // ============================================================
  // QUANTIDADE POR SÍMBOLO
  // ============================================================

  double quantityOf(
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
  // COPY WITH
  // ============================================================

  CryptoBalances copyWith({
    double? bitcoin,
    double? ethereum,
    double? solana,
    double? usdt,
  }) {
    return CryptoBalances(
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
    );
  }

  // ============================================================
  // UPDATE BY SYMBOL
  // ============================================================

  CryptoBalances updateSymbol({
    required String symbol,
    required double value,
  }) {
    final normalized = symbol.trim().toUpperCase();

    switch (normalized) {
      case 'BTC':
      case 'BITCOIN':
        return copyWith(
          bitcoin: value,
        );

      case 'ETH':
      case 'ETHEREUM':
        return copyWith(
          ethereum: value,
        );

      case 'SOL':
      case 'SOLANA':
        return copyWith(
          solana: value,
        );

      case 'USDT':
      case 'TETHER':
        return copyWith(
          usdt: value,
        );

      default:
        return this;
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  Map<
    String,
    double
  >
  toMap() {
    return {
      'BTC': bitcoin,
      'ETH': ethereum,
      'SOL': solana,
      'USDT': usdt,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory CryptoBalances.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CryptoBalances(
      bitcoin: _toDouble(
        map['bitcoin'] ??
            map['BTC'],
      ),
      ethereum: _toDouble(
        map['ethereum'] ??
            map['ETH'],
      ),
      solana: _toDouble(
        map['solana'] ??
            map['SOL'],
      ),
      usdt: _toDouble(
        map['usdt'] ??
            map['USDT'],
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  static const CryptoBalances empty = CryptoBalances();

  // ============================================================
  // TOTAL DE ATIVOS COM SALDO
  // ============================================================

  int get activeAssets {
    var total = 0;

    if (bitcoin >
        0) {
      total++;
    }

    if (ethereum >
        0) {
      total++;
    }

    if (solana >
        0) {
      total++;
    }

    if (usdt >
        0) {
      total++;
    }

    return total;
  }

  // ============================================================
  // HAS BALANCE
  // ============================================================

  bool hasBalance(
    String symbol,
  ) {
    return quantityOf(
          symbol,
        ) >
        0;
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
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'CryptoBalances('
        'bitcoin: $bitcoin, '
        'ethereum: $ethereum, '
        'solana: $solana, '
        'usdt: $usdt'
        ')';
  }
}
