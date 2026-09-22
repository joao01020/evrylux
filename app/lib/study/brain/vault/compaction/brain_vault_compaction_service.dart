import '../models/brain_vault_manifest.dart';
import '../models/brain_vault_object.dart';
import '../storage/brain_vault_storage.dart';
import 'brain_vault_compaction_ledger.dart';
import 'brain_vault_compaction_policy.dart';
import 'brain_vault_compaction_result.dart';

class BrainVaultCompactionSafetySnapshot {
  const BrainVaultCompactionSafetySnapshot({
    required this.hasPendingSync,
    required this.remoteDeletionConfirmed,
    required this.authorizedDevicesCovered,
  });

  const BrainVaultCompactionSafetySnapshot.conservative({
    this.hasPendingSync = false,
  }) : remoteDeletionConfirmed = false,
       authorizedDevicesCovered = false;

  final bool hasPendingSync;
  final bool remoteDeletionConfirmed;
  final bool authorizedDevicesCovered;
}

typedef BrainVaultCompactionSafetyProbe =
    Future<BrainVaultCompactionSafetySnapshot> Function(
      BrainVaultObject tombstone,
    );

class BrainVaultCompactionService {
  BrainVaultCompactionService({
    required BrainVaultStorage storage,
    BrainVaultCompactionPolicy policy = const BrainVaultCompactionPolicy(),
    BrainVaultCompactionSafetyProbe? safetyProbe,
    DateTime Function()? clock,
  }) : _storage = storage,
       _policy = policy,
       _safetyProbe = safetyProbe,
       _clock = clock ?? (() => DateTime.now().toUtc()) {
    _policy.validate();
  }

  final BrainVaultStorage _storage;
  final BrainVaultCompactionPolicy _policy;
  final BrainVaultCompactionSafetyProbe? _safetyProbe;
  final DateTime Function() _clock;

  bool _running = false;

  /// Examina o Vault sem modificar manifest, objetos, ledger ou SyncQueue.
  Future<BrainVaultCompactionResult> dryRun() {
    return _guarded(() => _run(purge: false));
  }

  /// Fase 2: remove fisicamente SOMENTE tombstones locais elegíveis.
  ///
  /// Antes de cada purge:
  /// - revalida o objeto no disco;
  /// - reexecuta o safety probe;
  /// - persiste um version floor local atomicamente;
  /// - só então remove o .evobj com precondições de versão/deletedAt.
  ///
  /// Nenhum registro remoto é removido por este método.
  Future<BrainVaultCompactionResult> compact() {
    return _guarded(() => _run(purge: true));
  }

  Future<T> _guarded<T>(Future<T> Function() action) async {
    if (_running) {
      throw StateError('Já existe uma compaction do Vault em andamento.');
    }
    _running = true;
    try {
      return await action();
    } finally {
      _running = false;
    }
  }

  Future<BrainVaultCompactionResult> _run({required bool purge}) async {
    final manifest = await _requireManifest();
    final objects = await _storage.loadAllObjects();
    final now = _clock().toUtc();

    var ledger = await _storage.loadCompactionLedger(vaultId: manifest.vaultId);
    final entries = <BrainVaultCompactionEntry>[];
    var activeObjects = 0;
    var eligible = 0;
    var purged = 0;
    var manifestNeedsTouch = false;

    for (final object in objects) {
      _validateObjectVault(object, manifest);

      if (object.isActive) {
        activeObjects++;
        continue;
      }

      final tombstone = object.tombstone;
      if (tombstone == null) {
        throw StateError(
          'Objeto ${object.header.objectId} marcado como excluído sem tombstone.',
        );
      }

      var evaluation = await _evaluate(object, now);
      var didPurge = false;

      if (evaluation.reasons.isEmpty) {
        eligible++;
      }

      if (purge && evaluation.reasons.isEmpty) {
        final current = await _storage.loadObject(object.header.objectId);

        if (!_sameTombstone(current, object)) {
          evaluation = evaluation.blockedBy(
            BrainVaultCompactionBlockReason.stateChangedDuringCompaction,
          );
          eligible--;
        } else {
          final freshEvaluation = await _evaluate(current!, _clock().toUtc());
          if (freshEvaluation.reasons.isNotEmpty) {
            evaluation = freshEvaluation;
            eligible--;
          } else {
            final floor = BrainVaultCompactionFloor(
              objectId: current.header.objectId,
              vaultId: current.header.vaultId,
              objectVersion: current.header.objectVersion.value,
              deletedAt: current.tombstone!.deletedAt.toUtc(),
              compactedAt: _clock().toUtc(),
            );

            // Crash safety: o floor é persistido ANTES do delete físico.
            // Se houver crash depois daqui, o próximo pull não esquece a
            // exclusão e uma nova compaction pode terminar o purge.
            ledger = ledger.record(floor);
            await _storage.saveCompactionLedger(ledger);

            didPurge = await _storage.purgeObjectPermanently(
              objectId: current.header.objectId,
              expectedObjectVersion: current.header.objectVersion.value,
              expectedDeletedAt: current.tombstone!.deletedAt,
            );

            if (didPurge) {
              purged++;
              manifestNeedsTouch = true;
            } else {
              evaluation = evaluation.blockedBy(
                BrainVaultCompactionBlockReason.stateChangedDuringCompaction,
              );
              eligible--;
            }
          }
        }
      }

      entries.add(
        BrainVaultCompactionEntry(
          objectId: object.header.objectId,
          objectVersion: object.header.objectVersion.value,
          deletedAt: tombstone.deletedAt.toUtc(),
          age: evaluation.age,
          eligible: evaluation.reasons.isEmpty,
          purged: didPurge,
          blockReasons: List.unmodifiable(evaluation.reasons),
        ),
      );
    }

    if (manifestNeedsTouch) {
      final latestManifest = await _requireManifest();
      final clockNow = _clock().toUtc();
      final manifestFloor =
          latestManifest.updatedAt.isAfter(latestManifest.createdAt)
              ? latestManifest.updatedAt
              : latestManifest.createdAt;
      final safeUpdatedAt =
          clockNow.isAfter(manifestFloor) ? clockNow : manifestFloor;
      await _storage.saveManifest(
        latestManifest.touch(updatedAt: safeUpdatedAt),
      );
    }

    final tombstones = entries.length;
    final retained = purge ? tombstones - purged : tombstones - eligible;

    return BrainVaultCompactionResult(
      totalObjects: objects.length,
      activeObjects: activeObjects,
      tombstones: tombstones,
      retained: retained,
      eligible: eligible,
      purged: purged,
      entries: List.unmodifiable(entries),
    );
  }

