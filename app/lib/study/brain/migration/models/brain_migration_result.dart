import 'brain_migration_record.dart';
import 'brain_migration_status.dart';

// ============================================================
// BRAIN MIGRATION RESULT
// ============================================================
//
// Resume uma execução de migração.
//
// ============================================================

class BrainMigrationResult {
  const BrainMigrationResult({
    required this.startedAt,
    required this.finishedAt,
    required this.records,
  });

  final DateTime startedAt;

  final DateTime finishedAt;

  final List<
    BrainMigrationRecord
  >
  records;

  // ============================================================
  // FACTORY
  // ============================================================

  factory BrainMigrationResult.fromRecords({
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<
      BrainMigrationRecord
    >
    records,
  }) {
    if (finishedAt.isBefore(
      startedAt,
    )) {
      throw ArgumentError(
        'finishedAt não pode ser anterior a startedAt.',
      );
    }

    return BrainMigrationResult(
      startedAt: startedAt.toUtc(),

      finishedAt: finishedAt.toUtc(),

      records:
          List<
            BrainMigrationRecord
          >.unmodifiable(
            records,
          ),
    );
  }

  // ============================================================
  // COUNTS
  // ============================================================

  int get total {
    return records.length;
  }

  int get validated {
    return records
        .where(
          (
            record,
          ) =>
              record.status ==
              BrainMigrationStatus.validated,
        )
        .length;
  }

  int get migrated {
    return records
        .where(
          (
            record,
          ) =>
              record.status ==
              BrainMigrationStatus.migrated,
        )
        .length;
  }

  int get skipped {
    return records
        .where(
          (
            record,
          ) =>
              record.status ==
              BrainMigrationStatus.skipped,
        )
        .length;
  }

  int get failed {
    return records
        .where(
          (
            record,
          ) =>
              record.status ==
              BrainMigrationStatus.failed,
        )
        .length;
  }

  int get pending {
    return records
        .where(
          (
            record,
          ) =>
              record.status ==
              BrainMigrationStatus.pending,
        )
        .length;
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get hasFailures {
    return failed >
        0;
  }

  bool get isSuccessful {
    return !hasFailures;
  }

  bool get allValidated {
    if (records.isEmpty) {
      return true;
    }

    return records.every(
      (
        record,
      ) =>
          record.status ==
              BrainMigrationStatus.validated ||
          record.status ==
              BrainMigrationStatus.skipped,
    );
  }

  Duration get duration {
    return finishedAt.difference(
      startedAt,
    );
  }

  // ============================================================
  // FAILED RECORDS
  // ============================================================

  List<
    BrainMigrationRecord
  >
  get failedRecords {
    return List<
      BrainMigrationRecord
    >.unmodifiable(
      records.where(
        (
          record,
        ) =>
            record.status ==
            BrainMigrationStatus.failed,
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'started_at': startedAt.toUtc().toIso8601String(),

      'finished_at': finishedAt.toUtc().toIso8601String(),

      'records': records
          .map(
            (
              record,
            ) => record.toJson(),
          )
          .toList(
            growable: false,
          ),

      'summary': {
        'total': total,
        'validated': validated,
        'migrated': migrated,
        'skipped': skipped,
        'failed': failed,
        'pending': pending,
      },
    };
  }
}
