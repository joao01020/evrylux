// ============================================================
// BRAIN VAULT OBJECT VERSION
// ============================================================
//
// Representa a versão monotônica de um objeto do Vault.
//
// Exemplo:
//
// objeto criado
// version = 1
//
// objeto editado
// version = 2
//
// objeto editado novamente
// version = 3
//
// Essa versão será importante posteriormente para:
//
// - sincronização;
// - conflitos;
// - tombstones;
// - múltiplos dispositivos.
//
// NÃO confundir com:
//
// crypto_version
//
// ============================================================

class BrainVaultObjectVersion
    implements
        Comparable<
          BrainVaultObjectVersion
        > {
  const BrainVaultObjectVersion(
    this.value,
  ) : assert(
        value >
            0,
        'Object version deve ser maior que zero.',
      );

  // ============================================================
  // VALUE
  // ============================================================

  final int value;

  // ============================================================
  // INITIAL
  // ============================================================

  static const BrainVaultObjectVersion initial = BrainVaultObjectVersion(
    1,
  );

  // ============================================================
  // NEXT
  // ============================================================

  BrainVaultObjectVersion next() {
    return BrainVaultObjectVersion(
      value +
          1,
    );
  }

  // ============================================================
  // FROM VALUE
  // ============================================================

  factory BrainVaultObjectVersion.fromValue(
    int value,
  ) {
    if (value <=
        0) {
      throw ArgumentError(
        'Object version inválida: $value',
      );
    }

    return BrainVaultObjectVersion(
      value,
    );
  }

  // ============================================================
  // FROM DYNAMIC
  // ============================================================

  factory BrainVaultObjectVersion.fromDynamic(
    dynamic value,
  ) {
    final parsed =
        value
            is int
        ? value
        : int.tryParse(
            value?.toString().trim() ??
                '',
          );

    if (parsed ==
            null ||
        parsed <=
            0) {
      throw const FormatException(
        'Object version inválida.',
      );
    }

    return BrainVaultObjectVersion(
      parsed,
    );
  }

  // ============================================================
  // COMPARE
  // ============================================================

  @override
  int compareTo(
    BrainVaultObjectVersion other,
  ) {
    return value.compareTo(
      other.value,
    );
  }

  bool isNewerThan(
    BrainVaultObjectVersion other,
  ) {
    return value >
        other.value;
  }

  bool isOlderThan(
    BrainVaultObjectVersion other,
  ) {
    return value <
        other.value;
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
            is BrainVaultObjectVersion &&
        other.value ==
            value;
  }

  @override
  int get hashCode {
    return value.hashCode;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainVaultObjectVersion($value)';
  }
}
