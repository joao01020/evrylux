import 'brain_migration_status.dart';

// ============================================================
// BRAIN MIGRATION RECORD
// ============================================================
//
// Representa o vínculo entre:
//
// entidade legada
//      ↓
// fingerprint opaco
//      ↓
// objectId do Vault
//
// IMPORTANTE:
//
// NÃO armazenamos:
//
// - path original;
// - título;
// - conteúdo;
// - pergunta;
// - resposta;
//
// no registry da migração.
//
// ============================================================

class BrainMigrationRecord {
  const BrainMigrationRecord({
    required this.legacyFingerprint,
    required this.entityType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.attempts,
    this.objectId,
    this.migratedAt,
    this.validatedAt,
    this.errorMessage,
  });

  // ============================================================
  // ENTITY TYPES
  // ============================================================

  static const String brainFileEntityType = 'brain_file';

  static const String brainReviewEntityType = 'brain_review';

  // ============================================================
  // DATA
  // ============================================================

  final String legacyFingerprint;

  final String entityType;

  final String? objectId;

  final BrainMigrationStatus status;

  final DateTime createdAt;

  final DateTime updatedAt;

  final DateTime? migratedAt;

  final DateTime? validatedAt;

  final String? errorMessage;

  final int attempts;

  // ============================================================
  // FACTORY — PENDING
  // ============================================================

