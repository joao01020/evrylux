import 'package:flutter/material.dart';

class CurrentTimeCard
    extends
        StatelessWidget {
  const CurrentTimeCard({
    super.key,
    required this.minutes,
  });

  final int minutes;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        leading: const Text(
          "⏱️",
          style: TextStyle(
            fontSize: 30,
          ),
        ),
        title: const Text(
          "Tempo atual",
        ),
        subtitle: Text(
          "$minutes minutos",
        ),
      ),
    );
  }
}
