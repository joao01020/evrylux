/*
|--------------------------------------------------------------------------
| APP DEPENDENCIES
|--------------------------------------------------------------------------
|
| Centraliza a criação das dependências da aplicação.
|
| Arquitetura principal:
|
| Controller
|      ↓
| Service
|      ↓
| Repository
|      ↓
| SQLite local / SyncQueue / Supabase / API externa
|
| Estratégia offline-first:
|
| Interface
|      ↓
| Repository
|      ↓
| salva primeiro no SQLite
|      ↓
| registra alteração na SyncQueue
|      ↓
| SyncService
|      ↓
| Supabase quando houver conexão
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
// CORE - STORAGE
// ======================================================

import '../../core/storage/local_storage.dart';

// ======================================================
// CORE - DATABASE
// ======================================================

import '../../core/database/app_database.dart';
import '../../core/database/daos/reminder_dao.dart';
import '../../core/database/daos/routine_dao.dart';

// ======================================================
// CORE - SYNC
// ======================================================

import '../../core/sync/connectivity_service.dart';
import '../../core/sync/sync_item.dart';
import '../../core/sync/sync_queue.dart';
import '../../core/sync/sync_service.dart';
import '../../core/sync/sync_status.dart';

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
// REMINDERS CONTROLLER
// ======================================================

import '../../reminders/controllers/reminder_controller.dart';

// ======================================================
// ROUTINE
// ======================================================

import '../../routine/data/datasources/routine_memory_datasource.dart';

import '../../routine/data/datasources/routine_remote_data_source.dart';

import '../../routine/data/repositories/routine_repository_impl.dart';

// ======================================================
// FINANCE LOCAL DATASOURCE
// ======================================================

import '../../finance/data/datasources/finance_local_data_source.dart';

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
// REMINDERS REPOSITORY
// ======================================================

import '../../reminders/data/reminder_repository.dart';

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
// REMINDERS SERVICE
// ======================================================

import '../../reminders/services/reminder_service.dart';

// ======================================================
// STORAGE
// ======================================================

final localStorage = LocalStorage();

// ======================================================
// SUPABASE
// ======================================================

SupabaseClient
get supabaseClient {
  return Supabase.instance.client;
}

// ======================================================
// LOCAL DATABASE
// ======================================================

final appDatabase = AppDatabase.instance;

// ======================================================
// CONNECTIVITY
// ======================================================

final connectivityService = ConnectivityService(
  checkInterval: const Duration(
    seconds: 15,
  ),
);

// ======================================================
// SYNC QUEUE
// ======================================================

final syncQueue = SyncQueue(
  database: appDatabase,
);

// ======================================================
// SYNC SERVICE
// ======================================================

final syncService = SyncService(
  queue: syncQueue,

  connectivityService: connectivityService,

  client: supabaseClient,

  syncInterval: const Duration(
    seconds: 20,
  ),

  batchSize: 50,
);

// ======================================================
// FINANCE LOCAL DATASOURCE
// ======================================================

final financeLocalDataSource = FinanceLocalDataSource(
  database: appDatabase,
);

// ======================================================
// ROUTINE DAO
// ======================================================

final routineDao = RoutineDao(
  database: appDatabase,
);

// ======================================================
// ROUTINE LOCAL DATASOURCE
// ======================================================
//
// Apesar do nome "Memory", esta implementação já usa
// RoutineDao + SQLite.
//
// ======================================================

final routineLocalDataSource = RoutineMemoryDataSource(
  dao: routineDao,
);

// ======================================================
// ROUTINE REMOTE DATASOURCE
// ======================================================

final routineRemoteDataSource = RoutineRemoteDataSource(
  client: supabaseClient,
);

// ======================================================
// REMINDER DAO
// ======================================================
//
// Persistência SQLite dos lembretes.
//
// ======================================================

final reminderDao = ReminderDao(
  database: appDatabase,
);

// ======================================================
// SYNC HANDLERS
// ======================================================

bool
_syncHandlersRegistered = false;

// ======================================================
// REGISTER SYNC HANDLERS
// ======================================================
//
// Entidades atualmente registradas:
//
// finance
// routine_day
// reminder
//
// ======================================================

void
registerSyncHandlers() {
  if (_syncHandlersRegistered) {
    return;
  }

  // ====================================================
  // FINANCE
  // ====================================================

  syncService.registerHandler(
    entityType: 'finance',

    handler:
        (
          item,
        ) async {
          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              final payload =
                  Map<
                    String,
                    dynamic
                  >.from(
                    item.payload,
                  );

              payload.putIfAbsent(
                'user_id',
                () => item.entityId,
              );

              await supabaseClient
                  .from(
                    'finance_data',
                  )
                  .upsert(
                    payload,
                    onConflict: 'user_id',
                  );

              await financeLocalDataSource.setSyncStatus(
                item.entityId,
                SyncStatus.synced,
              );

              break;

            case SyncOperation.delete:
              await supabaseClient
                  .from(
                    'finance_data',
                  )
                  .delete()
                  .eq(
                    'user_id',
                    item.entityId,
                  );

              await financeLocalDataSource.deletePermanently(
                item.entityId,
              );

              break;
          }
        },
  );

  // ====================================================
  // ROUTINE
  // ====================================================

  syncService.registerHandler(
    entityType: 'routine_day',

    handler:
        (
          item,
        ) async {
          final payload =
              Map<
                String,
                dynamic
              >.from(
                item.payload,
              );

          final userId = payload['user_id']?.toString().trim();

          if (userId ==
                  null ||
              userId.isEmpty) {
            throw StateError(
              'Operação de rotina sem user_id.',
            );
          }

          routineRemoteDataSource.ensureAuthenticatedUser(
            userId,
          );

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              payload['id'] = item.entityId;

              payload['user_id'] = userId;

              await routineRemoteDataSource.saveDay(
                userId: userId,
                data: payload,
              );

              await routineLocalDataSource.markSynced(
                item.entityId,
              );

              break;

            case SyncOperation.delete:
              await routineRemoteDataSource.deleteDay(
                userId: userId,
                dayId: item.entityId,
              );

              await routineDao.deletePermanently(
                item.entityId,
              );

              break;
          }
        },
  );

  // ====================================================
  // REMINDER
  // ====================================================
  //
  // CREATE / UPDATE
  //      ↓
  // UPSERT reminders
  //      ↓
  // marca SQLite como synced
  //
  // DELETE
  //      ↓
  // DELETE reminders
  //      ↓
  // remove tombstone do SQLite
  //
  // ====================================================

  syncService.registerHandler(
    entityType: 'reminder',

    handler:
        (
          item,
        ) async {
          final payload =
              Map<
                String,
                dynamic
              >.from(
                item.payload,
              );

          final userId = payload['user_id']?.toString().trim();

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              if (userId ==
                      null ||
                  userId.isEmpty) {
                throw StateError(
                  'Operação de lembrete sem user_id.',
                );
              }

              final currentUser = supabaseClient.auth.currentUser;

              if (currentUser ==
                  null) {
                throw StateError(
                  'Usuário não autenticado.',
                );
              }

              if (currentUser.id !=
                  userId) {
                throw StateError(
                  'O lembrete não pertence ao usuário autenticado.',
                );
              }

              payload['id'] = item.entityId;

              payload['user_id'] = userId;

              await supabaseClient
                  .from(
                    'reminders',
                  )
                  .upsert(
                    payload,
                    onConflict: 'id',
                  );

              await reminderDao.setSyncStatus(
                item.entityId,
                SyncStatus.synced,
              );

              break;

            case SyncOperation.delete:
              final currentUser = supabaseClient.auth.currentUser;

              if (currentUser ==
                  null) {
                throw StateError(
                  'Usuário não autenticado.',
                );
              }

              await supabaseClient
                  .from(
                    'reminders',
                  )
                  .delete()
                  .eq(
                    'id',
                    item.entityId,
                  )
                  .eq(
                    'user_id',
                    userId ??
                        currentUser.id,
                  );

              await reminderDao.deletePermanently(
                item.entityId,
              );

              break;
          }
        },
  );

  _syncHandlersRegistered = true;
}

// ======================================================
// INITIALIZE OFFLINE-FIRST
// ======================================================
//
// Deve ser chamado uma vez na janela principal após:
//
// Supabase.initialize(...)
//
// ======================================================

Future<
  void
>
initializeOfflineFirst() async {
  // ----------------------------------------------------
  // DATABASE
  // ----------------------------------------------------

  await appDatabase.initialize();

  // ----------------------------------------------------
  // HANDLERS
  // ----------------------------------------------------

  registerSyncHandlers();

  // ----------------------------------------------------
  // SERVICE
  // ----------------------------------------------------

  await syncService.start();
}

// ======================================================
// REFRESH SYNC STATUS
// ======================================================

Future<
  void
>
refreshSyncStatus() async {
  await syncService.refreshPendingCount();

  await connectivityService.checkNow();
}

// ======================================================
// FORCE SYNC
// ======================================================

Future<
  void
>
forceSyncNow() async {
  await syncService.syncNow(
    checkConnection: true,
  );
}

// ======================================================
// ROUTINE REPOSITORY
// ======================================================
//
// Routine UI
//      ↓
// RoutineRepositoryImpl
//      ↓
// SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// Supabase
//
// ======================================================

final routineRepository = RoutineRepositoryImpl(
  localDataSource: routineLocalDataSource,

  remoteDataSource: routineRemoteDataSource,

  syncQueue: syncQueue,

  syncService: syncService,

  fallbackToLocalOnRemoteError: true,
);

// ======================================================
// FINANCE
// ======================================================
//
// FinanceController
//      ↓
// FinanceService
//      ↓
// FinanceRepository
//      ↓
// SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// Supabase
//
// ======================================================

final financeRepository = FinanceRepository(
  client: supabaseClient,

  localDataSource: financeLocalDataSource,

  syncQueue: syncQueue,

  syncService: syncService,
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

// ======================================================
// REMINDERS
// ======================================================
//
// NOVO FLUXO:
//
// ReminderService
//      ↓
// ReminderController
//      ↓
// ReminderRepository
//      ↓
// ReminderDao / SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// Supabase
//
// O lembrete pode ser criado, atualizado, concluído,
// reaberto e removido mesmo sem internet.
//
// ======================================================

// ======================================================
// REMINDER REPOSITORY
// ======================================================

final reminderRepository = ReminderRepository(
  client: supabaseClient,

  localDao: reminderDao,

  syncQueue: syncQueue,

  syncService: syncService,
);

// ======================================================
// REMINDER CONTROLLER
// ======================================================

final reminderController = ReminderController(
  repository: reminderRepository,
);

// ======================================================
// REMINDER SERVICE
// ======================================================
//
// Continua sendo iniciado pela camada com acesso ao contexto
// global da interface para exibir o lembrete dentro do app.
//
// A diferença é que agora o ReminderRepository consegue buscar
// lembretes vencidos diretamente do SQLite, inclusive offline.
//
// ======================================================

final reminderService = ReminderService(
  controller: reminderController,

  checkInterval: const Duration(
    seconds: 30,
  ),
);
