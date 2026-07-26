import 'package:flutter/material.dart';

class InvestmentRhythmStyle {
  const InvestmentRhythmStyle._();

  static String normalize(
    String rhythm,
  ) {
    final value = rhythm.trim().toLowerCase();

    if (value.contains(
          'tranquilo',
        ) ||
        value.contains(
          'mínimo',
        ) ||
        value.contains(
          'minimo',
        )) {
      return 'Tranquilo';
    }

    if (value.contains(
          'normal',
        ) ||
        value.contains(
          'médio',
        ) ||
        value.contains(
          'medio',
        )) {
      return 'Normal';
    }

    if (value.contains(
          'forte',
        ) ||
        value.contains(
          'máximo',
        ) ||
        value.contains(
          'maximo',
        )) {
      return 'Forte';
    }

    if (value.contains(
      'personalizado',
    )) {
      return 'Personalizado';
    }

    if (value.contains(
      'sem aporte',
    )) {
      return 'Sem aporte';
    }

    if (rhythm.trim().isEmpty) {
      return 'Sem ritmo';
    }

    return rhythm;
  }

  static Color color(
    String rhythm,
  ) {
    switch (normalize(
      rhythm,
    )) {
      case 'Tranquilo':
        return Colors.green;

      case 'Normal':
        return Colors.blue;

      case 'Forte':
        return Colors.purple;

      case 'Personalizado':
        return Colors.orange;

      case 'Sem aporte':
        return Colors.grey;

      default:
        return Colors.blueGrey;
    }
  }

  static IconData icon(
    String rhythm,
  ) {
    switch (normalize(
      rhythm,
    )) {
      case 'Tranquilo':
        return Icons.eco_outlined;

      case 'Normal':
        return Icons.directions_walk_outlined;

      case 'Forte':
        return Icons.local_fire_department_outlined;

      case 'Personalizado':
        return Icons.tune_outlined;

      case 'Sem aporte':
        return Icons.remove_circle_outline;

      default:
        return Icons.savings_outlined;
    }
  }

  static String description(
    String rhythm,
  ) {
    switch (normalize(
      rhythm,
    )) {
      case 'Tranquilo':
        return 'Você manteve seu objetivo em movimento.';

      case 'Normal':
        return 'Você avançou em um ritmo equilibrado.';

      case 'Forte':
        return 'Você acelerou seu objetivo financeiro.';

      case 'Personalizado':
        return 'Este aporte seguiu um ritmo próprio.';

      case 'Sem aporte':
        return 'Nenhum valor foi registrado neste período.';

      default:
        return 'Aporte registrado no seu histórico.';
    }
  }
}
