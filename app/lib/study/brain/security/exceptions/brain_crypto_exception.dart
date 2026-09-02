// ============================================================
// BRAIN CRYPTO ERROR CODE
// ============================================================
//
// Códigos internos de erro da camada criptográfica.
//
// IMPORTANTE:
//
// As mensagens não devem incluir:
//
// - plaintext;
// - título;
// - conteúdo;
// - pergunta;
// - resposta;
// - Master Key;
// - nonce completo;
// - ciphertext completo.
//
// ============================================================

enum BrainCryptoErrorCode {
  invalidKey,
  invalidNonce,
  invalidMac,
  invalidPayload,
  invalidPlaintext,
  unsupportedVersion,
  unsupportedAlgorithm,
  encryptionFailed,
  decryptionFailed,
  authenticationFailed,
  keyStorageFailed,
  keyNotFound,
}

// ============================================================
// BRAIN CRYPTO EXCEPTION
// ============================================================

class BrainCryptoException
    implements
        Exception {
  const BrainCryptoException({
    required this.code,
    required this.message,
    this.cause,
  });

  final BrainCryptoErrorCode code;

  final String message;

  final Object? cause;

  // ============================================================
  // FACTORIES
  // ============================================================

  factory BrainCryptoException.invalidKey({
    String message = 'Chave criptográfica inválida.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.invalidKey,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.invalidNonce({
    String message = 'Nonce criptográfico inválido.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.invalidNonce,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.invalidMac({
    String message = 'Código de autenticação inválido.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.invalidMac,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.invalidPayload({
    String message = 'Payload criptografado inválido.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.invalidPayload,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.invalidPlaintext({
    String message = 'Conteúdo para criptografia inválido.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.invalidPlaintext,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.unsupportedVersion({
    String message = 'Versão criptográfica não suportada.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.unsupportedVersion,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.unsupportedAlgorithm({
    String message = 'Algoritmo criptográfico não suportado.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.unsupportedAlgorithm,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.encryptionFailed({
    String message = 'Não foi possível criptografar o conteúdo.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.encryptionFailed,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.decryptionFailed({
    String message = 'Não foi possível descriptografar o conteúdo.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.decryptionFailed,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.authenticationFailed({
    String message = 'A autenticação do conteúdo criptografado falhou.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.authenticationFailed,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.keyStorageFailed({
    String message = 'Falha ao acessar o armazenamento seguro da chave.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.keyStorageFailed,
      message: message,
      cause: cause,
    );
  }

  factory BrainCryptoException.keyNotFound({
    String message = 'Chave criptográfica não encontrada.',
    Object? cause,
  }) {
    return BrainCryptoException(
      code: BrainCryptoErrorCode.keyNotFound,
      message: message,
      cause: cause,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainCryptoException('
        'code: ${code.name}, '
        'message: $message'
        ')';
  }
}
