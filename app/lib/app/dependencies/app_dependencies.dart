import 'dart:io';

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
| - Brain / Cérebro
| - Brain Reviews / Revisões
| - Training
| - Training Body Map
| - Journey
|
|--------------------------------------------------------------------------
*/

// ======================================================
// SUPABASE
// ======================================================

import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

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
import '../../core/database/daos/training_activity_plan_dao.dart';
import '../../core/database/daos/board_attachment_dao.dart';

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

import '../../training/body_map/controllers/body_map_controller.dart';
import '../../training/body_map/data/body_map_repository.dart';
import '../../training/body_map/services/body_map_service.dart';

import '../../evolution/my_journey/controllers/journey_controller.dart';

import '../../study/controllers/study_controller.dart';

// ======================================================
// STUDY - BRAIN / CÉREBRO
// ======================================================

import '../../study/brain/controllers/brain_controller.dart';
import '../../study/brain/controllers/review_controller.dart';

import '../../study/brain/models/brain_concept.dart';
import '../../study/brain/models/brain_review_item.dart';

import '../../study/brain/repositories/brain_repository.dart';
import '../../study/brain/repositories/review_repository.dart';

import '../../study/brain/services/brain_storage.dart';
import '../../study/brain/services/review_storage.dart';
import '../../study/brain/services/supabase_brain_service.dart';
import '../../study/brain/services/supabase_review_service.dart';

import '../../study/brain/migration/services/brain_migration_factory.dart';
import '../../study/brain/migration/services/brain_review_startup_migration_service.dart';

import '../../study/brain/security/keys/brain_key_service.dart';
import '../../study/brain/security/keys/brain_platform_key_storage.dart';

import '../../study/brain/vault/services/brain_vault_service.dart';
import '../../study/brain/vault/stores/brain_review_vault_store.dart';

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
// ROUTINE - BOARD ATTACHMENTS
// ======================================================

import '../../routine/controllers/attachments/board_attachment_controller.dart';
import '../../routine/data/attachments/board_attachment_repository.dart';
import '../../routine/services/attachments/board_attachment_service.dart';
import '../../routine/services/attachments/board_attachment_storage.dart';

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

