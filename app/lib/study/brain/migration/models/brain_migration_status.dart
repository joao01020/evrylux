// ============================================================
// BRAIN MIGRATION STATUS
// ============================================================
//
// Representa o estado de uma entidade durante a migração:
//
// legado
//   ↓
// Vault criptografado
//
// ============================================================

enum BrainMigrationStatus {
  pending(
    'pending',
  ),

  migrating(
    'migrating',
  ),

  migrated(
    'migrated',
  ),

  validated(
    'validated',
  ),

  failed(
    'failed',
  ),

  skipped(
    'skipped',
  );

  const BrainMigrationStatus(
    this.value,
  );

  final String value;

  // ============================================================
  // FROM VALUE
  // ============================================================

  static BrainMigrationStatus fromValue(
    String value,
  ) {
    for (final status in values) {
      if (status.value ==
          value) {
        return status;
      }
    }

    throw FormatException(
      'BrainMigrationStatus não suportado: $value',
    );
  }

  // ============================================================
  // TRY FROM VALUE
  // ============================================================

  static BrainMigrationStatus? tryFromValue(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    for (final status in values) {
      if (status.value ==
          value) {
        return status;
      }
    }

    return null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isFinished {
    return this ==
            validated ||
        this ==
            failed ||
        this ==
            skipped;
  }

  bool get isSuccessful {
    return this ==
            migrated ||
        this ==
            validated ||
        this ==
            skipped;
  }

  bool get isFailure {
    return this ==
        failed;
  }
}
