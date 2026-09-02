import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_linux_key_storage.dart';
import 'package:EVRYLUX/study/brain/security/models/brain_key_bundle.dart';

// ============================================================
// BRAIN LINUX KEY STORAGE INTEGRATION TEST
// ============================================================
//
// Este teste usa o armazenamento seguro REAL do Linux.
//
// Portanto:
//
// - não usa InMemoryBrainKeyStorage;
// - não usa arquivo;
// - não usa SharedPreferences;
// - não simula persistência.
//
// Fluxo:
//
// storage A
//      ↓
// salva BrainKeyBundle
//
// descarta storage A
//
// storage B
//      ↓
// recupera BrainKeyBundle
//
// ============================================================

void
main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'BrainLinuxKeyStorage integration',
    () {
      const vaultId = 'vault_integration_secure_storage_test';

      final masterKey =
          List<
            int
          >.generate(
            BrainKeyBundle.masterKeyLengthBytes,
            (
              index,
            ) {
              return (index *
                          7 +
                      31) %
                  256;
            },
            growable: false,
          );

      final createdAt = DateTime.utc(
        2026,
        9,
        2,
        18,
        45,
      );

      // ==========================================================
      // CLEANUP
      // ==========================================================

      setUp(
        () async {
          final storage = BrainLinuxKeyStorage();

          await storage.deleteKeyBundle(
            vaultId: vaultId,
          );
        },
      );

      tearDown(
        () async {
          final storage = BrainLinuxKeyStorage();

          await storage.deleteKeyBundle(
            vaultId: vaultId,
          );
        },
      );

      // ==========================================================
      // SAVE + NEW INSTANCE + LOAD
      // ==========================================================

      testWidgets(
        'persiste BrainKeyBundle entre instâncias',
        (
          tester,
        ) async {
          final original = BrainKeyBundle(
            masterKeyBytes: masterKey,
            keyVersion: 1,
            createdAt: createdAt,
          );

          // ======================================================
          // STORAGE INSTANCE A
          // ======================================================

          final storageA = BrainLinuxKeyStorage();

          await storageA.saveKeyBundle(
            vaultId: vaultId,
            bundle: original,
          );

          expect(
            await storageA.containsKeyBundle(
              vaultId: vaultId,
            ),
            true,
          );

          // ======================================================
          // STORAGE INSTANCE B
          // ======================================================
          //
          // Nova instância.
          //
          // Se os dados estivessem apenas em memória,
          // este load não funcionaria.
          //
          // ======================================================

          final storageB = BrainLinuxKeyStorage();

          final restored = await storageB.loadKeyBundle(
            vaultId: vaultId,
          );

          expect(
            restored,
            isNotNull,
          );

          expect(
            restored!.masterKeyBytes,
            original.masterKeyBytes,
          );

          expect(
            restored.keyVersion,
            original.keyVersion,
          );

          expect(
            restored.createdAt.toUtc(),
            original.createdAt.toUtc(),
          );

          expect(
            restored.isValid,
            true,
          );
        },
      );

      // ==========================================================
      // DELETE
      // ==========================================================

      testWidgets(
        'remove BrainKeyBundle do armazenamento seguro',
        (
          tester,
        ) async {
          final bundle = BrainKeyBundle(
            masterKeyBytes: masterKey,
            keyVersion: 1,
            createdAt: createdAt,
          );

          final storage = BrainLinuxKeyStorage();

          await storage.saveKeyBundle(
            vaultId: vaultId,
            bundle: bundle,
          );

          expect(
            await storage.containsKeyBundle(
              vaultId: vaultId,
            ),
            true,
          );

          await storage.deleteKeyBundle(
            vaultId: vaultId,
          );

          expect(
            await storage.containsKeyBundle(
              vaultId: vaultId,
            ),
            false,
          );

          expect(
            await storage.loadKeyBundle(
              vaultId: vaultId,
            ),
            isNull,
          );
        },
      );

      // ==========================================================
      // DIFFERENT VAULTS
      // ==========================================================

      testWidgets(
        'isola Master Keys de Vaults diferentes',
        (
          tester,
        ) async {
          const vaultA = 'vault_secure_test_a';

          const vaultB = 'vault_secure_test_b';

          final storage = BrainLinuxKeyStorage();

          try {
            await storage.deleteKeyBundle(
              vaultId: vaultA,
            );

            await storage.deleteKeyBundle(
              vaultId: vaultB,
            );

            final keyA = BrainKeyBundle(
              masterKeyBytes:
                  List<
                    int
                  >.filled(
                    32,
                    11,
                  ),
              keyVersion: 1,
              createdAt: createdAt,
            );

            final keyB = BrainKeyBundle(
              masterKeyBytes:
                  List<
                    int
                  >.filled(
                    32,
                    22,
                  ),
              keyVersion: 1,
              createdAt: createdAt,
            );

            await storage.saveKeyBundle(
              vaultId: vaultA,
              bundle: keyA,
            );

            await storage.saveKeyBundle(
              vaultId: vaultB,
              bundle: keyB,
            );

            final restoredA = await storage.loadKeyBundle(
              vaultId: vaultA,
            );

            final restoredB = await storage.loadKeyBundle(
              vaultId: vaultB,
            );

            expect(
              restoredA,
              isNotNull,
            );

            expect(
              restoredB,
              isNotNull,
            );

            expect(
              restoredA!.masterKeyBytes,
              keyA.masterKeyBytes,
            );

            expect(
              restoredB!.masterKeyBytes,
              keyB.masterKeyBytes,
            );

            expect(
              restoredA.masterKeyBytes,
              isNot(
                restoredB.masterKeyBytes,
              ),
            );
          } finally {
            await storage.deleteKeyBundle(
              vaultId: vaultA,
            );

            await storage.deleteKeyBundle(
              vaultId: vaultB,
            );
          }
        },
      );
    },
  );
}
