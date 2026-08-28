import 'package:flutter/material.dart';

import '../models/brain_file.dart';

class DeleteNoteDialog
    extends
        StatelessWidget {
  final BrainFile note;

  const DeleteNoteDialog({
    super.key,
    required this.note,
  });

  static Future<
    bool
  >
  show({
    required BuildContext context,
    required BrainFile note,
  }) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return DeleteNoteDialog(
                  note: note,
                );
              },
        );

    return confirmed ??
        false;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      icon: const Icon(
        Icons.delete_outline,
      ),
      title: const Text(
        'Excluir anotação?',
      ),
      content: Text(
        'A anotação "${note.title}" será excluída permanentemente.',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              false,
            );
          },
          child: const Text(
            'Cancelar',
          ),
        ),

        FilledButton.icon(
          onPressed: () {
            Navigator.pop(
              context,
              true,
            );
          },
          icon: const Icon(
            Icons.delete_outline,
          ),
          label: const Text(
            'Excluir',
          ),
        ),
      ],
    );
  }
}
