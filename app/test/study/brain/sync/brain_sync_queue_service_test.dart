import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/settings/models/brain_data_mode.dart';
import 'package:EVRYLUX/study/brain/settings/services/brain_data_mode_service.dart';
import 'package:EVRYLUX/study/brain/settings/storage/brain_data_mode_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

import 'package:EVRYLUX/study/brain/sync/models/brain_sync_payload.dart';
import 'package:EVRYLUX/study/brain/sync/ports/brain_sync_queue_writer.dart';
import 'package:EVRYLUX/study/brain/sync/services/brain_sync_queue_service.dart';

class _FakeWriter extends BrainSyncQueueWriter {
  final List<BrainSyncPayload> items = <BrainSyncPayload>[];

  @override
  Future<void> write(BrainSyncPayload payload) async {
    items.add(payload);
  }
}

void main() {
  group('BrainSyncQueueService', () {
    late Directory directory;
    late BrainVaultService vaultService;
    late InMemoryBrainDataModeStorage modeStorage;
    late BrainDataModeService modeService;
    late _FakeWriter writer;
    late BrainSyncQueueService syncQueueService;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp(
        'evrylux_brain_sync_queue_',
      );

      final keyStorage = InMemoryBrainKeyStorage();

      vaultService = BrainVaultService(
        keyService: BrainKeyService(storage: keyStorage),
        storage: BrainVaultStorage(
          documentsDirectoryProvider: () async => directory,
        ),
      );

      await vaultService.createVault();

      modeStorage = InMemoryBrainDataModeStorage();

      modeService = BrainDataModeService(storage: modeStorage);

      writer = _FakeWriter();

      syncQueueService = BrainSyncQueueService(
        dataModeService: modeService,
        vaultService: vaultService,
        writer: writer,
      );
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('LOCAL não enfileira nada', () async {
      await modeService.initialize();

      final object = await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'Somente local.'},
      );

      final result = await syncQueueService.enqueueObject(object);

      expect(result, false);

      expect(writer.items, isEmpty);
    });

    test('CLOUD enfileira somente objeto criptografado', () async {
      await modeService.setMode(BrainDataMode.cloud);

      final object = await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'Conteúdo secreto cloud.'},
      );

      final result = await syncQueueService.enqueueObject(object);

      expect(result, true);

      expect(writer.items.length, 1);

      expect(writer.items.single.objectId, object.header.objectId);
    });

    test('backfill enfileira ativos e tombstones', () async {
      await modeService.setMode(BrainDataMode.cloud);

      await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'A'},
      );

      final second = await vaultService.createObject(
        type: BrainVaultObjectType.note,
        data: const <String, dynamic>{'content': 'B'},
      );

      await vaultService.deleteObject(second.header.objectId);

      final count = await syncQueueService.enqueueAllVaultObjects();

      expect(count, 2);

      expect(writer.items.length, 2);

      expect(writer.items.any((item) => item.isDeleted), true);
    });
  });
}
