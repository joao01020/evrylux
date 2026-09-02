// ============================================================
// BRAIN VAULT OBJECT TYPE
// ============================================================
//
// Define os tipos lógicos de objetos que podem existir
// dentro do EVRYLUX Cérebro.
//
// IMPORTANTE:
//
// Este tipo representa a natureza LÓGICA do conteúdo.
//
// O objetivo futuro é que essa informação permaneça dentro
// do conteúdo criptografado sempre que possível.
//
// Não utilizar este enum para criar nomes físicos como:
//
// notes/
// reviews/
// concepts/
//
// No Vault físico todos os objetos devem poder utilizar
// nomes opacos:
//
// <objectId>.evobj
//
// ============================================================

enum BrainVaultObjectType {
  note(
    value: 'note',
  ),

  concept(
    value: 'concept',
  ),

  review(
    value: 'review',
  ),

  externalSource(
    value: 'external_source',
  ),

  generic(
    value: 'generic',
  );

  const BrainVaultObjectType({
    required this.value,
  });

  // ============================================================
  // VALUE
  // ============================================================

  final String value;

  // ============================================================
  // FROM VALUE
  // ============================================================

  static BrainVaultObjectType fromValue(
    String value,
  ) {
    final normalized = value.trim().toLowerCase();

    for (final type in BrainVaultObjectType.values) {
      if (type.value ==
          normalized) {
        return type;
      }
    }

    throw ArgumentError(
      'Tipo de objeto do Vault não suportado: $value',
    );
  }

  // ============================================================
  // TRY FROM VALUE
  // ============================================================

  static BrainVaultObjectType? tryFromValue(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();

    if (normalized.isEmpty) {
      return null;
    }

    for (final type in BrainVaultObjectType.values) {
      if (type.value ==
          normalized) {
        return type;
      }
    }

    return null;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return value;
  }
}
