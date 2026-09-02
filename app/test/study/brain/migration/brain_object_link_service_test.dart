import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_record.dart';
import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_object_link_service.dart';

void
main() {
  group(
    'BrainObjectLinkService',
    () {
      late InMemoryBrainMigrationLinkStore store;

      late BrainObjectLinkService service;

      late DateTime currentTime;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () {
          currentTime = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          store = InMemoryBrainMigrationLinkStore();

          service = BrainObjectLinkService(
            store: store,
            now: () => currentTime,
          );
        },
      );

      // ============================================================
      // FINGERPRINT
      // ============================================================

      test(
        'gera fingerprint determinístico',
        () async {
          final first = await service.fingerprint(
            namespace: 'brain_file',
            legacyIdentity: '/home/joao/documentos/teste.md',
          );

          final second = await service.fingerprint(
            namespace: 'brain_file',
            legacyIdentity: '/home/joao/documentos/teste.md',
          );

          expect(
            first,
            second,
          );

          expect(
            first.startsWith(
              'legacy_',
            ),
            true,
          );

          expect(
            first.length,
            greaterThan(
              16,
            ),
          );
        },
      );

      test(
        'identidades diferentes geram fingerprints diferentes',
        () async {
          final first = await service.fingerprintBrainFile(
            '/tmp/a.md',
          );

          final second = await service.fingerprintBrainFile(
            '/tmp/b.md',
          );

          expect(
            first,
            isNot(
              second,
            ),
          );
        },
      );

      test(
        'namespace participa do fingerprint',
        () async {
          final fileFingerprint = await service.fingerprint(
            namespace: 'brain_file',
            legacyIdentity: 'mesma-identidade',
          );

          final reviewFingerprint = await service.fingerprint(
            namespace: 'brain_review',
            legacyIdentity: 'mesma-identidade',
          );

          expect(
            fileFingerprint,
            isNot(
              reviewFingerprint,
            ),
          );
        },
      );

      test(
        'fingerprint não contém path legado',
        () async {
          const path = '/home/joao/documentos/conhecimento/secreto.md';

          final fingerprint = await service.fingerprintBrainFile(
            path,
          );

          expect(
            fingerprint.contains(
              path,
            ),
            false,
          );

          expect(
            fingerprint.contains(
              'secreto.md',
            ),
            false,
          );
        },
      );

      // ============================================================
      // REGISTER
      // ============================================================

      test(
        'registerPending cria registro pending',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/teste.md',
          );

          final record = await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          expect(
            record.legacyFingerprint,
            fingerprint,
          );

          expect(
            record.entityType,
            BrainMigrationRecord.brainFileEntityType,
          );

          expect(
            record.status,
            BrainMigrationStatus.pending,
          );

          expect(
            record.objectId,
            isNull,
          );

          expect(
            record.attempts,
            0,
          );
        },
      );

      test(
        'registerPending é idempotente',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/idempotente.md',
          );

          final first = await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          final second = await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          expect(
            second.legacyFingerprint,
            first.legacyFingerprint,
          );

          final records = await service.listRecords();

          expect(
            records.length,
            1,
          );
        },
      );

      // ============================================================
      // MIGRATING
      // ============================================================

      test(
        'markMigrating incrementa attempts',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/migrating.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          final migrated = await service.markMigrating(
            fingerprint,
          );

          expect(
            migrated.status,
            BrainMigrationStatus.migrating,
          );

          expect(
            migrated.attempts,
            1,
          );
        },
      );

      // ============================================================
      // MIGRATED
      // ============================================================

      test(
        'markMigrated vincula objectId',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/migrated.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          await service.markMigrating(
            fingerprint,
          );

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            13,
          );

          final record = await service.markMigrated(
            legacyFingerprint: fingerprint,
            objectId: 'obj_test_123456789',
          );

          expect(
            record.status,
            BrainMigrationStatus.migrated,
          );

          expect(
            record.objectId,
            'obj_test_123456789',
          );

          expect(
            record.migratedAt,
            currentTime,
          );
        },
      );

      // ============================================================
      // VALIDATED
      // ============================================================

      test(
        'markValidated finaliza registro',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/validated.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          await service.markMigrating(
            fingerprint,
          );

          await service.markMigrated(
            legacyFingerprint: fingerprint,
            objectId: 'obj_validated_123',
          );

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            14,
          );

          final record = await service.markValidated(
            fingerprint,
          );

          expect(
            record.status,
            BrainMigrationStatus.validated,
          );

          expect(
            record.validatedAt,
            currentTime,
          );

          expect(
            record.objectId,
            'obj_validated_123',
          );
        },
      );

      test(
        'não permite validar sem objectId',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/no-object.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          expect(
            () async {
              await service.markValidated(
                fingerprint,
              );
            },
            throwsStateError,
          );
        },
      );

      // ============================================================
      // FAILED
      // ============================================================

      test(
        'markFailed registra erro',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/fail.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          final record = await service.markFailed(
            legacyFingerprint: fingerprint,
            error: StateError(
              'Falha de teste',
            ),
          );

          expect(
            record.status,
            BrainMigrationStatus.failed,
          );

          expect(
            record.errorMessage,
            contains(
              'Falha de teste',
            ),
          );
        },
      );

      // ============================================================
      // GET
      // ============================================================

      test(
        'getObjectId recupera vínculo salvo',
        () async {
          final fingerprint = await service.fingerprintBrainReview(
            'review-001',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainReviewEntityType,
          );

          await service.markMigrating(
            fingerprint,
          );

          await service.markMigrated(
            legacyFingerprint: fingerprint,
            objectId: 'obj_review_001',
          );

          final objectId = await service.getObjectId(
            fingerprint,
          );

          expect(
            objectId,
            'obj_review_001',
          );
        },
      );

      // ============================================================
      // REMOVE
      // ============================================================

      test(
        'remove elimina registro',
        () async {
          final fingerprint = await service.fingerprintBrainFile(
            '/tmp/remove.md',
          );

          await service.registerPending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
          );

          expect(
            await service.contains(
              fingerprint,
            ),
            true,
          );

          await service.remove(
            fingerprint,
          );

          expect(
            await service.contains(
              fingerprint,
            ),
            false,
          );
        },
      );
    },
  );
}
