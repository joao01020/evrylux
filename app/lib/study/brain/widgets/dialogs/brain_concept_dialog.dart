import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';

class BrainConceptDialog
    extends
        StatefulWidget {
  const BrainConceptDialog({
    super.key,
    this.initialConcept,
    this.initialType,
  });

  final BrainConcept? initialConcept;

  final BrainConceptType? initialType;

  @override
  State<
    BrainConceptDialog
  >
  createState() {
    return _BrainConceptDialogState();
  }
}

class _BrainConceptDialogState
    extends
        State<
          BrainConceptDialog
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _titleController;

  late final TextEditingController _descriptionController;

  // ============================================================
  // TYPE
  // ============================================================

  late BrainConceptType _type;

  // ============================================================
  // INIT
  // ============================================================

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
        widget.initialType ??
        BrainConceptType.concept;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();

    _descriptionController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    final title = _titleController.text.trim();

    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Informe o título.',
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
            'Informe a descrição.',
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

  // ============================================================
  // LABELS
  // ============================================================

  String get _titleLabel {
    switch (_type) {
      case BrainConceptType.concept:
        return 'Conceito';

      case BrainConceptType.question:
        return 'Pergunta';

      case BrainConceptType.example:
        return 'Exemplo';

      case BrainConceptType.warning:
        return 'Atenção';
    }
  }

  String get _titleHint {
    switch (_type) {
      case BrainConceptType.concept:
        return 'Ex.: Diferença entre p e *p';

      case BrainConceptType.question:
        return 'Ex.: Quando usar ponteiros?';

      case BrainConceptType.example:
        return 'Ex.: int* p = &valor;';

      case BrainConceptType.warning:
        return 'Ex.: Cuidado com ponteiros nulos';
    }
  }

  String get _descriptionLabel {
    switch (_type) {
      case BrainConceptType.concept:
        return 'Explicação';

      case BrainConceptType.question:
        return 'Resposta / contexto';

      case BrainConceptType.example:
        return 'Descrição do exemplo';

      case BrainConceptType.warning:
        return 'Detalhes da atenção';
    }
  }

  String get _descriptionHint {
    switch (_type) {
      case BrainConceptType.concept:
        return 'Explique o conceito com suas palavras.';

      case BrainConceptType.question:
        return 'Explique a dúvida ou escreva uma resposta para revisar depois.';

      case BrainConceptType.example:
        return 'Descreva o exemplo, código ou situação prática.';

      case BrainConceptType.warning:
        return 'Explique o erro comum, cuidado ou detalhe importante.';
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _type.icon,
            color: _type.color,
          ),

          const SizedBox(
            width: 10,
          ),

          Text(
            widget.initialConcept ==
                    null
                ? 'Novo ${_type.label.toLowerCase()}'
                : 'Editar ${_type.label.toLowerCase()}',
          ),
        ],
      ),

      content: SizedBox(
        width: 520,

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // TITLE
              // =================================================
              TextField(
                controller: _titleController,

                decoration: InputDecoration(
                  labelText: _titleLabel,

                  hintText: _titleHint,

                  prefixIcon: Icon(
                    _type.icon,
                    color: _type.color,
                  ),

                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // DESCRIPTION
              // =================================================
              TextField(
                controller: _descriptionController,

                minLines: 5,

                maxLines: 10,

                decoration: InputDecoration(
                  labelText: _descriptionLabel,

                  hintText: _descriptionHint,

                  alignLabelWithHint: true,

                  border: const OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 24,
              ),

              // =================================================
              // TYPE TITLE
              // =================================================
              Text(
                'Tipo de conhecimento',

                style: Theme.of(
                  context,
                ).textTheme.titleMedium,
              ),

              const SizedBox(
                height: 12,
              ),

              // =================================================
              // TYPES
              // =================================================
              Wrap(
                spacing: 10,

                runSpacing: 10,

                children: [
                  _buildTypeChip(
                    type: BrainConceptType.concept,
                  ),

                  _buildTypeChip(
                    type: BrainConceptType.question,
                  ),

                  _buildTypeChip(
                    type: BrainConceptType.example,
                  ),

                  _buildTypeChip(
                    type: BrainConceptType.warning,
                  ),
                ],
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // TYPE DESCRIPTION
              // =================================================
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 220,
                ),

                width: double.infinity,

                padding: const EdgeInsets.all(
                  14,
                ),

                decoration: BoxDecoration(
                  color: _type.color.withValues(
                    alpha: 0.10,
                  ),

                  borderRadius: BorderRadius.circular(
                    12,
                  ),

                  border: Border.all(
                    color: _type.color.withValues(
                      alpha: 0.28,
                    ),
                  ),
                ),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      _type.emoji,

                      style: const TextStyle(
                        fontSize: 22,
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Icon(
                      _type.icon,

                      color: _type.color,

                      size: 20,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            _type.label,

                            style: TextStyle(
                              color: _type.color,

                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          const SizedBox(
                            height: 4,
                          ),

                          Text(
                            _type.description,
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            'Será salvo em: ${_type.folderName}/',

                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // ACTIONS
      // ========================================================
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

          icon: Icon(
            _type.icon,
          ),

          label: const Text(
            'Salvar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TYPE CHIP
  // ============================================================

  Widget _buildTypeChip({
    required BrainConceptType type,
  }) {
    final selected =
        _type ==
        type;

    return ChoiceChip(
      selected: selected,

      onSelected:
          (
            _,
          ) {
            setState(
              () {
                _type = type;
              },
            );
          },

      avatar: Text(
        type.emoji,

        style: const TextStyle(
          fontSize: 16,
        ),
      ),

      label: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            type.icon,

            size: 17,

            color: selected
                ? Colors.white
                : type.color,
          ),

          const SizedBox(
            width: 6,
          ),

          Text(
            type.label,
          ),
        ],
      ),

      selectedColor: type.color.withValues(
        alpha: 0.80,
      ),

      side: BorderSide(
        color: selected
            ? type.color
            : type.color.withValues(
                alpha: 0.28,
              ),
      ),
    );
  }
}