SupabaseClient get supabaseClient {
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
// training_activity_plans
// journey_history
//
// Brain / Cérebro:
// utiliza SupabaseBrainService para preservar os nomes de tabelas
// e regras remotas já existentes no módulo.
//
// Brain Reviews:
// utiliza SupabaseReviewService e a tabela brain_reviews.
//
// Essas tabelas precisam existir no Supabase para o envio remoto
// funcionar.
//
// ======================================================

const String _studyTable = 'study_data';

const String _trainingTable = 'training_data';

const String _trainingPlanTable = 'training_plans';

const String _trainingActivityPlanTable = 'training_activity_plans';

const String _journeyTable = 'journey_history';

const String _boardAttachmentTable = 'board_attachments';

const String _boardAttachmentBucket = 'board-files';

// ======================================================
// LOCAL DATABASE
// ======================================================

final appDatabase = AppDatabase.instance;

// ======================================================
// CONNECTIVITY
// ======================================================

final connectivityService = ConnectivityService(
  checkInterval: const Duration(seconds: 15),
);

// ======================================================
// SYNC QUEUE
// ======================================================

final syncQueue = SyncQueue(database: appDatabase);

// ======================================================
// SYNC SERVICE
// ======================================================

final syncService = SyncService(
  queue: syncQueue,

  connectivityService: connectivityService,

  client: supabaseClient,

  syncInterval: const Duration(seconds: 20),

  batchSize: 50,
);

// ======================================================
// BRAIN / CÉREBRO - DEPENDENCIES
// ======================================================
//
// OFFLINE-FIRST:
//
// BrainController
//      ↓
// BrainRepository
//      ↓
// BrainStorage local
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// SupabaseBrainService
//
// ======================================================

const brainStorage = BrainStorage();

final supabaseBrainService = SupabaseBrainService(client: supabaseClient);

final brainRepository = BrainRepository(
  remote: supabaseBrainService,

  local: brainStorage,

  syncQueue: syncQueue,

  syncService: syncService,
);

final brainController = BrainController(repository: brainRepository);

// ======================================================
// BRAIN / CÉREBRO - REVIEW VAULT DEPENDENCIES
// ======================================================
//
// NOVA ARQUITETURA LOCAL:
//
// ReviewController
//      ↓
// ReviewRepository
//      ↓
// BrainReviewVaultStore
//      ↓
// BrainVaultService
//      ↓
// BrainKeyService
//      ↓
// BrainPlatformKeyStorage
//      ↓
// Secure Storage do sistema operacional
//
// ======================================================
//
// IMPORTANTE:
//
// - o Vault é a fonte local principal das revisões;
// - ReviewStorage permanece apenas como legado/migração;
// - novas revisões não entram na SyncQueue antiga em plaintext;
// - SupabaseReviewService permanece temporariamente apenas para
//   importação remota legada e para drenar operações antigas já
//   existentes na fila;
// - não existe fallback inseguro para InMemoryBrainKeyStorage.
//
// ======================================================

const reviewStorage = ReviewStorage();

// ======================================================
// BRAIN MASTER KEY STORAGE
// ======================================================

final brainKeyStorage = BrainPlatformKeyStorage();

// ======================================================
// BRAIN KEY SERVICE
// ======================================================

final brainKeyService = BrainKeyService(storage: brainKeyStorage);

// ======================================================
// BRAIN VAULT
// ======================================================

final brainVaultService = BrainVaultService(keyService: brainKeyService);

// ======================================================
// REVIEW VAULT STORE
// ======================================================

final brainReviewVaultStore = BrainReviewVaultStore(
  vaultService: brainVaultService,
);

// ======================================================
// LEGACY REMOTE REVIEW SERVICE
// ======================================================

final supabaseReviewService = SupabaseReviewService(client: supabaseClient);

// ======================================================
// REVIEW REPOSITORY
// ======================================================

final reviewRepository = ReviewRepository(
  vaultStore: brainReviewVaultStore,

  remote: supabaseReviewService,

  local: reviewStorage,

  syncQueue: syncQueue,
);

// ======================================================
// REVIEW CONTROLLER
// ======================================================

final reviewController = ReviewController(repository: reviewRepository);

// ======================================================
// FINANCE LOCAL DATASOURCE
// ======================================================

final financeLocalDataSource = FinanceLocalDataSource(database: appDatabase);

// ======================================================
// ROUTINE DAO
// ======================================================

final routineDao = RoutineDao(database: appDatabase);

// ======================================================
// ROUTINE LOCAL DATASOURCE
// ======================================================

final routineLocalDataSource = RoutineMemoryDataSource(dao: routineDao);

// ======================================================
// ROUTINE REMOTE DATASOURCE
// ======================================================

final routineRemoteDataSource = RoutineRemoteDataSource(client: supabaseClient);

// ======================================================
// REMINDER DAO
// ======================================================

final reminderDao = ReminderDao(database: appDatabase);

// ======================================================
// TRAINING ACTIVITY PLAN DAO
// ======================================================
//
// Persistência SQLite do mapa corporal / plano de atividades.
//
// ======================================================

final trainingActivityPlanDao = TrainingActivityPlanDao(database: appDatabase);

// ======================================================
// BOARD ATTACHMENTS - OFFLINE-FIRST
// ======================================================
//
// BoardAttachmentController
//      ↓
// BoardAttachmentRepository
//      ↓
// BoardAttachmentService + BoardAttachmentDao
//      ↓
// arquivo físico local + SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// Supabase Storage + board_attachments
//
// ======================================================

final boardAttachmentDao = BoardAttachmentDao(database: appDatabase);

const boardAttachmentStorage = BoardAttachmentStorage();

final boardAttachmentService = BoardAttachmentService(
  storage: boardAttachmentStorage,
  client: supabaseClient,
);

final boardAttachmentRepository = BoardAttachmentRepository(
  client: supabaseClient,
  localDao: boardAttachmentDao,
  service: boardAttachmentService,
  syncQueue: syncQueue,
  syncService: syncService,
);

final boardAttachmentController = BoardAttachmentController(
  repository: boardAttachmentRepository,
);

// ======================================================
// SYNC HANDLERS STATE
// ======================================================

bool _syncHandlersRegistered = false;

// ======================================================
// AUTH VALIDATION FOR QUEUED ITEMS
// ======================================================

User _requireQueueUser({required String? userId, required String entity}) {
  final currentUser = supabaseClient.auth.currentUser;

  if (currentUser == null) {
    throw StateError(
      'Usuário não autenticado durante sincronização de $entity.',
    );
  }

  final normalizedUserId = userId?.trim();

  if (normalizedUserId != null &&
      normalizedUserId.isNotEmpty &&
      normalizedUserId != currentUser.id) {
    throw StateError('Operação de $entity pertence a outro usuário.');
  }

  return currentUser;
}

// ======================================================
// SYNC PAYLOAD DATE
// ======================================================

DateTime? _syncPayloadDate(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(text);
}

// ======================================================
// REGISTER SYNC HANDLERS
// ======================================================

void registerSyncHandlers() {
  if (_syncHandlersRegistered) {
    return;
  }

  // ====================================================
  // FINANCE
  // ====================================================

  syncService.registerHandler(
    entityType: 'finance',

    handler: (item) async {
      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          final payload = Map<String, dynamic>.from(item.payload);

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'finance',
          );

          payload['user_id'] = user.id;

          await supabaseClient
              .from('finance_data')
              .upsert(payload, onConflict: 'user_id');

          await financeLocalDataSource.setSyncStatus(
            item.entityId,
            SyncStatus.synced,
          );

          break;

        case SyncOperation.delete:
          final payload = Map<String, dynamic>.from(item.payload);

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: 'finance',
          );

          await supabaseClient
              .from('finance_data')
              .delete()
              .eq('user_id', user.id);

          await financeLocalDataSource.deletePermanently(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // ROUTINE
  // ====================================================

  syncService.registerHandler(
    entityType: 'routine_day',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: 'routine_day',
      );

      final userId = user.id;

      routineRemoteDataSource.ensureAuthenticatedUser(userId);

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          payload['id'] = item.entityId;

          payload['user_id'] = userId;

          await routineRemoteDataSource.saveDay(userId: userId, data: payload);

          await routineLocalDataSource.markSynced(item.entityId);

          break;

        case SyncOperation.delete:
          await routineRemoteDataSource.deleteDay(
            userId: userId,
            dayId: item.entityId,
          );

          await routineDao.deletePermanently(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // REMINDER
  // ====================================================

  syncService.registerHandler(
    entityType: 'reminder',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

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
              .from('reminders')
              .upsert(payload, onConflict: 'id');

          await reminderDao.setSyncStatus(item.entityId, SyncStatus.synced);

          break;

        case SyncOperation.delete:
          await supabaseClient
              .from('reminders')
              .delete()
              .eq('id', item.entityId)
              .eq('user_id', user.id);

          await reminderDao.deletePermanently(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // BOARD ATTACHMENT
  // ====================================================
  //
  // Fluxo remoto:
  //
  // CREATE / UPDATE
  //   1. valida usuário;
  //   2. envia o arquivo local para o Storage;
  //   3. salva os metadados em board_attachments;
  //   4. marca o registro SQLite como synced.
  //
  // DELETE
  //   1. remove o arquivo do Storage quando houver remote_path;
  //   2. remove os metadados no Supabase;
  //   3. remove definitivamente o registro SQLite.
  //
  // IMPORTANTE:
  //
  // local_path existe apenas no payload local da SyncQueue.
  // Ele nunca é persistido na tabela remota.
  //
  // ====================================================

  syncService.registerHandler(
    entityType: BoardAttachmentRepository.entityType,

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: BoardAttachmentRepository.entityType,
      );

      final boardId = payload['board_id']?.toString().trim() ?? '';

      final blockId = payload['block_id']?.toString().trim() ?? '';

      final fileName = payload['file_name']?.toString().trim() ?? '';

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          if (boardId.isEmpty) {
            throw StateError('Operação de board_attachment sem board_id.');
          }

          if (blockId.isEmpty) {
            throw StateError('Operação de board_attachment sem block_id.');
          }

          if (fileName.isEmpty) {
            throw StateError('Operação de board_attachment sem file_name.');
          }

          final localPath = payload['local_path']?.toString().trim() ?? '';

          if (localPath.isEmpty) {
            throw StateError('Operação de board_attachment sem local_path.');
          }

          final localFile = File(localPath);

          if (!await localFile.exists()) {
            throw StateError(
              'Arquivo local do board_attachment não encontrado: '
              '$localPath',
            );
          }

          final rawRemotePath = payload['remote_path']?.toString().trim();

          final remotePath = rawRemotePath != null && rawRemotePath.isNotEmpty
              ? rawRemotePath
              : '${user.id}/'
                    '$boardId/'
                    '${item.entityId}/'
                    '$fileName';

          final mimeType = payload['mime_type']?.toString().trim();

          final bytes = await localFile.readAsBytes();

          await supabaseClient.storage
              .from(_boardAttachmentBucket)
              .uploadBinary(
                remotePath,
                bytes,
                fileOptions: FileOptions(
                  upsert: true,
                  contentType: mimeType != null && mimeType.isNotEmpty
                      ? mimeType
                      : null,
                ),
              );

          final remotePayload = <String, dynamic>{
            'id': item.entityId,
            'user_id': user.id,
            'board_id': boardId,
            'block_id': blockId,
            'file_name': fileName,
            'type': payload['type']?.toString() ?? 'unknown',
            'remote_path': remotePath,
            'mime_type': mimeType,
            'size_bytes': payload['size_bytes'] ?? bytes.length,
            'created_at':
                payload['created_at'] ??
                DateTime.now().toUtc().toIso8601String(),
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          };

          await supabaseClient
              .from(_boardAttachmentTable)
              .upsert(remotePayload, onConflict: 'id');

          await boardAttachmentDao.updateRemotePath(
            userId: user.id,
            id: item.entityId,
            remotePath: remotePath,
            syncStatus: SyncStatus.synced,
          );

          break;

        case SyncOperation.delete:
          final remotePath = payload['remote_path']?.toString().trim();

          if (remotePath != null && remotePath.isNotEmpty) {
            await supabaseClient.storage.from(_boardAttachmentBucket).remove(
              <String>[remotePath],
            );
          }

          await supabaseClient
              .from(_boardAttachmentTable)
              .delete()
              .eq('id', item.entityId)
              .eq('user_id', user.id);

          await boardAttachmentDao.deletePermanently(
            userId: user.id,
            id: item.entityId,
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

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: 'study_day',
      );

      final day = payload['day']?.toString().trim();

      if (day == null || day.isEmpty) {
        throw StateError('Operação de estudo sem day.');
      }

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          await supabaseClient.from(_studyTable).upsert({
            'user_id': user.id,
            'day': day,
            'minutes': payload['minutes'] ?? 0,
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,day');

          break;

        case SyncOperation.delete:
          await supabaseClient
              .from(_studyTable)
              .delete()
              .eq('user_id', user.id)
              .eq('day', day);

          break;
      }
    },
  );

  // ====================================================
  // TRAINING DAY
  // ====================================================

  syncService.registerHandler(
    entityType: 'training_day',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

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

          if (day == null || day.isEmpty || date == null || date.isEmpty) {
            throw StateError('Operação de treino sem day/date.');
          }

          await supabaseClient.from(_trainingTable).upsert({
            'user_id': user.id,
            'day': day,
            'training': payload['training']?.toString() ?? '',
            'date': date,
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,day,date,training');

          break;

        case SyncOperation.delete:
          if (deleteScope == 'all') {
            await supabaseClient
                .from(_trainingTable)
                .delete()
                .eq('user_id', user.id);

            break;
          }

          final day = payload['day']?.toString().trim();

          final date = payload['date']?.toString().trim();

          if (day == null || day.isEmpty || date == null || date.isEmpty) {
            throw StateError('Exclusão de treino sem day/date.');
          }

          final training = payload['training']?.toString().trim();

          if (training == null || training.isEmpty) {
            throw StateError('Exclusão de treino sem training.');
          }

          await supabaseClient
              .from(_trainingTable)
              .delete()
              .eq('user_id', user.id)
              .eq('day', day)
              .eq('date', date)
              .eq('training', training);

          break;
      }
    },
  );

  // ====================================================
  // TRAINING PLAN
  // ====================================================

  syncService.registerHandler(
    entityType: 'training_plan',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: 'training_plan',
      );

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          await supabaseClient.from(_trainingPlanTable).upsert({
            'user_id': user.id,
            'weekly_goal': payload['weekly_goal'] ?? 0,
            'planned_weekdays': payload['planned_weekdays'] ?? const <int>[],
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id');

          break;

        case SyncOperation.delete:
          await supabaseClient
              .from(_trainingPlanTable)
              .delete()
              .eq('user_id', user.id);

          break;
      }
    },
  );

  // ====================================================
  // TRAINING ACTIVITY PLAN / BODY MAP
  // ====================================================
  //
  // Repository:
  //
  // entityType = training_activity_plan
  //
  // Remote uniqueness:
  //
  // user_id + activity
  //
  // Exemplos de activity:
  //
  // chest
  // legs
  // arms
  // back
  // shoulders
  // core
  // running
  // walking
  //
  // ====================================================

  syncService.registerHandler(
    entityType: 'training_activity_plan',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: 'training_activity_plan',
      );

      final activity = payload['activity']?.toString().trim().toLowerCase();

      if (activity == null || activity.isEmpty) {
        throw StateError('Operação de plano corporal sem activity.');
      }

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          final rawWeekdays = payload['weekdays'];

          final weekdays = <int>[];

          if (rawWeekdays is Iterable) {
            for (final raw in rawWeekdays) {
              final day = raw is int ? raw : int.tryParse(raw.toString());

              if (day == null ||
                  day < DateTime.monday ||
                  day > DateTime.sunday) {
                continue;
              }

              if (!weekdays.contains(day)) {
                weekdays.add(day);
              }
            }
          }

          weekdays.sort();

          await supabaseClient.from(_trainingActivityPlanTable).upsert({
            'user_id': user.id,
            'activity': activity,
            'weekdays': weekdays,
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,activity');

          await trainingActivityPlanDao.setActivitySyncStatus(
            userId: user.id,
            activity: activity,
            syncStatus: SyncStatus.synced,
          );

          break;

        case SyncOperation.delete:
          await supabaseClient
              .from(_trainingActivityPlanTable)
              .delete()
              .eq('user_id', user.id)
              .eq('activity', activity);

          await trainingActivityPlanDao.deletePermanently(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // BRAIN NOTE
  // ====================================================
  //
  // Repository:
  //
  // entityType = brain_note
  //
  // A persistência local acontece primeiro em BrainStorage.
  //
  // O handler apenas envia a alteração pendente para o
  // Supabase quando houver conexão.
  //
  // created_at e updated_at vêm do payload local para que uma
  // nota criada offline preserve a data original no servidor.
  //
  // ====================================================

  syncService.registerHandler(
    entityType: BrainRepository.noteEntityType,

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: BrainRepository.noteEntityType,
      );

      final topic = payload['topic']?.toString().trim() ?? '';

      final title = payload['title']?.toString().trim() ?? '';

      final content = payload['content']?.toString() ?? '';

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          if (topic.isEmpty) {
            throw StateError('Operação de brain_note sem topic.');
          }

          if (title.isEmpty) {
            throw StateError('Operação de brain_note sem title.');
          }

          if (content.trim().isEmpty) {
            throw StateError('Operação de brain_note sem content.');
          }

          // ==================================================
          // REMOTE SAVE
          // ==================================================
          //
          // O SupabaseBrainService continua responsável pelas
          // tabelas e regras específicas do módulo Brain.
          //
          // O ID da SyncQueue é usado como ID remoto estável.
          //
          // ==================================================

          await supabaseBrainService.saveNote(
            id: item.entityId,

            topic: topic,

            title: title,

            content: content,

            createdAt: _syncPayloadDate(payload['created_at']),

            updatedAt: _syncPayloadDate(payload['updated_at']),
          );

          break;

        case SyncOperation.delete:
          await supabaseBrainService.deleteNote(item.entityId);

          break;
      }

      // Mantém a validação explícita de usuário usada pelos
      // demais handlers e evita warning de variável não usada.
      assert(user.id.isNotEmpty);
    },
  );

  // ====================================================
  // BRAIN CONCEPT
  // ====================================================
  //
  // Repository:
  //
  // entityType = brain_concept
  //
  // Conceitos também seguem:
  //
  // local -> fila -> Supabase.
  //
  // As datas locais também são preservadas durante o envio.
  //
  // ====================================================

  syncService.registerHandler(
    entityType: BrainRepository.conceptEntityType,

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: BrainRepository.conceptEntityType,
      );

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          final title = payload['title']?.toString().trim() ?? '';

          final description = payload['description']?.toString().trim() ?? '';

          final typeName = payload['type']?.toString().trim() ?? '';

          if (title.isEmpty) {
            throw StateError('Operação de brain_concept sem title.');
          }

          if (description.isEmpty) {
            throw StateError('Operação de brain_concept sem description.');
          }

          final type = BrainConceptType.values.firstWhere(
            (value) {
              return value.name == typeName;
            },
            orElse: () {
              throw StateError('Tipo de brain_concept inválido: $typeName');
            },
          );

          final concept = BrainConcept(
            id: item.entityId,
            title: title,
            description: description,
            type: type,
          );

          final rawNoteId = payload['note_id']?.toString().trim();

          final noteId = rawNoteId == null || rawNoteId.isEmpty
              ? null
              : rawNoteId;

          await supabaseBrainService.saveConcept(
            concept: concept,

            noteId: noteId,

            createdAt: _syncPayloadDate(payload['created_at']),

            updatedAt: _syncPayloadDate(payload['updated_at']),
          );

          break;

        case SyncOperation.delete:
          await supabaseBrainService.deleteConcept(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // BRAIN REVIEW - LEGACY SYNC HANDLER
  // ====================================================
  //
  // Este handler existe SOMENTE para processar itens antigos
  // de brain_review que já estavam na SyncQueue antes da
  // migração para o Vault.
  //
  // O ReviewRepository Vault-first NÃO cria novos itens deste
  // tipo na fila.
  //
  // Portanto:
  //
  // - nenhuma revisão nova é colocada aqui em plaintext;
  // - operações antigas ainda podem ser drenadas;
  // - este bloco será removido quando a SyncQueue E2EE e a
  //   tabela brain_objects estiverem prontas.
  //
  // ====================================================

  syncService.registerHandler(
    entityType: ReviewRepository.entityType,

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: ReviewRepository.entityType,
      );

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          final conceptId = payload['concept_id']?.toString().trim() ?? '';

          final question = payload['question']?.toString().trim() ?? '';

          final answer = payload['answer']?.toString().trim() ?? '';

          final sourceNotePath =
              payload['source_note_path']?.toString().trim() ?? '';

          final sourceNoteTitle =
              payload['source_note_title']?.toString().trim() ?? '';

          if (conceptId.isEmpty) {
            throw StateError('Operação de brain_review sem concept_id.');
          }

          if (question.isEmpty) {
            throw StateError('Operação de brain_review sem question.');
          }

          if (answer.isEmpty) {
            throw StateError('Operação de brain_review sem answer.');
          }

          if (sourceNotePath.isEmpty) {
            throw StateError('Operação de brain_review sem source_note_path.');
          }

          final createdAt =
              _syncPayloadDate(payload['created_at']) ?? DateTime.now();

          final nextReviewAt =
              _syncPayloadDate(payload['next_review_at']) ?? DateTime.now();

          final lastReviewedAt = _syncPayloadDate(payload['last_reviewed_at']);

          final archivedAt = _syncPayloadDate(payload['archived_at']);

          int parseInt(dynamic value) {
            if (value is int) {
              return value;
            }

            return int.tryParse(value?.toString().trim() ?? '') ?? 0;
          }

          bool parseBool(dynamic value) {
            if (value is bool) {
              return value;
            }

            final normalized = value?.toString().trim().toLowerCase();

            return normalized == 'true' || normalized == '1';
          }

          final review = BrainReviewItem(
            id: item.entityId,

            conceptId: conceptId,

            question: question,

            answer: answer,

            sourceNotePath: sourceNotePath,

            sourceNoteTitle: sourceNoteTitle,

            createdAt: createdAt,

            nextReviewAt: nextReviewAt,

            lastReviewedAt: lastReviewedAt,

            archivedAt: archivedAt,

            reviewCount: parseInt(payload['review_count']),

            correctCount: parseInt(payload['correct_count']),

            wrongCount: parseInt(payload['wrong_count']),

            streak: parseInt(payload['streak']),

            archived: parseBool(payload['archived']),
          );

          await supabaseReviewService.saveReview(review);

          break;

        case SyncOperation.delete:
          await supabaseReviewService.deleteReview(item.entityId);

          break;
      }
    },
  );

  // ====================================================
  // JOURNEY
  // ====================================================

  syncService.registerHandler(
    entityType: 'journey_day',

    handler: (item) async {
      final payload = Map<String, dynamic>.from(item.payload);

      final user = _requireQueueUser(
        userId: payload['user_id']?.toString(),
        entity: 'journey_day',
      );

      final deleteScope = payload['delete_scope']?.toString();

      switch (item.operation) {
        case SyncOperation.create:
        case SyncOperation.update:
          final date = payload['date']?.toString().trim();

          if (date == null || date.isEmpty) {
            throw StateError('Operação de jornada sem date.');
          }

          await supabaseClient.from(_journeyTable).upsert({
            'user_id': user.id,
            'date': date,
            'notes': payload['notes'] ?? const <String>[],
            'updated_at':
                payload['updated_at'] ??
                DateTime.now().toUtc().toIso8601String(),
          }, onConflict: 'user_id,date');

          break;

        case SyncOperation.delete:
          if (deleteScope == 'all') {
            await supabaseClient
                .from(_journeyTable)
                .delete()
                .eq('user_id', user.id);

            break;
          }

          final date = payload['date']?.toString().trim();

          if (date == null || date.isEmpty) {
            throw StateError('Exclusão de jornada sem date.');
          }

          await supabaseClient
              .from(_journeyTable)
              .delete()
              .eq('user_id', user.id)
              .eq('date', date);

          break;
      }
    },
  );

  _syncHandlersRegistered = true;
}

// ======================================================
// INITIALIZE OFFLINE-FIRST
// ======================================================

Future<void> initializeOfflineFirst() async {
  await appDatabase.initialize();

  await trainingActivityPlanDao.initialize();

  await boardAttachmentDao.initialize();

  // ====================================================
  // BRAIN REVIEW VAULT
  // ====================================================
  //
  // 1. abre/cria o Vault;
  // 2. recupera a Master Key pelo secure storage;
  // 3. só depois executa a migração legada de reviews.
  //
  // ====================================================

  await reviewRepository.initialize();

  // ====================================================
  // BRAIN LEGACY MIGRATION RUNTIME
  // ====================================================
  //
  // Reutilizamos a infraestrutura de migração que já existe.
  //
  // NÃO criamos uma segunda lógica de migração.
  //
  // BrainMigrationFactory
  //      ↓
  // BrainMigrationCoordinator
  //      ↓
  // BrainReviewStartupMigrationService
  //      ↓
  // reviews.json legado
  //      ↓
  // Vault criptografado
  //
  // A infraestrutura existente mantém o registry de migração e
  // impede duplicação persistente.
  //
  // O arquivo legado NÃO é apagado nesta etapa.
  //
  // ====================================================

  final brainMigrationRuntime = await BrainMigrationFactory.create(
    vaultService: brainVaultService,
    brainStorage: brainStorage,
    reviewStorage: reviewStorage,
  );

  final brainReviewStartupMigrationService = BrainReviewStartupMigrationService(
    coordinator: brainMigrationRuntime.coordinator,
  );

  await brainReviewStartupMigrationService.run();

  // ====================================================
  // SYNC
  // ====================================================
  //
  // Só iniciamos a sincronização depois de:
  //
  // - banco local;
  // - Vault;
  // - migração de reviews legadas.
  //
  // ====================================================

  registerSyncHandlers();

  await syncService.start();
}

// ======================================================
// REFRESH SYNC STATUS
// ======================================================

Future<void> refreshSyncStatus() async {
  await syncService.refreshPendingCount();

  await connectivityService.checkNow();
}

// ======================================================
// FORCE SYNC
// ======================================================

Future<void> forceSyncNow() async {
  await syncService.syncNow(checkConnection: true);
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

final financeService = FinanceService(repository: financeRepository);

final financeController = FinanceController(financeService);

// ======================================================
// CRYPTO REPOSITORY
// ======================================================

final cryptoRepository = CryptoRepository(storage: localStorage);

// ======================================================
// CRYPTO SERVICE
// ======================================================

final cryptoService = CryptoService(repository: cryptoRepository);

// ======================================================
// CRYPTO PRICE SERVICE
// ======================================================

final cryptoPriceService = CryptoPriceService();

// ======================================================
// CRYPTO CONTROLLER
// ======================================================

final cryptoController = CryptoController(service: cryptoService);

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

final trainingService = TrainingService(repository: trainingRepository);

final trainingController = TrainingController(service: trainingService);

// ======================================================
// TRAINING - BODY MAP
// ======================================================
//
// OFFLINE-FIRST:
//
// BodyMapDialog
//      ↓
// BodyMapController
//      ↓
// BodyMapService
//      ↓
// BodyMapRepository
//      ↓
// TrainingActivityPlanDao
//      ↓
// SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// Supabase training_activity_plans
//
// ======================================================

final bodyMapRepository = BodyMapRepository(
  client: supabaseClient,

  localDao: trainingActivityPlanDao,

  syncQueue: syncQueue,

  syncService: syncService,
);

final bodyMapService = BodyMapService(repository: bodyMapRepository);

final bodyMapController = BodyMapController();

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

final studyService = StudyService(repository: studyRepository);

final studyController = StudyController(service: studyService);

// ======================================================
// EVOLUTION
// ======================================================

final evolutionRepository = EvolutionRepository(
  studyRepository: studyRepository,

  trainingRepository: trainingRepository,

  financeRepository: financeRepository,

  storage: localStorage,
);

final evolutionService = EvolutionService(repository: evolutionRepository);

final evolutionController = EvolutionController(service: evolutionService);

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

final journeyService = JourneyService(repository: journeyRepository);

final journeyController = JourneyController(service: journeyService);

// ======================================================
// REMINDERS
// ======================================================

final reminderRepository = ReminderRepository(
  client: supabaseClient,

  localDao: reminderDao,

  syncQueue: syncQueue,

  syncService: syncService,
);

final reminderController = ReminderController(repository: reminderRepository);

final reminderService = ReminderService(
  controller: reminderController,

  checkInterval: const Duration(seconds: 30),
);
