import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void
main() {
  test(
    'app_dependencies não registra handlers legados de note/concept',
    () async {
      final file = File(
        'lib/app/dependencies/app_dependencies.dart',
      );

      expect(
        await file.exists(),
        true,
      );

      final raw = await file.readAsString();

      expect(
        raw.contains(
          'entityType: BrainRepository.noteEntityType',
        ),
        false,
      );

      expect(
        raw.contains(
          'entityType: BrainRepository.conceptEntityType',
        ),
        false,
      );

      expect(
        raw.contains(
          'entityType: BrainSyncQueueService.entityType',
        ),
        true,
      );
    },
  );
}
