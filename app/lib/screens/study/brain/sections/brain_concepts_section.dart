import 'package:flutter/material.dart';

import '../models/brain_concept.dart';

class BrainConceptsSection extends StatelessWidget {
  final List<BrainConcept> concepts;

  final VoidCallback onAddConcept;

  final Widget Function(BuildContext context, BrainConcept concept, int index)
  itemBuilder;

  const BrainConceptsSection({
    super.key,
    required this.concepts,
    required this.onAddConcept,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Conceitos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),

            FilledButton.tonalIcon(
              onPressed: onAddConcept,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Text(
          'Separe os pontos principais que deseja revisar depois.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),

        const SizedBox(height: 16),

        if (concepts.isEmpty)
          const _BrainEmptyConcepts()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: concepts.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 8);
            },
            itemBuilder: (context, index) {
              final concept = concepts[index];

              return itemBuilder(context, concept, index);
            },
          ),
      ],
    );
  }
}

class _BrainEmptyConcepts extends StatelessWidget {
  const _BrainEmptyConcepts();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.lightbulb_outline, size: 40),

          SizedBox(height: 10),

          Text(
            'Nenhum conceito adicionado.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 6),

          Text(
            'Adicione os conceitos mais importantes desta anotação.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
