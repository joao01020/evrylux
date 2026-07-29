import 'package:flutter/material.dart';

class EmptyLastContribution extends StatelessWidget {
  const EmptyLastContribution({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.savings_outlined,
            size: 38,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          const Text(
            'Registre seu primeiro aporte para começar o histórico.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
