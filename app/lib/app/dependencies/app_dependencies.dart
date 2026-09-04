import 'dart:io';

import 'package:flutter/foundation.dart';

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
import '../../core/database/daos/sync_queue_dao.dart';
import '../../core/database/daos/training_activity_plan_dao.dart';
import '../../core/database/daos/board_attachment_dao.dart';
import '../../core/database/daos/board_comment_dao.dart';

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

import '../../profile/security/devices/repositories/account_device_repository.dart';
import '../../profile/security/devices/services/account_device_identity_service.dart';
import '../../profile/security/devices/services/account_device_presence_service.dart';

import '../../routine/controllers/routine_controller.dart';
import '../../routine/controllers/comments/board_comment_controller.dart';
import '../../routine/data/datasources/comments/board_comment_remote_data_source.dart';
import '../../routine/data/repositories/comments/board_comment_repository.dart';

// ======================================================
// STUDY - BRAIN / CÉREBRO
// ======================================================

import '../../study/brain/controllers/brain_controller.dart';
import '../../study/brain/controllers/review_controller.dart';

import '../../study/brain/repositories/brain_repository.dart';
import '../../study/brain/repositories/review_repository.dart';

import '../../study/brain/services/brain_storage.dart';
import '../../study/brain/services/review_storage.dart';
import '../../study/brain/services/supabase_brain_service.dart';
import '../../study/brain/services/supabase_review_service.dart';
import '../../study/brain/backup/services/brain_backup_service.dart';

import '../../study/brain/migration/services/brain_migration_factory.dart';
import '../../study/brain/migration/services/brain_review_startup_migration_service.dart';

import '../../study/brain/security/keys/brain_key_service.dart';
import '../../study/brain/security/keys/brain_platform_key_storage.dart';

import '../../study/brain/vault/services/brain_vault_service.dart';
import '../../study/brain/vault/storage/brain_vault_storage.dart';
import '../../study/brain/vault/stores/brain_review_vault_store.dart';
import '../../study/brain/vault/stores/brain_note_vault_store.dart';
import '../../study/brain/vault/stores/brain_concept_vault_store.dart';

import '../../study/brain/settings/controllers/brain_data_mode_controller.dart';
import '../../study/brain/settings/services/brain_data_mode_service.dart';
import '../../study/brain/settings/storage/brain_data_mode_storage.dart';

import '../../study/brain/sync/services/brain_cloud_pull_service.dart';
import '../../study/brain/sync/services/brain_core_sync_queue_writer.dart';
import '../../study/brain/sync/services/brain_e2ee_sync_coordinator.dart';
import '../../study/brain/sync/services/brain_supabase_e2ee_service.dart';
import '../../study/brain/sync/services/brain_sync_queue_service.dart';

import '../../study/brain/devices/adapters/brain_key_service_device_master_key_adapter.dart';
import '../../study/brain/devices/security/brain_device_crypto_service.dart';
import '../../study/brain/devices/security/brain_device_secure_storage.dart';
import '../../study/brain/devices/services/brain_device_authorization_service.dart';
import '../../study/brain/devices/services/brain_device_gate_service.dart';
import '../../study/brain/devices/services/brain_device_identity_service.dart';
import '../../study/brain/devices/services/brain_device_supabase_service.dart';
import '../../study/brain/devices/services/brain_recovery_device_service.dart';

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
import '../../study/services/study_day_service.dart';

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

const String
_studyTable = 'study_data';

const String
_trainingTable = 'training_data';

const String
_trainingPlanTable = 'training_plans';

const String
_trainingActivityPlanTable = 'training_activity_plans';

const String
_journeyTable = 'journey_history';

const String
_boardAttachmentTable = 'board_attachments';

const String
_boardAttachmentBucket = 'board-files';

// ======================================================
// LOCAL DATABASE
// ======================================================

final appDatabase = AppDatabase.instance;

// ======================================================
// CONNECTIVITY
// ======================================================

