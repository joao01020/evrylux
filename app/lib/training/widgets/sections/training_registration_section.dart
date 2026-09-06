import 'package:flutter/material.dart';

import '../../controllers/training_controller.dart';

class TrainingRegistrationSection
    extends
        StatelessWidget {
  const TrainingRegistrationSection({
    super.key,
    required this.controller,
    required this.onComplete,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final TrainingController controller;

  // ============================================================
  // ACTION
  // ============================================================

  final Future<
    void
  >
  Function()
  onComplete;

  // ============================================================
  // SELECTED COUNT
  // ============================================================

  int get _selectedCount {
    return controller.selectedActivities.length;
  }

  // ============================================================
  // SELECTED TEXT
  // ============================================================

  String get _selectedActivitiesText {
    if (_selectedCount ==
        0) {
      return 'Nenhuma atividade selecionada';
    }

    if (_selectedCount ==
        1) {
      return '1 atividade selecionada';
    }

    return '$_selectedCount atividades selecionadas';
  }

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // INTRO
        // ======================================================
        _SectionHeader(
          selectedCount: _selectedCount,
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // ACTIVITIES
        // ======================================================
        _ActivityOptions(
          controller: controller,
        ),

        // ======================================================
        // SELECTED
        // ======================================================
        AnimatedSize(
          duration: const Duration(
            milliseconds: 220,
          ),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: controller.selectedActivities.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(
                    top: 18,
                  ),
                  child: _SelectedActivitiesCard(
                    activities: controller.selectedActivities.toList(),
                    text: _selectedActivitiesText,
                    onClear: controller.clearSelectedActivities,
                    onRemove:
                        (
                          activity,
                        ) {
                          controller.toggleActivity(
                            activity,
                          );
                        },
                  ),
                ),
        ),

        const SizedBox(
          height: 24,
        ),

        // ======================================================
        // DIVIDER
        // ======================================================
        Divider(
          height: 1,
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.55,
          ),
        ),

        const SizedBox(
          height: 20,
        ),

        // ======================================================
        // SAVE
        // ======================================================
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed:
                controller.selectedActivities.isEmpty ||
                    controller.isSaving
                ? null
                : onComplete,

            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,

              foregroundColor: colorScheme.onPrimary,

              disabledBackgroundColor: colorScheme.surfaceContainerHighest,

              disabledForegroundColor: colorScheme.onSurfaceVariant.withValues(
                alpha: 0.55,
              ),

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  15,
                ),
              ),
            ),

            icon: controller.isSaving
                ? SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                  ),

            label: Text(
              controller.isSaving
                  ? 'Registrando treino...'
                  : _selectedCount ==
                        0
                  ? 'Selecione uma atividade'
                  : _selectedCount ==
                        1
                  ? 'Registrar treino'
                  : 'Registrar $_selectedCount atividades',

              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Center(
          child: Text(
            'O registro será usado para acompanhar sua evolução.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(
                alpha: 0.72,
              ),
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HEADER
// ============================================================

class _SectionHeader
    extends
        StatelessWidget {
  const _SectionHeader({
    required this.selectedCount,
  });

  final int selectedCount;

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ICON
        // ======================================================
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: colorScheme.primary.withValues(
                alpha: 0.11,
              ),
            ),
          ),
          child: Icon(
            Icons.fitness_center_rounded,
            size: 21,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        // ======================================================
        // TEXT
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'O que você treinou?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              Text(
                'Selecione uma ou mais atividades realizadas hoje.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // COUNTER
        // ======================================================
        AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color:
                selectedCount >
                    0
                ? colorScheme.primary.withValues(
                    alpha: 0.09,
                  )
                : colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
            borderRadius: BorderRadius.circular(
              999,
            ),
            border: Border.all(
              color:
                  selectedCount >
                      0
                  ? colorScheme.primary.withValues(
                      alpha: 0.13,
                    )
                  : colorScheme.outlineVariant.withValues(
                      alpha: 0.55,
                    ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selectedCount >
                        0
                    ? Icons.check_rounded
                    : Icons.touch_app_outlined,
                size: 13,
                color:
                    selectedCount >
                        0
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),

              const SizedBox(
                width: 5,
              ),

              Text(
                selectedCount ==
                        0
                    ? 'Selecione'
                    : '$selectedCount selecionada${selectedCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color:
                      selectedCount >
                          0
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTIVITY OPTIONS
// ============================================================

class _ActivityOptions
    extends
        StatelessWidget {
  const _ActivityOptions({
    required this.controller,
  });

  final TrainingController controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            // ======================================================
            // RESPONSIVE WIDTH
            // ======================================================

            final available = constraints.maxWidth;

            final columns =
                available >=
                    560
                ? 4
                : available >=
                      390
                ? 3
                : 2;

            const spacing = 10.0;

            final cardWidth =
                (available -
                    (spacing *
                        (columns -
                            1))) /
                columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: TrainingController.activityOptions.map(
                (
                  activity,
                ) {
                  return SizedBox(
                    width: cardWidth,
                    child: _ModernActivityCard(
                      activity: activity,
                      selected: controller.isActivitySelected(
                        activity,
                      ),
                      onTap: () {
                        controller.toggleActivity(
                          activity,
                        );
                      },
                    ),
                  );
                },
              ).toList(),
            );
          },
    );
  }
}

