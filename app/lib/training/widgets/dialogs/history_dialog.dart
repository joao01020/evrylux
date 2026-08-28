import 'package:flutter/material.dart';

class HistoryDialog
    extends
        StatelessWidget {
  const HistoryDialog({
    super.key,

    required this.activities,
  });

  final List<
    String
  >
  activities;

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: const Text(
        "Histórico 📚",
      ),

      content: SizedBox(
        width: 300,

        height: 300,

        child: activities.isEmpty
            ? const Center(
                child: Text(
                  "Nenhuma atividade concluída.",
                ),
              )
            : ListView.builder(
                itemCount: activities.length,

                itemBuilder:
                    (
                      context,
                      index,
                    ) {
                      return Card(
                        child: ListTile(
                          dense: true,

                          leading: const Text(
                            "✅",
                          ),

                          title: Text(
                            activities[index],

                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
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
            "Fechar",
          ),
        ),
      ],
    );
  }
}
