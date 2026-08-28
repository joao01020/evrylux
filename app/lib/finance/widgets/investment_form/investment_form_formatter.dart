class InvestmentFormFormatter {
  const InvestmentFormFormatter._();

  static double parseMoney(String value) {
    var normalized = value.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (normalized.isEmpty) {
      return 0;
    }

    final hasComma = normalized.contains(',');

    final hasDot = normalized.contains('.');

    if (hasComma && hasDot) {
      final lastComma = normalized.lastIndexOf(',');

      final lastDot = normalized.lastIndexOf('.');

      if (lastComma > lastDot) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (hasComma) {
      normalized = normalized.replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

  static int parseYears(String value) {
    final years = int.tryParse(value.trim()) ?? 0;

    if (years < 0) {
      return 0;
    }

    return years;
  }

  static String currency(double value) {
    final safeValue = value.isFinite ? value : 0.0;

    final negative = safeValue < 0;
    final absoluteValue = safeValue.abs();

    final parts = absoluteValue.toStringAsFixed(2).split('.');

    final integerPart = parts.first;

    final decimalPart = parts.length > 1 ? parts.last : '00';

    final reversed = integerPart.split('').reversed.toList();

    final buffer = StringBuffer();

    for (int index = 0; index < reversed.length; index++) {
      if (index > 0 && index % 3 == 0) {
        buffer.write('.');
      }

      buffer.write(reversed[index]);
    }

    final formattedInteger = buffer.toString().split('').reversed.join();

    final sign = negative ? '-' : '';

    return '${sign}R\$ $formattedInteger,$decimalPart';
  }

  static String projectionPeriod(int years) {
    if (years <= 0) {
      return 'Defina o tempo';
    }

    if (years == 1) {
      return 'Em 1 ano';
    }

    return 'Em $years anos';
  }
}
