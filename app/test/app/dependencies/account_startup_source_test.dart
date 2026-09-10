import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup global não abre armazenamento privado', () {
    final source = File(
      'lib/app/dependencies/app_dependencies.dart',
    ).readAsStringSync();
    final start = source.indexOf(
      'Future<void> initializeOfflineFirst() async {',
    );
    final end = source.indexOf('final accountStartupCoordinator =', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final global = source.substring(start, end);
    expect(global, isNot(contains('await reviewRepository.initialize()')));
    expect(
      global,
      isNot(contains('await brainE2eeSyncCoordinator.bootstrap()')),
    );
    expect(global, isNot(contains('await syncService.start()')));
    expect(source, contains('await reviewRepository.initialize();'));
    expect(source, contains('await brainReviewStartupMigrationService.run();'));
    expect(source, contains('await brainE2eeSyncCoordinator.bootstrap();'));
  });

  test('login prepara a conta antes de buscar perfil', () {
    final source = File('lib/auth/auth_gate.dart').readAsStringSync();
    final prepare = source.indexOf('await widget.prepareUser(user.id);');
    final profile = source.indexOf(
      'final profile = await _profileRepository.getProfile(',
      prepare,
    );
    expect(prepare, greaterThanOrEqualTo(0));
    expect(profile, greaterThan(prepare));
    expect(source, contains('widget.onUserChanged(null);'));
  });

  test('sync revoga identidade e aguarda lote ativo', () {
    final source = File('lib/core/sync/sync_service.dart').readAsStringSync();
    expect(source, contains('void authorizeUser(String? userId)'));
    expect(source, contains('if (!_isAuthorizedFor(owner))'));
    expect(source, contains('if (running != null) await running;'));
    expect(source, contains('Future<void> _stopInternal() async'));
  });
}
