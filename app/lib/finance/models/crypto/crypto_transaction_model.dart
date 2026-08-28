class CryptoTransactionModel {
  final String id;

  final String symbol;

  final DateTime date;

  final double quantity;

  final double invested;

  const CryptoTransactionModel({
    required this.id,
    required this.symbol,
    required this.date,
    required this.quantity,
    required this.invested,
  });

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      "id": id,
      "symbol": symbol,
      "date": date.toIso8601String(),
      "quantity": quantity,
      "invested": invested,
    };
  }

  factory CryptoTransactionModel.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return CryptoTransactionModel(
      id:
          map["id"] ??
          "",
      symbol:
          map["symbol"] ??
          "",
      date: DateTime.parse(
        map["date"],
      ),
      quantity:
          (map["quantity"] ??
                  0)
              .toDouble(),
      invested:
          (map["invested"] ??
                  0)
              .toDouble(),
    );
  }

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
}
