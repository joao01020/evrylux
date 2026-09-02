import 'dart:io';

import '../../services/brain_storage.dart';
import '../../services/review_storage.dart';

import '../../vault/services/brain_vault_service.dart';

import '../storage/brain_migration_registry.dart';

import 'brain_legacy_migration_service.dart';
import 'brain_migration_coordinator.dart';
import 'brain_migration_validation_service.dart';
import 'brain_object_link_service.dart';

// ============================================================
// BRAIN MIGRATION FACTORY
// ============================================================
//
// Ponto central de composição da infraestrutura de migração.
//
// Monta:
//
// BrainMigrationRegistry
//          ↓
// BrainObjectLinkService
//          ↓
// BrainMigrationValidationService
//          ↓
// BrainLegacyMigrationService
//          ↓
// BrainMigrationCoordinator
//
// Agora também conecta diretamente:
//
// ReviewStorage.loadReviews()
//
// evitando que a camada de integração precise montar manualmente
// um callback para as reviews.
//
// ============================================================
//
// IMPORTANTE:
//
// Esta factory NÃO cria:
//
// - Master Key;
// - BrainKeyService;
// - armazenamento de chave;
// - BrainVaultService.
//
// O BrainVaultService deve chegar pronto e configurado.
//
// ============================================================

class BrainMigrationFactory {
  const BrainMigrationFactory._();

  // ============================================================
  // CREATE
  // ============================================================

  static Future<
    BrainMigrationRuntime
  >
  create({
    required BrainVaultService vaultService,
    BrainStorage brainStorage = const BrainStorage(),
    ReviewStorage reviewStorage = const ReviewStorage(),
    Future<
      Directory
    >
    Function()?
    documentsDirectoryProvider,
    DateTime Function()? now,
  }) async {
    // ==========================================================
    // REGISTRY
    // ==========================================================

    final registry = BrainMigrationRegistry(
      documentsDirectoryProvider: documentsDirectoryProvider,
    );

    await registry.initialize();

    // ==========================================================
    // OBJECT LINK SERVICE
    // ==========================================================

    final objectLinkService = BrainObjectLinkService(
      store: registry,
      now: now,
    );

    await objectLinkService.initialize();

    // ==========================================================
    // VALIDATION SERVICE
    // ==========================================================

    final validationService = BrainMigrationValidationService(
      vaultService: vaultService,
    );

    // ==========================================================
    // LEGACY MIGRATION SERVICE
    // ==========================================================

    final legacyMigrationService = BrainLegacyMigrationService(
      vaultService: vaultService,
      objectLinkService: objectLinkService,
      validationService: validationService,
      now: now,
    );

    // ==========================================================
    // COORDINATOR
    // ==========================================================
    //
    // ReviewStorage passa a ser a fonte real das reviews legadas.
    //
    // ==========================================================

    final coordinator = BrainMigrationCoordinator(
      brainStorage: brainStorage,
      migrationService: legacyMigrationService,
      reviewLoader: reviewStorage.loadReviews,
      now: now,
    );

    // ==========================================================
    // RUNTIME
    // ==========================================================

    return BrainMigrationRuntime(
      registry: registry,
      objectLinkService: objectLinkService,
      validationService: validationService,
      legacyMigrationService: legacyMigrationService,
      coordinator: coordinator,
      brainStorage: brainStorage,
      reviewStorage: reviewStorage,
    );
  }
}

// ============================================================
// BRAIN MIGRATION RUNTIME
// ============================================================
//
// Representa o grafo completo da migração já montado.
//
// ============================================================

class BrainMigrationRuntime {
  const BrainMigrationRuntime({
    required this.registry,
    required this.objectLinkService,
    required this.validationService,
    required this.legacyMigrationService,
    required this.coordinator,
    required this.brainStorage,
    required this.reviewStorage,
  });

  // ============================================================
  // MIGRATION SERVICES
  // ============================================================

  final BrainMigrationRegistry registry;

  final BrainObjectLinkService objectLinkService;

  final BrainMigrationValidationService validationService;

  final BrainLegacyMigrationService legacyMigrationService;

  final BrainMigrationCoordinator coordinator;

  // ============================================================
  // LEGACY SOURCES
  // ============================================================

  final BrainStorage brainStorage;

  final ReviewStorage reviewStorage;

  // ============================================================
  // READY
  // ============================================================

  bool get isReady {
    return true;
  }
}
