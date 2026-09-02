import '../../models/brain_file.dart';
import '../../models/brain_review_item.dart';

import '../../vault/mappers/brain_file_vault_mapper.dart';
import '../../vault/mappers/brain_review_vault_mapper.dart';
import '../../vault/models/brain_vault_object_type.dart';
import '../../vault/services/brain_vault_service.dart';

import '../models/brain_migration_record.dart';
import '../models/brain_migration_result.dart';
import '../models/brain_migration_status.dart';

import 'brain_migration_validation_service.dart';
import 'brain_object_link_service.dart';

// ============================================================
// BRAIN LEGACY MIGRATION SERVICE
// ============================================================
//
// Responsável SOMENTE por:
//
// BrainFile legado
//     ↓
// Mapper
//     ↓
// Vault
//     ↓
// validação
//     ↓
// registro legacy fingerprint → objectId
//
// E:
//
// BrainReviewItem legado
//     ↓
// Mapper
//     ↓
// Vault
//     ↓
// validação
//     ↓
// registro legacy fingerprint → objectId
//
// IMPORTANTE:
//
// Este serviço NÃO:
//
// - apaga .md;
// - apaga reviews.json;
// - altera BrainStorage;
// - altera ReviewStorage;
// - altera Repository;
// - altera SyncQueue;
// - envia nada ao Supabase.
//
// ============================================================

class BrainLegacyMigrationService {
  BrainLegacyMigrationService({
    required BrainVaultService vaultService,
    required BrainObjectLinkService objectLinkService,
    required BrainMigrationValidationService validationService,
    BrainFileVaultMapper brainFileMapper = const BrainFileVaultMapper(),
    BrainReviewVaultMapper brainReviewMapper = const BrainReviewVaultMapper(),
    DateTime Function()? now,
  }) : _vaultService =
           vaultService,
       _objectLinkService = objectLinkService,
       _validationService = validationService,
       _brainFileMapper = brainFileMapper,
       _brainReviewMapper = brainReviewMapper,
       _now =
           now ??
           DateTime.now;

  final BrainVaultService _vaultService;

  final BrainObjectLinkService _objectLinkService;

  final BrainMigrationValidationService _validationService;

  final BrainFileVaultMapper _brainFileMapper;

  final BrainReviewVaultMapper _brainReviewMapper;

  final DateTime Function() _now;

