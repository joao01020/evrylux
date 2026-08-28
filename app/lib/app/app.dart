import 'package:flutter/material.dart';

import '../auth/auth_gate.dart';
import '../core/theme/app_theme.dart';

import '../evolution/controllers/evolution_controller.dart';

import '../routine/screen/routine_screen.dart';
import '../study/study_screen.dart';
import '../training/training_screen.dart';
import '../welcome/welcome_screen.dart';

class GhostApp
    extends
        StatelessWidget {
  const GhostApp({
    super.key,
    required this.evolutionController,
  });

  final EvolutionController evolutionController;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ========================================================
      // THEME
      // ========================================================
      theme: AppTheme.theme,

      // ========================================================
      // AUTH
      // ========================================================
      //
      // AuthGate decide:
      //
      // sem sessão
      //      ↓
      // LoginScreen
      //
      // com sessão
      //      ↓
      // WelcomeScreen
      //
      // ========================================================
      home: AuthGate(
        authenticatedBuilder:
            (
              context,
              user,
            ) {
              return WelcomeScreen(
                controller: evolutionController,
              );
            },
      ),

      // ========================================================
      // ROUTES
      // ========================================================
      routes: {
        '/study':
            (
              context,
            ) {
              return const StudyScreen();
            },

        '/training':
            (
              context,
            ) {
              return const TrainingScreen();
            },

        '/routine':
            (
              context,
            ) {
              return const RoutineScreen();
            },
      },
    );
  }
}
