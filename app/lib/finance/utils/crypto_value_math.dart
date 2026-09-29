class CryptoValueMath {
  const CryptoValueMath._();

  static double positive(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    if (!parsed.isFinite || parsed <= 0) {
      return 0.0;
    }

    return parsed;
  }

  static double currentValue({
    required dynamic quantity,
    required dynamic price,
  }) {
    final safeQuantity = positive(quantity);
    final safePrice = positive(price);
    final result = safeQuantity * safePrice;

    if (!result.isFinite || result < 0) {
      return 0.0;
    }

    return result;
  }

  static double profitLoss({
    required dynamic currentValue,
    required dynamic invested,
  }) {
    final current = positive(currentValue);
    final cost = positive(invested);
    final result = current - cost;

    return result.isFinite ? result : 0.0;
  }

  static double profitLossPercent({
    required dynamic currentValue,
    required dynamic invested,
  }) {
    final cost = positive(invested);

    if (cost <= 0) {
      return 0.0;
    }

    final value = positive(currentValue);
    final result = ((value - cost) / cost) * 100;

    return result.isFinite ? result : 0.0;
  }

  static double patrimony({
    required Map<String, double> quantities,
    required Map<String, double> prices,
  }) {
    var total = 0.0;

    for (final entry in quantities.entries) {
      total += currentValue(quantity: entry.value, price: prices[entry.key]);
    }

    return total.isFinite && total >= 0 ? total : 0.0;
  }
}
