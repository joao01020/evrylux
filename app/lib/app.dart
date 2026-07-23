import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'screens/walking_screen.dart';
import 'screens/study_screen.dart';
import 'screens/training_screen.dart';
import 'screens/reading_screen.dart';

import 'theme/app_theme.dart';

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

      home: WelcomeScreen(),

      routes: {
        '/walking':
            (
              context,
            ) => WalkingScreen(),

        '/study':
            (
              context,
            ) => StudyScreen(),

        '/training':
            (
              context,
            ) => TrainingScreen(),

        '/reading':
            (
              context,
            ) => ReadingScreen(),
      },
    );
  }
}
