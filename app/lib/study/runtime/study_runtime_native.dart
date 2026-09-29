import 'package:flutter/material.dart';

import '../../app/dependencies/app_dependencies.dart' as deps;
import '../brain/screen/brain_screen.dart';
import '../controllers/study_controller.dart';
import '../services/study_day_service.dart';

StudyController get studyController => deps.studyController;

StudyDayService get studyDayService => deps.studyDayService;

Widget buildBrainDestination() => const BrainScreen();
