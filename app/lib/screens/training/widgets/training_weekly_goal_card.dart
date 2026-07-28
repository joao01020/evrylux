import 'package:flutter/material.dart';

class TrainingWeeklyGoalCard extends StatelessWidget {
  final int weeklyGoal;
  final ValueChanged<int> onGoalChanged;

  const TrainingWeeklyGoalCard({
    super.key,
    required this.weeklyGoal,
    required this.onGoalChanged,
  });

  Future<void> _openDialog(BuildContext context) async {
    int selectedGoal = weeklyGoal;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar plano semanal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quantos dias por semana você pretende treinar?'),

                  const SizedBox(height: 24),

                  _GoalSelector(
                    value: selectedGoal,
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGoal = value;
                      });
                    },
                  ),

                  const SizedBox(height: 18),

                  Slider(
                    value: selectedGoal.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    label: '$selectedGoal',
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGoal = value.round();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Essa meta será usada para comparar quantos dias você planejou treinar com quantos dias realmente treinou.',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selectedGoal);
                  },
                  child: const Text('Salvar meta'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    onGoalChanged(result);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == 1
              ? 'Meta alterada para 1 dia por semana.'
              : 'Meta alterada para $result dias por semana.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () {
          _openDialog(context);
        },
        leading: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.calendar_month_outlined),
        ),
        title: const Text(
          'Seu plano semanal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          weeklyGoal == 1
              ? 'Treinar 1 dia por semana'
              : 'Treinar $weeklyGoal dias por semana',
        ),
        trailing: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _GoalSelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _GoalSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: value > 1
              ? () {
                  onChanged(value - 1);
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: 'Diminuir',
        ),
        Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
            ),
            Text(value == 1 ? 'dia por semana' : 'dias por semana'),
          ],
        ),
        IconButton(
          onPressed: value < 7
              ? () {
                  onChanged(value + 1);
                }
              : null,
          icon: const Icon(Icons.add_circle_outline),
          tooltip: 'Aumentar',
        ),
      ],
    );
  }
}
