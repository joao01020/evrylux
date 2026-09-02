import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../exceptions/brain_crypto_exception.dart';
import '../models/brain_crypto_metadata.dart';
import '../models/brain_crypto_version.dart';
import '../models/brain_encrypted_payload.dart';
import '../models/brain_key_bundle.dart';
import 'brain_secure_random.dart';

// ============================================================
// BRAIN CRYPTO SERVICE
// ============================================================
//
// Implementação criptográfica V1 do EVRYLUX Cérebro.
//
// V1:
//
// - XChaCha20-Poly1305;
// - Master Key de 32 bytes / 256 bits;
// - nonce de 24 bytes / 192 bits;
// - authenticated encryption;
// - crypto_version = 1.
//
// RESPONSABILIDADE:
//
// plaintext
//      ↓
// encrypt
//      ↓
// BrainEncryptedPayload
//
// BrainEncryptedPayload
//      ↓
// decrypt
//      ↓
// plaintext
//
// ============================================================

class BrainCryptoService {
  BrainCryptoService({
    BrainSecureRandom? secureRandom,
    Cipher? algorithm,
  }) : _secureRandom =
           secureRandom ??
           BrainSecureRandom(),
       _algorithm =
           algorithm ??
           Xchacha20.poly1305Aead();

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainSecureRandom _secureRandom;

  final Cipher _algorithm;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String algorithmName = 'xchacha20-poly1305';

  static const int masterKeyLengthBytes = 32;

  static const int nonceLengthBytes = 24;

  static const int macLengthBytes = 16;

  // ============================================================
  // ENCRYPT STRING
  // ============================================================

  Future<
    BrainEncryptedPayload
  >
  encryptString({
    required String plaintext,
    required BrainKeyBundle keyBundle,
  }) async {
    final bytes = utf8.encode(
      plaintext,
    );

    return encryptBytes(
      plaintextBytes: bytes,
      keyBundle: keyBundle,
    );
  }

  // ============================================================
  // ENCRYPT BYTES
  // ============================================================

  Future<
    BrainEncryptedPayload
  >
  encryptBytes({
    required List<
      int
    >
    plaintextBytes,
    required BrainKeyBundle keyBundle,
  }) async {
    _validateKeyBundle(
      keyBundle,
    );

    final nonce = _secureRandom.generateNonce();

    if (nonce.length !=
        nonceLengthBytes) {
      throw BrainCryptoException.invalidNonce(
        message:
            'Nonce inválido: esperado '
            '$nonceLengthBytes bytes.',
      );
    }

    try {
      final secretKey = SecretKey(
        keyBundle.masterKeyBytes,
      );

      final secretBox = await _algorithm.encrypt(
        plaintextBytes,
        secretKey: secretKey,
        nonce: nonce,
      );

      final macBytes = secretBox.mac.bytes;

      if (secretBox.nonce.length !=
          nonceLengthBytes) {
        throw BrainCryptoException.invalidNonce(
          message: 'Nonce produzido possui tamanho inesperado.',
        );
      }

      if (macBytes.length !=
          macLengthBytes) {
        throw BrainCryptoException.invalidMac(
          message: 'MAC produzido possui tamanho inesperado.',
        );
      }

      return BrainEncryptedPayload(
        cipherText:
            List<
              int
            >.unmodifiable(
              secretBox.cipherText,
            ),
        nonce:
            List<
              int
            >.unmodifiable(
              secretBox.nonce,
            ),
        mac:
            List<
              int
            >.unmodifiable(
              macBytes,
            ),
        metadata: BrainCryptoMetadata(
          version: BrainCryptoVersion.current,
          algorithm: algorithmName,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    } on BrainCryptoException {
      rethrow;
    } catch (
      error
    ) {
      throw BrainCryptoException.encryptionFailed(
        cause: error,
      );
    }
  }

  // ============================================================
  // DECRYPT STRING
  // ============================================================

  Future<
    String
  >
  decryptString({
    required BrainEncryptedPayload payload,
    required BrainKeyBundle keyBundle,
  }) async {
    final bytes = await decryptBytes(
      payload: payload,
      keyBundle: keyBundle,
    );

    try {
      return utf8.decode(
        bytes,
      );
    } catch (
      error
    ) {
      throw BrainCryptoException.decryptionFailed(
        message: 'O conteúdo descriptografado não contém UTF-8 válido.',
        cause: error,
      );
    }
  }

  // ============================================================
  // DECRYPT BYTES
  // ============================================================

  Future<
    List<
      int
    >
  >
  decryptBytes({
    required BrainEncryptedPayload payload,
    required BrainKeyBundle keyBundle,
  }) async {
    _validateKeyBundle(
      keyBundle,
    );

    _validatePayload(
      payload,
    );

    try {
      final secretKey = SecretKey(
        keyBundle.masterKeyBytes,
      );

      final secretBox = SecretBox(
        payload.cipherText,
        nonce: payload.nonce,
        mac: Mac(
          payload.mac,
        ),
      );

      final clearText = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      return List<
        int
      >.unmodifiable(
        clearText,
      );
    } on SecretBoxAuthenticationError catch (
      error
    ) {
      throw BrainCryptoException.authenticationFailed(
        cause: error,
      );
    } on BrainCryptoException {
      rethrow;
    } catch (
      error
    ) {
      throw BrainCryptoException.decryptionFailed(
        cause: error,
      );
    }
  }

  // ============================================================
  // VALIDATE KEY
  // ============================================================

  void _validateKeyBundle(
    BrainKeyBundle bundle,
  ) {
    if (bundle.masterKeyBytes.length !=
        masterKeyLengthBytes) {
      throw BrainCryptoException.invalidKey(
        message:
            'Master Key inválida: esperado '
            '$masterKeyLengthBytes bytes.',
      );
    }

    if (bundle.keyVersion <=
        0) {
      throw BrainCryptoException.invalidKey(
        message: 'Versão da Master Key inválida.',
      );
    }
  }

  // ============================================================
  // VALIDATE PAYLOAD
  // ============================================================

  void _validatePayload(
    BrainEncryptedPayload payload,
  ) {
    if (payload.metadata.version !=
        BrainCryptoVersion.current) {
      throw BrainCryptoException.unsupportedVersion(
        message:
            'Versão criptográfica não suportada: '
            '${payload.metadata.version.value}.',
      );
    }

    if (payload.metadata.algorithm.trim() !=
        algorithmName) {
      throw BrainCryptoException.unsupportedAlgorithm(
        message:
            'Algoritmo criptográfico não suportado: '
            '${payload.metadata.algorithm}.',
      );
    }

    if (payload.nonce.length !=
        nonceLengthBytes) {
      throw BrainCryptoException.invalidNonce(
        message:
            'Nonce inválido: esperado '
            '$nonceLengthBytes bytes.',
      );
    }

    if (payload.mac.length !=
        macLengthBytes) {
      throw BrainCryptoException.invalidMac(
        message:
            'MAC inválido: esperado '
            '$macLengthBytes bytes.',
      );
    }
  }
}
