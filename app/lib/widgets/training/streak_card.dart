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
      elevation: 1,

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),

        child: Column(
          children: [
            const Text(
              "🔥",
              style: TextStyle(
                fontSize: 22,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              "$streak",

              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const Text(
              "dias",

              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
