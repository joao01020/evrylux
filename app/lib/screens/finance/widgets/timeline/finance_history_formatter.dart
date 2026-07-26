class FinanceHistoryFormatter {
  const FinanceHistoryFormatter._();

  static String currency(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final negative =
        safeValue <
        0;
    final absoluteValue = safeValue.abs();

    final parts = absoluteValue
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integerPart = parts.first;

    final decimalPart =
        parts.length >
            1
        ? parts.last
        : '00';

    final reversed = integerPart
        .split(
          '',
        )
        .reversed
        .toList();

    final buffer = StringBuffer();

    for (
      int index = 0;
      index <
          reversed.length;
      index++
    ) {
      if (index >
              0 &&
          index %
                  3 ==
              0) {
        buffer.write(
          '.',
        );
      }

      buffer.write(
        reversed[index],
      );
    }

    final formattedInteger = buffer
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    final sign = negative
        ? '-'
        : '';

    return '${sign}R\$ $formattedInteger,$decimalPart';
  }

  static String percentage(
    double value,
  ) {
    double percentage = value;

    if (percentage.abs() <=
        1) {
      percentage *= 100;
    }

    if (!percentage.isFinite) {
      percentage = 0;
    }

    percentage = percentage.clamp(
      0.0,
      100.0,
    );

    if (percentage ==
        percentage.roundToDouble()) {
      return '${percentage.toStringAsFixed(0)}%';
    }

    return '${percentage.toStringAsFixed(1).replaceAll('.', ',')}%';
  }

  static String date(
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

  static String time(
    DateTime date,
  ) {
    final hour = date.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = date.minute.toString().padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  static String monthName(
    int month,
  ) {
    const months =
        <
          String
        >[
          'Janeiro',
          'Fevereiro',
          'Março',
          'Abril',
          'Maio',
          'Junho',
          'Julho',
          'Agosto',
          'Setembro',
          'Outubro',
          'Novembro',
          'Dezembro',
        ];

    if (month <
            1 ||
        month >
            12) {
      return '';
    }

    return months[month -
        1];
  }

  static String monthGroupTitle(
    DateTime date,
  ) {
    return '${monthName(date.month)} de ${date.year}';
  }
}
