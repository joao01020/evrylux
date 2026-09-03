import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/backup/models/brain_backup_header.dart';
import 'package:EVRYLUX/study/brain/backup/models/brain_backup_package.dart';
import 'package:EVRYLUX/study/brain/backup/services/brain_backup_serializer.dart';

void main() {
  group('BrainBackupSerializer', () {
    const serializer = BrainBackupSerializer();

    test('package faz round-trip', () {
      final package = BrainBackupPackage(
        header: BrainBackupHeader.create(
          vaultId: 'vault_AAAAAAAAAAAAAAAAAAAAAA',
          cryptoVersion: 1,
          keyVersion: 1,
          objectCount: 3,
          createdAt: DateTime.utc(2026, 9, 2, 12),
        ),
        encryptedPayloadObject: '{"encrypted":"yes"}',
      );

      final raw = serializer.serializePackage(package);

      final decoded = serializer.deserializePackage(raw);

      expect(decoded.header.vaultId, package.header.vaultId);

      expect(decoded.header.objectCount, 3);

      expect(decoded.encryptedPayloadObject, package.encryptedPayloadObject);
    });

    test('archive interno faz round-trip', () {
      final raw = serializer.serializeArchive(
        vaultId: 'vault_AAAAAAAAAAAAAAAAAAAAAA',
        objects: const <String>['{"a":1}', '{"b":2}'],
      );

      final decoded = serializer.deserializeArchive(raw);

      expect(decoded.objects.length, 2);

      expect(decoded.objects.first, '{"a":1}');
    });
  });
}
