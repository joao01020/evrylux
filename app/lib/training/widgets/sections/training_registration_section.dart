import 'package:flutter/material.dart';

import '../../controllers/training_controller.dart';

import '../cards/activity_card.dart';

class TrainingRegistrationSection
    extends
        StatelessWidget {
  final TrainingController controller;

  final Future<
    void
  >
  Function()
  onComplete;

  const TrainingRegistrationSection({
    super.key,
    required this.controller,
    required this.onComplete,
  });

  // ============================================================
  // ATIVIDADES SELECIONADAS
  // ============================================================

  String get selectedActivitiesText {
    final total = controller.selectedActivities.length;

    return total ==
            1
        ? '1 atividade selecionada'
        : '$total atividades selecionadas';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ATIVIDADES
        // ======================================================
        Row(
          children: [
            Icon(
              Icons.sports_gymnastics_rounded,
              color: colorScheme.primary,
              size: 21,
            ),

            const SizedBox(
              width: 9,
            ),

            const Expanded(
              child: Text(
                'O que você treinou hoje?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 6,
        ),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.library_add_check_rounded,
              size: 17,
              color: colorScheme.onSurfaceVariant,
            ),

            const SizedBox(
              width: 8,
            ),

            const Expanded(
              child: Text(
                'Você pode selecionar mais de uma opção.',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 14,
        ),

        // ======================================================
        // OPÇÕES
        // ======================================================
        _ActivityOptions(
          controller: controller,
        ),

        // ======================================================
        // SELECIONADOS
        // ======================================================
        if (controller.selectedActivities.isNotEmpty) ...[
          const SizedBox(
            height: 16,
          ),

          _SelectedActivitiesCard(
            text: selectedActivitiesText,
            onClear: controller.clearSelectedActivities,
          ),
        ],

        const SizedBox(
          height: 22,
        ),

        // ======================================================
        // REGISTRAR
        // ======================================================
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed:
                controller.selectedActivities.isEmpty ||
                    controller.isSaving
                ? null
                : onComplete,
            icon: controller.isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save_alt_rounded,
                  ),
            label: Text(
              controller.isSaving
                  ? 'Salvando...'
                  : 'Registrar treino',
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// OPÇÕES DE ATIVIDADE
// ============================================================

class _ActivityOptions
    extends
        StatelessWidget {
  final TrainingController controller;

  const _ActivityOptions({
    required this.controller,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: TrainingController.activityOptions.map(
        (
          activity,
        ) {
          return SizedBox(
            width: 105,
            child: ActivityCard(
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
  }
}

// ============================================================
// ATIVIDADES SELECIONADAS
// ============================================================

class _SelectedActivitiesCard
    extends
        StatelessWidget {
  final String text;

  final VoidCallback onClear;

  const _SelectedActivitiesCard({
    required this.text,
    required this.onClear,
  });

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
        14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // SELECIONADOS
          // ====================================================
          Icon(
            Icons.check_circle_rounded,
            color: colorScheme.onPrimaryContainer,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ====================================================
          // LIMPAR
          // ====================================================
          TextButton.icon(
            onPressed: onClear,
            icon: const Icon(
              Icons.clear_all_rounded,
              size: 18,
            ),
            label: const Text(
              'Limpar',
            ),
          ),
        ],
      ),
    );
  }
}
