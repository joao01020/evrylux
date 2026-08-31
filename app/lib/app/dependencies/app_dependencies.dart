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
| armazenamento local
|      ↓
| SyncQueue
|      ↓
| SyncService
|      ↓
| Supabase
|
| Módulos atualmente integrados ao offline-first:
|
| - Finance
| - Routine
| - Reminders
| - Study
| - Training
| - Journey
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
// REMOTE TABLES
// ======================================================
//
// IMPORTANTE:
//
// Finance, Routine e Reminders já utilizavam tabelas existentes.
//
// Para os módulos recém-integrados ao sync, esta versão usa:
//
// study_data
// training_data
// training_plans
// journey_history
//
// Essas tabelas precisam existir no Supabase para o envio remoto
// funcionar.
//
// ======================================================

const String
_studyTable = 'study_data';

const String
_trainingTable = 'training_data';

const String
_trainingPlanTable = 'training_plans';

const String
_journeyTable = 'journey_history';

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

final reminderDao = ReminderDao(
  database: appDatabase,
);

// ======================================================
// SYNC HANDLERS STATE
// ======================================================

bool
_syncHandlersRegistered = false;

// ======================================================
// AUTH VALIDATION FOR QUEUED ITEMS
// ======================================================

User
_requireQueueUser({
  required String? userId,
  required String entity,
}) {
  final currentUser = supabaseClient.auth.currentUser;

  if (currentUser ==
      null) {
    throw StateError(
      'Usuário não autenticado durante sincronização de $entity.',
    );
  }

  final normalizedUserId = userId?.trim();

  if (normalizedUserId !=
          null &&
      normalizedUserId.isNotEmpty &&
      normalizedUserId !=
          currentUser.id) {
    throw StateError(
      'Operação de $entity pertence a outro usuário.',
    );
  }

  return currentUser;
}

