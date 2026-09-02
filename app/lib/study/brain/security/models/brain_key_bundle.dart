// ============================================================
// BRAIN KEY BUNDLE
// ============================================================
//
// Representa o material criptográfico principal do Vault.
//
// IMPORTANTE:
//
// Este objeto pode conter a MASTER KEY.
//
// Por isso:
//
// - NÃO possui toJson();
// - NÃO possui fromJson();
// - NÃO imprime bytes da chave;
// - NÃO deve ser salvo em SharedPreferences;
// - NÃO deve ser salvo em SQLite plaintext;
// - NÃO deve ser salvo em arquivos comuns;
// - NÃO deve entrar na SyncQueue;
// - NÃO deve ser enviado diretamente ao Supabase.
//
// Persistência segura pertence ao BrainKeyStorage.
//
// ============================================================

class BrainKeyBundle {
  const BrainKeyBundle({
    required this.masterKeyBytes,
    required this.keyVersion,
    required this.createdAt,
  });

  // ============================================================
  // MASTER KEY
  // ============================================================
  //
  // V1:
  //
  // 32 bytes / 256 bits
  //
  // ============================================================

  final List<
    int
  >
  masterKeyBytes;

  // ============================================================
  // KEY VERSION
  // ============================================================
  //
  // Separada de crypto_version.
  //
  // crypto_version:
  // define formato/algoritmo criptográfico.
  //
  // key_version:
  // permite futura rotação da Master Key.
  //
  // ============================================================

  final int keyVersion;

  // ============================================================
  // CREATED AT
  // ============================================================

  final DateTime createdAt;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int masterKeyLengthBytes = 32;

  static const int initialKeyVersion = 1;

  // ============================================================
  // VALIDATION
  // ============================================================

  bool get hasValidMasterKeyLength {
    return masterKeyBytes.length ==
        masterKeyLengthBytes;
  }

  bool get hasValidKeyVersion {
    return keyVersion >
        0;
  }

  bool get isValid {
    return hasValidMasterKeyLength &&
        hasValidKeyVersion;
  }

  // ============================================================
  // ASSERT VALID
  // ============================================================

  void validate() {
    if (!hasValidMasterKeyLength) {
      throw StateError(
        'Master Key inválida: '
        'esperado $masterKeyLengthBytes bytes, '
        'recebido ${masterKeyBytes.length}.',
      );
    }

    if (!hasValidKeyVersion) {
      throw StateError(
        'Versão de chave inválida: $keyVersion.',
      );
    }
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainKeyBundle copyWith({
    List<
      int
    >?
    masterKeyBytes,
    int? keyVersion,
    DateTime? createdAt,
  }) {
    return BrainKeyBundle(
      masterKeyBytes:
          masterKeyBytes ??
          this.masterKeyBytes,
      keyVersion:
          keyVersion ??
          this.keyVersion,
      createdAt:
          createdAt ??
          this.createdAt,
    );
  }

  // ============================================================
  // STRING
  // ============================================================
  //
  // NUNCA imprimir a Master Key.
  //
  // ============================================================

  @override
  String toString() {
    return 'BrainKeyBundle('
        'masterKeyBytes: [REDACTED ${masterKeyBytes.length} bytes], '
        'keyVersion: $keyVersion, '
        'createdAt: $createdAt'
        ')';
  }
}
