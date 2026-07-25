/*
|--------------------------------------------------------------------------
| APP DEPENDENCIES
|--------------------------------------------------------------------------
|
| Centraliza a criação das dependências da aplicação.
|
| Arquitetura:
|
| Controller
|      ↓
| Service
|      ↓
| Repository
|      ↓
| LocalStorage
|
|--------------------------------------------------------------------------
*/

// ======================================================
// STORAGE
// ======================================================

import 'core/storage/local_storage.dart';

// ======================================================
// CONTROLLERS
// ======================================================

import 'controllers/finance/finance_controller.dart';
import 'controllers/evolution/evolution_controller.dart';
import 'controllers/training/training_controller.dart';
import 'controllers/journey/journey_controller.dart';
import 'controllers/study/study_controller.dart';

// ======================================================
// REPOSITORIES
// ======================================================

import 'data/finance/finance_repository.dart';
import 'data/evolution/evolution_repository.dart';
import 'data/study/study_repository.dart';
import 'data/training/training_repository.dart';
import 'data/journey/journey_repository.dart';

// ======================================================
// SERVICES
// ======================================================
import 'services/study/study_service.dart';
import 'services/finance/finance_service.dart';
import 'services/evolution/evolution_service.dart';
import 'services/training/training_service.dart';
import 'services/journey/journey_service.dart';

// ======================================================
// STORAGE
// ======================================================

final localStorage = LocalStorage();

// ======================================================
// FINANCE
// ======================================================

final financeRepository = FinanceRepository();

final financeService = FinanceService(
  repository: financeRepository,
);

final financeController = FinanceController(
  financeService,
);

// ======================================================
// TRAINING
// ======================================================

final trainingRepository = TrainingRepository();

final trainingService = TrainingService(
  repository: trainingRepository,
);

final trainingController = TrainingController(
  service: trainingService,
);

// ======================================================
// STUDY
// ======================================================

final studyRepository = StudyRepository();

final studyService = StudyService(
  repository: studyRepository,
);

final studyController = StudyController(
  service: studyService,
);

// ======================================================
// EVOLUTION
// ======================================================

final evolutionRepository = EvolutionRepository(
  studyRepository: studyRepository,

  trainingRepository: trainingRepository,

  financeRepository: financeRepository,

  storage: localStorage,
);

final evolutionService = EvolutionService(
  repository: evolutionRepository,
);

final evolutionController = EvolutionController(
  service: evolutionService,
);

// ======================================================
// JOURNEY
// ======================================================

final journeyRepository = JourneyRepository(
  storage: localStorage,
);

final journeyService = JourneyService(
  repository: journeyRepository,
);

final journeyController = JourneyController(
  service: journeyService,
);
