import 'package:flutter/material.dart';

import 'screens/welcome/welcome_screen.dart';

import 'screens/study/study_screen.dart';

import 'screens/training/training_screen.dart';

import 'core/theme/app_theme.dart';

class GhostApp
    extends
        StatelessWidget {
  const GhostApp({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      theme: AppTheme.theme,

      home: const WelcomeScreen(),

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