  factory BrainMigrationRecord.pending({
    required String legacyFingerprint,
    required String entityType,
    required DateTime now,
  }) {
    _validateFingerprint(
      legacyFingerprint,
    );

    _validateEntityType(
      entityType,
    );

    return BrainMigrationRecord(
      legacyFingerprint: legacyFingerprint,
      entityType: entityType,
      status: BrainMigrationStatus.pending,
      createdAt: now.toUtc(),
      updatedAt: now.toUtc(),
      attempts: 0,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasObject {
    return objectId !=
            null &&
        objectId!.trim().isNotEmpty;
  }

  bool get isValidated {
    return status ==
        BrainMigrationStatus.validated;
  }

  bool get hasFailed {
    return status ==
        BrainMigrationStatus.failed;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BrainMigrationRecord copyWith({
    String? legacyFingerprint,
    String? entityType,
    String? objectId,
    bool clearObjectId = false,
    BrainMigrationStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? migratedAt,
    bool clearMigratedAt = false,
    DateTime? validatedAt,
    bool clearValidatedAt = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    int? attempts,
  }) {
    final next = BrainMigrationRecord(
      legacyFingerprint:
          legacyFingerprint ??
          this.legacyFingerprint,

      entityType:
          entityType ??
          this.entityType,

      objectId: clearObjectId
          ? null
          : objectId ??
                this.objectId,

      status:
          status ??
          this.status,

      createdAt:
          createdAt ??
          this.createdAt,

      updatedAt:
          updatedAt ??
          this.updatedAt,

      migratedAt: clearMigratedAt
          ? null
          : migratedAt ??
                this.migratedAt,

      validatedAt: clearValidatedAt
          ? null
          : validatedAt ??
                this.validatedAt,

      errorMessage: clearErrorMessage
          ? null
          : errorMessage ??
                this.errorMessage,

      attempts:
          attempts ??
          this.attempts,
    );

    next.validate();

    return next;
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate() {
    _validateFingerprint(
      legacyFingerprint,
    );

    _validateEntityType(
      entityType,
    );

    if (attempts <
        0) {
      throw const FormatException(
        'BrainMigrationRecord inválido: attempts negativo.',
      );
    }

    if (updatedAt.isBefore(
      createdAt,
    )) {
      throw const FormatException(
        'BrainMigrationRecord inválido: updatedAt anterior a createdAt.',
      );
    }

    if (migratedAt !=
            null &&
        migratedAt!.isBefore(
          createdAt,
        )) {
      throw const FormatException(
        'BrainMigrationRecord inválido: migratedAt anterior a createdAt.',
      );
    }

    if (validatedAt !=
            null &&
        migratedAt !=
            null &&
        validatedAt!.isBefore(
          migratedAt!,
        )) {
      throw const FormatException(
        'BrainMigrationRecord inválido: validatedAt anterior a migratedAt.',
      );
    }

    if ((status ==
                BrainMigrationStatus.migrated ||
            status ==
                BrainMigrationStatus.validated) &&
        !hasObject) {
      throw const FormatException(
        'BrainMigrationRecord migrado precisa possuir objectId.',
      );
    }

    if (status ==
            BrainMigrationStatus.validated &&
        validatedAt ==
            null) {
      throw const FormatException(
        'BrainMigrationRecord validado precisa possuir validatedAt.',
      );
    }
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    validate();

    return {
      'legacy_fingerprint': legacyFingerprint,

      'entity_type': entityType,

      'object_id': objectId,

      'status': status.value,

      'created_at': createdAt.toUtc().toIso8601String(),

      'updated_at': updatedAt.toUtc().toIso8601String(),

      'migrated_at': migratedAt?.toUtc().toIso8601String(),

      'validated_at': validatedAt?.toUtc().toIso8601String(),

      'error_message': errorMessage,

      'attempts': attempts,
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainMigrationRecord.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final record = BrainMigrationRecord(
      legacyFingerprint: _requiredString(
        json['legacy_fingerprint'],
        fieldName: 'legacy_fingerprint',
      ),

      entityType: _requiredString(
        json['entity_type'],
        fieldName: 'entity_type',
      ),

      objectId: _optionalString(
        json['object_id'],
      ),

      status: BrainMigrationStatus.fromValue(
        _requiredString(
          json['status'],
          fieldName: 'status',
        ),
      ),

      createdAt: _requiredDate(
        json['created_at'],
        fieldName: 'created_at',
      ),

      updatedAt: _requiredDate(
        json['updated_at'],
        fieldName: 'updated_at',
      ),

      migratedAt: _optionalDate(
        json['migrated_at'],
        fieldName: 'migrated_at',
      ),

      validatedAt: _optionalDate(
        json['validated_at'],
        fieldName: 'validated_at',
      ),

      errorMessage: _optionalString(
        json['error_message'],
      ),

      attempts: _requiredNonNegativeInt(
        json['attempts'],
        fieldName: 'attempts',
      ),
    );

    record.validate();

    return record;
  }

  // ============================================================
  // VALIDATE FINGERPRINT
  // ============================================================

  static void _validateFingerprint(
    String value,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw const FormatException(
        'legacyFingerprint não pode estar vazio.',
      );
    }

    if (normalized.length <
        16) {
      throw const FormatException(
        'legacyFingerprint inválido.',
      );
    }
  }

  // ============================================================
  // VALIDATE ENTITY TYPE
  // ============================================================

  static void _validateEntityType(
    String value,
  ) {
    if (value !=
            brainFileEntityType &&
        value !=
            brainReviewEntityType) {
      throw FormatException(
        'entityType não suportado: $value',
      );
    }
  }

  // ============================================================
  // PARSERS
  // ============================================================

  static String _requiredString(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed =
        value?.toString().trim() ??
        '';

    if (parsed.isEmpty) {
      throw FormatException(
        '$fieldName não pode estar vazio.',
      );
    }

    return parsed;
  }

  static String? _optionalString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final parsed = value.toString().trim();

    if (parsed.isEmpty) {
      return null;
    }

    return parsed;
  }

  static DateTime _requiredDate(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed = DateTime.tryParse(
      value?.toString().trim() ??
          '',
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido.',
      );
    }

    return parsed.toUtc();
  }

  static DateTime? _optionalDate(
    dynamic value, {
    required String fieldName,
  }) {
    if (value ==
        null) {
      return null;
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(
      raw,
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido.',
      );
    }

    return parsed.toUtc();
  }

  static int _requiredNonNegativeInt(
    dynamic value, {
    required String fieldName,
  }) {
    final int? parsed;

    if (value
        is int) {
      parsed = value;
    } else {
      parsed = int.tryParse(
        value?.toString().trim() ??
            '',
      );
    }

    if (parsed ==
            null ||
        parsed <
            0) {
      throw FormatException(
        '$fieldName inválido.',
      );
    }

    return parsed;
  }
}