final connectivityService = ConnectivityService(
  probeCacheDuration: const Duration(
    seconds: 30,
  ),
);

// ======================================================
// SYNC QUEUE DAO
// ======================================================
//
// Única camada responsável pelo SQL da fila de sincronização.
//
// SyncQueue
//      ↓
// SyncQueueDao
//      ↓
// SQLite
//
// ======================================================

final syncQueueDao = SyncQueueDao(
  database: appDatabase,
);

// ======================================================
// SYNC QUEUE
// ======================================================

final syncQueue = SyncQueue(
  dao: syncQueueDao,
);

// ======================================================
// SYNC SERVICE
// ======================================================

final syncService = SyncService(
  queue: syncQueue,

  connectivityService: connectivityService,

  client: supabaseClient,

  // Fallback de segurança.
  //
  // O fluxo normal deve acontecer via requestSync() e eventos de
  // conectividade. O timer não deve ser o motor principal do sync.
  syncInterval: const Duration(
    seconds: 60,
  ),

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

final supabaseBrainService = SupabaseBrainService(
  client: supabaseClient,
);

final brainRepository = BrainRepository(
  remote: supabaseBrainService,
  local: brainStorage,
  noteVaultStore: brainNoteVaultStore,
  conceptVaultStore: brainConceptVaultStore,
  brainSyncQueueService: brainSyncQueueService,
);

final brainController = BrainController(
  repository: brainRepository,
);

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
//   compatibilidade/importação remota legada;
// - a SyncQueue antiga de brain_review é purgada após a migração;
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

final brainKeyService = BrainKeyService(
  storage: brainKeyStorage,
);

// ======================================================
// BRAIN VAULT STORAGE
// ======================================================
//
// Instância explícita e única.
//
// O BrainVaultService e o BrainCloudPullService precisam apontar
// para o mesmo armazenamento físico.
//
// ======================================================

final brainVaultStorage = BrainVaultStorage();

// ======================================================
// BRAIN VAULT
// ======================================================

final brainVaultService = BrainVaultService(
  keyService: brainKeyService,
  storage: brainVaultStorage,
);

// ======================================================
// BRAIN BACKUP — .evbrain
// ======================================================

final brainBackupService = BrainBackupService(
  vaultService: brainVaultService,
  vaultStorage: brainVaultStorage,
  keyService: brainKeyService,
);

// ======================================================
// NOTE / CONCEPT VAULT STORES
// ======================================================

final brainNoteVaultStore = BrainNoteVaultStore(
  vaultService: brainVaultService,
);

final brainConceptVaultStore = BrainConceptVaultStore(
  vaultService: brainVaultService,
);

// ======================================================
// BRAIN DATA MODE — FASE 05
// ======================================================

final brainDataModeStorage = SharedPreferencesBrainDataModeStorage();

final brainDataModeService = BrainDataModeService(
  storage: brainDataModeStorage,
);

final brainDataModeController = BrainDataModeController(
  service: brainDataModeService,
);

// ======================================================
// BRAIN E2EE — FASE 06
// ======================================================
//
// Vault
//   ↓
// BrainSyncPayload
//   ↓
// SyncQueue (brain_e2ee_object)
//   ↓
// SyncService
//   ↓
// BrainSupabaseE2eeService
//   ↓
// public.brain_objects
//
// ======================================================

final brainCoreSyncQueueWriter = CoreBrainSyncQueueWriter(
  queue: syncQueue,
  syncService: syncService,
);

final brainSyncQueueService = BrainSyncQueueService(
  dataModeService: brainDataModeService,
  vaultService: brainVaultService,
  writer: brainCoreSyncQueueWriter,
);

final brainSupabaseE2eeService = BrainSupabaseE2eeService(
  client: supabaseClient,
);

final brainCloudPullService = BrainCloudPullService(
  remote: brainSupabaseE2eeService,
  vaultService: brainVaultService,
  vaultStorage: brainVaultStorage,
  keyService: brainKeyService,
);

final brainE2eeSyncCoordinator = BrainE2eeSyncCoordinator(
  dataModeService: brainDataModeService,
  queueService: brainSyncQueueService,
  pullService: brainCloudPullService,

  // ==========================================================
  // FASE 07 — GATE TAMBÉM PARA O PULL
  // ==========================================================
  //
  // O coordinator não pode acessar brain_objects apenas porque
  // existe uma sessão autenticada.
  //
  // Agora o mesmo gate utilizado pelo SyncService protege:
  //
  // - bootstrap pull;
  // - pull manual;
  // - transmissão dos objetos E2EE.
  //
  // Requisitos:
  //
  // Cloud
  // + auth
  // + Vault
  // + Master Key local
  // + device identity
  // + device authorized
  //
  // ==========================================================
  canUseCloudOperations: _canUseBrainCloudWithAuthorizedDevice,
);

// ======================================================
// ACCOUNT DEVICES / SESSIONS
// ======================================================
//
// Esta identidade é separada do Brain/E2EE.
// Ela representa a instalação do EVRYLUX para fins de sessão,
// presença e gerenciamento de dispositivos da conta.
//
// ======================================================

final accountDeviceIdentityService = AccountDeviceIdentityService();

final accountDeviceRepository = AccountDeviceRepository(
  client: supabaseClient,
);

final accountDevicePresenceService = AccountDevicePresenceService(
  client: supabaseClient,
  repository: accountDeviceRepository,
  identityService: accountDeviceIdentityService,
);

// ======================================================
// BRAIN AUTHORIZED DEVICES — FASE 07
// ======================================================
//
// Device Private Key
//      ↓
// PlatformBrainDeviceSecureStorage
//
// Public Key / status / envelope criptografado
//      ↓
// BrainDeviceSupabaseService
//
// Master Key
//      ↓
// BrainKeyServiceDeviceMasterKeyAdapter
//      ↓
// BrainKeyService
//      ↓
// BrainPlatformKeyStorage
//
// IMPORTANTE:
//
// - não existe segundo storage de Master Key;
// - private key X25519 fica no secure storage local;
// - Supabase nunca recebe a Master Key em plaintext;
// - Cloud sync do Brain passa a exigir dispositivo autorizado;
// - qualquer erro no gate falha fechado.
//
// ======================================================

final brainDeviceSecureStorage = PlatformBrainDeviceSecureStorage();

final brainDeviceCryptoService = BrainDeviceCryptoService();

final brainDeviceIdentityService = BrainDeviceIdentityService(
  storage: brainDeviceSecureStorage,
  cryptoService: brainDeviceCryptoService,
);

final brainDeviceSupabaseService = BrainDeviceSupabaseService(
  client: supabaseClient,
);

final brainDeviceMasterKeyAdapter = BrainKeyServiceDeviceMasterKeyAdapter(
  keyService: brainKeyService,
);

final brainDeviceAuthorizationService = BrainDeviceAuthorizationService(
  identityService: brainDeviceIdentityService,
  remote: brainDeviceSupabaseService,
  masterKeyPort: brainDeviceMasterKeyAdapter,
  cryptoService: brainDeviceCryptoService,
);

final brainDeviceGateService = BrainDeviceGateService(
  identityService: brainDeviceIdentityService,
  remote: brainDeviceSupabaseService,
  masterKeyPort: brainDeviceMasterKeyAdapter,
);

final brainRecoveryDeviceService = BrainRecoveryDeviceService(
  authorizationService: brainDeviceAuthorizationService,
  vaultService: brainVaultService,
);

// ======================================================
// BRAIN DEVICE NAME
// ======================================================

String
brainDeviceName() {
  final host = Platform.localHostname.trim();

  final os = Platform.operatingSystem.trim();

  if (host.isNotEmpty &&
      os.isNotEmpty) {
    return '$host • $os';
  }

  if (host.isNotEmpty) {
    return host;
  }

  if (os.isNotEmpty) {
    return 'EVRYLUX • $os';
  }

  return 'EVRYLUX Device';
}

// ======================================================
// BRAIN CLOUD + AUTHORIZED DEVICE GATE
// ======================================================
//
// Gate final:
//
// Cloud mode
// + sessão autenticada
// + Vault local válido
// + identidade local de dispositivo
// + Master Key disponível localmente
// + dispositivo autorizado no Supabase
//
// Qualquer falha:
// false
//
// ======================================================

Future<
  bool
>
_canUseBrainCloudWithAuthorizedDevice() async {
  final isAuthenticated =
      supabaseClient.auth.currentUser !=
      null;

  final dataModeAllowsCloud = brainDataModeService.canUseCloudSync(
    isAuthenticated: isAuthenticated,
  );

  if (!dataModeAllowsCloud) {
    return false;
  }

  try {
    final manifest = await brainVaultService.openVault();

    return await brainDeviceGateService.canUseCloud(
      vaultId: manifest.vaultId,
      isAuthenticated: isAuthenticated,
      dataModeAllowsCloud: dataModeAllowsCloud,
    );
  } catch (
    error
  ) {
    debugPrint(
      '[BRAIN DEVICE GATE] '
      'Cloud bloqueado: $error',
    );

    return false;
  }
}

// ======================================================
// BRAIN DEVICE BOOTSTRAP
// ======================================================
//
// Executado apenas quando:
//
// - o modo permite Cloud;
// - existe usuário autenticado;
// - o Vault local já foi aberto.
//
// Primeiro dispositivo do Vault:
// servidor poderá marcá-lo como authorized.
//
// Dispositivos seguintes:
// começam pending e exigem aprovação explícita.
//
// Falha remota NÃO destrói o Vault local.
// O processingGate continuará fail-closed.
//
// ======================================================

Future<
  void
>
_bootstrapBrainAuthorizedDevice() async {
  final isAuthenticated =
      supabaseClient.auth.currentUser !=
      null;

  final dataModeAllowsCloud = brainDataModeService.canUseCloudSync(
    isAuthenticated: isAuthenticated,
  );

  if (!dataModeAllowsCloud) {
    return;
  }

  try {
    final manifest = await brainVaultService.openVault();

    final device = await brainDeviceAuthorizationService.registerCurrentDevice(
      vaultId: manifest.vaultId,
      deviceName: brainDeviceName(),
    );

    debugPrint(
      '[BRAIN DEVICE] '
      '${device.deviceName} '
      '(${device.deviceId}) '
      'status=${device.status.name} '
      'fingerprint=${device.keyFingerprint}',
    );
  } catch (
    error
  ) {
    debugPrint(
      '[BRAIN DEVICE] '
      'Bootstrap remoto indisponível/bloqueado: '
      '$error',
    );
  }
}

// ======================================================
// REVIEW VAULT STORE
// ======================================================

final brainReviewVaultStore = BrainReviewVaultStore(
  vaultService: brainVaultService,
);

// ======================================================
// LEGACY REMOTE REVIEW SERVICE
// ======================================================
//
// Mantido temporariamente apenas para compatibilidade/migração
// do backend antigo.
//
// ======================================================

final supabaseReviewService = SupabaseReviewService(
  client: supabaseClient,
);

// ======================================================
// REVIEW REPOSITORY
// ======================================================
//
// Novos saves/deletes:
//
// ReviewRepository
//      ↓
// BrainReviewVaultStore
//      ↓
// Vault criptografado
//      ↓
// BrainSyncQueueService
//
// Nenhuma pergunta/resposta nova entra na fila legada.
//
// ======================================================

final reviewRepository = ReviewRepository(
  vaultStore: brainReviewVaultStore,
  remote: supabaseReviewService,
  local: reviewStorage,
  syncQueue: syncQueue,
  brainSyncQueueService: brainSyncQueueService,
);

// ======================================================
// REVIEW CONTROLLER
// ======================================================

final reviewController = ReviewController(
  repository: reviewRepository,
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
// BOARD COMMENT DAO
// ======================================================

final boardCommentDao = BoardCommentDao(
  database: appDatabase,
);

// ======================================================
// TRAINING ACTIVITY PLAN DAO
// ======================================================
//
// Persistência SQLite do mapa corporal / plano de atividades.
//
// ======================================================

final trainingActivityPlanDao = TrainingActivityPlanDao(
  database: appDatabase,
);

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

final boardAttachmentDao = BoardAttachmentDao(
  database: appDatabase,
);

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
// PURGE LEGACY BRAIN QUEUE
// ======================================================
//
// Remove somente entityTypes antigos do Cérebro que carregavam
// payload lógico/plaintext.
//
// A fonte local já foi migrada para o Vault antes desta limpeza.
//
// NÃO remove brain_e2ee_object.
//
// Isso evita:
// - plaintext legado permanecer indefinidamente no SQLite;
// - handlers antigos precisarem continuar registrados;
// - uma versão futura voltar a transmitir esses itens por engano.
//
// ======================================================

Future<
  void
>
_purgeLegacyBrainQueueItems() async {
  const legacyEntityTypes =
      <
        String
      >{
        'brain_note',
        'brain_concept',
        'brain_review',
      };

  final items = await syncQueue.getAll();

  var removed = 0;

  for (final item in items) {
    if (!legacyEntityTypes.contains(
      item.entityType,
    )) {
      continue;
    }

    await syncQueue.remove(
      item.id,
    );

    removed++;
  }

  if (removed >
      0) {
    debugPrint(
      '[BRAIN E2EE] '
      '$removed item(ns) legado(s) removido(s) da SyncQueue.',
    );
  }
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
  // BOARD COMMENT
  // ====================================================

  syncService.registerHandler(
    entityType: BoardCommentRepository.entityType,

    handler:
        (
          item,
        ) async {
          final payload =
              Map<String, dynamic>.from(
                item.payload,
              );

          final user = _requireQueueUser(
            userId: payload['user_id']?.toString(),
            entity: BoardCommentRepository.entityType,
          );

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              await boardCommentRemoteDataSource.upsertQueued(
                userId: user.id,
                commentId: item.entityId,
                payload: payload,
              );

              await boardCommentDao.setSyncStatus(
                item.entityId,
                SyncStatus.synced,
              );

              break;

            case SyncOperation.delete:
              await boardCommentRemoteDataSource.deleteQueued(
                userId: user.id,
                commentId: item.entityId,
              );

              await boardCommentDao.deletePermanently(
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
            entity: BoardAttachmentRepository.entityType,
          );

          final boardId =
              payload['board_id']?.toString().trim() ??
              '';

          final blockId =
              payload['block_id']?.toString().trim() ??
              '';

          final fileName =
              payload['file_name']?.toString().trim() ??
              '';

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              if (boardId.isEmpty) {
                throw StateError(
                  'Operação de board_attachment sem board_id.',
                );
              }

              if (blockId.isEmpty) {
                throw StateError(
                  'Operação de board_attachment sem block_id.',
                );
              }

              if (fileName.isEmpty) {
                throw StateError(
                  'Operação de board_attachment sem file_name.',
                );
              }

              final localPath =
                  payload['local_path']?.toString().trim() ??
                  '';

              if (localPath.isEmpty) {
                throw StateError(
                  'Operação de board_attachment sem local_path.',
                );
              }

              final localFile = File(
                localPath,
              );

              if (!await localFile.exists()) {
                throw StateError(
                  'Arquivo local do board_attachment não encontrado: '
                  '$localPath',
                );
              }

              final rawRemotePath = payload['remote_path']?.toString().trim();

              final remotePath =
                  rawRemotePath !=
                          null &&
                      rawRemotePath.isNotEmpty
                  ? rawRemotePath
                  : '${user.id}/'
                        '$boardId/'
                        '${item.entityId}/'
                        '$fileName';

              final mimeType = payload['mime_type']?.toString().trim();

              final bytes = await localFile.readAsBytes();

              await supabaseClient.storage
                  .from(
                    _boardAttachmentBucket,
                  )
                  .uploadBinary(
                    remotePath,
                    bytes,
                    fileOptions: FileOptions(
                      upsert: true,
                      contentType:
                          mimeType !=
                                  null &&
                              mimeType.isNotEmpty
                          ? mimeType
                          : null,
                    ),
                  );

              final remotePayload =
                  <
                    String,
                    dynamic
                  >{
                    'id': item.entityId,
                    'user_id': user.id,
                    'board_id': boardId,
                    'block_id': blockId,
                    'file_name': fileName,
                    'type':
                        payload['type']?.toString() ??
                        'unknown',
                    'remote_path': remotePath,
                    'mime_type': mimeType,
                    'size_bytes':
                        payload['size_bytes'] ??
                        bytes.length,
                    'created_at':
                        payload['created_at'] ??
                        DateTime.now().toUtc().toIso8601String(),
                    'updated_at':
                        payload['updated_at'] ??
                        DateTime.now().toUtc().toIso8601String(),
                  };

              await supabaseClient
                  .from(
                    _boardAttachmentTable,
                  )
                  .upsert(
                    remotePayload,
                    onConflict: 'id',
                  );

              await boardAttachmentDao.updateRemotePath(
                userId: user.id,
                id: item.entityId,
                remotePath: remotePath,
                syncStatus: SyncStatus.synced,
              );

              break;

            case SyncOperation.delete:
              final remotePath = payload['remote_path']?.toString().trim();

              if (remotePath !=
                      null &&
                  remotePath.isNotEmpty) {
                await supabaseClient.storage
                    .from(
                      _boardAttachmentBucket,
                    )
                    .remove(
                      <
                        String
                      >[
                        remotePath,
                      ],
                    );
              }

              await supabaseClient
                  .from(
                    _boardAttachmentTable,
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
                      'date': date,
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id,day,date,training',
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

              final training = payload['training']?.toString().trim();

              if (training ==
                      null ||
                  training.isEmpty) {
                throw StateError(
                  'Exclusão de treino sem training.',
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
                  )
                  .eq(
                    'training',
                    training,
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
            entity: 'training_activity_plan',
          );

          final activity = payload['activity']?.toString().trim().toLowerCase();

          if (activity ==
                  null ||
              activity.isEmpty) {
            throw StateError(
              'Operação de plano corporal sem activity.',
            );
          }

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              final rawWeekdays = payload['weekdays'];

              final weekdays =
                  <
                    int
                  >[];

              if (rawWeekdays
                  is Iterable) {
                for (final raw in rawWeekdays) {
                  final day =
                      raw
                          is int
                      ? raw
                      : int.tryParse(
                          raw.toString(),
                        );

                  if (day ==
                          null ||
                      day <
                          DateTime.monday ||
                      day >
                          DateTime.sunday) {
                    continue;
                  }

                  if (!weekdays.contains(
                    day,
                  )) {
                    weekdays.add(
                      day,
                    );
                  }
                }
              }

              weekdays.sort();

              await supabaseClient
                  .from(
                    _trainingActivityPlanTable,
                  )
                  .upsert(
                    {
                      'user_id': user.id,
                      'activity': activity,
                      'weekdays': weekdays,
                      'updated_at':
                          payload['updated_at'] ??
                          DateTime.now().toUtc().toIso8601String(),
                    },
                    onConflict: 'user_id,activity',
                  );

              await trainingActivityPlanDao.setActivitySyncStatus(
                userId: user.id,
                activity: activity,
                syncStatus: SyncStatus.synced,
              );

              break;

            case SyncOperation.delete:
              await supabaseClient
                  .from(
                    _trainingActivityPlanTable,
                  )
                  .delete()
                  .eq(
                    'user_id',
                    user.id,
                  )
                  .eq(
                    'activity',
                    activity,
                  );

              await trainingActivityPlanDao.deletePermanently(
                item.entityId,
              );

              break;
          }
        },
  );

  // ====================================================
  // BRAIN E2EE OBJECT — FASE 06
  // ====================================================
  //
  // A fila contém somente BrainVaultObject já criptografado.
  //
  // Não reconstruímos pergunta/resposta aqui.
  //
  // O Supabase recebe:
  //
  // - metadata técnica;
  // - encrypted_object;
  // - tombstone quando excluído.
  //
  // ====================================================

  syncService.registerHandler(
    entityType: BrainSyncQueueService.entityType,

    // ==================================================
    // GATE DE TRANSMISSÃO DO BRAIN
    // ==================================================
    //
    // Segurança crítica:
    //
    // LOCAL
    //   -> false
    //   -> item permanece na fila
    //   -> NÃO chama Supabase
    //
    // CLOUD + autenticado
    //   -> true
    //
    // O SyncService trata false como "adiado":
    //
    // - não markSuccess;
    // - não markFailed;
    // - não remove;
    // - não incrementa retry.
    //
    // ==================================================
    processingGate:
        (
          _,
        ) async {
          return _canUseBrainCloudWithAuthorizedDevice();
        },

    handler:
        (
          item,
        ) async {
          // ==================================================
          // SEGUNDA CHECAGEM — FAIL CLOSED
          // ==================================================
          //
          // O processingGate bloqueia itens pendentes antes do
          // processamento.
          //
          // Rechecamos imediatamente antes do acesso remoto para
          // reduzir a janela de mudança Cloud -> Local.
          //
          // ==================================================

          final canTransmit = await _canUseBrainCloudWithAuthorizedDevice();

          if (!canTransmit) {
            throw StateError(
              'Transmissão do Cérebro bloqueada: '
              'modo Local, sessão ausente ou '
              'dispositivo não autorizado.',
            );
          }

          switch (item.operation) {
            case SyncOperation.create:
            case SyncOperation.update:
              await brainSupabaseE2eeService.upsertQueuePayload(
                Map<
                  String,
                  dynamic
                >.from(
                  item.payload,
                ),
              );

              break;

            case SyncOperation.delete:
              throw StateError(
                'brain_e2ee_object não usa SyncOperation.delete. '
                'Exclusões são tombstones versionados enviados como update.',
              );
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

  await trainingActivityPlanDao.initialize();

  await boardAttachmentDao.initialize();

  // ====================================================
  // BRAIN DATA MODE
  // ====================================================
  //
  // Inicializa a preferência Local / Cloud antes da futura
  // integração E2EE.
  //
  // Regras:
  //
  // - primeira execução -> LOCAL;
  // - valor desconhecido -> LOCAL;
  // - CLOUD apenas habilita o gate;
  // - nenhum sync do Brain é iniciado aqui;
  // - nenhum plaintext é enviado por esta camada.
  //
  // ====================================================

  await brainDataModeController.initialize();

  if (brainDataModeController.errorMessage !=
      null) {
    throw StateError(
      brainDataModeController.errorMessage!,
    );
  }

  // ====================================================
  // BRAIN DATA MODE — PREFERÊNCIA PERSISTIDA
  // ====================================================
  //
  // Nenhum modo é forçado no startup.
  //
  // A preferência carregada por BrainDataModeController:
  //
  // LOCAL
  //   -> permanece somente no dispositivo;
  //   -> não enfileira novos objetos Brain para cloud;
  //   -> processingGate impede a saída de itens pendentes.
  //
  // CLOUD
  //   -> permite sincronização E2EE quando autenticado.
  //
  // ====================================================

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
  // BRAIN AUTHORIZED DEVICE BOOTSTRAP — FASE 07
  // ====================================================
  //
  // O Vault já existe localmente neste ponto.
  //
  // Em Local:
  //   nenhuma chamada remota.
  //
  // Em Cloud autenticado:
  //   registra/reconhece a identidade desta instalação.
  //
  // IMPORTANTE:
  //
  // Novo dispositivo ainda precisa do fluxo explícito de
  // aprovação + importação do envelope antes de poder abrir
  // um Vault existente sem uma Master Key local.
  //
  // ====================================================

  await _bootstrapBrainAuthorizedDevice();

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
  // PURGE LEGACY BRAIN QUEUE
  // ====================================================
  //
  // A migração local já terminou. Agora descartamos somente
  // operações antigas brain_note / brain_concept / brain_review
  // que poderiam conter plaintext.
  //
  // ====================================================

  await _purgeLegacyBrainQueueItems();

  // ====================================================
  // SYNC HANDLERS
  // ====================================================
  //
  // Registramos handlers antes do bootstrap E2EE.
  //
  // ====================================================

  registerSyncHandlers();

  // ====================================================
  // BRAIN E2EE BOOTSTRAP — FASE 06
  // ====================================================
  //
  // LOCAL:
  //   nenhuma operação de nuvem.
  //
  // CLOUD:
  //   1. exige auth + Master Key + dispositivo authorized;
  //   2. só então tenta pull remoto;
  //   3. valida AEAD/binding antes de persistir;
  //   4. enfileira o estado criptografado local;
  //   5. SyncService reaplica o gate antes do envio.
  //
  // Uma falha de rede no pull NÃO invalida o Vault local.
  //
  // ====================================================

  await brainE2eeSyncCoordinator.bootstrap();

  // ====================================================
  // START GLOBAL SYNC
  // ====================================================

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
// ROUTINE CONTROLLER FACTORY
// ======================================================
//
// A UI não resolve Supabase Auth diretamente.
//
// Este composition root concentra a estratégia de identidade.
//
// Hoje:
// - userId explicitamente injetado tem prioridade;
// - caso contrário, usa a sessão autenticada global.
//
// Amanhã:
// - modo local-only pode resolver uma identidade local aqui;
// - a RoutineScreen não precisará mudar.
//
// ======================================================

RoutineController
createRoutineControllerForCurrentUser({
  String? userId,
}) {
  final injectedUserId = userId?.trim();

  final authenticatedUserId = supabaseClient.auth.currentUser?.id.trim();

  final resolvedUserId =
      injectedUserId !=
              null &&
          injectedUserId.isNotEmpty
      ? injectedUserId
      : authenticatedUserId;

  if (resolvedUserId ==
          null ||
      resolvedUserId.isEmpty) {
    throw StateError(
      'Não existe identidade válida para inicializar a rotina.',
    );
  }

  return RoutineController(
    repository: routineRepository,
    userId: resolvedUserId,
  );
}

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

final bodyMapService = BodyMapService(
  repository: bodyMapRepository,
);

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

final studyService = StudyService(
  repository: studyRepository,
);

final studyDayService = StudyDayService(
  repository: studyRepository,
  brainStorage: brainStorage,
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
// ROUTINE - BOARD COMMENTS
// ======================================================
//
// OFFLINE-FIRST:
//
// RoutineScreen
//      ↓
// BoardCommentController
//      ↓
// BoardCommentRepository
//      ↓
// BoardCommentDao / SQLite
//      ↓
// SyncQueue
//      ↓
// SyncService
//      ↓
// BoardCommentRemoteDataSource
//      ↓
// Supabase
//
// ======================================================

final boardCommentRemoteDataSource = BoardCommentRemoteDataSource(
  client: supabaseClient,
);

final boardCommentRepository = BoardCommentRepository(
  client: supabaseClient,
  localDao: boardCommentDao,
  remoteDataSource: boardCommentRemoteDataSource,
  syncQueue: syncQueue,
  syncService: syncService,
);

final boardCommentController = BoardCommentController(
  repository: boardCommentRepository,
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
