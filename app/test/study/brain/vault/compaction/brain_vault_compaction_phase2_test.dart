import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_policy.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_service.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_tombstone.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

void main() {
  group('BrainVaultCompactionService Fase 2', () {
    late Directory tempDirectory;
    late BrainVaultStorage storage;
    late BrainVaultService vaultService;
    late DateTime now;

    setUp(() async {
      now = DateTime.utc(2026, 9, 22, 18);
      tempDirectory = await Directory.systemTemp.createTemp(
        'evrylux_compaction_phase2_',
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

    test('compact remove somente tombstone elegível e grava floor', () async {
      final active = await vaultService.createObject(
        type: BrainVaultObjectType.review,
        data: const <String, dynamic>{'question': 'keep'},
      );
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = _safeService(storage: storage, now: now);
      final result = await service.compact();

      expect(result.purged, 1);
      expect(result.retained, 0);
      expect(await storage.containsObject(deleted.header.objectId), isFalse);
      expect(await storage.containsObject(active.header.objectId), isTrue);

      final manifest = await storage.loadManifest();
      expect(manifest, isNotNull);
      final ledger = await storage.loadCompactionLedger(
        vaultId: manifest!.vaultId,
      );
      final floor = ledger.floorFor(deleted.header.objectId);
      expect(floor, isNotNull);
      expect(floor!.objectVersion, deleted.header.objectVersion.value);
      expect(floor.deletedAt, deleted.tombstone!.deletedAt.toUtc());
    });

    test('compact é idempotente quando executado duas vezes', () async {
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = _safeService(storage: storage, now: now);
      final first = await service.compact();
      final second = await service.compact();

      expect(first.purged, 1);
      expect(second.purged, 0);
      expect(second.tombstones, 0);
      expect(await storage.containsObject(deleted.header.objectId), isFalse);
    });

    test('tombstone recente nunca é removido por compact', () async {
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 5)),
      );

      final result = await _safeService(storage: storage, now: now).compact();

      expect(result.purged, 0);
      expect(await storage.containsObject(deleted.header.objectId), isTrue);
    });

    test('sync pendente bloqueia purge físico', () async {
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        policy: const BrainVaultCompactionPolicy(
          requireAuthorizedDeviceCoverage: false,
        ),
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: true,
          remoteDeletionConfirmed: true,
          authorizedDevicesCovered: false,
        ),
      );

      final result = await service.compact();

      expect(result.purged, 0);
      expect(await storage.containsObject(deleted.header.objectId), isTrue);
    });

    test('sem confirmação remota falha fechado', () async {
      final deleted = await _createTombstone(
        vaultService: vaultService,
        storage: storage,
        deletedAt: now.subtract(const Duration(days: 45)),
      );

      final service = BrainVaultCompactionService(
        storage: storage,
        policy: const BrainVaultCompactionPolicy(
          requireAuthorizedDeviceCoverage: false,
        ),
        clock: () => now,
        safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
          hasPendingSync: false,
          remoteDeletionConfirmed: false,
          authorizedDevicesCovered: false,
        ),
      );

      final result = await service.compact();

      expect(result.purged, 0);
      expect(await storage.containsObject(deleted.header.objectId), isTrue);
    });
  });
}

BrainVaultCompactionService _safeService({
  required BrainVaultStorage storage,
  required DateTime now,
}) {
  return BrainVaultCompactionService(
    storage: storage,
    policy: const BrainVaultCompactionPolicy(
      requireAuthorizedDeviceCoverage: false,
    ),
    clock: () => now,
    safetyProbe: (_) async => const BrainVaultCompactionSafetySnapshot(
      hasPendingSync: false,
      remoteDeletionConfirmed: true,
      authorizedDevicesCovered: false,
    ),
  );
}

Future<BrainVaultObject> _createTombstone({
  required BrainVaultService vaultService,
  required BrainVaultStorage storage,
  required DateTime deletedAt,
}) async {
  final active = await vaultService.createObject(
    type: BrainVaultObjectType.note,
    data: const <String, dynamic>{'content': 'encrypted'},
  );

  final header = active.header.copyWith(
    objectVersion: active.header.objectVersion.next(),
    createdAt: deletedAt.toUtc().subtract(const Duration(minutes: 1)),
    updatedAt: deletedAt.toUtc(),
  );

  final tombstone = BrainVaultTombstone(
    objectId: header.objectId,
    vaultId: header.vaultId,
    objectVersion: header.objectVersion,
    deletedAt: deletedAt.toUtc(),
  );

  final deleted = BrainVaultObject.deleted(
    header: header,
    tombstone: tombstone,
  );

  await storage.saveObject(deleted);
  return deleted;
}
