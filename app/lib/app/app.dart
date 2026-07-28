import 'package:flutter/material.dart';

import '../screens/welcome/welcome_screen.dart';

import '../screens/study/study_screen.dart';
import '../screens/training/training_screen.dart';

import '../core/theme/app_theme.dart';

import '../controllers/evolution/evolution_controller.dart';

class GhostApp
    extends
        StatelessWidget {
  final EvolutionController evolutionController;

  const GhostApp({
    super.key,
    required this.evolutionController,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.theme,

      home: WelcomeScreen(
        controller: evolutionController,
      ),

      routes: {
        '/study':
            (
              context,
            ) => const StudyScreen(),

        '/training':
            (
              context,
            ) => const TrainingScreen(),
      },
    );
  }
}
