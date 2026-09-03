import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/settings/controllers/brain_data_mode_controller.dart';
import 'package:EVRYLUX/study/brain/settings/models/brain_data_mode.dart';
import 'package:EVRYLUX/study/brain/settings/services/brain_data_mode_service.dart';
import 'package:EVRYLUX/study/brain/settings/storage/brain_data_mode_storage.dart';

void main() {
  group('BrainDataModeController', () {
    late InMemoryBrainDataModeStorage storage;

    late BrainDataModeService service;

    late BrainDataModeController controller;

    setUp(() {
      storage = InMemoryBrainDataModeStorage();

      service = BrainDataModeService(storage: storage);

      controller = BrainDataModeController(service: service);
    });

    tearDown(() {
      controller.dispose();
    });

    test('initialize carrega local', () async {
      await controller.initialize();

      expect(controller.mode, BrainDataMode.local);

      expect(controller.isLocalMode, true);

      expect(controller.isCloudMode, false);
    });

    test('altera para cloud', () async {
      await controller.initialize();

      final changed = await controller.useCloudMode();

      expect(changed, true);

      expect(controller.mode, BrainDataMode.cloud);

      expect(storage.storedMode, BrainDataMode.cloud);
    });

    test('cloud gate respeita autenticação', () async {
      await controller.initialize();

      await controller.useCloudMode();

      expect(controller.canUseCloudSync(isAuthenticated: false), false);

      expect(controller.canUseCloudSync(isAuthenticated: true), true);
    });

    test('modo local bloqueia cloud mesmo autenticado', () async {
      await controller.initialize();

      expect(controller.canUseCloudSync(isAuthenticated: true), false);
    });
  });
}
