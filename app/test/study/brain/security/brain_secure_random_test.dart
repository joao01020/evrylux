import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/crypto/brain_crypto_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';
import 'package:EVRYLUX/study/brain/security/models/brain_encrypted_payload.dart';

void
main() {
  group(
    'BrainCryptoService',
    () {
      late BrainCryptoService crypto;
      late BrainKeyService keyService;

      setUp(
        () {
          crypto = BrainCryptoService();

          keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );
        },
      );

      test(
        'encrypt + decrypt retorna o mesmo texto',
        () async {
          const original = 'Hoje aprendi sobre negociação. 🧠';

          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: original,
            keyBundle: key,
          );

          final decrypted = await crypto.decryptString(
            payload: encrypted,
            keyBundle: key,
          );

          expect(
            decrypted,
            original,
          );
        },
      );

      test(
        'suporta português, russo, japonês e emoji',
        () async {
          const original = 'Olá çãõ — Привет — 日本語 — 🧠🔐';

          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: original,
            keyBundle: key,
          );

          final decrypted = await crypto.decryptString(
            payload: encrypted,
            keyBundle: key,
          );

          expect(
            decrypted,
            original,
          );
        },
      );

      test(
        'mesmo texto criptografado duas vezes produz resultado diferente',
        () async {
          const original = 'Mesmo conteúdo';

          final key = keyService.createKeyBundle();

          final first = await crypto.encryptString(
            plaintext: original,
            keyBundle: key,
          );

          final second = await crypto.encryptString(
            plaintext: original,
            keyBundle: key,
          );

          expect(
            first.nonce,
            isNot(
              equals(
                second.nonce,
              ),
            ),
          );

          expect(
            first.cipherText,
            isNot(
              equals(
                second.cipherText,
              ),
            ),
          );
        },
      );

      test(
        'chave errada deve falhar',
        () async {
          final firstKey = keyService.createKeyBundle();

          final secondKey = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: 'conteúdo secreto',
            keyBundle: firstKey,
          );

          expect(
            () async {
              await crypto.decryptString(
                payload: encrypted,
                keyBundle: secondKey,
              );
            },
            throwsException,
          );
        },
      );

      test(
        'ciphertext adulterado deve falhar',
        () async {
          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: 'conteúdo secreto',
            keyBundle: key,
          );

          final corruptedCiphertext =
              List<
                int
              >.from(
                encrypted.cipherText,
              );

          corruptedCiphertext[0] =
              corruptedCiphertext[0] ^
              1;

          final corrupted = encrypted.copyWith(
            cipherText: corruptedCiphertext,
          );

          expect(
            () async {
              await crypto.decryptString(
                payload: corrupted,
                keyBundle: key,
              );
            },
            throwsException,
          );
        },
      );

      test(
        'nonce adulterado deve falhar',
        () async {
          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: 'conteúdo secreto',
            keyBundle: key,
          );

          final corruptedNonce =
              List<
                int
              >.from(
                encrypted.nonce,
              );

          corruptedNonce[0] =
              corruptedNonce[0] ^
              1;

          final corrupted = encrypted.copyWith(
            nonce: corruptedNonce,
          );

          expect(
            () async {
              await crypto.decryptString(
                payload: corrupted,
                keyBundle: key,
              );
            },
            throwsException,
          );
        },
      );

      test(
        'MAC adulterado deve falhar',
        () async {
          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: 'conteúdo secreto',
            keyBundle: key,
          );

          final corruptedMac =
              List<
                int
              >.from(
                encrypted.mac,
              );

          corruptedMac[0] =
              corruptedMac[0] ^
              1;

          final corrupted = encrypted.copyWith(
            mac: corruptedMac,
          );

          expect(
            () async {
              await crypto.decryptString(
                payload: corrupted,
                keyBundle: key,
              );
            },
            throwsException,
          );
        },
      );

      test(
        'JSON preserva payload criptografado',
        () async {
          final key = keyService.createKeyBundle();

          final encrypted = await crypto.encryptString(
            plaintext: 'teste json',
            keyBundle: key,
          );

          final json = encrypted.toJsonString();

          final restored = BrainEncryptedPayload.fromJsonString(
            json,
          );

          final decrypted = await crypto.decryptString(
            payload: restored,
            keyBundle: key,
          );

          expect(
            decrypted,
            'teste json',
          );
        },
      );

      test(
        'texto grande funciona',
        () async {
          final key = keyService.createKeyBundle();

          final original =
              List.generate(
                10000,
                (
                  index,
                ) => 'Linha $index — EVRYLUX 🧠',
              ).join(
                '\n',
              );

          final encrypted = await crypto.encryptString(
            plaintext: original,
            keyBundle: key,
          );

          final decrypted = await crypto.decryptString(
            payload: encrypted,
            keyBundle: key,
          );

          expect(
            decrypted,
            original,
          );
        },
      );
    },
  );
}
