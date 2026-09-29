import 'package:flutter/material.dart';

import '../../web_app/screens/web_brain_access_gate.dart';
import '../controllers/study_controller.dart';
import '../data/repository/study_repository_web.dart';
import '../services/study_day_service_web.dart';
import '../services/study_service.dart';

final StudyRepository _studyRepository = StudyRepository();

final StudyController studyController = StudyController(
  service: StudyService(repository: _studyRepository),
);

final StudyDayService studyDayService = StudyDayService(
  repository: _studyRepository,
);

Widget buildBrainDestination() => const WebBrainAccessGate();
