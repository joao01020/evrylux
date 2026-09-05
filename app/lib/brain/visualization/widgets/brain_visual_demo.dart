import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/brain_visual_controller.dart';
import 'evolving_brain.dart';

class BrainVisualDemo
    extends StatefulWidget {
  const BrainVisualDemo({
    super.key,
  });

  @override
  State<BrainVisualDemo> createState() =>
      _BrainVisualDemoState();
}

class _BrainVisualDemoState
    extends State<BrainVisualDemo> {
  late final BrainVisualController
      controller;

  @override
  void initState() {
    super.initState();

    controller =
        BrainVisualController(
      knowledgeCount: 0,
      introSeen: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  Future<void> _addKnowledge() async {
    await controller
        .registerKnowledgeAdded(
      amount: 5,
    );

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _simulateSearch() async {
    controller.setSearching(true);

    await Future<void>.delayed(
      const Duration(
        seconds: 5,
      ),
    );

    controller.setSearching(false);
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EVRYLUX • Brain Demo',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            EvolvingBrain(
              controller: controller,
              size: 330,
              onBirthCompleted: () {
                debugPrint(
                  '[BRAIN] '
                  'Nascimento finalizado. '
                  'Persistir introSeen=true.',
                );
              },
            ),
            const SizedBox(
              height: 28,
            ),
            Text(
              'Conhecimentos: '
              '${controller.knowledgeCount}',
            ),
            const SizedBox(
              height: 16,
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment:
                  WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _addKnowledge,
                  icon: const Icon(
                    Icons.add_rounded,
                  ),
                  label: const Text(
                    'Adicionar conhecimento',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    unawaited(
                      _simulateSearch(),
                    );
                  },
                  icon: const Icon(
                    Icons.search_rounded,
                  ),
                  label: const Text(
                    'Simular pesquisa',
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    unawaited(
                      controller
                          .replayBirth(),
                    );
                  },
                  icon: const Icon(
                    Icons.replay_rounded,
                  ),
                  label: const Text(
                    'Repetir nascimento',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
