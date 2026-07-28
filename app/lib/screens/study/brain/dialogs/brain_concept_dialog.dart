import 'package:flutter/material.dart';

enum BrainConceptCategory { concept, question, example, warning }

extension BrainConceptCategoryExtension on BrainConceptCategory {
  String get label {
    switch (this) {
      case BrainConceptCategory.concept:
        return 'Conceito';

      case BrainConceptCategory.question:
        return 'Pergunta';

      case BrainConceptCategory.example:
        return 'Exemplo';

      case BrainConceptCategory.warning:
        return 'Atenção';
    }
  }

  String get description {
    switch (this) {
      case BrainConceptCategory.concept:
        return 'Uma ideia principal do conteúdo.';

      case BrainConceptCategory.question:
        return 'Uma pergunta para revisar depois.';

      case BrainConceptCategory.example:
        return 'Um exemplo prático do conteúdo.';

      case BrainConceptCategory.warning:
        return 'Um detalhe importante ou erro comum.';
    }
  }

  IconData get icon {
    switch (this) {
      case BrainConceptCategory.concept:
        return Icons.lightbulb_outline;

      case BrainConceptCategory.question:
        return Icons.help_outline;

      case BrainConceptCategory.example:
        return Icons.code_outlined;

      case BrainConceptCategory.warning:
        return Icons.warning_amber_outlined;
    }
  }
}

class BrainConceptDialogResult {
  final String title;
  final String description;
  final BrainConceptCategory category;

  const BrainConceptDialogResult({
    required this.title,
    required this.description,
    required this.category,
  });
}

class BrainConceptDialog extends StatefulWidget {
  final BrainConceptDialogResult? initialValue;

  const BrainConceptDialog({super.key, this.initialValue});

  static Future<BrainConceptDialogResult?> show({
    required BuildContext context,
    BrainConceptDialogResult? initialValue,
  }) {
    return showDialog<BrainConceptDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BrainConceptDialog(initialValue: initialValue);
      },
    );
  }

  @override
  State<BrainConceptDialog> createState() {
    return _BrainConceptDialogState();
  }
}

class _BrainConceptDialogState extends State<BrainConceptDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;

  late final TextEditingController _descriptionController;

  late BrainConceptCategory _selectedCategory;

  bool get _isEditing {
    return widget.initialValue != null;
  }

  @override
  void initState() {
    super.initState();

    final initialValue = widget.initialValue;

    _titleController = TextEditingController(text: initialValue?.title ?? '');

    _descriptionController = TextEditingController(
      text: initialValue?.description ?? '',
    );

    _selectedCategory = initialValue?.category ?? BrainConceptCategory.concept;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _save() {
    final formState = _formKey.currentState;

    if (formState == null) {
      return;
    }

    if (!formState.validate()) {
      return;
    }

    final result = BrainConceptDialogResult(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _selectedCategory,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Editar conceito' : 'Adicionar conceito'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    hintText: 'Ex.: Ponteiros em C++',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final title = value?.trim() ?? '';

                    if (title.isEmpty) {
                      return 'Informe o título do conceito.';
                    }

                    if (title.length < 3) {
                      return 'O título precisa ter pelo menos 3 caracteres.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Explique este conceito com suas palavras.',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.notes_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final description = value?.trim() ?? '';

                    if (description.isEmpty) {
                      return 'Escreva uma descrição.';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 20),

                Text(
                  'Tipo do conceito',
                  style: Theme.of(context).textTheme.titleMedium,
                ),

                const SizedBox(height: 10),

                ...BrainConceptCategory.values.map((category) {
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(category.icon),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    category.description,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),

                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),

        FilledButton.icon(
          onPressed: _save,
          icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
          label: Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
        ),
      ],
    );
  }
}
