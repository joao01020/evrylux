import 'package:flutter/material.dart';

class FinanceIntro extends StatelessWidget {
  const FinanceIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sua liberdade financeira começa aqui.',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Text(
          'Construa patrimônio seguindo um ritmo possível para sua realidade.',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
