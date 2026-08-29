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
| LocalStorage / Supabase / API externa
|
|--------------------------------------------------------------------------
*/

// ======================================================
// SUPABASE
// ======================================================

import 'package:supabase_flutter/supabase_flutter.dart'
    hide
        LocalStorage;

// ======================================================
// STORAGE
// ======================================================

import '../../core/storage/local_storage.dart';

// ======================================================
// CONTROLLERS
// ======================================================

import '../../finance/controllers/finance_controller.dart';
import '../../finance/controllers/crypto/crypto_controller.dart';

import '../../evolution/controllers/evolution_controller.dart';
import '../../training/controllers/training_controller.dart';
import '../../evolution/my_journey/controllers/journey_controller.dart';
import '../../study/controllers/study_controller.dart';

// ======================================================
// ROUTINE
// ======================================================

import '../../routine/data/datasources/routine_memory_datasource.dart';
import '../../routine/data/datasources/routine_remote_data_source.dart';
import '../../routine/data/repositories/routine_repository_impl.dart';

// ======================================================
// REPOSITORIES
// ======================================================

import '../../finance/data/repository/finance_repository.dart';
import '../../finance/data/repository/crypto/crypto_repository.dart';

import '../../evolution/data/repository/evolution_repository.dart';
import '../../study/data/repository/study_repository.dart';
import '../../training/data/training_repository.dart';
import '../../evolution/my_journey/data/repository/journey_repository.dart';

// ======================================================
// SERVICES
// ======================================================

import '../../study/services/study_service.dart';

import '../../finance/services/persistence/finance_service.dart';
import '../../finance/services/crypto/crypto_service.dart';
import '../../finance/services/crypto/crypto_price_service.dart';

import '../../evolution/services/evolution_service.dart';
import '../../training/services/training_service.dart';
import '../../evolution/my_journey/services/journey_service.dart';

// ======================================================
// STORAGE
// ======================================================

final localStorage = LocalStorage();

// ======================================================
// SUPABASE
// ======================================================

SupabaseClient
get supabaseClient => Supabase.instance.client;

// ======================================================
// ROUTINE LOCAL DATASOURCE
// ======================================================

final routineLocalDataSource = RoutineMemoryDataSource();

// ======================================================
// ROUTINE REMOTE DATASOURCE
// ======================================================

final routineRemoteDataSource = RoutineRemoteDataSource(
  client: supabaseClient,
);

// ======================================================
// ROUTINE REPOSITORY
// ======================================================

final routineRepository = RoutineRepositoryImpl(
  localDataSource: routineLocalDataSource,

  remoteDataSource: routineRemoteDataSource,

  fallbackToLocalOnRemoteError: false,
);

// ======================================================
// FINANCE
// ======================================================
//
// Fluxo:
//
// FinanceController
//      ↓
// FinanceService
//      ↓
// FinanceRepository
//      ↓
// Supabase
//
// O FinanceRepository utiliza:
// Supabase.instance.client.auth.currentUser
//
// ======================================================

final financeRepository = FinanceRepository(
  client: supabaseClient,
);

final financeService = FinanceService(
  repository: financeRepository,
);

final financeController = FinanceController(
  financeService,
);

// ======================================================
// CRYPTO REPOSITORY
// ======================================================
//
// Atualmente as transações de criptomoedas
// continuam sendo persistidas em LocalStorage.
//
// Fluxo:
//
// CryptoController
//      ↓
// CryptoService
//      ↓
// CryptoRepository
//      ↓
// LocalStorage
//
// ======================================================

final cryptoRepository = CryptoRepository(
  storage: localStorage,
);

// ======================================================
// CRYPTO SERVICE
// ======================================================

final cryptoService = CryptoService(
  repository: cryptoRepository,
);

// ======================================================
// CRYPTO PRICE SERVICE
// ======================================================
//
// Responsável por buscar:
// BTC
// ETH
// SOL
// USDT
//
// com cotação atual em BRL.
//
// Esse serviço NÃO salva transações.
//
// Ele apenas consulta preços atuais.
//
// ======================================================

final cryptoPriceService = CryptoPriceService();

// ======================================================
// CRYPTO CONTROLLER
// ======================================================

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
//
// EvolutionRepository continua recebendo
// o mesmo FinanceRepository.
//
// Isso permite que a Evolution também enxergue
// os dados financeiros carregados do Supabase.
//
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