// ============================================================
// MODERN ACTIVITY CARD
// ============================================================

class _ModernActivityCard
    extends
        StatefulWidget {
  const _ModernActivityCard({
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final String activity;

  final bool selected;

  final VoidCallback onTap;

  @override
  State<
    _ModernActivityCard
  >
  createState() {
    return _ModernActivityCardState();
  }
}

class _ModernActivityCardState
    extends
        State<
          _ModernActivityCard
        > {
  // ============================================================
  // HOVER
  // ============================================================

  bool _hovered = false;

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

    final info = _ActivityVisual.from(
      widget.activity,
    );

    final selected = widget.selected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter:
          (
            _,
          ) {
            setState(
              () {
                _hovered = true;
              },
            );
          },

      onExit:
          (
            _,
          ) {
            setState(
              () {
                _hovered = false;
              },
            );
          },

      child: AnimatedScale(
        duration: const Duration(
          milliseconds: 150,
        ),

        curve: Curves.easeOutCubic,

        scale: _hovered
            ? 1.018
            : 1,

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          curve: Curves.easeOutCubic,

          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(
                    alpha: 0.075,
                  )
                : _hovered
                ? colorScheme.surfaceContainerLowest
                : colorScheme.surface,

            borderRadius: BorderRadius.circular(
              16,
            ),

            border: Border.all(
              width: selected
                  ? 1.4
                  : 1,

              color: selected
                  ? colorScheme.primary.withValues(
                      alpha: 0.60,
                    )
                  : _hovered
                  ? colorScheme.primary.withValues(
                      alpha: 0.24,
                    )
                  : colorScheme.outlineVariant.withValues(
                      alpha: 0.70,
                    ),
            ),

            boxShadow:
                _hovered ||
                    selected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: 0.06,
                      ),
                      blurRadius: 16,
                      offset: const Offset(
                        0,
                        5,
                      ),
                    ),
                  ]
                : const [],
          ),

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: widget.onTap,

              borderRadius: BorderRadius.circular(
                16,
              ),

              child: Padding(
                padding: const EdgeInsets.all(
                  12,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==========================================
                    // TOP
                    // ==========================================
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 180,
                          ),

                          width: 38,

                          height: 38,

                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest.withValues(
                                    alpha: 0.62,
                                  ),

                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: Icon(
                            info.icon,

                            size: 19,

                            color: selected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),

                        const Spacer(),

                        AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 150,
                          ),

                          child: selected
                              ? Container(
                                  key: const ValueKey(
                                    'selected',
                                  ),

                                  width: 24,
                                  height: 24,

                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),

                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : Container(
                                  key: const ValueKey(
                                    'unselected',
                                  ),

                                  width: 24,
                                  height: 24,

                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 11,
                    ),

                    // ==========================================
                    // LABEL
                    // ==========================================
                    Text(
                      info.label,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      info.description,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.74,
                        ),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ACTIVITY VISUAL
// ============================================================

