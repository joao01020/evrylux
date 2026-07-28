import 'package:flutter/material.dart';

class TrainingConsistencyCard extends StatelessWidget {
  final double consistency;
  final int completedTrainings;
  final int expectedTrainings;
  final int weeklyGoal;

  const TrainingConsistencyCard({
    super.key,
    required this.consistency,
    required this.completedTrainings,
    required this.expectedTrainings,
    required this.weeklyGoal,
  });

  // =========================================================
  // MENSAGEM PRINCIPAL
  // =========================================================

  String get consistencyMessage {
    if (completedTrainings == 0) {
      return 'Seu ritmo começa com o primeiro treino.';
    }

    if (consistency >= 1.0) {
      return 'Você está acompanhando ou superando seu plano.';
    }

    if (consistency >= 0.75) {
      return 'Você está muito próximo do ritmo planejado.';
    }

    if (consistency >= 0.5) {
      return 'Seu ritmo continua vivo. Continue construindo.';
    }

    return 'Você já começou. Agora pode recuperar seu ritmo aos poucos.';
  }

  // =========================================================
  // TEXTO DOS TREINOS REALIZADOS
  // =========================================================

  String get completedTrainingsText {
    if (completedTrainings == 1) {
      return '1 treino realizado';
    }

    return '$completedTrainings treinos realizados';
  }

  // =========================================================
  // TEXTO DOS TREINOS PLANEJADOS
  // =========================================================

  String get expectedTrainingsText {
    if (expectedTrainings == 1) {
      return '1 treino planejado';
    }

    return '$expectedTrainings treinos planejados';
  }

  // =========================================================
  // TEXTO DA META SEMANAL
  // =========================================================

  String get weeklyGoalText {
    if (weeklyGoal == 1) {
      return 'Treinar 1 dia por semana';
    }

    return 'Treinar $weeklyGoal dias por semana';
  }

  // =========================================================
  // RESUMO PRINCIPAL
  // =========================================================

  String get progressSummary {
    if (expectedTrainings <= 0) {
      return 'Defina seu plano semanal para acompanhar seu ritmo.';
    }

    if (completedTrainings == 1 && expectedTrainings == 1) {
      return 'Você cumpriu o treino planejado até agora.';
    }

    return 'Você cumpriu $completedTrainings dos '
        '$expectedTrainings treinos planejados até agora.';
  }

  @override
  Widget build(BuildContext context) {
    final safeConsistency = consistency.clamp(0.0, 1.0);

    final percentage = (safeConsistency * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // CABEÇALHO
            // =================================================
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.local_fire_department_outlined),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    'Seu ritmo neste mês',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '$percentage%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =================================================
            // BARRA DE CONSISTÊNCIA
            // =================================================
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: safeConsistency,
                minHeight: 12,
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // RESUMO PRINCIPAL
            // =================================================
            Text(
              progressSummary,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              consistencyMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            // =================================================
            // INFORMAÇÕES DETALHADAS
            // =================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _ConsistencyInformation(
                    icon: Icons.check_circle_outline,
                    title: completedTrainingsText,
                    description:
                        'Dias em que você registrou pelo menos um treino neste mês.',
                  ),

                  const SizedBox(height: 14),

                  const Divider(height: 1),

                  const SizedBox(height: 14),

                  _ConsistencyInformation(
                    icon: Icons.flag_outlined,
                    title: expectedTrainingsText,
                    description:
                        'Quantidade de treinos que acompanharia seu plano até hoje.',
                  ),

                  const SizedBox(height: 14),

                  const Divider(height: 1),

                  const SizedBox(height: 14),

                  _ConsistencyInformation(
                    icon: Icons.calendar_today_outlined,
                    title: weeklyGoalText,
                    description: 'Este é o plano semanal que você escolheu.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsistencyInformation extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ConsistencyInformation({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
