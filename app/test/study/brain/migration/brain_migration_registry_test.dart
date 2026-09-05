import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_record.dart';
import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/storage/brain_migration_registry.dart';

void
main() {
  group(
    'BrainMigrationRegistry',
    () {
      late Directory tempDirectory;

      late BrainMigrationRegistry registry;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_migration_registry_test_',
          );

          registry = BrainMigrationRegistry(
            storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => tempDirectory,
              supportDirectoryProvider: () async => tempDirectory,
            ),
          );
        },
      );

      // ============================================================
      // TEARDOWN
      // ============================================================

      tearDown(
        () async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      // ============================================================
      // INITIALIZE
      // ============================================================

      test(
        'initialize cria diretório de migration',
        () async {
          await registry.initialize();

          final directory = await registry.getRootDirectory();

          expect(
            await directory.exists(),
            true,
          );

          expect(
            directory.path.endsWith(
              'evrylux/users/test-user/brain/migration',
            ),
            true,
          );
        },
      );

      test(
        'registry novo ainda não possui arquivo',
        () async {
          await registry.initialize();

          expect(
            await registry.exists(),
            false,
          );
        },
      );

      // ============================================================
      // SAVE / LOAD
      // ============================================================

      test(
        'saveAll e loadAll preservam registros',
        () async {
          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final record = BrainMigrationRecord.pending(
            legacyFingerprint: 'legacy_abcdefghijklmnop123456789',
            entityType: BrainMigrationRecord.brainFileEntityType,
            now: now,
          );

          await registry.saveAll(
            [
              record,
            ],
          );

          expect(
            await registry.exists(),
            true,
          );

          final restored = await registry.loadAll();

          expect(
            restored.length,
            1,
          );

          expect(
            restored.first.legacyFingerprint,
            record.legacyFingerprint,
          );

          expect(
            restored.first.entityType,
            record.entityType,
          );

          expect(
            restored.first.status,
            BrainMigrationStatus.pending,
          );
        },
      );

      test(
        'preserva registro migrated',
        () async {
          final createdAt = DateTime.utc(
            2026,
            9,
            2,
            10,
          );

          final migratedAt = DateTime.utc(
            2026,
            9,
            2,
            11,
          );

          final record = BrainMigrationRecord(
            legacyFingerprint: 'legacy_migrated_abcdefghijklmnop',
            entityType: BrainMigrationRecord.brainFileEntityType,
            objectId: 'obj_migrated_001',
            status: BrainMigrationStatus.migrated,
            createdAt: createdAt,
            updatedAt: migratedAt,
            migratedAt: migratedAt,
            validatedAt: null,
            errorMessage: null,
            attempts: 1,
          );

          await registry.saveAll(
            [
              record,
            ],
          );

          final restored = await registry.loadAll();

          expect(
            restored.first.objectId,
            'obj_migrated_001',
          );

          expect(
            restored.first.status,
            BrainMigrationStatus.migrated,
          );

          expect(
            restored.first.attempts,
            1,
          );
        },
      );

      // ============================================================
      // NO PLAINTEXT
      // ============================================================

      test(
        'registry não precisa conter path legado',
        () async {
          const secretPath = '/home/joao/documentos/segredo/arquivo-super-secreto.md';

          final record = BrainMigrationRecord.pending(
            legacyFingerprint: 'legacy_hash_sem_path_abcdefghijklmnop',
            entityType: BrainMigrationRecord.brainFileEntityType,
            now: DateTime.utc(
              2026,
              9,
              2,
            ),
          );

          await registry.saveAll(
            [
              record,
            ],
          );

          final file = await registry.getRegistryFile();

          final raw = await file.readAsString();

          expect(
            raw.contains(
              secretPath,
            ),
            false,
          );

          expect(
            raw.contains(
              'arquivo-super-secreto.md',
            ),
            false,
          );
        },
      );

      // ============================================================
      // COUNT
      // ============================================================

      test(
        'count retorna quantidade de registros',
        () async {
          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          await registry.saveAll(
            [
              BrainMigrationRecord.pending(
                legacyFingerprint: 'legacy_count_aaaaaaaaaaaaaaaa',
                entityType: BrainMigrationRecord.brainFileEntityType,
                now: now,
              ),
              BrainMigrationRecord.pending(
                legacyFingerprint: 'legacy_count_bbbbbbbbbbbbbbbb',
                entityType: BrainMigrationRecord.brainReviewEntityType,
                now: now,
              ),
            ],
          );

          expect(
            await registry.count(),
            2,
          );
        },
      );

      // ============================================================
      // FIND
      // ============================================================

      test(
        'findByFingerprint encontra registro',
        () async {
          const fingerprint = 'legacy_find_abcdefghijklmnop';

          await registry.saveAll(
            [
              BrainMigrationRecord.pending(
                legacyFingerprint: fingerprint,
                entityType: BrainMigrationRecord.brainFileEntityType,
                now: DateTime.utc(
                  2026,
                  9,
                  2,
                ),
              ),
            ],
          );

          final found = await registry.findByFingerprint(
            fingerprint,
          );

          expect(
            found,
            isNotNull,
          );

          expect(
            found!.legacyFingerprint,
            fingerprint,
          );
        },
      );

      // ============================================================
      // DUPLICATE
      // ============================================================

      test(
        'rejeita fingerprint duplicado',
        () async {
          const fingerprint = 'legacy_duplicate_abcdefghijklmnop';

          final first = BrainMigrationRecord.pending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
            now: DateTime.utc(
              2026,
              9,
              2,
            ),
          );

          final second = BrainMigrationRecord.pending(
            legacyFingerprint: fingerprint,
            entityType: BrainMigrationRecord.brainFileEntityType,
            now: DateTime.utc(
              2026,
              9,
              2,
            ),
          );

          expect(
            () async {
              await registry.saveAll(
                [
                  first,
                  second,
                ],
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      // ============================================================
      // CLEAR
      // ============================================================

      test(
        'clear remove registry',
        () async {
          await registry.saveAll(
            [
              BrainMigrationRecord.pending(
                legacyFingerprint: 'legacy_clear_abcdefghijklmnop',
                entityType: BrainMigrationRecord.brainFileEntityType,
                now: DateTime.utc(
                  2026,
                  9,
                  2,
                ),
              ),
            ],
          );

          expect(
            await registry.exists(),
            true,
          );

          await registry.clear();

          expect(
            await registry.exists(),
            false,
          );

          expect(
            await registry.loadAll(),
            isEmpty,
          );
        },
      );

      // ============================================================
      // TEMP FILE
      // ============================================================

      test(
        'gravação normal não deixa arquivo .tmp',
        () async {
          await registry.saveAll(
            [
              BrainMigrationRecord.pending(
                legacyFingerprint: 'legacy_temp_abcdefghijklmnop',
                entityType: BrainMigrationRecord.brainFileEntityType,
                now: DateTime.utc(
                  2026,
                  9,
                  2,
                ),
              ),
            ],
          );

          final directory = await registry.getRootDirectory();

          final files = await directory
              .list()
              .where(
                (
                  entity,
                ) =>
                    entity
                        is File &&
                    entity.path.endsWith(
                      '.tmp',
                    ),
              )
              .toList();

          expect(
            files,
            isEmpty,
          );
        },
      );
    },
  );
}