  Future<_Evaluation> _evaluate(BrainVaultObject object, DateTime now) async {
    final tombstone = object.tombstone;
    if (!object.isDeleted || tombstone == null) {
      throw StateError('Compaction recebeu objeto ativo ou sem tombstone.');
    }

    final age = _nonNegativeAge(now, tombstone.deletedAt.toUtc());
    final reasons = <BrainVaultCompactionBlockReason>[];

    if (age < _policy.tombstoneRetention) {
      reasons.add(BrainVaultCompactionBlockReason.retentionNotElapsed);
    }

    final safety = await _inspectSafety(object);

    if (safety.hasPendingSync) {
      reasons.add(BrainVaultCompactionBlockReason.pendingSync);
    }

    if (_policy.requireRemoteDeletionConfirmation &&
        !safety.remoteDeletionConfirmed) {
      reasons.add(BrainVaultCompactionBlockReason.remoteDeletionNotConfirmed);
    }

    if (_policy.requireAuthorizedDeviceCoverage &&
        !safety.authorizedDevicesCovered) {
      reasons.add(
        BrainVaultCompactionBlockReason.authorizedDeviceCoverageUnknown,
      );
    }

    return _Evaluation(age: age, reasons: reasons);
  }

  Future<BrainVaultManifest> _requireManifest() async {
    final manifest = await _storage.loadManifest();
    if (manifest == null) {
      throw StateError('Nenhum Vault foi inicializado.');
    }
    manifest.validate();
    return manifest;
  }

  void _validateObjectVault(
    BrainVaultObject object,
    BrainVaultManifest manifest,
  ) {
    if (object.header.vaultId != manifest.vaultId) {
      throw StateError(
        'Objeto ${object.header.objectId} pertence a outro Vault.',
      );
    }
  }

  bool _sameTombstone(BrainVaultObject? current, BrainVaultObject expected) {
    if (current == null || !current.isDeleted || current.tombstone == null) {
      return false;
    }
    return current.header.objectId == expected.header.objectId &&
        current.header.vaultId == expected.header.vaultId &&
        current.header.objectVersion.value == expected.header.objectVersion.value &&
        current.tombstone!.deletedAt.toUtc() ==
            expected.tombstone!.deletedAt.toUtc();
  }

  Future<BrainVaultCompactionSafetySnapshot> _inspectSafety(
    BrainVaultObject tombstone,
  ) async {
    final probe = _safetyProbe;
    if (probe == null) {
      return const BrainVaultCompactionSafetySnapshot.conservative();
    }
    return probe(tombstone);
  }

  Duration _nonNegativeAge(DateTime now, DateTime deletedAt) {
    if (deletedAt.isAfter(now)) {
      return Duration.zero;
    }
    return now.difference(deletedAt);
  }
}

class _Evaluation {
  const _Evaluation({required this.age, required this.reasons});

  final Duration age;
  final List<BrainVaultCompactionBlockReason> reasons;

  _Evaluation blockedBy(BrainVaultCompactionBlockReason reason) {
    if (reasons.contains(reason)) {
      return this;
    }
    return _Evaluation(
      age: age,
      reasons: <BrainVaultCompactionBlockReason>[...reasons, reason],
    );
  }
}
