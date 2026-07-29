import 'package:flutter/material.dart';

class BrainEmptyNotes extends StatelessWidget {
  final String title;
  final String description;

  const BrainEmptyNotes({
    super.key,
    this.title = 'Seu cérebro ainda está vazio.',
    this.description = 'Crie sua primeira anotação e salve seu conhecimento.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.psychology_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(description, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
