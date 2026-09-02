// ============================================================
// BRAIN CRYPTO VERSION
// ============================================================
//
// Centraliza as versões criptográficas suportadas pelo
// EVRYLUX Cérebro.
//
// IMPORTANTE:
//
// Nunca assumir que todos os objetos foram criptografados com
// exatamente o mesmo formato para sempre.
//
// A versão permite:
//
// V1
// ↓
// V2
// ↓
// V3
//
// sem tornar dados antigos ilegíveis.
//
// ============================================================

enum BrainCryptoVersion {
  v1(
    value: 1,
  );

  const BrainCryptoVersion({
    required this.value,
  });

  // ============================================================
  // VALUE
  // ============================================================

  final int value;

  // ============================================================
  // CURRENT
  // ============================================================

  static const BrainCryptoVersion current = BrainCryptoVersion.v1;

  // ============================================================
  // FROM VALUE
  // ============================================================

  static BrainCryptoVersion fromValue(
    int value,
  ) {
    for (final version in BrainCryptoVersion.values) {
      if (version.value ==
          value) {
        return version;
      }
    }

    throw ArgumentError(
      'Versão criptográfica não suportada: $value',
    );
  }

  // ============================================================
  // TRY FROM VALUE
  // ============================================================

  static BrainCryptoVersion? tryFromValue(
    int? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    for (final version in BrainCryptoVersion.values) {
      if (version.value ==
          value) {
        return version;
      }
    }

    return null;
  }

  // ============================================================
  // IS CURRENT
  // ============================================================

  bool get isCurrent {
    return this ==
        current;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainCryptoVersion('
        'value: $value'
        ')';
  }
}
