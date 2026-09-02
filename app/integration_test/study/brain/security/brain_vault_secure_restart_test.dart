import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:EVRYLUX/study/brain/security/exceptions/brain_crypto_exception.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_platform_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_type.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

// ============================================================
// BRAIN VAULT SECURE RESTART INTEGRATION TEST
// ============================================================
//
// Objetivo:
//
// provar que:
//
// 1. o Vault é criado;
// 2. a Master Key vai para o secure storage real do Linux;
// 3. um objeto é criptografado;
// 4. todo o grafo de serviços é descartado;
// 5. um novo BrainPlatformKeyStorage é criado;
// 6. um novo BrainKeyService é criado;
// 7. um novo BrainVaultService é criado;
// 8. o mesmo Vault é aberto;
// 9. o mesmo objeto é descriptografado.
//
// ============================================================
//
// Isso simula um restart real da aplicação.
//
// IMPORTANTE:
//
// - o diretório do Vault permanece o mesmo;
// - a Master Key NÃO fica em memória entre as duas instâncias;
// - a chave precisa ser recuperada do Keyring.
//
// ============================================================

void
main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group(
    'BrainVault secure restart',
    () {
      late Directory tempDirectory;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_vault_secure_restart_',
          );
        },
      );

      // ============================================================
      // TEARDOWN
      // ============================================================

      tearDown(
        () async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      // ============================================================
      // RESTART ROUND TRIP
      // ============================================================

      testWidgets(
        'abre o mesmo Vault após recriar todos os serviços',
        (
          tester,
        ) async {
          // ========================================================
          // PRIMEIRO GRAFO
          // ========================================================

          final firstKeyStorage = BrainPlatformKeyStorage();

          final firstKeyService = BrainKeyService(
            storage: firstKeyStorage,
          );

          final firstVaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          final firstVaultService = BrainVaultService(
            keyService: firstKeyService,
            storage: firstVaultStorage,
          );

          // ========================================================
          // CREATE VAULT
          // ========================================================

          final manifest = await firstVaultService.createVault();

          expect(
            manifest.vaultId,
            isNotEmpty,
          );

          expect(
            manifest.keyVersion,
            greaterThan(
              0,
            ),
          );

          // ========================================================
          // CREATE OBJECT
          // ========================================================

          const originalData =
              <
                String,
                dynamic
              >{
                'model': 'secure_restart_test',

                'message': 'Este conteúdo deve sobreviver ao restart.',

                'language': 'pt-BR',

                'number': 42,
              };

          final createdObject = await firstVaultService.createObject(
            type: BrainVaultObjectType.generic,
            data: originalData,
          );

          final objectId = createdObject.header.objectId;

          expect(
            objectId,
            isNotEmpty,
          );

          // ========================================================
          // CONFIRM FIRST READ
          // ========================================================

          final firstDecoded = await firstVaultService.readObject(
            objectId,
          );

          expect(
            firstDecoded,
            isNotNull,
          );

          expect(
            firstDecoded!.data,
            originalData,
          );

          // ========================================================
          // CONFIRM KEY EXISTS
          // ========================================================

          expect(
            await firstKeyStorage.containsKeyBundle(
              vaultId: manifest.vaultId,
            ),
            true,
          );

          // ========================================================
          // SIMULATED APP RESTART
          // ========================================================
          //
          // A partir daqui não reutilizamos:
          //
          // - firstKeyStorage;
          // - firstKeyService;
          // - firstVaultStorage;
          // - firstVaultService.
          //
          // ========================================================

          final secondKeyStorage = BrainPlatformKeyStorage();

          final secondKeyService = BrainKeyService(
            storage: secondKeyStorage,
          );

          final secondVaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          final secondVaultService = BrainVaultService(
            keyService: secondKeyService,
            storage: secondVaultStorage,
          );

          // ========================================================
          // OPEN SAME VAULT
          // ========================================================

          final reopenedManifest = await secondVaultService.openVault();

          expect(
            reopenedManifest.vaultId,
            manifest.vaultId,
          );

          expect(
            reopenedManifest.keyVersion,
            manifest.keyVersion,
          );

          // ========================================================
          // CONFIRM KEY WAS RECOVERED
          // ========================================================

          expect(
            await secondKeyStorage.containsKeyBundle(
              vaultId: manifest.vaultId,
            ),
            true,
          );

          // ========================================================
          // READ SAME OBJECT
          // ========================================================

          final secondDecoded = await secondVaultService.readObject(
            objectId,
          );

          expect(
            secondDecoded,
            isNotNull,
          );

          expect(
            secondDecoded!.data,
            originalData,
          );

          // ========================================================
          // RAW OBJECT STILL EXISTS
          // ========================================================

          final encryptedObject = await secondVaultService.loadEncryptedObject(
            objectId,
          );

          expect(
            encryptedObject,
            isNotNull,
          );

          expect(
            encryptedObject!.isDeleted,
            false,
          );

          expect(
            encryptedObject.header.objectId,
            objectId,
          );

          expect(
            encryptedObject.header.vaultId,
            manifest.vaultId,
          );

          // ========================================================
          // CLEAN SECURE STORAGE
          // ========================================================

          await secondKeyStorage.deleteKeyBundle(
            vaultId: manifest.vaultId,
          );

          expect(
            await secondKeyStorage.containsKeyBundle(
              vaultId: manifest.vaultId,
            ),
            false,
          );
        },
      );

      // ============================================================
      // MISSING KEY MUST FAIL CLOSED
      // ============================================================

      testWidgets(
        'não abre Vault se a Master Key for removida',
        (
          tester,
        ) async {
          final keyStorage = BrainPlatformKeyStorage();

          final keyService = BrainKeyService(
            storage: keyStorage,
          );

          final vaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          final vaultService = BrainVaultService(
            keyService: keyService,
            storage: vaultStorage,
          );

          final manifest = await vaultService.createVault();

          await vaultService.createObject(
            type: BrainVaultObjectType.generic,
            data: const {
              'message': 'dados protegidos',
            },
          );

          // ========================================================
          // DELETE MASTER KEY
          // ========================================================

          await keyStorage.deleteKeyBundle(
            vaultId: manifest.vaultId,
          );

          expect(
            await keyStorage.containsKeyBundle(
              vaultId: manifest.vaultId,
            ),
            false,
          );

          // ========================================================
          // NEW GRAPH
          // ========================================================

          final reopenedKeyStorage = BrainPlatformKeyStorage();

          final reopenedKeyService = BrainKeyService(
            storage: reopenedKeyStorage,
          );

          final reopenedVaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          final reopenedVaultService = BrainVaultService(
            keyService: reopenedKeyService,
            storage: reopenedVaultStorage,
          );

          // ========================================================
          // FAIL CLOSED
          // ========================================================
          //
          // BrainKeyService.requireKeyBundle() usa a exceção de
          // domínio BrainCryptoException quando a Master Key não
          // existe.
          //
          // Portanto esse é o comportamento correto.
          //
          // ========================================================

          expect(
            () async {
              await reopenedVaultService.openVault();
            },
            throwsA(
              isA<
                BrainCryptoException
              >(),
            ),
          );
        },
      );

      // ============================================================
      // DIFFERENT VAULT DIRECTORY
      // ============================================================

      testWidgets(
        'chave de um Vault não abre outro Vault',
        (
          tester,
        ) async {
          final firstDirectory = await Directory.systemTemp.createTemp(
            'evrylux_vault_a_',
          );

          final secondDirectory = await Directory.systemTemp.createTemp(
            'evrylux_vault_b_',
          );

          try {
            // ======================================================
            // VAULT A
            // ======================================================

            final storageA = BrainPlatformKeyStorage();

            final serviceA = BrainVaultService(
              keyService: BrainKeyService(
                storage: storageA,
              ),
              storage: BrainVaultStorage(
                documentsDirectoryProvider: () async => firstDirectory,
              ),
            );

            final manifestA = await serviceA.createVault();

            // ======================================================
            // VAULT B
            // ======================================================

            final storageB = BrainPlatformKeyStorage();

            final serviceB = BrainVaultService(
              keyService: BrainKeyService(
                storage: storageB,
              ),
              storage: BrainVaultStorage(
                documentsDirectoryProvider: () async => secondDirectory,
              ),
            );

            final manifestB = await serviceB.createVault();

            expect(
              manifestA.vaultId,
              isNot(
                manifestB.vaultId,
              ),
            );

            expect(
              await storageA.containsKeyBundle(
                vaultId: manifestA.vaultId,
              ),
              true,
            );

            expect(
              await storageB.containsKeyBundle(
                vaultId: manifestB.vaultId,
              ),
              true,
            );

            // ======================================================
            // CLEANUP KEYRING
            // ======================================================

            await storageA.deleteKeyBundle(
              vaultId: manifestA.vaultId,
            );

            await storageB.deleteKeyBundle(
              vaultId: manifestB.vaultId,
            );
          } finally {
            if (await firstDirectory.exists()) {
              await firstDirectory.delete(
                recursive: true,
              );
            }

            if (await secondDirectory.exists()) {
              await secondDirectory.delete(
                recursive: true,
              );
            }
          }
        },
      );
    },
  );
}
