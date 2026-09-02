import 'dart:convert';

import 'brain_crypto_metadata.dart';

// ============================================================
// BRAIN ENCRYPTED PAYLOAD
// ============================================================
//
// Representa um conteúdo já criptografado.
//
// IMPORTANTE:
//
// Este objeto NÃO contém plaintext.
//
// Ele pode ser persistido em:
//
// - .evobj;
// - SyncQueue;
// - .evbrain;
// - Supabase.
//
// Estrutura lógica:
//
// metadata
// ciphertext
// nonce
// mac
//
// Todos os campos binários são mantidos como bytes em memória.
//
// Ao serializar para JSON usamos Base64 apenas como representação.
//
// Base64 NÃO é criptografia.
//
// ============================================================

class BrainEncryptedPayload {
  const BrainEncryptedPayload({
    required this.cipherText,
    required this.nonce,
    required this.mac,
    required this.metadata,
  });

  // ============================================================
  // CIPHERTEXT
  // ============================================================

  final List<
    int
  >
  cipherText;

  // ============================================================
  // NONCE
  // ============================================================

  final List<
    int
  >
  nonce;

  // ============================================================
  // MAC
  // ============================================================
  //
  // Authentication tag produzido pelo Poly1305.
  //
  // ============================================================

  final List<
    int
  >
  mac;

  // ============================================================
  // METADATA
  // ============================================================

  final BrainCryptoMetadata metadata;

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isEmpty {
    return cipherText.isEmpty;
  }

  bool get hasNonce {
    return nonce.isNotEmpty;
  }

  bool get hasMac {
    return mac.isNotEmpty;
  }

  // ============================================================
  // BASE64
  // ============================================================

  String get cipherTextBase64 {
    return base64Encode(
      cipherText,
    );
  }

  String get nonceBase64 {
    return base64Encode(
      nonce,
    );
  }

  String get macBase64 {
    return base64Encode(
      mac,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'metadata': metadata.toJson(),
      'ciphertext': cipherTextBase64,
      'nonce': nonceBase64,
      'mac': macBase64,
    };
  }

  // ============================================================
  // JSON STRING
  // ============================================================

  String toJsonString() {
    return jsonEncode(
      toJson(),
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainEncryptedPayload.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final rawMetadata = json['metadata'];

    if (rawMetadata
        is! Map) {
      throw const FormatException(
        'Metadados criptográficos inválidos.',
      );
    }

    final cipherText = _decodeBase64(
      json['ciphertext'],
      fieldName: 'ciphertext',
    );

    final nonce = _decodeBase64(
      json['nonce'],
      fieldName: 'nonce',
    );

    final mac = _decodeBase64(
      json['mac'],
      fieldName: 'mac',
    );

    return BrainEncryptedPayload(
      cipherText:
          List<
            int
          >.unmodifiable(
            cipherText,
          ),
      nonce:
          List<
            int
          >.unmodifiable(
            nonce,
          ),
      mac:
          List<
            int
          >.unmodifiable(
            mac,
          ),
      metadata: BrainCryptoMetadata.fromJson(
        Map<
          String,
          dynamic
        >.from(
          rawMetadata,
        ),
      ),
    );
  }

  // ============================================================
  // FROM JSON STRING
  // ============================================================

  factory BrainEncryptedPayload.fromJsonString(
    String jsonString,
  ) {
    final decoded = jsonDecode(
      jsonString,
    );

    if (decoded
        is! Map) {
      throw const FormatException(
        'Payload criptografado inválido.',
      );
    }

    return BrainEncryptedPayload.fromJson(
      Map<
        String,
        dynamic
      >.from(
        decoded,
      ),
    );
  }

  // ============================================================
  // DECODE BASE64
  // ============================================================

  static List<
    int
  >
  _decodeBase64(
    dynamic value, {
    required String fieldName,
  }) {
    final encoded =
        value?.toString().trim() ??
        '';

    if (encoded.isEmpty) {
      throw FormatException(
        '$fieldName ausente.',
      );
    }

    try {
      return base64Decode(
        encoded,
      );
    } catch (
      _
    ) {
      throw FormatException(
        '$fieldName não contém Base64 válido.',
      );
    }
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainEncryptedPayload copyWith({
    List<
      int
    >?
    cipherText,
    List<
      int
    >?
    nonce,
    List<
      int
    >?
    mac,
    BrainCryptoMetadata? metadata,
  }) {
    return BrainEncryptedPayload(
      cipherText:
          cipherText ??
          this.cipherText,
      nonce:
          nonce ??
          this.nonce,
      mac:
          mac ??
          this.mac,
      metadata:
          metadata ??
          this.metadata,
    );
  }

  // ============================================================
  // STRING
  // ============================================================
  //
  // NUNCA imprimir ciphertext completo.
  //
  // ============================================================

  @override
  String toString() {
    return 'BrainEncryptedPayload('
        'cipherTextBytes: ${cipherText.length}, '
        'nonceBytes: ${nonce.length}, '
        'macBytes: ${mac.length}, '
        'cryptoVersion: ${metadata.version.value}, '
        'algorithm: ${metadata.algorithm}'
        ')';
  }
}
