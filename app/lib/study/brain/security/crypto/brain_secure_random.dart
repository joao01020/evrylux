import 'dart:math';
import 'dart:typed_data';

import '../exceptions/brain_crypto_exception.dart';

// ============================================================
// BRAIN SECURE RANDOM
// ============================================================
//
// Responsável pela geração de bytes criptograficamente seguros.
//
// V1:
//
// Master Key:
// - 32 bytes
// - 256 bits
//
// Nonce XChaCha20:
// - 24 bytes
// - 192 bits
//
// IMPORTANTE:
//
// Nunca substituir Random.secure() por Random().
//
// ============================================================

class BrainSecureRandom {
  BrainSecureRandom({
    Random? random,
  }) : _random =
           random ??
           Random.secure();

  final Random _random;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int masterKeyLengthBytes = 32;

  static const int xChaCha20NonceLengthBytes = 24;

  // ============================================================
  // GENERATE BYTES
  // ============================================================

  Uint8List generateBytes(
    int length,
  ) {
    if (length <=
        0) {
      throw BrainCryptoException.invalidPayload(
        message: 'O tamanho solicitado para bytes aleatórios é inválido.',
      );
    }

    final result = Uint8List(
      length,
    );

    for (
      var index = 0;
      index <
          length;
      index++
    ) {
      result[index] = _random.nextInt(
        256,
      );
    }

    return result;
  }

  // ============================================================
  // MASTER KEY
  // ============================================================

  Uint8List generateMasterKey() {
    return generateBytes(
      masterKeyLengthBytes,
    );
  }

  // ============================================================
  // NONCE
  // ============================================================

  Uint8List generateNonce() {
    return generateBytes(
      xChaCha20NonceLengthBytes,
    );
  }
}
