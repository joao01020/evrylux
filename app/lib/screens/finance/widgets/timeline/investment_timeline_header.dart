import 'package:flutter/material.dart';

class InvestmentTimelineHeader extends StatelessWidget {
  final int contributionCount;

  const InvestmentTimelineHeader({super.key, required this.contributionCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.history_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Histórico de aportes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              Text(
                contributionCount == 0
                    ? 'Seus aportes aparecerão aqui.'
                    : '$contributionCount '
                          '${contributionCount == 1 ? 'aporte registrado' : 'aportes registrados'}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
