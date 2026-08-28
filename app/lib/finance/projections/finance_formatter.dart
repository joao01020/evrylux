import 'package:flutter/material.dart';

/// =========================================================
/// FORMATAÇÃO DE TEMPO
/// =========================================================

/// Converte uma quantidade de meses em um texto legível.
///
/// Exemplos:
///
/// 0  -> Objetivo alcançado
/// 1  -> 1 mês
/// 5  -> 5 meses
/// 12 -> 1 ano
/// 18 -> 1 ano e 6 meses
/// 24 -> 2 anos
String
formatMonths(
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
    return months ==
            1
        ? '1 mês'
        : '$months meses';
  }

  if (months ==
      0) {
    return years ==
            1
        ? '1 ano'
        : '$years anos';
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

/// =========================================================
/// FORMATAÇÃO DE DATA
/// =========================================================

/// Converte uma data para DD/MM/AAAA.
///
/// Exemplo:
///
/// 2026-08-15 -> 15/08/2026
String
formatDate(
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

/// Retorna uma data no formato brasileiro.
String
formatDateLong(
  DateTime date,
) {
  const months = [
    '',
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

  return '${date.day} de ${months[date.month]} de ${date.year}';
}

/// =========================================================
/// MANIPULAÇÃO DE DATAS
/// =========================================================

/// Adiciona meses preservando o último dia válido.
///
/// Exemplo:
///
/// 31/01 + 1 mês
///
/// Resultado:
///
/// 28/02
DateTime
addMonths(
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

  final lastDay = DateTime(
    year,
    month +
        1,
    0,
  ).day;

  final day =
      date.day >
          lastDay
      ? lastDay
      : date.day;

  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

/// Remove meses preservando o último dia válido.
DateTime
subtractMonths(
  DateTime date,
  int months,
) {
  return addMonths(
    date,
    -months,
  );
}

/// =========================================================
/// FORMATAÇÃO MONETÁRIA
/// =========================================================

/// Formata um valor monetário simples.
///
/// Exemplo:
///
/// 1234.5
///
/// Resultado:
///
/// R$ 1.234,50
String
formatMoney(
  double value,
) {
  final negative =
      value <
      0;

  final absolute = value.abs().toStringAsFixed(
    2,
  );

  final parts = absolute.split(
    '.',
  );

  final integer = parts.first;

  final decimal = parts.last;

  final buffer = StringBuffer();

  for (
    int i = 0;
    i <
        integer.length;
    i++
  ) {
    final reverse =
        integer.length -
        i;

    buffer.write(
      integer[i],
    );

    if (reverse >
            1 &&
        reverse %
                3 ==
            1) {
      buffer.write(
        '.',
      );
    }
  }

  final money = 'R\$ ${buffer.toString()},$decimal';

  return negative
      ? '-$money'
      : money;
}

/// =========================================================
/// PORCENTAGEM
/// =========================================================

String
formatPercentage(
  double value,
) {
  return '${value.toStringAsFixed(1)}%';
}

/// =========================================================
/// PROGRESSO
/// =========================================================

double
clampProgress(
  double value,
) {
  return value
      .clamp(
        0.0,
        1.0,
      )
      .toDouble();
}

/// =========================================================
/// CORES
/// =========================================================

Color
progressColor(
  double progress,
) {
  progress = clampProgress(
    progress,
  );

  if (progress <
      0.33) {
    return Colors.red;
  }

  if (progress <
      0.66) {
    return Colors.orange;
  }

  return Colors.green;
}
