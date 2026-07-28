import 'package:flutter/material.dart';

class TrainingCoverageCard
    extends
        StatelessWidget {
  final Map<
    String,
    int
  >
  coverage;

  const TrainingCoverageCard({
    super.key,
    required this.coverage,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final entries = coverage.entries.toList();

    final highestValue = entries.isEmpty
        ? 0
        : entries
              .map(
                (
                  entry,
                ) => entry.value,
              )
              .reduce(
                (
                  current,
                  next,
                ) {
                  return current >
                          next
                      ? current
                      : next;
                },
              );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      12,
                    ),
                  ),
                  child: const Icon(
                    Icons.fitness_center,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Text(
                    'Como seus treinos se distribuíram',
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              'Veja quais atividades apareceram mais vezes nos seus registros deste mês.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium,
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'As barras apenas comparam seus próprios registros.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),

            const SizedBox(
              height: 22,
            ),

            if (entries.isEmpty)
              const _EmptyCoverage()
            else ...[
              ...entries.map(
                (
                  entry,
                ) {
                  final progress =
                      highestValue ==
                          0
                      ? 0.0
                      : entry.value /
                            highestValue;

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 18,
                    ),
                    child: _CoverageItem(
                      name: entry.key,
                      total: entry.value,
                      progress: progress,
                    ),
                  );
                },
              ),

              _CoverageExplanation(
                highestValue: highestValue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CoverageItem
    extends
        StatelessWidget {
  final String name;
  final int total;
  final double progress;

  const _CoverageItem({
    required this.name,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final safeProgress = progress.clamp(
      0.0,
      1.0,
    );

    final totalText =
        total ==
            1
        ? '1 registro'
        : '$total registros';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Text(
              totalText,
              style:
                  Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),

        const SizedBox(
          height: 9,
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(
            20,
          ),
          child: LinearProgressIndicator(
            value: safeProgress,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}

class _CoverageExplanation
    extends
        StatelessWidget {
  final int highestValue;

  const _CoverageExplanation({
    required this.highestValue,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final referenceText =
        highestValue ==
            1
        ? 'A maior frequência deste mês foi 1 registro.'
        : 'A maior frequência deste mês foi de $highestValue registros.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 21,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              '$referenceText '
              'As outras barras são comparadas com esse valor.',
              style:
                  Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCoverage
    extends
        StatelessWidget {
  const _EmptyCoverage();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.query_stats_outlined,
            size: 38,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Nenhum treino registrado neste mês.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 7,
          ),

          Text(
            'Quando você registrar seus treinos, esta área mostrará quais atividades apareceram mais vezes.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
