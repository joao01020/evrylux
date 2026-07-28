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

import '../core/storage/local_storage.dart';

// ======================================================
// CONTROLLERS
// ======================================================

import '../screens/finance/controllers/finance_controller.dart';
import '../screens/finance/controllers/crypto/crypto_controller.dart';

import '../controllers/evolution/evolution_controller.dart';
import '../screens/training/controllers/training_controller.dart';
import '../controllers/journey/journey_controller.dart';
import '../controllers/study/study_controller.dart';

// ======================================================
// REPOSITORIES
// ======================================================

import '../screens/finance/data/repository/finance_repository.dart';
import '../screens/finance/data/repository/crypto/crypto_repository.dart';

import '../data/evolution/evolution_repository.dart';
import '../screens/study/data/repository/study_repository.dart';
import '../screens/training/data/training_repository.dart';
import '../screens/evolution/my_journey/data/repository/journey_repository.dart';

// ======================================================
// SERVICES
// ======================================================

import '../screens/study/brain/services/study_service.dart';

import '../screens/finance/services/finance_service.dart';
import '../screens/finance/services/crypto/crypto_service.dart';

import '../screens/evolution/services/evolution_service.dart';
import '../screens/training/services/training_service.dart';
import '../screens/evolution/my_journey/services/journey_service.dart';

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
// CRYPTO
// ======================================================

final cryptoRepository = CryptoRepository(
  storage: localStorage,
);

final cryptoService = CryptoService(
  repository: cryptoRepository,
);

final cryptoController = CryptoController(
  service: cryptoService,
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
