import 'package:flutter/material.dart';

class InvestmentTimelineHeader
    extends
        StatelessWidget {
  const InvestmentTimelineHeader({
    super.key,
    required this.contributionCount,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final int contributionCount;

  // ============================================================
  // TEXTO
  // ============================================================

  String get _subtitle {
    if (contributionCount <=
        0) {
      return 'Seus aportes aparecerão aqui.';
    }

    if (contributionCount ==
        1) {
      return '1 aporte registrado.';
    }

    return '$contributionCount aportes registrados.';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            Icons.history_outlined,
            color: colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // TEXTOS
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Histórico de aportes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                _subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
