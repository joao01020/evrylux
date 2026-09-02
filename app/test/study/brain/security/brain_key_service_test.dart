import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

void
main() {
  group(
    'BrainKeyService',
    () {
      test(
        'cria Master Key válida',
        () {
          final service = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          final bundle = service.createKeyBundle();

          expect(
            bundle.masterKeyBytes.length,
            32,
          );

          expect(
            bundle.keyVersion,
            1,
          );

          expect(
            bundle.isValid,
            true,
          );
        },
      );

      test(
        'getOrCreate cria e salva a chave',
        () async {
          final storage = InMemoryBrainKeyStorage();

          final service = BrainKeyService(
            storage: storage,
          );

          final first = await service.getOrCreateKeyBundle(
            vaultId: 'vault-test',
          );

          final second = await service.getOrCreateKeyBundle(
            vaultId: 'vault-test',
          );

          expect(
            second.masterKeyBytes,
            equals(
              first.masterKeyBytes,
            ),
          );

          expect(
            second.keyVersion,
            first.keyVersion,
          );
        },
      );

      test(
        'vaults diferentes recebem chaves diferentes',
        () async {
          final storage = InMemoryBrainKeyStorage();

          final service = BrainKeyService(
            storage: storage,
          );

          final first = await service.getOrCreateKeyBundle(
            vaultId: 'vault-a',
          );

          final second = await service.getOrCreateKeyBundle(
            vaultId: 'vault-b',
          );

          expect(
            first.masterKeyBytes,
            isNot(
              equals(
                second.masterKeyBytes,
              ),
            ),
          );
        },
      );

      test(
        'delete remove a chave',
        () async {
          final storage = InMemoryBrainKeyStorage();

          final service = BrainKeyService(
            storage: storage,
          );

          await service.getOrCreateKeyBundle(
            vaultId: 'vault-test',
          );

          expect(
            await service.hasKeyBundle(
              vaultId: 'vault-test',
            ),
            true,
          );

          await service.deleteKeyBundle(
            vaultId: 'vault-test',
          );

          expect(
            await service.hasKeyBundle(
              vaultId: 'vault-test',
            ),
            false,
          );
        },
      );
    },
  );
}
