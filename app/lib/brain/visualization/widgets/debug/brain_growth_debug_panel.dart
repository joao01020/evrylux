import 'dart:async';

import 'package:flutter/material.dart';

import '../../controllers/brain_visual_controller.dart';
import '../../models/brain_growth_planner.dart';
import '../../painters/brain_paths.dart';
import '../evolving_brain.dart';

class BrainGrowthDebugPanel
    extends
        StatefulWidget {
  const BrainGrowthDebugPanel({
    super.key,
    required this.controller,
    this.showBrain = true,
    this.brainSize = 190,
  });

  final BrainVisualController controller;
  final bool showBrain;
  final double brainSize;

  @override
  State<
    BrainGrowthDebugPanel
  >
  createState() => _BrainGrowthDebugPanelState();
}

class _BrainGrowthDebugPanelState
    extends
        State<
          BrainGrowthDebugPanel
        > {
  static const List<
    _DebugTopic
  >
  _topics =
      <
        _DebugTopic
      >[
        _DebugTopic(
          key: 'programacao',
          label: 'Programação',
          icon: Icons.code_rounded,
        ),
        _DebugTopic(
          key: 'eletronica',
          label: 'Eletrônica',
          icon: Icons.memory_rounded,
        ),
        _DebugTopic(
          key: 'arte',
          label: 'Arte',
          icon: Icons.palette_outlined,
        ),
        _DebugTopic(
          key: 'matematica',
          label: 'Matemática',
          icon: Icons.calculate_outlined,
        ),
        _DebugTopic(
          key: 'fisica',
          label: 'Física',
          icon: Icons.science_outlined,
        ),
        _DebugTopic(
          key: 'musica',
          label: 'Música',
          icon: Icons.music_note_rounded,
        ),
      ];

  static const List<
    String
  >
  _stressLabels =
      <
        String
      >[
        'Programação',
        'Eletrônica',
        'Arte',
        'Matemática',
        'Física',
        'Música',
        'Design',
        'Negócios',
        'Filosofia',
        'Segurança',
        'Hardware',
        'Ideias',
      ];

  bool _searching = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      _onControllerChanged,
    );
  }

  @override
  void didUpdateWidget(
    covariant BrainGrowthDebugPanel oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.controller !=
        widget.controller) {
      oldWidget.controller.removeListener(
        _onControllerChanged,
      );
      widget.controller.addListener(
        _onControllerChanged,
      );
    }
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  void _addTopic(
    _DebugTopic topic,
  ) {
    widget.controller.registerSemanticKnowledge(
      semanticKey: topic.key,
      label: topic.label,
    );
  }

  void _jumpToNextMilestone(
    _DebugTopic topic,
  ) {
    final current = widget.controller.topicBySemanticKey(
      topic.key,
    );

    final currentCount =
        current?.knowledgeCount ??
        0;

    int? target;

    for (final milestone in BrainGrowthPlanner.growthMilestones) {
      if (milestone >
          currentCount) {
        target = milestone;
        break;
      }
    }

    if (target ==
        null) {
      return;
    }

    final amount =
        target -
        currentCount;

    for (
      var i = 0;
      i <
          amount;
      i += 1
    ) {
      widget.controller.registerSemanticKnowledge(
        semanticKey: topic.key,
        label: topic.label,
      );
    }
  }

  void _fillExtreme() {
    final topics =
        <
          BrainTopicState
        >[];

    for (
      var i = 0;
      i <
          BrainPaths.mainBranchCount;
      i += 1
    ) {
      topics.add(
        BrainTopicState(
          semanticKey: 'stress_$i',
          label:
              i <
                  _stressLabels.length
              ? _stressLabels[i]
              : 'Conhecimento ${i + 1}',
          branchIndex: i,
          knowledgeCount: BrainGrowthPlanner.growthMilestones.last,
        ),
      );
    }

    widget.controller.applyGrowthState(
      BrainGrowthState(
        topics: topics,
      ),
    );
  }

  Future<
    void
  >
  _simulateSearch() async {
    if (_searching) {
      return;
    }

    setState(
      () {
        _searching = true;
      },
    );

    widget.controller.setSearching(
      true,
    );

    try {
      await Future<
        void
      >.delayed(
        const Duration(
          seconds: 5,
        ),
      );
    } finally {
      widget.controller.setSearching(
        false,
      );

      if (mounted) {
        setState(
          () {
            _searching = false;
          },
        );
      }
    }
  }

  void _resetGrowth() {
    widget.controller.resetGrowthState();
  }

  void _replayBirth() {
    unawaited(
      widget.controller.replayBirth(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 780,
        ),
        padding: const EdgeInsets.all(
          16,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: theme.dividerColor.withValues(
              alpha: 0.45,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showBrain)
              Center(
                child: EvolvingBrain(
                  controller: widget.controller,
                  size: widget.brainSize,
                ),
              ),

            const SizedBox(
              height: 16,
            ),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_tree_outlined,
                    size: 18,
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      '${BrainPaths.mainBranchCount} ramos disponíveis'
                      '  •  '
                      '${BrainGrowthPlanner.growthMilestones.length} níveis',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    final isNarrow =
                        constraints.maxWidth <
                        520;

                    final width = isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth -
                                  12) /
                              2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _topics
                          .map(
                            (
                              topic,
                            ) => SizedBox(
                              width: width,
                              child: _topicCard(
                                context,
                                topic,
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
            ),

            const SizedBox(
              height: 16,
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _searching
                      ? null
                      : () {
                          unawaited(
                            _simulateSearch(),
                          );
                        },
                  icon: const Icon(
                    Icons.bolt_rounded,
                  ),
                  label: Text(
                    _searching
                        ? 'Pesquisando...'
                        : 'Simular pesquisa',
                  ),
                ),

                FilledButton.tonalIcon(
                  onPressed: _fillExtreme,
                  icon: const Icon(
                    Icons.account_tree_outlined,
                  ),
                  label: const Text(
                    'Preencher extremo',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _replayBirth,
                  icon: const Icon(
                    Icons.replay_rounded,
                  ),
                  label: const Text(
                    'Repetir nascimento',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: _resetGrowth,
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                  ),
                  label: const Text(
                    'Resetar ramos',
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 16,
            ),

            _summary(
              context,
            ),
          ],
        ),
      ),
    );
  }

  Widget _topicCard(
    BuildContext context,
    _DebugTopic topic,
  ) {
    final state = widget.controller.topicBySemanticKey(
      topic.key,
    );

    final count =
        state?.knowledgeCount ??
        0;

    final level =
        state?.level ??
        0;

    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.45,
              ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                topic.icon,
                size: 18,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Text(
                  topic.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 7,
          ),

          Text(
            'Itens: $count  •  Nível: $level'
            '${state == null ? '' : '  •  Ramo: ${state.branchIndex}'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall,
          ),

          const SizedBox(
            height: 9,
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _addTopic(
                      topic,
                    );
                  },
                  child: const Text(
                    '+1',
                  ),
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    _jumpToNextMilestone(
                      topic,
                    );
                  },
                  child: const Text(
                    'Próximo nível',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summary(
    BuildContext context,
  ) {
    final topics =
        <
            BrainTopicState
          >[
            ...widget.controller.topics,
          ]
          ..sort(
            (
              a,
              b,
            ) => a.branchIndex.compareTo(
              b.branchIndex,
            ),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.45,
            ),
        borderRadius: BorderRadius.circular(
          12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estado atual',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${topics.length}/${BrainPaths.mainBranchCount}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(
            height: 7,
          ),
          if (topics.isEmpty)
            const Text(
              'Nenhum ramo criado.',
            )
          else
            ...topics.map(
              (
                topic,
              ) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 3,
                ),
                child: Text(
                  '${topic.label}: '
                  '${topic.knowledgeCount} itens '
                  '→ ramo ${topic.branchIndex} '
                  '→ nível ${topic.level}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.controller.removeListener(
      _onControllerChanged,
    );

    super.dispose();
  }
}

@immutable
class _DebugTopic {
  const _DebugTopic({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}
