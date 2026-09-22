import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/sync/models/brain_sync_payload.dart';
import 'package:EVRYLUX/study/brain/sync/ports/brain_remote_object_source.dart';
import 'package:EVRYLUX/study/brain/sync/services/brain_cloud_pull_service.dart';
import 'package:EVRYLUX/study/brain/vault/compaction/brain_vault_compaction_ledger.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

class _Remote extends BrainRemoteObjectSource {
  _Remote(this.items);

  final List<BrainSyncPayload> items;

  @override
  Future<List<BrainSyncPayload>> loadVaultObjects({
    required String vaultId,
  }) async {
    return items.where((item) => item.vaultId == vaultId).toList();
  }
}

void main() {
  group('BrainCloudPullService compaction floor', () {
    test('não baixa novamente tombstone já compactado localmente', () async {
      final sourceDir = await Directory.systemTemp.createTemp('floor_source_');
      final targetDir = await Directory.systemTemp.createTemp('floor_target_');
      final keyService = BrainKeyService(storage: InMemoryBrainKeyStorage());

      try {
        final sourceStorage = _storage(sourceDir);
        final sourceVault = BrainVaultService(
          keyService: keyService,
          storage: sourceStorage,
        );
        final manifest = await sourceVault.createVault();
        final active = await sourceVault.createObject(
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'secret'},
        );
        final deleted = await sourceVault.deleteObject(active.header.objectId);
        final remote = BrainSyncPayload.fromVaultObject(object: deleted);

        final targetStorage = _storage(targetDir);
        final targetVault = BrainVaultService(
          keyService: keyService,
          storage: targetStorage,
        );
        await targetVault.createVault(vaultId: manifest.vaultId);

        final floor = BrainVaultCompactionFloor(
          objectId: deleted.header.objectId,
          vaultId: manifest.vaultId,
          objectVersion: deleted.header.objectVersion.value,
          deletedAt: deleted.tombstone!.deletedAt,
          compactedAt: deleted.tombstone!.deletedAt.add(
            const Duration(days: 31),
          ),
        );
        await targetStorage.saveCompactionLedger(
          BrainVaultCompactionLedger.empty(vaultId: manifest.vaultId).record(
            floor,
          ),
        );

        final pull = BrainCloudPullService(
          remote: _Remote(<BrainSyncPayload>[remote]),
          vaultService: targetVault,
          vaultStorage: targetStorage,
          keyService: keyService,
        );

        final result = await pull.pullCurrentVault();

        expect(result.applied, 0);
        expect(result.skippedCompactedFloor, 1);
        expect(
          await targetStorage.containsObject(deleted.header.objectId),
          isFalse,
        );
      } finally {
        await sourceDir.delete(recursive: true);
        await targetDir.delete(recursive: true);
      }
    });

    test('rejeita objeto ativo para objectId com deletion floor', () async {
      final sourceDir = await Directory.systemTemp.createTemp('floor_active_');
      final targetDir = await Directory.systemTemp.createTemp('floor_block_');
      final keyService = BrainKeyService(storage: InMemoryBrainKeyStorage());

      try {
        final sourceStorage = _storage(sourceDir);
        final sourceVault = BrainVaultService(
          keyService: keyService,
          storage: sourceStorage,
        );
        final manifest = await sourceVault.createVault();
        final v1 = await sourceVault.createObject(
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'v1'},
        );
        final v2 = await sourceVault.updateObject(
          objectId: v1.header.objectId,
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'v2'},
        );
        final v3 = await sourceVault.updateObject(
          objectId: v2.header.objectId,
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'v3'},
        );

        final targetStorage = _storage(targetDir);
        final targetVault = BrainVaultService(
          keyService: keyService,
          storage: targetStorage,
        );
        await targetVault.createVault(vaultId: manifest.vaultId);

        final deletedAt = DateTime.utc(2026, 1, 1);
        await targetStorage.saveCompactionLedger(
          BrainVaultCompactionLedger.empty(vaultId: manifest.vaultId).record(
            BrainVaultCompactionFloor(
              objectId: v1.header.objectId,
              vaultId: manifest.vaultId,
              objectVersion: 2,
              deletedAt: deletedAt,
              compactedAt: deletedAt.add(const Duration(days: 31)),
            ),
          ),
        );

        final pull = BrainCloudPullService(
          remote: _Remote(<BrainSyncPayload>[
            BrainSyncPayload.fromVaultObject(object: v3),
          ]),
          vaultService: targetVault,
          vaultStorage: targetStorage,
          keyService: keyService,
        );

        final result = await pull.pullCurrentVault();

        expect(result.applied, 0);
        expect(result.rejectedResurrection, 1);
        expect(await targetStorage.containsObject(v1.header.objectId), isFalse);
      } finally {
        await sourceDir.delete(recursive: true);
        await targetDir.delete(recursive: true);
      }
    });
  });
}

BrainVaultStorage _storage(Directory root) {
  return BrainVaultStorage(
    storageScope: UserStorageScope.fixed(
      userId: 'test-user',
      documentsDirectoryProvider: () async => root,
      supportDirectoryProvider: () async => root,
    ),
  );
}
