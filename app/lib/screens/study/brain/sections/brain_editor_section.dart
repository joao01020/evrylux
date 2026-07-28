import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import '../widgets/brain_save_button.dart';

class BrainEditorSection
    extends
        StatelessWidget {
  final BrainFile? selectedNote;

  final TextEditingController topicController;
  final TextEditingController titleController;
  final TextEditingController contentController;

  final FocusNode contentFocusNode;

  final bool isSaving;

  final VoidCallback onSave;
  final ValueChanged<
    BrainFile
  >
  onDelete;

  const BrainEditorSection({
    super.key,
    required this.selectedNote,
    required this.topicController,
    required this.titleController,
    required this.contentController,
    required this.contentFocusNode,
    required this.isSaving,
    required this.onSave,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedNote ==
                  null
              ? 'Nova anotação'
              : 'Editando anotação',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall,
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Organize seu conhecimento por tema e salve em Markdown.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
        ),

        const SizedBox(
          height: 24,
        ),

        TextField(
          controller: topicController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Tema',
            hintText: 'Ex.: Programação C++',
            prefixIcon: Icon(
              Icons.folder_outlined,
            ),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        TextField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Ex.: Assunto aprendido hoje',
            prefixIcon: Icon(
              Icons.title,
            ),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 16,
        ),

        TextField(
          controller: contentController,
          focusNode: contentFocusNode,
          minLines: 14,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'Anotação em Markdown',
            hintText:
                '## O que aprendi\n\n'
                '## Resumo\n\n'
                'Explique o conteúdo com suas palavras.',
            alignLabelWithHint: true,
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 18,
        ),

        BrainSaveButton(
          isSaving: isSaving,
          onPressed: onSave,
        ),

        if (selectedNote !=
            null) ...[
          const SizedBox(
            height: 10,
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final note = selectedNote;

                if (note ==
                    null) {
                  return;
                }

                onDelete(
                  note,
                );
              },
              icon: const Icon(
                Icons.delete_outline,
              ),
              label: const Text(
                'Excluir anotação',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