class _ActivityVisual {
  const _ActivityVisual({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;

  final String description;

  final IconData icon;

  // ============================================================
  // FROM ACTIVITY
  // ============================================================

  factory _ActivityVisual.from(
    String activity,
  ) {
    final normalized = activity.toLowerCase();

    final cleanLabel = _cleanActivityName(
      activity,
    );

    // ==========================================================
    // PEITO
    // ==========================================================

    if (normalized.contains(
      'peito',
    )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Peitoral',
        icon: Icons.fitness_center_rounded,
      );
    }

    // ==========================================================
    // PERNAS
    // ==========================================================

    if (normalized.contains(
          'perna',
        ) ||
        normalized.contains(
          'leg',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Membros inferiores',
        icon: Icons.directions_run_rounded,
      );
    }

    // ==========================================================
    // BRAÇO
    // ==========================================================

    if (normalized.contains(
          'braço',
        ) ||
        normalized.contains(
          'braco',
        ) ||
        normalized.contains(
          'bíceps',
        ) ||
        normalized.contains(
          'biceps',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Braços',
        icon: Icons.sports_gymnastics_rounded,
      );
    }

    // ==========================================================
    // COSTAS
    // ==========================================================

    if (normalized.contains(
      'costas',
    )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Dorsais',
        icon: Icons.accessibility_new_rounded,
      );
    }

    // ==========================================================
    // OMBRO
    // ==========================================================

    if (normalized.contains(
      'ombro',
    )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Deltoides',
        icon: Icons.sports_martial_arts_rounded,
      );
    }

    // ==========================================================
    // CORE
    // ==========================================================

    if (normalized.contains(
          'core',
        ) ||
        normalized.contains(
          'abd',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Centro corporal',
        icon: Icons.adjust_rounded,
      );
    }

    // ==========================================================
    // CORRIDA
    // ==========================================================

    if (normalized.contains(
          'corrida',
        ) ||
        normalized.contains(
          'correr',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Cardio',
        icon: Icons.directions_run_rounded,
      );
    }

    // ==========================================================
    // CAMINHADA
    // ==========================================================

    if (normalized.contains(
      'caminhada',
    )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Movimento',
        icon: Icons.directions_walk_rounded,
      );
    }

    // ==========================================================
    // BIKE
    // ==========================================================

    if (normalized.contains(
          'bike',
        ) ||
        normalized.contains(
          'cicl',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Cardio',
        icon: Icons.directions_bike_rounded,
      );
    }

    // ==========================================================
    // NATAÇÃO
    // ==========================================================

    if (normalized.contains(
          'nata',
        ) ||
        normalized.contains(
          'swim',
        )) {
      return _ActivityVisual(
        label: cleanLabel,
        description: 'Corpo inteiro',
        icon: Icons.pool_rounded,
      );
    }

    // ==========================================================
    // DEFAULT
    // ==========================================================

    return _ActivityVisual(
      label: cleanLabel,
      description: 'Atividade',
      icon: Icons.fitness_center_rounded,
    );
  }

  // ============================================================
  // CLEAN NAME
  // ============================================================

  static String _cleanActivityName(
    String value,
  ) {
    final result = value
        .replaceAll(
          RegExp(
            r'^[^\p{L}\p{N}]+',
            unicode: true,
          ),
          '',
        )
        .trim();

    if (result.isEmpty) {
      return value.trim();
    }

    return result;
  }
}

// ============================================================
// SELECTED ACTIVITIES
// ============================================================

class _SelectedActivitiesCard
    extends
        StatelessWidget {
  const _SelectedActivitiesCard({
    required this.activities,
    required this.text,
    required this.onClear,
    required this.onRemove,
  });

  final List<
    String
  >
  activities;

  final String text;

  final VoidCallback onClear;

  final ValueChanged<
    String
  >
  onRemove;

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

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        15,
      ),

      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(
          alpha: 0.055,
        ),

        borderRadius: BorderRadius.circular(
          16,
        ),

        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.15,
          ),
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              Container(
                width: 30,
                height: 30,

                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),

                child: Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  text,

                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: onClear,

                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),

                  minimumSize: Size.zero,

                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),

                icon: const Icon(
                  Icons.delete_sweep_outlined,
                  size: 15,
                ),

                label: const Text(
                  'Limpar',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // CHIPS
          // ====================================================
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: activities.map(
              (
                activity,
              ) {
                final info = _ActivityVisual.from(
                  activity,
                );

                return Container(
                  padding: const EdgeInsets.fromLTRB(
                    9,
                    5,
                    5,
                    5,
                  ),

                  decoration: BoxDecoration(
                    color: colorScheme.surface,

                    borderRadius: BorderRadius.circular(
                      999,
                    ),

                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(
                        alpha: 0.68,
                      ),
                    ),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      Icon(
                        info.icon,
                        size: 13,
                        color: colorScheme.primary,
                      ),

                      const SizedBox(
                        width: 5,
                      ),

                      Text(
                        info.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        width: 3,
                      ),

                      InkWell(
                        onTap: () {
                          onRemove(
                            activity,
                          );
                        },

                        borderRadius: BorderRadius.circular(
                          999,
                        ),

                        child: Padding(
                          padding: const EdgeInsets.all(
                            3,
                          ),

                          child: Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}
