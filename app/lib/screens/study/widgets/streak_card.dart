import 'package:flutter/material.dart';

class StreakCard
    extends
        StatelessWidget {
  const StreakCard({
    super.key,
    required this.streak,
  });

  final int streak;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "🔥",
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              "$streak dias",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
