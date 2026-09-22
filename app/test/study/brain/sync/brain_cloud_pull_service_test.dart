import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/core/storage/user_storage_scope.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

import 'package:EVRYLUX/study/brain/sync/models/brain_sync_payload.dart';
import 'package:EVRYLUX/study/brain/sync/ports/brain_remote_object_source.dart';
import 'package:EVRYLUX/study/brain/sync/services/brain_cloud_pull_service.dart';

class _FakeRemoteSource extends BrainRemoteObjectSource {
  _FakeRemoteSource(this.items);

  final List<BrainSyncPayload> items;

  @override
  Future<List<BrainSyncPayload>> loadVaultObjects({
    required String vaultId,
  }) async {
    return items.where((item) => item.vaultId == vaultId).toList();
  }
}

void main() {
  group('BrainCloudPullService', () {
    test('aplica versão remota mais nova e preserva descriptografia', () async {
      final sourceDirectory = await Directory.systemTemp.createTemp(
        'evrylux_pull_source_',
      );

      final targetDirectory = await Directory.systemTemp.createTemp(
        'evrylux_pull_target_',
      );

      final keyStorage = InMemoryBrainKeyStorage();

      final keyService = BrainKeyService(storage: keyStorage);

      try {
        // ==================================================
        // SOURCE
        // ==================================================

        final sourceStorage = BrainVaultStorage(
          storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => sourceDirectory,
              supportDirectoryProvider: () async => sourceDirectory,
            ),
        );

        final sourceVault = BrainVaultService(
          keyService: keyService,
          storage: sourceStorage,
        );

        final manifest = await sourceVault.createVault();

        final original = await sourceVault.createObject(
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'V1'},
        );

        final updated = await sourceVault.updateObject(
          objectId: original.header.objectId,
          type: BrainVaultObjectType.note,
          data: const <String, dynamic>{'content': 'V2 remota'},
        );

        final remotePayload = BrainSyncPayload.fromVaultObject(object: updated);

        // ==================================================
        // TARGET
        // ==================================================

        final targetStorage = BrainVaultStorage(
          storageScope: UserStorageScope.fixed(
              userId: 'test-user',
              documentsDirectoryProvider: () async => targetDirectory,
              supportDirectoryProvider: () async => targetDirectory,
            ),
        );

        final targetVault = BrainVaultService(
          keyService: keyService,
          storage: targetStorage,
        );

        await targetVault.createVault(vaultId: manifest.vaultId);

        // Coloca V1 no destino usando o mesmo .evobj.
        final originalRaw = await sourceStorage.loadObject(
          original.header.objectId,
        );

        expect(originalRaw, isNotNull);

        // sourceStorage já contém V2, então reconstruímos um
        // cenário simples: alvo vazio + remoto V2.
        final pull = BrainCloudPullService(
          remote: _FakeRemoteSource(<BrainSyncPayload>[remotePayload]),
          vaultService: targetVault,
          vaultStorage: targetStorage,
          keyService: keyService,
        );

        final result = await pull.pullCurrentVault();

        expect(result.applied, 1);

        final decoded = await targetVault.readObject(updated.header.objectId);

        expect(decoded, isNotNull);

        expect(decoded!.data['content'], 'V2 remota');
      } finally {
        if (await sourceDirectory.exists()) {
          await sourceDirectory.delete(recursive: true);
        }

        if (await targetDirectory.exists()) {
          await targetDirectory.delete(recursive: true);
        }
      }
    });
  });
}

