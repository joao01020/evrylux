import 'package:flutter/material.dart';

class TrainingCoverageCard
    extends
        StatelessWidget {
  const TrainingCoverageCard({
    super.key,
    required this.coverage,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final Map<
    String,
    int
  >
  coverage;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    final entries =
        coverage.entries
            .where(
              (
                entry,
              ) {
                return entry.value >
                    0;
              },
            )
            .toList(
              growable: false,
            )
          ..sort(
            (
              first,
              second,
            ) {
              return second.value.compareTo(
                first.value,
              );
            },
          );

    final total =
        entries.fold<
          int
        >(
          0,
          (
            current,
            entry,
          ) {
            return current +
                entry.value;
          },
        );

    final highestValue = entries.isEmpty
        ? 0
        : entries.first.value;

    final topActivity = entries.isEmpty
        ? null
        : entries.first.key;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.72,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(
              alpha: 0.055,
            ),
            blurRadius: 28,
            offset: const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          22,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================================================
            // HEADER
            // ======================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                18,
                20,
                17,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.query_stats_rounded,
                      size: 22,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 13,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Como seus treinos se distribuíram',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.1,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Text(
                          'Veja quais atividades apareceram mais vezes nos seus registros deste mês.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (entries.isNotEmpty) ...[
                    const SizedBox(
                      width: 12,
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(
                          alpha: 0.07,
                        ),
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                        border: Border.all(
                          color: colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      child: Text(
                        total ==
                                1
                            ? '1 registro'
                            : '$total registros',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(
                alpha: 0.52,
              ),
            ),

            // ======================================================
            // CONTEÚDO
            // ======================================================
            Padding(
              padding: const EdgeInsets.all(
                20,
              ),
              child: entries.isEmpty
                  ? _EmptyCoverageState(
                      colorScheme: colorScheme,
                      theme: theme,
                    )
                  : _CoverageContent(
                      entries: entries,
                      total: total,
                      highestValue: highestValue,
                      topActivity: topActivity,
                      colorScheme: colorScheme,
                      theme: theme,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CONTEÚDO COM DADOS
// ============================================================

class _CoverageContent
    extends
        StatelessWidget {
  const _CoverageContent({
    required this.entries,
    required this.total,
    required this.highestValue,
    required this.topActivity,
    required this.colorScheme,
    required this.theme,
  });

  final List<
    MapEntry<
      String,
      int
    >
  >
  entries;

  final int total;

  final int highestValue;

  final String? topActivity;

  final ColorScheme colorScheme;

  final ThemeData theme;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ==========================================================
        // RESUMO
        // ==========================================================
        Row(
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Icons.auto_graph_rounded,
                label: 'Mais frequente',
                value: _cleanActivityName(
                  topActivity ??
                      '—',
                ),
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: _SummaryTile(
                icon: Icons.fitness_center_rounded,
                label: 'Atividades',
                value:
                    entries.length ==
                        1
                    ? '1 tipo'
                    : '${entries.length} tipos',
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Expanded(
              child: _SummaryTile(
                icon: Icons.repeat_rounded,
                label: 'Registros',
                value: '$total',
                colorScheme: colorScheme,
                theme: theme,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        // ==========================================================
        // LEGENDA
        // ==========================================================
        Row(
          children: [
            Text(
              'Distribuição no mês',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Spacer(),

            Text(
              'comparação entre seus registros',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 12,
        ),

        // ==========================================================
        // BARRAS
        // ==========================================================
        ...List.generate(
          entries.length,
          (
            index,
          ) {
            final entry = entries[index];

            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    index ==
                        entries.length -
                            1
                    ? 0
                    : 13,
              ),
              child: _CoverageBar(
                activity: entry.key,
                value: entry.value,
                total: total,
                highestValue: highestValue,
                colorScheme: colorScheme,
                theme: theme,
              ),
            );
          },
        ),
      ],
    );
  }

  String _cleanActivityName(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'^[^\p{L}\p{N}]+',
            unicode: true,
          ),
          '',
        )
        .trim();
  }
}

// ============================================================
// RESUMO
// ============================================================

class _SummaryTile
    extends
        StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
  });

  final IconData icon;

  final String label;

  final String value;

  final ColorScheme colorScheme;

  final ThemeData theme;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.58,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: 0.08,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BARRA
// ============================================================

class _CoverageBar
    extends
        StatelessWidget {
  const _CoverageBar({
    required this.activity,
    required this.value,
    required this.total,
    required this.highestValue,
    required this.colorScheme,
    required this.theme,
  });

  final String activity;

  final int value;

  final int total;

  final int highestValue;

  final ColorScheme colorScheme;

  final ThemeData theme;

  @override
  Widget build(
    BuildContext context,
  ) {
    final relativeProgress =
        highestValue <=
            0
        ? 0.0
        : value /
              highestValue;

    final percentage =
        total <=
            0
        ? 0
        : ((value /
                      total) *
                  100)
              .round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                activity,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.55,
                ),
                borderRadius: BorderRadius.circular(
                  999,
                ),
              ),
              child: Text(
                value ==
                        1
                    ? '1x · $percentage%'
                    : '${value}x · $percentage%',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 7,
        ),

        LayoutBuilder(
          builder:
              (
                context,
                constraints,
              ) {
                final width =
                    constraints.maxWidth *
                    relativeProgress.clamp(
                      0.0,
                      1.0,
                    );

                return Container(
                  height: 9,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 380,
                      ),
                      curve: Curves.easeOutCubic,
                      width: width,
                      height: 9,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(
                              alpha: 0.72,
                            ),
                            colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                      ),
                    ),
                  ),
                );
              },
        ),
      ],
    );
  }
}

// ============================================================
// ESTADO VAZIO
// ============================================================

class _EmptyCoverageState
    extends
        StatelessWidget {
  const _EmptyCoverageState({
    required this.colorScheme,
    required this.theme,
  });

  final ColorScheme colorScheme;

  final ThemeData theme;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 28,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.60,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: 0.08,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
              ),
            ),
            child: Icon(
              Icons.monitor_heart_outlined,
              size: 24,
              color: colorScheme.primary,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Text(
            'Seu mês ainda está em branco',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 520,
            ),
            child: Text(
              'Quando você registrar seus primeiros treinos, esta área vai mostrar quais atividades aparecem mais vezes na sua rotina.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: 0.055,
              ),
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: 1,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(
                  width: 7,
                ),

                Expanded(
                  child: Text(
                    'As barras comparam apenas os seus próprios registros.',
                    softWrap: true,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
