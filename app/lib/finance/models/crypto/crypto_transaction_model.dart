class CryptoTransactionModel {
  const CryptoTransactionModel({
    required this.id,
    required this.symbol,
    required this.date,
    required this.quantity,
    required this.invested,
  });

  // ============================================================
  // FIELDS
  // ============================================================

  final String id;

  final String symbol;

  final DateTime date;

  final double quantity;

  final double invested;

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'symbol': symbol.trim().toUpperCase(),
      'date': date.toUtc().toIso8601String(),
      'quantity': quantity,
      'invested': invested,
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory CryptoTransactionModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CryptoTransactionModel(
      id:
          map['id']?.toString() ??
          '',
      symbol:
          map['symbol']?.toString().trim().toUpperCase() ??
          '',
      date: _parseDate(
        map['date'],
      ),
      quantity: _parseDouble(
        map['quantity'],
      ),
      invested: _parseDouble(
        map['invested'],
      ),
    );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  CryptoTransactionModel copyWith({
    String? id,
    String? symbol,
    DateTime? date,
    double? quantity,
    double? invested,
  }) {
    return CryptoTransactionModel(
      id:
          id ??
          this.id,
      symbol:
          symbol ??
          this.symbol,
      date:
          date ??
          this.date,
      quantity:
          quantity ??
          this.quantity,
      invested:
          invested ??
          this.invested,
    );
  }

  // ============================================================
  // PARSE DOUBLE
  // ============================================================

  static double _parseDouble(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    if (value
        is num) {
      return value.toDouble();
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
  // PARSE DATE
  // ============================================================

  static DateTime _parseDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    if (value ==
        null) {
      return DateTime.now();
    }

    return DateTime.tryParse(
          value.toString(),
        ) ??
        DateTime.now();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool get isValid {
    return id.trim().isNotEmpty &&
        symbol.trim().isNotEmpty &&
        quantity >=
            0 &&
        invested >=
            0 &&
        quantity.isFinite &&
        invested.isFinite;
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'CryptoTransactionModel('
        'id: $id, '
        'symbol: $symbol, '
        'date: $date, '
        'quantity: $quantity, '
        'invested: $invested'
        ')';
  }
}
