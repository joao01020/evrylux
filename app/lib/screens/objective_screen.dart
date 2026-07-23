import 'package:flutter/material.dart';

import '../models/objective.dart';

import 'walking_screen.dart';
import 'study_screen.dart';
import 'training_screen.dart';
import 'reading_screen.dart';

class ObjectiveScreen
    extends
        StatelessWidget {
  final Objective objective;

  const ObjectiveScreen({
    super.key,

    required this.objective,
  });

  void openObjective(
    BuildContext context,
  ) {
    switch (objective.name) {
      case "Caminhada":
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const WalkingScreen(),
          ),
        );

        break;

      case "Estudos":
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const StudyScreen(),
          ),
        );

        break;

      case "Treino":
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const TrainingScreen(),
          ),
        );

        break;

      case "Leitura":
        Navigator.pushReplacement(
          context,

          MaterialPageRoute(
            builder:
                (
                  _,
                ) => const ReadingScreen(),
          ),
        );

        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Meu objetivo",
        ),
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Text(
              objective.title,

              style: const TextStyle(
                fontSize: 32,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Text(
              objective.description,

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            ElevatedButton(
              onPressed: () {
                openObjective(
                  context,
                );
              },

              child: const Text(
                "Iniciar jornada",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
