import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import '../widgets/buttons/brain_save_button.dart';

// ============================================================
// BRAIN EDITOR SECTION
// ============================================================
//
// Responsabilidade:
//
// - editar título;
// - editar conteúdo;
// - salvar;
// - solicitar exclusão REAL da anotação selecionada.
//
// FASE 09 — CAPTURA SEM TEMA
//
// O campo Tema foi removido da interface.
//
// [topicController] permanece opcional somente para compatibilidade
// temporária com chamadas antigas que ainda possam passar esse
// controller. Ele NÃO é exibido e NÃO participa da captura.
//
// Este widget NÃO apaga arquivos diretamente.
// Ele chama [onDelete] e deixa o BrainController / Repository
// executarem:
//
// local -> SyncQueue -> Supabase.
//
// ============================================================

class BrainEditorSection extends StatelessWidget {
  const BrainEditorSection({
    super.key,
    required this.selectedNote,
    this.topicController,
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
  //
  // LEGADO FASE 09:
  //
  // Mantido temporariamente para não quebrar chamadas antigas.
  // Não é renderizado.
  //
  // ============================================================

  final TextEditingController? topicController;

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

  final Future<void> Function(
    BrainFile note,
  ) onDelete;

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
        // HEADER
        // ======================================================

        Text(
          note == null
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
          note == null
              ? 'Registre o conhecimento diretamente, sem precisar escolher um tema.'
              : 'Atualize o título ou o conteúdo desta anotação.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium,
        ),

        const SizedBox(
          height: 16,
        ),

        // ======================================================
        // TITLE
        // ======================================================

        TextField(
          controller: titleController,
          enabled: !isSaving,
          textInputAction: TextInputAction.next,
          onSubmitted: (
            _,
          ) {
            if (contentFocusNode.canRequestFocus) {
              contentFocusNode.requestFocus();
            }
          },
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Escreva um título para este conhecimento',
            prefixIcon: Icon(
              Icons.title_rounded,
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
          minLines: 3,
          maxLines: null,

          decoration: const InputDecoration(
            labelText: 'Conteúdo',
            hintText:
                'Escreva o resumo, aprendizado, ideia ou informação que deseja guardar.',
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
          height: 12,
        ),

        // ======================================================
        // PHASE 09 INFO
        // ======================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            12,
          ),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(
                  alpha: 0.055,
                ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(
                    alpha: 0.14,
                  ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: Theme.of(
                  context,
                ).colorScheme.primary,
              ),

              const SizedBox(
                width: 8,
              ),

              Expanded(
                child: Text(
                  'Você não precisa escolher um tema. '
                  'O conhecimento pode ser salvo diretamente.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              ),
            ],
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

        if (note != null) ...[
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

  Future<void> _confirmDelete(
    BuildContext context,
    BrainFile note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (
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

    if (confirmed != true) {
      return;
    }

    await onDelete(
      note,
    );
  }
}
