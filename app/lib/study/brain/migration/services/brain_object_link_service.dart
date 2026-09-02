import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/brain_migration_record.dart';
import '../models/brain_migration_status.dart';

// ============================================================
// MIGRATION LINK STORE
// ============================================================
//
// Interface mínima que posteriormente será implementada por:
//
// brain_migration_registry.dart
//
// Enquanto isso, podemos usar a implementação em memória
// durante os testes.
//
// ============================================================

abstract class BrainMigrationLinkStore {
  Future<
    List<
      BrainMigrationRecord
    >
  >
  loadAll();

  Future<
    void
  >
  saveAll(
    List<
      BrainMigrationRecord
    >
    records,
  );
}

// ============================================================
// IN MEMORY STORE
// ============================================================
//
// TESTES / DESENVOLVIMENTO.
//
// NÃO é persistente.
//
// ============================================================

class InMemoryBrainMigrationLinkStore
    implements
        BrainMigrationLinkStore {
  final Map<
    String,
    BrainMigrationRecord
  >
  _records = {};

  @override
  Future<
    List<
      BrainMigrationRecord
    >
  >
  loadAll() async {
    return List<
      BrainMigrationRecord
    >.unmodifiable(
      _records.values,
    );
  }

  @override
  Future<
    void
  >
  saveAll(
    List<
      BrainMigrationRecord
    >
    records,
  ) async {
    _records.clear();

    for (final record in records) {
      _records[record.legacyFingerprint] = record;
    }
  }
}

// ============================================================
// BRAIN OBJECT LINK SERVICE
// ============================================================
//
// Mantém:
//
// fingerprint do legado
//          ↓
// objectId do Vault
//
// O path original NÃO é persistido.
//
// ============================================================

class BrainObjectLinkService {
  BrainObjectLinkService({
    BrainMigrationLinkStore? store,
    DateTime Function()? now,
  }) : _store =
           store ??
           InMemoryBrainMigrationLinkStore(),
       _now =
           now ??
           DateTime.now;

  final BrainMigrationLinkStore _store;

  final DateTime Function() _now;

  final Sha256 _sha256 = Sha256();

  final Map<
    String,
    BrainMigrationRecord
  >
  _records = {};

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    if (_initialized) {
      return;
    }

    final loaded = await _store.loadAll();

    _records.clear();

    for (final record in loaded) {
      record.validate();

      _records[record.legacyFingerprint] = record;
    }

