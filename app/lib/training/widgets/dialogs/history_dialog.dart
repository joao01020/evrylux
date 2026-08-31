import 'package:flutter/material.dart';

import '../../models/training_model.dart';
import 'training_history_edit_dialog.dart';

// ============================================================
// HISTORY DIALOG
// ============================================================
//
// Conteúdo do modal de histórico.
//
// O modal externo continua sendo aberto pelo TrainingScreen.
//
// Diferenças:
// - visual em timeline;
// - usa TrainingModel real;
// - editar;
// - apagar;
// - confirmação antes de excluir.
//
// ============================================================

class HistoryDialog
    extends
        StatelessWidget {
  const HistoryDialog({
    super.key,
    required this.trainings,
    required this.onEdit,
    required this.onDelete,
  });

  final List<
    TrainingModel
  >
  trainings;

  final Future<
    bool
  >
  Function(
    TrainingModel original,
    TrainingModel updated,
  )
  onEdit;

  final Future<
    bool
  >
  Function(
    TrainingModel training,
  )
  onDelete;

  @override
  Widget build(
    BuildContext context,
  ) {
    final ordered =
        List<
            TrainingModel
          >.from(
            trainings,
          )
          ..sort(
            (
              first,
              second,
            ) => second.date.compareTo(
              first.date,
            ),
          );

    if (ordered.isEmpty) {
      return const _HistoryEmptyState();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryOverview(
          trainings: ordered,
        ),

        const SizedBox(
          height: 16,
        ),

        ConstrainedBox(
          constraints: const BoxConstraints(
            maxHeight: 460,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: ordered.length,
            separatorBuilder:
                (
                  _,
                  __,
                ) => const SizedBox(
                  height: 9,
                ),
            itemBuilder:
                (
                  context,
                  index,
                ) {
                  final training = ordered[index];

                  return _HistoryTimelineItem(
                    training: training,
                    isLast:
                        index ==
                        ordered.length -
                            1,
                    onEdit: () async {
                      final updated = await TrainingHistoryEditDialog.show(
                        context,
                        training: training,
                      );

                      if (updated ==
                          null) {
                        return;
                      }

                      final success = await onEdit(
                        training,
                        updated,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      _showResult(
                        context,
                        success
                            ? 'Treino atualizado.'
                            : 'Não foi possível atualizar o treino.',
                      );
                    },
                    onDelete: () async {
                      final confirmed = await _confirmDelete(
                        context,
                        training,
                      );

                      if (!confirmed) {
                        return;
                      }

                      final success = await onDelete(
                        training,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      _showResult(
                        context,
                        success
                            ? 'Treino apagado.'
                            : 'Não foi possível apagar o treino.',
                      );
                    },
                  );
                },
          ),
        ),
      ],
    );
  }

  static void _showResult(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
        ),
      );
  }

  static Future<
    bool
  >
  _confirmDelete(
    BuildContext context,
    TrainingModel training,
  ) async {
    final result =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                context,
              ) {
                final colorScheme = Theme.of(
                  context,
                ).colorScheme;

                return AlertDialog(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  title: const Text(
                    'Apagar treino?',
                  ),
                  content: Text(
                    '${training.training}\n'
                    '${_formatDate(training.date)}\n\n'
                    'Essa ação removerá o registro do histórico.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          true,
                        );
                      },
                      child: const Text(
                        'Apagar',
                      ),
                    ),
                  ],
                );
              },
        );

    return result ==
        true;
  }

  static String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }
}

// ============================================================
// OVERVIEW
// ============================================================

class _HistoryOverview
    extends
        StatelessWidget {
  const _HistoryOverview({
    required this.trainings,
  });

  final List<
    TrainingModel
  >
  trainings;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final totalMinutes =
        trainings.fold<
          int
        >(
          0,
          (
            total,
            item,
          ) =>
              total +
              item.minutes,
        );

    final uniqueDays = trainings
        .map(
          (
            item,
          ) =>
              '${item.date.year}-'
              '${item.date.month}-'
              '${item.date.day}',
        )
        .toSet()
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              icon: Icons.fitness_center_rounded,
              value: '${trainings.length}',
              label: 'registros',
            ),
          ),

          _VerticalDivider(
            color: colorScheme.outlineVariant,
          ),

          Expanded(
            child: _OverviewMetric(
              icon: Icons.calendar_today_rounded,
              value: '$uniqueDays',
              label: 'dias treinados',
            ),
          ),

          _VerticalDivider(
            color: colorScheme.outlineVariant,
          ),

          Expanded(
            child: _OverviewMetric(
              icon: Icons.timer_outlined,
              value:
                  totalMinutes >
                      0
                  ? '$totalMinutes'
                  : '—',
              label:
                  totalMinutes >
                      0
                  ? 'minutos'
                  : 'sem tempo',
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider
    extends
        StatelessWidget {
  const _VerticalDivider({
    required this.color,
  });

  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: 1,
      height: 40,
      color: color,
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
      ),
    );
  }
}

class _OverviewMetric
    extends
        StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;

  final String value;

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: colorScheme.primary,
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 1,
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// TIMELINE ITEM
// ============================================================

class _HistoryTimelineItem
    extends
        StatelessWidget {
  const _HistoryTimelineItem({
    required this.training,
    required this.isLast,
    required this.onEdit,
    required this.onDelete,
  });

  final TrainingModel training;

  final bool isLast;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 30,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.only(
                        top: 4,
                      ),
                      color: colorScheme.outlineVariant,
                    ),
                  ),

                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: 0.28,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                12,
                8,
                12,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      _iconFor(
                        training.training,
                      ),
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          training.training,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Wrap(
                          spacing: 9,
                          runSpacing: 3,
                          children: [
                            _HistoryMeta(
                              icon: Icons.calendar_today_rounded,
                              text: _formatDate(
                                training.date,
                              ),
                            ),
                            _HistoryMeta(
                              icon:
                                  training.minutes >
                                      0
                                  ? Icons.timer_outlined
                                  : Icons.timer_off_outlined,
                              text:
                                  training.minutes >
                                      0
                                  ? '${training.minutes} min'
                                  : 'sem cronômetro',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Editar',
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Apagar',
                    onPressed: onDelete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  static IconData _iconFor(
    String value,
  ) {
    final lower = value.toLowerCase();

    if (lower.contains(
      'corrida',
    )) {
      return Icons.directions_run_rounded;
    }

    if (lower.contains(
      'caminhada',
    )) {
      return Icons.directions_walk_rounded;
    }

    if (lower.contains(
      'core',
    )) {
      return Icons.local_fire_department_rounded;
    }

    if (lower.contains(
      'ombro',
    )) {
      return Icons.adjust_rounded;
    }

    if (lower.contains(
      'perna',
    )) {
      return Icons.accessibility_new_rounded;
    }

    return Icons.fitness_center_rounded;
  }
}

class _HistoryMeta
    extends
        StatelessWidget {
  const _HistoryMeta({
    required this.icon,
    required this.text,
  });

  final IconData icon;

  final String text;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EMPTY
// ============================================================

class _HistoryEmptyState
    extends
        StatelessWidget {
  const _HistoryEmptyState();

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        34,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 36,
            color: colorScheme.primary,
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Nenhum treino no histórico',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            'Os treinos registrados aparecerão aqui.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
