import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/crypto/brain_secure_random.dart';

void
main() {
  group(
    'BrainSecureRandom',
    () {
      test(
        'gera Master Key com 32 bytes',
        () {
          final random = BrainSecureRandom();

          final key = random.generateMasterKey();

          expect(
            key.length,
            BrainSecureRandom.masterKeyLengthBytes,
          );
        },
      );

      test(
        'gera nonce com 24 bytes',
        () {
          final random = BrainSecureRandom();

          final nonce = random.generateNonce();

          expect(
            nonce.length,
            BrainSecureRandom.xChaCha20NonceLengthBytes,
          );
        },
      );

      test(
        'duas Master Keys devem ser diferentes',
        () {
          final random = BrainSecureRandom();

          final first = random.generateMasterKey();
          final second = random.generateMasterKey();

          expect(
            first,
            isNot(
              equals(
                second,
              ),
            ),
          );
        },
      );

      test(
        'dois nonces devem ser diferentes',
        () {
          final random = BrainSecureRandom();

          final first = random.generateNonce();
          final second = random.generateNonce();

          expect(
            first,
            isNot(
              equals(
                second,
              ),
            ),
          );
        },
      );

      test(
        'generateBytes rejeita tamanho inválido',
        () {
          final random = BrainSecureRandom();

          expect(
            () => random.generateBytes(
              0,
            ),
            throwsException,
          );
        },
      );
    },
  );
}