  // ============================================================
  // MIGRATE BRAIN FILE
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  migrateBrainFile(
    BrainFile file,
  ) async {
    final legacyPath = file.path.trim();

    if (legacyPath.isEmpty) {
      throw ArgumentError(
        'BrainFile legado precisa possuir path para migração.',
      );
    }

    final fingerprint = await _objectLinkService.fingerprintBrainFile(
      legacyPath,
    );

    var record = await _objectLinkService.registerPending(
      legacyFingerprint: fingerprint,
      entityType: BrainMigrationRecord.brainFileEntityType,
    );

    // ==========================================================
    // ALREADY VALIDATED
    // ==========================================================

    if (record.status ==
            BrainMigrationStatus.validated &&
        record.hasObject) {
      final validation = await _validationService.validateBrainFile(
        objectId: record.objectId!,
        source: file,
      );

      if (validation.valid) {
        return record;
      }
    }

    // ==========================================================
    // EXISTING OBJECT
    // ==========================================================

    if (record.hasObject) {
      final validation = await _validationService.validateBrainFile(
        objectId: record.objectId!,
        source: file,
      );

      if (validation.valid) {
        return _objectLinkService.markValidated(
          fingerprint,
        );
      }
    }

    // ==========================================================
    // MIGRATE
    // ==========================================================

    await _objectLinkService.markMigrating(
      fingerprint,
    );

    try {
      final data = _brainFileMapper.toVaultData(
        file,
      );

      final object = await _vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: data,
      );

      record = await _objectLinkService.markMigrated(
        legacyFingerprint: fingerprint,
        objectId: object.header.objectId,
      );

      final validation = await _validationService.validateBrainFile(
        objectId: object.header.objectId,
        source: file,
      );

      if (!validation.valid) {
        return _objectLinkService.markFailed(
          legacyFingerprint: fingerprint,
          error: StateError(
            validation.reason ??
                'Validação do BrainFile falhou.',
          ),
        );
      }

      return _objectLinkService.markValidated(
        fingerprint,
      );
    } catch (
      error
    ) {
      return _objectLinkService.markFailed(
        legacyFingerprint: fingerprint,
        error: error,
      );
    }
  }

  // ============================================================
  // MIGRATE REVIEW
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  migrateBrainReview(
    BrainReviewItem review,
  ) async {
    final reviewId = review.id.trim();

    if (reviewId.isEmpty) {
      throw ArgumentError(
        'BrainReviewItem legado precisa possuir id.',
      );
    }

    final fingerprint = await _objectLinkService.fingerprintBrainReview(
      reviewId,
    );

    var record = await _objectLinkService.registerPending(
      legacyFingerprint: fingerprint,
      entityType: BrainMigrationRecord.brainReviewEntityType,
    );

    // ==========================================================
    // ALREADY VALIDATED
    // ==========================================================

    if (record.status ==
            BrainMigrationStatus.validated &&
        record.hasObject) {
      final validation = await _validationService.validateBrainReview(
        objectId: record.objectId!,
        source: review,
      );

      if (validation.valid) {
        return record;
      }
    }

    // ==========================================================
    // EXISTING OBJECT
    // ==========================================================

    if (record.hasObject) {
      final validation = await _validationService.validateBrainReview(
        objectId: record.objectId!,
        source: review,
      );

      if (validation.valid) {
        return _objectLinkService.markValidated(
          fingerprint,
        );
      }
    }

    // ==========================================================
    // MIGRATE
    // ==========================================================

    await _objectLinkService.markMigrating(
      fingerprint,
    );

    try {
      final data = _brainReviewMapper.toVaultData(
        review,
      );

      final object = await _vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: data,
      );

      record = await _objectLinkService.markMigrated(
        legacyFingerprint: fingerprint,
        objectId: object.header.objectId,
      );

      final validation = await _validationService.validateBrainReview(
        objectId: object.header.objectId,
        source: review,
      );

      if (!validation.valid) {
        return _objectLinkService.markFailed(
          legacyFingerprint: fingerprint,
          error: StateError(
            validation.reason ??
                'Validação do BrainReviewItem falhou.',
          ),
        );
      }

      return _objectLinkService.markValidated(
        fingerprint,
      );
    } catch (
      error
    ) {
      return _objectLinkService.markFailed(
        legacyFingerprint: fingerprint,
        error: error,
      );
    }
  }

  // ============================================================
  // MIGRATE ALL
  // ============================================================

  Future<
    BrainMigrationResult
  >
  migrateAll({
    required List<
      BrainFile
    >
    files,
    required List<
      BrainReviewItem
    >
    reviews,
  }) async {
    final startedAt = _now().toUtc();

    final records =
        <
          BrainMigrationRecord
        >[];

    // ==========================================================
    // FILES
    // ==========================================================

    for (final file in files) {
      try {
        final record = await migrateBrainFile(
          file,
        );

        records.add(
          record,
        );
      } catch (
        error
      ) {
        final path = file.path.trim();

        if (path.isEmpty) {
          continue;
        }

        final fingerprint = await _objectLinkService.fingerprintBrainFile(
          path,
        );

        await _objectLinkService.registerPending(
          legacyFingerprint: fingerprint,
          entityType: BrainMigrationRecord.brainFileEntityType,
        );

        final failed = await _objectLinkService.markFailed(
          legacyFingerprint: fingerprint,
          error: error,
        );

        records.add(
          failed,
        );
      }
    }

    // ==========================================================
    // REVIEWS
    // ==========================================================

    for (final review in reviews) {
      try {
        final record = await migrateBrainReview(
          review,
        );

        records.add(
          record,
        );
      } catch (
        error
      ) {
        final reviewId = review.id.trim();

        if (reviewId.isEmpty) {
          continue;
        }

        final fingerprint = await _objectLinkService.fingerprintBrainReview(
          reviewId,
        );

        await _objectLinkService.registerPending(
          legacyFingerprint: fingerprint,
          entityType: BrainMigrationRecord.brainReviewEntityType,
        );

        final failed = await _objectLinkService.markFailed(
          legacyFingerprint: fingerprint,
          error: error,
        );

        records.add(
          failed,
        );
      }
    }

    final finishedAt = _now().toUtc();

    return BrainMigrationResult.fromRecords(
      startedAt: startedAt,
      finishedAt: finishedAt,
      records: records,
    );
  }
}