    _initialized = true;
  }

  // ============================================================
  // FINGERPRINT
  // ============================================================

  Future<
    String
  >
  fingerprint({
    required String namespace,
    required String legacyIdentity,
  }) async {
    final normalizedNamespace = namespace.trim();

    final normalizedIdentity = legacyIdentity.trim();

    if (normalizedNamespace.isEmpty) {
      throw ArgumentError(
        'namespace não pode estar vazio.',
      );
    }

    if (normalizedIdentity.isEmpty) {
      throw ArgumentError(
        'legacyIdentity não pode estar vazio.',
      );
    }

    final input =
        '$normalizedNamespace\n'
        '$normalizedIdentity';

    final hash = await _sha256.hash(
      utf8.encode(
        input,
      ),
    );

    final encoded =
        base64UrlEncode(
          hash.bytes,
        ).replaceAll(
          '=',
          '',
        );

    return 'legacy_$encoded';
  }

  // ============================================================
  // FILE FINGERPRINT
  // ============================================================

  Future<
    String
  >
  fingerprintBrainFile(
    String legacyPath,
  ) {
    return fingerprint(
      namespace: BrainMigrationRecord.brainFileEntityType,
      legacyIdentity: legacyPath,
    );
  }

  // ============================================================
  // REVIEW FINGERPRINT
  // ============================================================

  Future<
    String
  >
  fingerprintBrainReview(
    String reviewId,
  ) {
    return fingerprint(
      namespace: BrainMigrationRecord.brainReviewEntityType,
      legacyIdentity: reviewId,
    );
  }

  // ============================================================
  // GET
  // ============================================================

  Future<
    BrainMigrationRecord?
  >
  getRecord(
    String legacyFingerprint,
  ) async {
    await initialize();

    return _records[legacyFingerprint];
  }

  // ============================================================
  // GET OBJECT ID
  // ============================================================

  Future<
    String?
  >
  getObjectId(
    String legacyFingerprint,
  ) async {
    final record = await getRecord(
      legacyFingerprint,
    );

    return record?.objectId;
  }

  // ============================================================
  // CONTAINS
  // ============================================================

  Future<
    bool
  >
  contains(
    String legacyFingerprint,
  ) async {
    await initialize();

    return _records.containsKey(
      legacyFingerprint,
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Future<
    List<
      BrainMigrationRecord
    >
  >
  listRecords() async {
    await initialize();

    final records = _records.values.toList();

    records.sort(
      (
        a,
        b,
      ) => a.createdAt.compareTo(
        b.createdAt,
      ),
    );

    return List<
      BrainMigrationRecord
    >.unmodifiable(
      records,
    );
  }

  // ============================================================
  // REGISTER PENDING
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  registerPending({
    required String legacyFingerprint,
    required String entityType,
  }) async {
    await initialize();

    final existing = _records[legacyFingerprint];

    if (existing !=
        null) {
      if (existing.entityType !=
          entityType) {
        throw StateError(
          'Fingerprint já registrado para outro entityType.',
        );
      }

      return existing;
    }

    final now = _now().toUtc();

    final record = BrainMigrationRecord.pending(
      legacyFingerprint: legacyFingerprint,
      entityType: entityType,
      now: now,
    );

    await _save(
      record,
    );

    return record;
  }

  // ============================================================
  // MARK MIGRATING
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  markMigrating(
    String legacyFingerprint,
  ) async {
    final current = await _require(
      legacyFingerprint,
    );

    final now = _now().toUtc();

    final updated = current.copyWith(
      status: BrainMigrationStatus.migrating,
      updatedAt: now,
      attempts:
          current.attempts +
          1,
      clearErrorMessage: true,
    );

    await _save(
      updated,
    );

    return updated;
  }

  // ============================================================
  // MARK MIGRATED
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  markMigrated({
    required String legacyFingerprint,
    required String objectId,
  }) async {
    final normalizedObjectId = objectId.trim();

    if (normalizedObjectId.isEmpty) {
      throw ArgumentError(
        'objectId não pode estar vazio.',
      );
    }

    final current = await _require(
      legacyFingerprint,
    );

    final now = _now().toUtc();

    final updated = current.copyWith(
      objectId: normalizedObjectId,
      status: BrainMigrationStatus.migrated,
      migratedAt: now,
      updatedAt: now,
      clearValidatedAt: true,
      clearErrorMessage: true,
    );

    await _save(
      updated,
    );

    return updated;
  }

  // ============================================================
  // MARK VALIDATED
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  markValidated(
    String legacyFingerprint,
  ) async {
    final current = await _require(
      legacyFingerprint,
    );

    if (!current.hasObject) {
      throw StateError(
        'Não é possível validar migração sem objectId.',
      );
    }

    final now = _now().toUtc();

    final updated = current.copyWith(
      status: BrainMigrationStatus.validated,
      validatedAt: now,
      updatedAt: now,
      clearErrorMessage: true,
    );

    await _save(
      updated,
    );

    return updated;
  }

  // ============================================================
  // MARK FAILED
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  markFailed({
    required String legacyFingerprint,
    required Object error,
  }) async {
    final current = await _require(
      legacyFingerprint,
    );

    final now = _now().toUtc();

    final message = error.toString().trim();

    final updated = current.copyWith(
      status: BrainMigrationStatus.failed,
      updatedAt: now,
      errorMessage: message.isEmpty
          ? 'Erro desconhecido durante migração.'
          : message,
    );

    await _save(
      updated,
    );

    return updated;
  }

  // ============================================================
  // MARK SKIPPED
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  markSkipped(
    String legacyFingerprint,
  ) async {
    final current = await _require(
      legacyFingerprint,
    );

    final now = _now().toUtc();

    final updated = current.copyWith(
      status: BrainMigrationStatus.skipped,
      updatedAt: now,
      clearErrorMessage: true,
    );

    await _save(
      updated,
    );

    return updated;
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<
    void
  >
  remove(
    String legacyFingerprint,
  ) async {
    await initialize();

    _records.remove(
      legacyFingerprint,
    );

    await _persist();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    await initialize();

    _records.clear();

    await _persist();
  }

  // ============================================================
  // REQUIRE
  // ============================================================

  Future<
    BrainMigrationRecord
  >
  _require(
    String legacyFingerprint,
  ) async {
    await initialize();

    final record = _records[legacyFingerprint];

    if (record ==
        null) {
      throw StateError(
        'Registro de migração não encontrado: '
        '$legacyFingerprint',
      );
    }

    return record;
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _save(
    BrainMigrationRecord record,
  ) async {
    record.validate();

    _records[record.legacyFingerprint] = record;

    await _persist();
  }

  // ============================================================
  // PERSIST
  // ============================================================

  Future<
    void
  >
  _persist() async {
    await _store.saveAll(
      _records.values.toList(
        growable: false,
      ),
    );
  }
}
