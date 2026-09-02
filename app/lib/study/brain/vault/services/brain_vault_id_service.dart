import 'dart:convert';
import 'dart:math';

// ============================================================
// BRAIN VAULT ID SERVICE
// ============================================================
//
// Responsável por gerar identificadores opacos e estáveis.
//
// IDs gerados:
//
// vault_<random>
// obj_<random>
//
// IMPORTANTE:
//
// Um objectId:
//
// - NÃO depende do path;
// - NÃO depende do título;
// - NÃO depende do tema;
// - NÃO depende do userId;
// - NÃO depende do dispositivo.
//
// Dessa forma o mesmo objeto pode atravessar:
//
// dispositivo
// backup
// restore
// cloud
//
// sem mudar de identidade.
//
// ============================================================

class BrainVaultIdService {
  BrainVaultIdService({
    Random? random,
  }) : _random =
           random ??
           Random.secure();

  // ============================================================
  // DEPENDENCY
  // ============================================================

  final Random _random;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int entropyLengthBytes = 16;

  static const String vaultPrefix = 'vault_';

  static const String objectPrefix = 'obj_';

  // ============================================================
  // VAULT ID
  // ============================================================

  String generateVaultId() {
    return _generateId(
      prefix: vaultPrefix,
    );
  }

  // ============================================================
  // OBJECT ID
  // ============================================================

  String generateObjectId() {
    return _generateId(
      prefix: objectPrefix,
    );
  }

  // ============================================================
  // VALIDATE VAULT ID
  // ============================================================

  bool isValidVaultId(
    String value,
  ) {
    final clean = value.trim();

    if (!clean.startsWith(
      vaultPrefix,
    )) {
      return false;
    }

    return _isSafeId(
      clean,
    );
  }

  // ============================================================
  // VALIDATE OBJECT ID
  // ============================================================

  bool isValidObjectId(
    String value,
  ) {
    final clean = value.trim();

    if (!clean.startsWith(
      objectPrefix,
    )) {
      return false;
    }

    return _isSafeId(
      clean,
    );
  }

  // ============================================================
  // GENERATE
  // ============================================================

  String _generateId({
    required String prefix,
  }) {
    final bytes =
        List<
          int
        >.generate(
          entropyLengthBytes,
          (
            _,
          ) {
            return _random.nextInt(
              256,
            );
          },
          growable: false,
        );

    final encoded =
        base64UrlEncode(
          bytes,
        ).replaceAll(
          '=',
          '',
        );

    return '$prefix$encoded';
  }

  // ============================================================
  // SAFE ID
  // ============================================================
  //
  // Bloqueia:
  //
  // /
  // \
  // ..
  // espaços
  //
  // evitando utilizar IDs como caminhos arbitrários.
  //
  // ============================================================

  bool _isSafeId(
    String value,
  ) {
    if (value.isEmpty) {
      return false;
    }

    if (value.contains(
          '/',
        ) ||
        value.contains(
          '\\',
        ) ||
        value.contains(
          '..',
        )) {
      return false;
    }

    final expression = RegExp(
      r'^[A-Za-z0-9_-]+$',
    );

    return expression.hasMatch(
      value,
    );
  }
}
