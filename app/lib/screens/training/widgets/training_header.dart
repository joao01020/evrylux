import 'package:flutter/material.dart';

import 'streak_card.dart';

class TrainingHeader
    extends
        StatelessWidget {
  const TrainingHeader({
    super.key,
    required this.streak,
  });

  final int streak;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Expanded(
          child: Text(
            "Escolha sua atividade de hoje e mantenha sua evolução.",

            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        StreakCard(
          streak: streak,
        ),
      ],
    );
  }
}
