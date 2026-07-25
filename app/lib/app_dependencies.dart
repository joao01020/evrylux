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
| StorageService
|
|--------------------------------------------------------------------------
*/

// Controllers

import 'controllers/finance/finance_controller.dart';
import 'controllers/evolution/evolution_controller.dart';

// Repositories

import 'data/finance/finance_repository.dart';
import 'data/evolution/evolution_repository.dart';
import 'data/study/study_repository.dart';
import 'data/training/training_repository.dart';

// Services

import 'services/finance/finance_service.dart';
import 'services/evolution/evolution_service.dart';

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
// EVOLUTION
// ======================================================

final studyRepository = StudyRepository();

final trainingRepository = TrainingRepository();

final evolutionRepository = EvolutionRepository(
  studyRepository: studyRepository,
  trainingRepository: trainingRepository,
  financeRepository: financeRepository,
);

final evolutionService = EvolutionService(
  repository: evolutionRepository,
);

final evolutionController = EvolutionController(
  service: evolutionService,
);
