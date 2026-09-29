import 'package:flutter_test/flutter_test.dart';
import 'package:EVRYLUX/finance/services/crypto/crypto_price_cache_policy.dart';

void main() {
  group('CryptoPriceCachePolicy', () {
    final now = DateTime.utc(2026, 9, 29, 20);

    test('classifica cache recente como fresh', () {
      final state = CryptoPriceCachePolicy.classify(
        hasPrices: true,
        updatedAt: now.subtract(const Duration(seconds: 30)),
        now: now,
      );

      expect(state, CryptoPriceCacheState.fresh);
    });

    test('classifica cache intermediário como stale', () {
      final state = CryptoPriceCachePolicy.classify(
        hasPrices: true,
        updatedAt: now.subtract(const Duration(minutes: 5)),
        now: now,
      );

      expect(state, CryptoPriceCacheState.stale);
    });

    test('classifica cache antigo como expired', () {
      final state = CryptoPriceCachePolicy.classify(
        hasPrices: true,
        updatedAt: now.subtract(const Duration(hours: 1)),
        now: now,
      );

      expect(state, CryptoPriceCacheState.expired);
    });

    test('sem preços é empty mesmo com timestamp', () {
      final state = CryptoPriceCachePolicy.classify(
        hasPrices: false,
        updatedAt: now,
        now: now,
      );

      expect(state, CryptoPriceCacheState.empty);
    });
  });
}
