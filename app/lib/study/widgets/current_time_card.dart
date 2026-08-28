import 'package:flutter/material.dart';

class CurrentTimeCard
    extends
        StatelessWidget {
  const CurrentTimeCard({
    super.key,
    required this.minutes,
    this.onSave,
  });

  final int minutes;

  final VoidCallback? onSave;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        leading: const Text(
          '⏱️',

          style: TextStyle(
            fontSize: 30,
          ),
        ),

        title: const Text(
          'Tempo atual',
        ),

        subtitle: Text(
          '$minutes minutos',
        ),

        trailing:
            onSave !=
                null
            ? IconButton(
                tooltip: 'Salvar estudo',

                icon: const Icon(
                  Icons.save_outlined,
                ),

                onPressed: onSave,
              )
            : null,
      ),
    );
  }
}
