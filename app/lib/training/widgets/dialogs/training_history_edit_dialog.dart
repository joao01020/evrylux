import 'package:flutter/material.dart';

import '../../models/training_model.dart';

// ============================================================
// TRAINING HISTORY EDIT DIALOG
// ============================================================
//
// Modal pequeno usado para editar:
//
// - atividade;
// - data;
// - duração.
//
// ============================================================

class TrainingHistoryEditDialog
    extends
        StatefulWidget {
  const TrainingHistoryEditDialog({
    super.key,
    required this.training,
  });

  final TrainingModel training;

  static Future<
    TrainingModel?
  >
  show(
    BuildContext context, {
    required TrainingModel training,
  }) {
    return showDialog<
      TrainingModel
    >(
      context: context,
      builder:
          (
            context,
          ) {
            return TrainingHistoryEditDialog(
              training: training,
            );
          },
    );
  }

  @override
  State<
    TrainingHistoryEditDialog
  >
  createState() => _TrainingHistoryEditDialogState();
}

class _TrainingHistoryEditDialogState
    extends
        State<
          TrainingHistoryEditDialog
        > {
  static const List<
    String
  >
  _activities =
      <
        String
      >[
        '🏋️ Peito',
        '🦵 Pernas',
        '💪 Braço',
        '🧱 Costas',
        '🎯 Ombro',
        '🔥 Core',
        '🏃 Corrida',
        '🚶 Caminhada',
      ];

  late String _activity;

  late DateTime _date;

  late TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();

    _activity =
        _activities.contains(
          widget.training.training,
        )
        ? widget.training.training
        : _activities.first;

    _date = widget.training.date.toLocal();

    _minutesController = TextEditingController(
      text: widget.training.minutes.toString(),
    );
  }

  @override
  void dispose() {
    _minutesController.dispose();

    super.dispose();
  }

  String _dayName(
    DateTime date,
  ) {
    const names =
        <
          String
        >[
          'segunda',
          'terça',
          'quarta',
          'quinta',
          'sexta',
          'sábado',
          'domingo',
        ];

    return names[date.weekday -
        1];
  }

  String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<
    void
  >
  _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(
        2020,
      ),
      lastDate: DateTime(
        2100,
      ),
    );

    if (picked ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          widget.training.date.hour,
          widget.training.date.minute,
          widget.training.date.second,
        );
      },
    );
  }

  void _save() {
    final minutes = int.tryParse(
      _minutesController.text.trim(),
    );

    if (minutes ==
            null ||
        minutes <
            0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe uma duração válida.',
          ),
        ),
      );

      return;
    }

    Navigator.of(
      context,
    ).pop(
      TrainingModel(
        day: _dayName(
          _date,
        ),
        training: _activity,
        minutes: minutes,
        date: _date,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 430,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            20,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x22000000,
                ),
                blurRadius: 28,
                offset: Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_calendar_rounded,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editar treino',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(
                          height: 2,
                        ),
                        Text(
                          'Atualize os dados deste registro.',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              DropdownButtonFormField<
                String
              >(
                initialValue: _activity,
                decoration: const InputDecoration(
                  labelText: 'Atividade',
                  prefixIcon: Icon(
                    Icons.fitness_center_rounded,
                  ),
                  border: OutlineInputBorder(),
                ),
                items: _activities
                    .map(
                      (
                        value,
                      ) =>
                          DropdownMenuItem<
                            String
                          >(
                            value: value,
                            child: Text(
                              value,
                            ),
                          ),
                    )
                    .toList(
                      growable: false,
                    ),
                onChanged:
                    (
                      value,
                    ) {
                      if (value ==
                          null) {
                        return;
                      }

                      setState(
                        () {
                          _activity = value;
                        },
                      );
                    },
              ),

              const SizedBox(
                height: 14,
              ),

              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data',
                    prefixIcon: Icon(
                      Icons.calendar_today_rounded,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _formatDate(
                      _date,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 14,
              ),

              TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duração em minutos',
                  prefixIcon: Icon(
                    Icons.timer_outlined,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();
                    },
                    child: const Text(
                      'Cancelar',
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.check_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Salvar alterações',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
