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

// Storage

import 'core/storage/local_storage.dart';

// Controllers

import 'controllers/finance/finance_controller.dart';
import 'controllers/evolution/evolution_controller.dart';
import 'controllers/training/training_controller.dart';

// Repositories

import 'data/finance/finance_repository.dart';
import 'data/evolution/evolution_repository.dart';
import 'data/study/study_repository.dart';
import 'data/training/training_repository.dart';

// Services

import 'services/finance/finance_service.dart';
import 'services/evolution/evolution_service.dart';
import 'services/training/training_service.dart';

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
// EVOLUTION
// ======================================================

final studyRepository = StudyRepository();

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
