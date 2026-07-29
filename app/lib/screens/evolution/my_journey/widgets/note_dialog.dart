import 'package:flutter/material.dart';

class NoteDialog
    extends
        StatelessWidget {
  final String date;

  final Future<
    void
  >
  Function(
    String note,
  )
  onSave;

  const NoteDialog({
    super.key,

    required this.date,

    required this.onSave,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = TextEditingController();

    return AlertDialog(
      title: Text(
        "Anotação $date",
      ),

      content: TextField(
        controller: controller,

        maxLines: 4,

        decoration: const InputDecoration(
          hintText: "Escreva sua evolução do dia...",

          border: OutlineInputBorder(),
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
            "Cancelar",
          ),
        ),

        ElevatedButton(
          onPressed: () async {
            final text = controller.text.trim();

            if (text.isEmpty) {
              return;
            }

            await onSave(
              text,
            );

            if (context.mounted) {
              Navigator.pop(
                context,
              );
            }
          },

          child: const Text(
            "Salvar",
          ),
        ),
      ],
    );
  }
}
