import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/settings/models/brain_data_mode.dart';
import 'package:EVRYLUX/study/brain/settings/services/brain_data_mode_service.dart';
import 'package:EVRYLUX/study/brain/settings/storage/brain_data_mode_storage.dart';

void main() {
  group('BrainDataModeService', () {
    late InMemoryBrainDataModeStorage storage;

    late BrainDataModeService service;

    setUp(() {
      storage = InMemoryBrainDataModeStorage();

      service = BrainDataModeService(storage: storage);
    });

    test('primeira inicialização usa local por padrão', () async {
      final mode = await service.initialize();

      expect(mode, BrainDataMode.local);

      expect(service.allowsCloudSync, false);
    });

    test('modo cloud persiste no storage', () async {
      await service.initialize();

      await service.useCloudMode();

      expect(storage.storedMode, BrainDataMode.cloud);

      expect(service.currentMode, BrainDataMode.cloud);
    });

    test('nova instância recupera modo persistido', () async {
      await storage.save(BrainDataMode.cloud);

      final secondService = BrainDataModeService(storage: storage);

      final mode = await secondService.initialize();

      expect(mode, BrainDataMode.cloud);
    });

    test('local nunca permite cloud sync', () async {
      await service.initialize();

      expect(service.canUseCloudSync(isAuthenticated: true), false);

      expect(service.canUseCloudSync(isAuthenticated: false), false);
    });

    test('cloud exige autenticação', () async {
      await service.useCloudMode();

      expect(service.canUseCloudSync(isAuthenticated: false), false);

      expect(service.canUseCloudSync(isAuthenticated: true), true);
    });

    test('reset volta ao modo local', () async {
      await service.useCloudMode();

      final mode = await service.reset();

      expect(mode, BrainDataMode.local);

      expect(storage.storedMode, isNull);
    });
  });
}
