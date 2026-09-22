import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/sync/models/brain_remote_deletion_floor.dart';
import 'package:EVRYLUX/study/brain/sync/models/brain_sync_payload.dart';
import 'package:EVRYLUX/study/brain/sync/ports/brain_remote_object_source.dart';
import 'package:EVRYLUX/study/brain/sync/services/brain_cloud_pull_service.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

class _RemoteWithFloor extends BrainRemoteObjectSource {
  _RemoteWithFloor({required this.floors});

  final List<BrainRemoteDeletionFloor> floors;

  @override
  Future<List<BrainSyncPayload>> loadVaultObjects({required String vaultId}) async {
    return const <BrainSyncPayload>[];
  }

  @override
  Future<List<BrainRemoteDeletionFloor>> loadDeletionFloors({
    required String vaultId,
  }) async {
    return floors.where((item) => item.vaultId == vaultId).toList();
  }
}

void main() {
  test('remote deletion floor remove estado local antigo e persiste floor', () async {
    final root = await Directory.systemTemp.createTemp('phase3_floor_');
    final keyService = BrainKeyService(storage: InMemoryBrainKeyStorage());

    try {
      final storage = BrainVaultStorage(
        storageScope: UserStorageScope.fixed(
          userId: 'test-user',
          documentsDirectoryProvider: () async => root,
          supportDirectoryProvider: () async => root,
        ),
      );
      final vault = BrainVaultService(keyService: keyService, storage: storage);
      final manifest = await vault.createVault();
      final local = await vault.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'stale local'},
      );

      final deletedAt = DateTime.utc(2026, 1, 1);
      final pull = BrainCloudPullService(
        remote: _RemoteWithFloor(
          floors: <BrainRemoteDeletionFloor>[
            BrainRemoteDeletionFloor(
              vaultId: manifest.vaultId,
              objectId: local.header.objectId,
              objectVersion: local.header.objectVersion.value + 1,
              deletedAt: deletedAt,
              compactedAt: deletedAt.add(const Duration(days: 180)),
            ),
          ],
        ),
        vaultService: vault,
        vaultStorage: storage,
        keyService: keyService,
      );

      final result = await pull.pullCurrentVault();

      expect(result.remoteDeletionFloorCount, 1);
      expect(result.appliedRemoteFloors, 1);
      expect(result.purgedByRemoteFloor, 1);
      expect(await storage.containsObject(local.header.objectId), isFalse);

      final ledger = await storage.loadCompactionLedger(vaultId: manifest.vaultId);
      expect(ledger.floorFor(local.header.objectId), isNotNull);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
