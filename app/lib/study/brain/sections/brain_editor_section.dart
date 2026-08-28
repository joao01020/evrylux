import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import '../widgets/buttons/brain_save_button.dart';

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
          height: 4,
        ),

        Text(
          'Organize seu conhecimento por tema e salve em Markdown.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
        ),

        const SizedBox(
          height: 16,
        ),

        TextField(
          controller: topicController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Tema',
            hintText: 'Ex.: Programação C++',
            prefixIcon: Icon(
              Icons.folder_outlined,
              size: 20,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        TextField(
          controller: titleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Ex.: Assunto aprendido hoje',
            prefixIcon: Icon(
              Icons.title,
              size: 20,
            ),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        TextField(
          controller: contentController,
          focusNode: contentFocusNode,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,

          // Começa pequena e aumenta conforme você escreve.
          minLines: 1,
          maxLines: null,

          decoration: const InputDecoration(
            labelText: 'Anotação em Markdown',
            hintText: 'Escreva o conteúdo com suas palavras',
            alignLabelWithHint: true,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        BrainSaveButton(
          isSaving: isSaving,
          onPressed: onSave,
        ),

        if (selectedNote !=
            null) ...[
          const SizedBox(
            height: 8,
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
                size: 20,
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
