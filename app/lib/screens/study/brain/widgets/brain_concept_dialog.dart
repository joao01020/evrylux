import 'package:flutter/material.dart';

import '../models/brain_concept.dart';

class BrainConceptDialog
    extends
        StatefulWidget {
  const BrainConceptDialog({
    super.key,
    this.initialConcept,
  });

  final BrainConcept? initialConcept;

  @override
  State<
    BrainConceptDialog
  >
  createState() => _BrainConceptDialogState();
}

class _BrainConceptDialogState
    extends
        State<
          BrainConceptDialog
        > {
  late final TextEditingController _titleController;

  late final TextEditingController _descriptionController;

  BrainConceptType _type = BrainConceptType.memorize;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text:
          widget.initialConcept?.title ??
          '',
    );

    _descriptionController = TextEditingController(
      text:
          widget.initialConcept?.description ??
          '',
    );

    _type =
        widget.initialConcept?.type ??
        BrainConceptType.memorize;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();

    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();

    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o conceito.',
          ),
        ),
      );

      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Explique o conceito.',
          ),
        ),
      );

      return;
    }

    Navigator.pop(
      context,
      BrainConcept(
        id:
            widget.initialConcept?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        description: description,
        type: _type,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text(
        widget.initialConcept ==
                null
            ? 'Novo conhecimento'
            : 'Editar conhecimento',
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Conceito',
                  hintText: 'Ex.: Diferença entre p e *p',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller: _descriptionController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Explicação',
                  hintText: 'Explique o conceito com suas palavras.',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              Text(
                'Objetivo',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium,
              ),

              const SizedBox(
                height: 12,
              ),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ChoiceChip(
                    avatar: const Icon(
                      Icons.bookmark_outline,
                      size: 18,
                    ),
                    label: const Text(
                      'Guardar',
                    ),
                    selected:
                        _type ==
                        BrainConceptType.keep,
                    onSelected:
                        (
                          _,
                        ) {
                          setState(
                            () {
                              _type = BrainConceptType.keep;
                            },
                          );
                        },
                  ),

                  ChoiceChip(
                    avatar: const Icon(
                      Icons.psychology_alt_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Memorizar',
                    ),
                    selected:
                        _type ==
                        BrainConceptType.memorize,
                    onSelected:
                        (
                          _,
                        ) {
                          setState(
                            () {
                              _type = BrainConceptType.memorize;
                            },
                          );
                        },
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                width: double.infinity,
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _type ==
                              BrainConceptType.memorize
                          ? Icons.psychology
                          : Icons.bookmark_outline,
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Text(
                        _type ==
                                BrainConceptType.memorize
                            ? 'Este conhecimento será incluído no sistema de revisões espaçadas e poderá gerar perguntas automaticamente no futuro.'
                            : 'Este conhecimento ficará salvo apenas como referência para consultas futuras.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child: const Text(
            'Cancelar',
          ),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(
            Icons.save_outlined,
          ),
          label: const Text(
            'Salvar',
          ),
        ),
      ],
    );
  }
}
