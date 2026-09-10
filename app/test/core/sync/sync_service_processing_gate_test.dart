import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncService processing gate - Brain E2EE', () {
    late String syncServiceSource;
    late String appDependenciesSource;

    setUpAll(() async {
      final syncServiceFile = File('lib/core/sync/sync_service.dart');

      final appDependenciesFile = File(
        'lib/app/dependencies/app_dependencies.dart',
      );

      expect(
        await syncServiceFile.exists(),
        isTrue,
        reason: 'lib/core/sync/sync_service.dart não foi encontrado.',
      );

      expect(
        await appDependenciesFile.exists(),
        isTrue,
        reason:
            'lib/app/dependencies/app_dependencies.dart não foi encontrado.',
      );

      syncServiceSource = await syncServiceFile.readAsString();

      appDependenciesSource = await appDependenciesFile.readAsString();
    });

    test('SyncService possui processingGate', () {
      expect(syncServiceSource, contains('typedef SyncItemProcessingGate'));

      expect(
        syncServiceSource,
        contains('SyncItemProcessingGate? processingGate'),
      );

      expect(syncServiceSource, contains('_processingGates'));
    });

    test('syncNow processa somente itens retornados por _loadProcessableItems', () {
      final syncNowStart = syncServiceSource.indexOf('syncNow({');

      expect(syncNowStart, greaterThanOrEqualTo(0));

      final helperCallIndex = syncServiceSource.indexOf(
        'await _loadProcessableItems()',
        syncNowStart,
      );

      final handlerLookupIndex = syncServiceSource.indexOf(
        'final handler = _handlers[item.entityType]',
        syncNowStart,
      );

      expect(
        helperCallIndex,
        greaterThan(syncNowStart),
        reason:
            'syncNow precisa obter os itens através de _loadProcessableItems().',
      );

      expect(
        handlerLookupIndex,
        greaterThan(helperCallIndex),
        reason:
            'O handler só pode ser consultado depois que o gate filtrou os itens.',
      );
    });

    test(
      '_loadProcessableItems adia item bloqueado antes de adicioná-lo ao lote',
      () {
        final methodStart = syncServiceSource.indexOf(
          '_loadProcessableItems() async',
        );

        final methodEnd = syncServiceSource.indexOf(
          '// REFRESH PENDING COUNT',
          methodStart,
        );

        expect(methodStart, greaterThanOrEqualTo(0));

        expect(methodEnd, greaterThan(methodStart));

        final gateMethod = syncServiceSource.substring(methodStart, methodEnd);

        final blockedLogIndex = gateMethod.indexOf('ADIADO PELO GATE:');

        final continueIndex = gateMethod.indexOf('continue;', blockedLogIndex);

        final resultAddIndex = gateMethod.indexOf('result.add(');

        expect(
          blockedLogIndex,
          greaterThanOrEqualTo(0),
          reason: 'Log de adiamento do processingGate não encontrado.',
        );

        expect(
          continueIndex,
          greaterThan(blockedLogIndex),
          reason: 'O caminho bloqueado precisa executar continue.',
        );

        expect(
          resultAddIndex,
          greaterThan(continueIndex),
          reason:
              'O item bloqueado precisa ser descartado do lote antes de result.add().',
        );
      },
    );

    test('gate não marca item bloqueado como sucesso ou falha', () {
      final methodStart = syncServiceSource.indexOf(
        '_loadProcessableItems() async',
      );

      final methodEnd = syncServiceSource.indexOf(
        '// REFRESH PENDING COUNT',
        methodStart,
      );

      final gateMethod = syncServiceSource.substring(methodStart, methodEnd);

      expect(
        gateMethod,
        isNot(contains('markSuccess')),
        reason: 'processingGate não pode remover item bloqueado.',
      );

      expect(
        gateMethod,
        isNot(contains('markFailed')),
        reason: 'processingGate não pode consumir retry do item bloqueado.',
      );
    });

    test('Brain E2EE registra gate baseado no BrainDataModeService', () {
      final e2eeHandlerIndex = appDependenciesSource.indexOf(
        'entityType: BrainSyncQueueService.entityType',
      );

      expect(
        e2eeHandlerIndex,
        greaterThanOrEqualTo(0),
        reason: 'Handler brain_e2ee_object não encontrado.',
      );

      final nextJourneyIndex = appDependenciesSource.indexOf(
        '// JOURNEY',
        e2eeHandlerIndex,
      );

      expect(nextJourneyIndex, greaterThan(e2eeHandlerIndex));

      final brainHandler = appDependenciesSource.substring(
        e2eeHandlerIndex,
        nextJourneyIndex,
      );

      expect(brainHandler, contains('processingGate:'));

      expect(brainHandler, contains('_canUseBrainCloudWithAuthorizedDevice()'));

      final gateStart = appDependenciesSource.indexOf(
        'Future<bool> _canUseBrainCloudWithAuthorizedDevice() async',
      );
      expect(gateStart, greaterThanOrEqualTo(0));

      final gateEnd = appDependenciesSource.indexOf(
        '// BRAIN DEVICE BOOTSTRAP',
        gateStart,
      );
      expect(gateEnd, greaterThan(gateStart));

      final gateSource = appDependenciesSource.substring(gateStart, gateEnd);

      expect(gateSource, contains('brainDataModeService.canUseCloudSync'));
      expect(gateSource, contains('supabaseClient.auth.currentUser'));
      expect(gateSource, contains('brainDeviceGateService.canUseCloud'));
      expect(gateSource, contains('return false;'));
    });

    test('handler legado brain_review não é mais registrado', () {
      expect(
        appDependenciesSource,
        isNot(contains("entityType: 'brain_review'")),
      );

      expect(
        appDependenciesSource,
        isNot(contains('entityType: ReviewRepository.entityType')),
      );
    });

    test('fila legada do Brain é purgada sem remover brain_e2ee_object', () {
      final purgeStart = appDependenciesSource.indexOf(
        '_purgeLegacyBrainQueueItems(void Function() check) async',
      );

      final registerStart = appDependenciesSource.indexOf(
        '// REGISTER SYNC HANDLERS',
        purgeStart,
      );

      expect(purgeStart, greaterThanOrEqualTo(0));

      expect(registerStart, greaterThan(purgeStart));

      final purgeSource = appDependenciesSource.substring(
        purgeStart,
        registerStart,
      );

      expect(purgeSource, contains("'brain_note'"));

      expect(purgeSource, contains("'brain_concept'"));

      expect(purgeSource, contains("'brain_review'"));
      expect(purgeSource, contains('check();'));

      expect(
        purgeSource,
        isNot(contains("'brain_e2ee_object'")),
        reason: 'A limpeza de legado nunca pode apagar brain_e2ee_object.',
      );
    });
  });
}
