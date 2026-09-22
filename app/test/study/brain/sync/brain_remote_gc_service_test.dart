import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/sync/models/brain_remote_gc.dart';
import 'package:EVRYLUX/study/brain/sync/services/brain_remote_gc_service.dart';

void main() {
  group('BrainRemoteGcService Phase 3', () {
    final candidateEligible = BrainRemoteGcCandidate(
      objectId: 'obj_eligible',
      objectVersion: 5,
      deletedUpdatedAt: DateTime.utc(2026, 1, 1),
      serverUpdatedAt: DateTime.utc(2026, 1, 1),
      authorizedDeviceCount: 2,
      acknowledgedDeviceCount: 2,
      eligible: true,
    );

    final candidateBlocked = BrainRemoteGcCandidate(
      objectId: 'obj_blocked',
      objectVersion: 3,
      deletedUpdatedAt: DateTime.utc(2026, 1, 1),
      serverUpdatedAt: DateTime.utc(2026, 1, 1),
      authorizedDeviceCount: 2,
      acknowledgedDeviceCount: 1,
      eligible: false,
    );

    test('dryRun nunca chama purge', () async {
      var purgeCalls = 0;
      final service = BrainRemoteGcService(
        loadCandidates: ({required retentionDays, required limit}) async =>
            <BrainRemoteGcCandidate>[candidateEligible, candidateBlocked],
        purge: ({required objectId, required retentionDays}) async {
          purgeCalls++;
          return true;
        },
      );

      final report = await service.dryRun();

      expect(report.scanned, 2);
      expect(report.eligible, 1);
      expect(report.blockedByDevices, 1);
      expect(report.purged, 0);
      expect(purgeCalls, 0);
    });

    test('collect purga somente candidato elegível', () async {
      final purgedIds = <String>[];
      final service = BrainRemoteGcService(
        loadCandidates: ({required retentionDays, required limit}) async =>
            <BrainRemoteGcCandidate>[candidateEligible, candidateBlocked],
        purge: ({required objectId, required retentionDays}) async {
          purgedIds.add(objectId);
          return true;
        },
      );

      final report = await service.collect();

      expect(purgedIds, <String>['obj_eligible']);
      expect(report.purged, 1);
      expect(report.blockedByDevices, 1);
    });

    test('collect respeita limite por execução', () async {
      final candidates = List<BrainRemoteGcCandidate>.generate(
        4,
        (index) => BrainRemoteGcCandidate(
          objectId: 'obj_$index',
          objectVersion: 2,
          deletedUpdatedAt: DateTime.utc(2026, 1, 1),
          serverUpdatedAt: DateTime.utc(2026, 1, 1),
          authorizedDeviceCount: 1,
          acknowledgedDeviceCount: 1,
          eligible: true,
        ),
      );
      var calls = 0;
      final service = BrainRemoteGcService(
        policy: const BrainRemoteGcPolicy(
          maxCandidatesPerRun: 10,
          maxPurgesPerRun: 2,
        ),
        loadCandidates: ({required retentionDays, required limit}) async =>
            candidates,
        purge: ({required objectId, required retentionDays}) async {
          calls++;
          return true;
        },
      );

      final report = await service.collect();

      expect(calls, 2);
      expect(report.purged, 2);
      expect(report.eligible, 4);
    });
  });
}
