import 'brain_crypto_version.dart';

// ============================================================
// BRAIN CRYPTO METADATA
// ============================================================
//
// Representa metadados criptográficos NÃO sensíveis.
//
// Este objeto NÃO deve armazenar:
//
// - título;
// - conteúdo;
// - pergunta;
// - resposta;
// - tema;
// - tags;
// - conhecimento do usuário.
//
// Ele existe apenas para permitir que o sistema saiba:
//
// - qual versão criptográfica foi utilizada;
// - qual algoritmo foi utilizado;
// - quando o payload foi produzido.
//
// ============================================================

class BrainCryptoMetadata {
  const BrainCryptoMetadata({
    required this.version,
    required this.algorithm,
    required this.createdAt,
  });

  // ============================================================
  // VERSION
  // ============================================================

  final BrainCryptoVersion version;

  // ============================================================
  // ALGORITHM
  // ============================================================
  //
  // Valor esperado na V1:
  //
  // xchacha20-poly1305
  //
  // ============================================================

  final String algorithm;

  // ============================================================
  // CREATED AT
  // ============================================================

  final DateTime createdAt;

  // ============================================================
  // COPY
  // ============================================================

  BrainCryptoMetadata copyWith({
    BrainCryptoVersion? version,
    String? algorithm,
    DateTime? createdAt,
  }) {
    return BrainCryptoMetadata(
      version:
          version ??
          this.version,
      algorithm:
          algorithm ??
          this.algorithm,
      createdAt:
          createdAt ??
          this.createdAt,
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
      'crypto_version': version.value,
      'algorithm': algorithm,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainCryptoMetadata.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final rawVersion = json['crypto_version'];

    final version = BrainCryptoVersion.fromValue(
      _parseInt(
        rawVersion,
      ),
    );

    final algorithm =
        json['algorithm']?.toString().trim() ??
        '';

    if (algorithm.isEmpty) {
      throw const FormatException(
        'Algoritmo criptográfico ausente.',
      );
    }

    final createdAt = DateTime.tryParse(
      json['created_at']?.toString().trim() ??
          '',
    );

    if (createdAt ==
        null) {
      throw const FormatException(
        'Data criptográfica inválida.',
      );
    }

    return BrainCryptoMetadata(
      version: version,
      algorithm: algorithm,
      createdAt: createdAt.toUtc(),
    );
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int _parseInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    final parsed = int.tryParse(
      value?.toString().trim() ??
          '',
    );

    if (parsed ==
        null) {
      throw const FormatException(
        'Versão criptográfica inválida.',
      );
    }

    return parsed;
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is BrainCryptoMetadata &&
        other.version ==
            version &&
        other.algorithm ==
            algorithm &&
        other.createdAt ==
            createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      version,
      algorithm,
      createdAt,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainCryptoMetadata('
        'version: ${version.value}, '
        'algorithm: $algorithm, '
        'createdAt: $createdAt'
        ')';
  }
}
