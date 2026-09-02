import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/models/brain_crypto_version.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_manifest.dart';

void
main() {
  group(
    'BrainVaultManifest',
    () {
      test(
        'cria manifest válido',
        () {
          final createdAt = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          final manifest = BrainVaultManifest(
            vaultId: 'vault_test_001',
            formatVersion: BrainVaultManifest.currentFormatVersion,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: 1,
            createdAt: createdAt,
            updatedAt: createdAt,
          );

          expect(
            manifest.vaultId,
            'vault_test_001',
          );

          expect(
            manifest.formatVersion,
            BrainVaultManifest.currentFormatVersion,
          );

          expect(
            manifest.cryptoVersion,
            BrainCryptoVersion.current,
          );

          expect(
            manifest.keyVersion,
            1,
          );

          expect(
            manifest.createdAt,
            createdAt,
          );

          expect(
            manifest.updatedAt,
            createdAt,
          );
        },
      );

      test(
        'toJson preserva dados do manifest',
        () {
          final createdAt = DateTime.utc(
            2026,
            9,
            2,
            10,
          );

          final updatedAt = DateTime.utc(
            2026,
            9,
            2,
            11,
          );

          final manifest = BrainVaultManifest(
            vaultId: 'vault_manifest_json',
            formatVersion: BrainVaultManifest.currentFormatVersion,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: 1,
            createdAt: createdAt,
            updatedAt: updatedAt,
          );

          final json = manifest.toJson();

          expect(
            json['vault_id'],
            manifest.vaultId,
          );

          expect(
            json['format_version'],
            BrainVaultManifest.currentFormatVersion,
          );

          expect(
            json['crypto_version'],
            BrainCryptoVersion.current.value,
          );

          expect(
            json['key_version'],
            1,
          );

          expect(
            json['created_at'],
            createdAt.toIso8601String(),
          );

          expect(
            json['updated_at'],
            updatedAt.toIso8601String(),
          );
        },
      );

      test(
        'fromJson recria manifest corretamente',
        () {
          final createdAt = DateTime.utc(
            2026,
            9,
            1,
            8,
          );

          final updatedAt = DateTime.utc(
            2026,
            9,
            2,
            9,
          );

          final original = BrainVaultManifest(
            vaultId: 'vault_round_trip',
            formatVersion: BrainVaultManifest.currentFormatVersion,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: 1,
            createdAt: createdAt,
            updatedAt: updatedAt,
          );

          final restored = BrainVaultManifest.fromJson(
            original.toJson(),
          );

          expect(
            restored.vaultId,
            original.vaultId,
          );

          expect(
            restored.formatVersion,
            original.formatVersion,
          );

          expect(
            restored.cryptoVersion,
            original.cryptoVersion,
          );

          expect(
            restored.keyVersion,
            original.keyVersion,
          );

          expect(
            restored.createdAt,
            original.createdAt,
          );

          expect(
            restored.updatedAt,
            original.updatedAt,
          );
        },
      );

      test(
        'formato possui identificação EVRYLUX',
        () {
          expect(
            BrainVaultManifest.format,
            'evrylux-brain-vault',
          );
        },
      );

      test(
        'format version atual é 1',
        () {
          expect(
            BrainVaultManifest.currentFormatVersion,
            1,
          );
        },
      );

      test(
        'touch atualiza updatedAt sem alterar identidade',
        () {
          final createdAt = DateTime.utc(
            2026,
            9,
            1,
          );

          final original = BrainVaultManifest(
            vaultId: 'vault_touch',
            formatVersion: BrainVaultManifest.currentFormatVersion,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: 1,
            createdAt: createdAt,
            updatedAt: createdAt,
          );

          final touched = original.touch();

          expect(
            touched.vaultId,
            original.vaultId,
          );

          expect(
            touched.createdAt,
            original.createdAt,
          );

          expect(
            touched.formatVersion,
            original.formatVersion,
          );

          expect(
            touched.cryptoVersion,
            original.cryptoVersion,
          );

          expect(
            touched.keyVersion,
            original.keyVersion,
          );

          expect(
            touched.updatedAt.isBefore(
              original.updatedAt,
            ),
            false,
          );
        },
      );

      test(
        'copyWith permite alterar keyVersion',
        () {
          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final original = BrainVaultManifest(
            vaultId: 'vault_key_version',
            formatVersion: BrainVaultManifest.currentFormatVersion,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: 1,
            createdAt: now,
            updatedAt: now,
          );

          final updated = original.copyWith(
            keyVersion: 2,
          );

          expect(
            updated.keyVersion,
            2,
          );

          expect(
            updated.vaultId,
            original.vaultId,
          );
        },
      );
    },
  );
}
