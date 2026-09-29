import 'package:flutter_test/flutter_test.dart';
import 'package:EVRYLUX/finance/utils/crypto_value_math.dart';

void main() {
  group('CryptoValueMath', () {
    test('calcula Patrimônio por quantidade x cotação', () {
      final result = CryptoValueMath.patrimony(
        quantities: const <String, double>{
          'BTC': 0.00118671,
          'SOL': 0.14382312,
          'USDT': 18.52412687,
        },
        prices: const <String, double>{
          'BTC': 435993.46,
          'SOL': 620.0,
          'USDT': 5.23,
        },
      );

      expect(result, greaterThan(690));

      expect(result, lessThan(720));
    });

    test('valor do modal usa quantidade x preço', () {
      final value = CryptoValueMath.currentValue(
        quantity: 0.00118671,
        price: 435993.46,
      );

      expect(value, closeTo(517.40, 1.0));
    });

    test('zero ou valor inválido nunca produz patrimônio negativo', () {
      final value = CryptoValueMath.currentValue(
        quantity: -1,
        price: 435993.46,
      );

      expect(value, 0);
    });

    test('resultado percentual é protegido quando investido é zero', () {
      final value = CryptoValueMath.profitLossPercent(
        currentValue: 500,
        invested: 0,
      );

      expect(value, 0);
    });
  });
}