// ======================================================
// REGISTER SYNC HANDLERS
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

              final user = _requireQueueUser(
                userId: payload['user_id']?.toString(),
                entity: 'finance',
              );

              payload['user_id'] = user.id;

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
              final payload =
                  Map<
                    String,
                    dynamic
                  >.from(
                    item.payload,
                  );

              final user = _requireQueueUser(
                userId: payload['user_id']?.toString(),
                entity: 'finance',
              );

              await supabaseClient
                  .from(
                    'finance_data',
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'routine_day',
          );

          final userId = user.id;

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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'reminder',
          );

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              payload['id'] = item.entityId;

              payload['user_id'] = user.id;

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
                    user.id,
                  );

              await reminderDao.deletePermanently(
                item.entityId,
              );

              break;
          }
        },
  );

  // ====================================================
  // STUDY
  // ====================================================
  //
  // Repository:
  //
  // entityType = study_day
  //
  // Remote uniqueness:
  //
  // user_id + day
  //
  // ====================================================

  syncService.registerHandler(
    entityType: 'study_day',

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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'study_day',
          );

          final day = payload['day']?.toString().trim();

          if (day ==
                  null ||
              day.isEmpty) {
            throw StateError(
              'Operação de estudo sem day.',
            );
          }

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              await supabaseClient
                  .from(
                    _studyTable,
                  )
                  .upsert(
                    {
                      'user_id': user.id,
                      'day': day,
                      'minutes':
                          payload['minutes'] ??
                          0,
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id,day',
                  );

              break;

            case SyncOperation.delete:
              await supabaseClient
                  .from(
                    _studyTable,
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
                  )
                  .eq(
                    'day',
                    day,
                  );

              break;
          }
        },
  );

  // ====================================================
  // TRAINING DAY
  // ====================================================

  syncService.registerHandler(
    entityType: 'training_day',

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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'training_day',
          );

          final deleteScope = payload['delete_scope']?.toString();

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              final day = payload['day']?.toString().trim();

              final date = payload['date']?.toString().trim();

              if (day ==
                      null ||
                  day.isEmpty ||
                  date ==
                      null ||
                  date.isEmpty) {
                throw StateError(
                  'Operação de treino sem day/date.',
                );
              }

              await supabaseClient
                  .from(
                    _trainingTable,
                  )
                  .upsert(
                    {
                      'user_id': user.id,
                      'day': day,
                      'training':
                          payload['training']?.toString() ??
                          '',
                      'minutes':
                          payload['minutes'] ??
                          0,
                      'date': date,
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id,day,date',
                  );

              break;

            case SyncOperation.delete:
              if (deleteScope ==
                  'all') {
                await supabaseClient
                    .from(
                      _trainingTable,
                    )
                    .delete()
                    .eq(
                      'user_id',
                      user.id,
                    );

                break;
              }

              final day = payload['day']?.toString().trim();

              final date = payload['date']?.toString().trim();

              if (day ==
                      null ||
                  day.isEmpty ||
                  date ==
                      null ||
                  date.isEmpty) {
                throw StateError(
                  'Exclusão de treino sem day/date.',
                );
              }

              await supabaseClient
                  .from(
                    _trainingTable,
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
                  )
                  .eq(
                    'day',
                    day,
                  )
                  .eq(
                    'date',
                    date,
                  );

              break;
          }
        },
  );

  // ====================================================
  // TRAINING PLAN
  // ====================================================

  syncService.registerHandler(
    entityType: 'training_plan',

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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'training_plan',
          );

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              await supabaseClient
                  .from(
                    _trainingPlanTable,
                  )
                  .upsert(
                    {
                      'user_id': user.id,
                      'weekly_goal':
                          payload['weekly_goal'] ??
                          0,
                      'planned_weekdays':
                          payload['planned_weekdays'] ??
                          const <
                            int
                          >[],
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id',
                  );

              break;

            case SyncOperation.delete:
              await supabaseClient
                  .from(
                    _trainingPlanTable,
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
                  );

              break;
          }
        },
  );

  // ====================================================
  // JOURNEY
  // ====================================================

  syncService.registerHandler(
    entityType: 'journey_day',

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

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'journey_day',
          );

          final deleteScope = payload['delete_scope']?.toString();

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              final date = payload['date']?.toString().trim();

              if (date ==
                      null ||
                  date.isEmpty) {
                throw StateError(
                  'Operação de jornada sem date.',
                );
              }

              await supabaseClient
                  .from(
                    _journeyTable,
                  )
                  .upsert(
                    {
                      'user_id': user.id,
                      'date': date,
                      'notes':
                          payload['notes'] ??
                          const <
                            String
                          >[],
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id,date',
                  );

              break;

            case SyncOperation.delete:
              if (deleteScope ==
                  'all') {
                await supabaseClient
                    .from(
                      _journeyTable,
                    )
                    .delete()
                    .eq(
                      'user_id',
                      user.id,
                    );

                break;
              }

              final date = payload['date']?.toString().trim();

              if (date ==
                      null ||
                  date.isEmpty) {
                throw StateError(
                  'Exclusão de jornada sem date.',
                );
              }

              await supabaseClient
                  .from(
                    _journeyTable,
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
                  )
                  .eq(
                    'date',
                    date,
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

Future<
  void
>
initializeOfflineFirst() async {
  await appDatabase.initialize();

  registerSyncHandlers();

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
//
// StorageService continua sendo a fonte local imediata.
// Alterações também entram na SyncQueue.
//
// ======================================================

final trainingRepository = TrainingRepository(
  client: supabaseClient,

  syncQueue: syncQueue,

  syncService: syncService,
);

final trainingService = TrainingService(
  repository: trainingRepository,
);

final trainingController = TrainingController(
  service: trainingService,
);

// ======================================================
// STUDY
// ======================================================
//
// StorageService continua sendo a fonte local imediata.
// Alterações também entram na SyncQueue.
//
// ======================================================

final studyRepository = StudyRepository(
  client: supabaseClient,

  syncQueue: syncQueue,

  syncService: syncService,
);

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
//
// LocalStorage continua sendo a fonte local.
// Mudanças também entram na SyncQueue.
//
// ======================================================

final journeyRepository = JourneyRepository(
  storage: localStorage,

  client: supabaseClient,

  syncQueue: syncQueue,

  syncService: syncService,
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

final reminderRepository = ReminderRepository(
  client: supabaseClient,

  localDao: reminderDao,

  syncQueue: syncQueue,

  syncService: syncService,
);

final reminderController = ReminderController(
  repository: reminderRepository,
);

final reminderService = ReminderService(
  controller: reminderController,

  checkInterval: const Duration(
    seconds: 30,
  ),
);
