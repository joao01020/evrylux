import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_policy.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_result.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_service.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_tombstone.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void main() {
  group('BrainVaultCompactionService Fase 1', () {
    late Directory tempDirectory;
    late BrainVaultStorage storage;
    late BrainVaultService vaultService;
    late DateTime now;

    setUp(() async {
      now = DateTime.utc(2026, 9, 22, 18);
      tempDirectory = await Directory.systemTemp.createTemp(
        'evrylux_compaction_test_',
      );

      storage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
          userId: 'test-user',
          documentsDirectoryProvider: () async => tempDirectory,
          supportDirectoryProvider: () async => tempDirectory,
        ),
      );

      vaultService = BrainVaultService(
        keyService: BrainKeyService(storage: InMemoryBrainKeyStorage()),
        storage: storage,
      );

      await vaultService.createVault();
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('tombstone recente não é elegível', () async {
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 5)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: false,
          remoteDeletionConfirmed: true,
          authorizedDevicesCovered: true,
        ),
      );

      final result = await service.dryRun();
      final entry = result.entries.single;

      expect(result.tombstones, 1);
      expect(result.eligible, 0);
      expect(result.purged, 0);
      expect(entry.objectId, deleted.header.objectId);
      expect(
        entry.blockReasons,
        contains(BrainVaultCompactionBlockReason.retentionNotElapsed),
      );
    });

    test('tombstone antigo com sync pendente não é elegível', () async {
      await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: true,
          remoteDeletionConfirmed: true,
          authorizedDevicesCovered: true,
        ),
      );

      final result = await service.dryRun();

      expect(result.eligible, 0);
      expect(
        result.entries.single.blockReasons,
        contains(BrainVaultCompactionBlockReason.pendingSync),
      );
    });

    test('sem prova remota e de devices o default falha fechado', () async {
      await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
      );

      final result = await service.dryRun();
      final reasons = result.entries.single.blockReasons;

      expect(result.eligible, 0);
      expect(
        reasons,
        contains(
          BrainVaultCompactionBlockReason.remoteDeletionNotConfirmed,
        ),
      );
      expect(
        reasons,
        contains(
          BrainVaultCompactionBlockReason.authorizedDeviceCoverageUnknown,
        ),
      );
    });

    test('tombstone antigo e comprovadamente seguro aparece como elegível', () async {
      await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: false,
          remoteDeletionConfirmed: true,
          authorizedDevicesCovered: true,
        ),
      );

      final result = await service.dryRun();

      expect(result.eligible, 1);
      expect(result.retained, 0);
      expect(result.purged, 0);
      expect(result.entries.single.eligible, true);
    });

    test('dryRun é estritamente não destrutivo e idempotente', () async {
      final active = await vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: const {'question': 'encrypted in the real object'},
      );
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final activeFile = storage.objectFile(active.header.objectId);
      final deletedFile = storage.objectFile(deleted.header.objectId);
      final activeBefore = await activeFile.readAsBytes();
      final deletedBefore = await deletedFile.readAsBytes();
      final manifestBefore = await storage.manifestFile.readAsBytes();

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: false,
          remoteDeletionConfirmed: true,
          authorizedDevicesCovered: true,
        ),
      );

      final first = await service.dryRun();
      final second = await service.dryRun();

      expect(first.totalObjects, 2);
      expect(first.activeObjects, 1);
      expect(first.tombstones, 1);
      expect(first.eligible, 1);
      expect(first.purged, 0);
      expect(second.toString(), first.toString());
      expect(await activeFile.readAsBytes(), activeBefore);
      expect(await deletedFile.readAsBytes(), deletedBefore);
      expect(await storage.manifestFile.readAsBytes(), manifestBefore);
    });

    test('objetos ativos e outros tipos nunca entram no scanner de tombstones', () async {
      await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const {'content': 'note'},
      );
      await vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: const {'question': 'review'},
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        clock: () => now,
      );

      final result = await service.dryRun();

      expect(result.totalObjects, 2);
      expect(result.activeObjects, 2);
      expect(result.tombstones, 0);
      expect(result.entries, isEmpty);
      expect(result.purged, 0);
    });

    test('policy rejeita retenção negativa', () {
      expect(
        () => BrainVaultCompactionService(
          storage: storage,
          policy: const BrainVaultCompactionPolicy(
            tombstoneRetention: Duration(seconds: -1),
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

Future<BrainVaultObject> _createTombstone({
  required BrainVaultService vaultService,
  required BrainVaultStorage storage,
  required DateTime deletedAt,
}) async {
  final active = await vaultService.createObject(
    type: BrainVaultObjectType.note,
    data: const {'content': 'encrypted by BrainVaultService'},
  );

  final header = active.header.copyWith(
    objectVersion: active.header.objectVersion.next(),
    updatedAt: deletedAt.toUtc(),
  );

  // Test fixtures may use a historical timestamp earlier than createObject().
  // Keep the authenticated technical header internally consistent.
  final normalizedHeader = header.copyWith(
    createdAt: deletedAt.toUtc().subtract(const Duration(minutes: 1)),
  );

  final tombstone = BrainVaultTombstone(
    objectId: normalizedHeader.objectId,
    vaultId: normalizedHeader.vaultId,
    objectVersion: normalizedHeader.objectVersion,
    deletedAt: deletedAt.toUtc(),
  );

  final deleted = BrainVaultObject.deleted(
    header: normalizedHeader,
    tombstone: tombstone,
  );

  await storage.saveObject(deleted);
  return deleted;
}
