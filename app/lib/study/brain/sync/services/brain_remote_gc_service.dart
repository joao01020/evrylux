import '../models/brain_remote_gc.dart';

class BrainRemoteGcPolicy {
  const BrainRemoteGcPolicy({
    this.remoteTombstoneRetention = const Duration(days: 180),
    this.maxCandidatesPerRun = 100,
    this.maxPurgesPerRun = 50,
  });

  final Duration remoteTombstoneRetention;
  final int maxCandidatesPerRun;
  final int maxPurgesPerRun;

  int get retentionDays => remoteTombstoneRetention.inDays;

  void validate() {
    if (retentionDays < 30 || retentionDays > 3650) {
      throw ArgumentError('Retenção remota deve ficar entre 30 e 3650 dias.');
    }
    if (maxCandidatesPerRun <= 0 || maxCandidatesPerRun > 500) {
      throw ArgumentError('maxCandidatesPerRun inválido.');
    }
    if (maxPurgesPerRun <= 0 || maxPurgesPerRun > maxCandidatesPerRun) {
      throw ArgumentError('maxPurgesPerRun inválido.');
    }
  }
}

typedef BrainRemoteGcCandidateLoader = Future<List<BrainRemoteGcCandidate>>
    Function({required int retentionDays, required int limit});

typedef BrainRemoteGcPurger = Future<bool> Function({
  required String objectId,
  required int retentionDays,
});

class BrainRemoteGcService {
  BrainRemoteGcService({
    required BrainRemoteGcCandidateLoader loadCandidates,
    required BrainRemoteGcPurger purge,
    BrainRemoteGcPolicy policy = const BrainRemoteGcPolicy(),
  })  : _loadCandidates = loadCandidates,
        _purge = purge,
        _policy = policy {
    _policy.validate();
  }

  final BrainRemoteGcCandidateLoader _loadCandidates;
  final BrainRemoteGcPurger _purge;
  final BrainRemoteGcPolicy _policy;

  bool _running = false;

  Future<BrainRemoteGcReport> dryRun() => _guarded(() async {
        final candidates = await _loadCandidates(
          retentionDays: _policy.retentionDays,
          limit: _policy.maxCandidatesPerRun,
        );
        return _report(candidates: candidates, purged: 0);
      });

  Future<BrainRemoteGcReport> collect() => _guarded(() async {
        final candidates = await _loadCandidates(
          retentionDays: _policy.retentionDays,
          limit: _policy.maxCandidatesPerRun,
        );

        var purged = 0;
        for (final candidate in candidates) {
          if (!candidate.eligible) continue;
          if (purged >= _policy.maxPurgesPerRun) break;

          final didPurge = await _purge(
            objectId: candidate.objectId,
            retentionDays: _policy.retentionDays,
          );
          if (didPurge) purged++;
        }

        return _report(candidates: candidates, purged: purged);
      });

  BrainRemoteGcReport _report({
    required List<BrainRemoteGcCandidate> candidates,
    required int purged,
  }) {
    final eligible = candidates.where((item) => item.eligible).length;
    final blockedByDevices = candidates
        .where((item) => !item.eligible && item.missingAcknowledgements > 0)
        .length;

    return BrainRemoteGcReport(
      scanned: candidates.length,
      eligible: eligible,
      purged: purged,
      blockedByDevices: blockedByDevices,
      candidates: List.unmodifiable(candidates),
    );
  }

  Future<T> _guarded<T>(Future<T> Function() action) async {
    if (_running) {
      throw StateError('GC remoto do Brain já está em andamento.');
    }
    _running = true;
    try {
      return await action();
    } finally {
      _running = false;
    }
  }
}
