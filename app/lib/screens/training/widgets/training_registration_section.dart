import 'package:flutter/material.dart';

import '../controllers/training_controller.dart';

import '../../../widgets/generic/activity_timer.dart';

import 'activity_card.dart';

class TrainingRegistrationSection
    extends
        StatelessWidget {
  final TrainingController controller;
  final Future<
    void
  >
  Function()
  onComplete;
  final VoidCallback onOpenHistory;

  const TrainingRegistrationSection({
    super.key,
    required this.controller,
    required this.onComplete,
    required this.onOpenHistory,
  });

  int get minutes {
    return controller.currentSeconds ~/
        60;
  }

  String get timerText {
    if (minutes ==
        0) {
      return 'Cronômetro opcional';
    }

    if (minutes ==
        1) {
      return '1 minuto registrado';
    }

    return '$minutes minutos registrados';
  }

  String get selectedActivitiesText {
    final total = controller.selectedActivities.length;

    return total ==
            1
        ? '1 atividade selecionada'
        : '$total atividades selecionadas';
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Registrar treino',
          style:
              Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Use o cronômetro ou apenas marque o que treinou hoje.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
        ),

        const SizedBox(
          height: 20,
        ),

        ActivityTimer(
          title: 'Tempo de atividade',
          onTimeChanged: controller.updateTimer,
        ),

        const SizedBox(
          height: 15,
        ),

        Card(
          child: ListTile(
            leading: const Text(
              '⏱️',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            title: const Text(
              'Tempo atual',
            ),
            subtitle: Text(
              timerText,
            ),
          ),
        ),

        const SizedBox(
          height: 22,
        ),

        const Text(
          'O que você treinou hoje?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        const Text(
          'Você pode selecionar mais de uma opção.',
        ),

        const SizedBox(
          height: 12,
        ),

        _ActivityOptions(
          controller: controller,
        ),

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
                    Icons.check,
                  ),
            label: Text(
              controller.isSaving
                  ? 'Salvando...'
                  : 'Registrar treino',
            ),
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenHistory,
            icon: const Icon(
              Icons.history,
            ),
            label: const Text(
              'Histórico 📚',
            ),
          ),
        ),
      ],
    );
  }
}

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
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

          TextButton(
            onPressed: onClear,
            child: const Text(
              'Limpar',
            ),
          ),
        ],
      ),
    );
  }
}
