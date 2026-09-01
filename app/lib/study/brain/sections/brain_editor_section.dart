import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import '../widgets/buttons/brain_save_button.dart';

// ============================================================
// BRAIN EDITOR SECTION
// ============================================================
//
// Responsabilidade:
//
// - editar tema;
// - editar título;
// - editar conteúdo;
// - salvar;
// - solicitar exclusão REAL da anotação selecionada.
//
// IMPORTANTE:
//
// Este widget NÃO apaga arquivos diretamente.
// Ele chama [onDelete] e deixa o BrainController / Repository
// executarem:
//
// local -> SyncQueue -> Supabase.
//
// ============================================================

class BrainEditorSection
    extends
        StatelessWidget {
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

  // ============================================================
  // DATA
  // ============================================================

  final BrainFile? selectedNote;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController topicController;

  final TextEditingController titleController;

  final TextEditingController contentController;

  final FocusNode contentFocusNode;

  // ============================================================
  // STATE
  // ============================================================

  final bool isSaving;

  // ============================================================
  // ACTIONS
  // ============================================================

  final VoidCallback onSave;

  final Future<
    void
  >
  Function(
    BrainFile note,
  )
  onDelete;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final note = selectedNote;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // TITLE
        // ======================================================
        Text(
          note ==
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

        // ======================================================
        // TOPIC
        // ======================================================
        TextField(
          controller: topicController,
          enabled: !isSaving,
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

        // ======================================================
        // TITLE
        // ======================================================
        TextField(
          controller: titleController,
          enabled: !isSaving,
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

        // ======================================================
        // CONTENT
        // ======================================================
        TextField(
          controller: contentController,
          focusNode: contentFocusNode,
          enabled: !isSaving,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,

          // Começa pequena e cresce conforme o conteúdo.
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

        // ======================================================
        // SAVE
        // ======================================================
        BrainSaveButton(
          isSaving: isSaving,
          onPressed: onSave,
        ),

        // ======================================================
        // DELETE
        // ======================================================
        if (note !=
            null) ...[
          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSaving
                  ? null
                  : () async {
                      await _confirmDelete(
                        context,
                        note,
                      );
                    },
              icon: const Icon(
                Icons.delete_outline_rounded,
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

  // ============================================================
  // CONFIRM DELETE
  // ============================================================

  Future<
    void
  >
  _confirmDelete(
    BuildContext context,
    BrainFile note,
  ) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: true,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir anotação?',
                  ),
                  content: Text(
                    '"${note.title.trim().isEmpty ? 'Sem título' : note.title.trim()}" '
                    'será removida deste dispositivo e a exclusão será '
                    'sincronizada com a nuvem.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
        true) {
      return;
    }

    await onDelete(
      note,
    );
  }
}
