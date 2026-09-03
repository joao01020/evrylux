import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/settings/models/brain_data_mode.dart';

void main() {
  group('BrainDataMode', () {
    test('local bloqueia cloud sync', () {
      expect(BrainDataMode.local.allowsCloudSync, false);

      expect(BrainDataMode.local.requiresAuthentication, false);

      expect(BrainDataMode.local.isLocalOnly, true);
    });

    test('cloud permite sync e exige autenticação', () {
      expect(BrainDataMode.cloud.allowsCloudSync, true);

      expect(BrainDataMode.cloud.requiresAuthentication, true);

      expect(BrainDataMode.cloud.isLocalOnly, false);
    });

    test('tryParse reconhece valores válidos', () {
      expect(BrainDataMode.tryParse('local'), BrainDataMode.local);

      expect(BrainDataMode.tryParse(' CLOUD '), BrainDataMode.cloud);
    });

    test('tryParse retorna null para valor desconhecido', () {
      expect(BrainDataMode.tryParse('unknown'), isNull);
    });
  });
}
