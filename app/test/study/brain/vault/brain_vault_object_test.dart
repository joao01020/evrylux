import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/models/brain_crypto_metadata.dart';
import 'package:EVRYLUX/study/brain/security/models/brain_crypto_version.dart';
import 'package:EVRYLUX/study/brain/security/models/brain_encrypted_payload.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_header.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_version.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_tombstone.dart';

void
main() {
  group(
    'BrainVaultObject',
    () {
      late DateTime createdAt;

      late BrainVaultObjectHeader header;

      late BrainEncryptedPayload payload;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () {
          createdAt = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          header = BrainVaultObjectHeader(
            objectId: 'obj_test_001',
            vaultId: 'vault_test_001',

            objectVersion: BrainVaultObjectVersion.initial,

            cryptoVersion: BrainCryptoVersion.current,

            keyVersion: 1,

            createdAt: createdAt,

            updatedAt: createdAt,
          );

          payload = BrainEncryptedPayload(
            cipherText:
                List<
                  int
                >.generate(
                  32,
                  (
                    index,
                  ) => index,
                ),

            nonce:
                List<
                  int
                >.generate(
                  24,
                  (
                    index,
                  ) =>
                      index +
                      1,
                ),

            mac:
                List<
                  int
                >.generate(
                  16,
                  (
                    index,
                  ) =>
                      index +
                      2,
                ),

            metadata: BrainCryptoMetadata(
              version: BrainCryptoVersion.current,

              algorithm: 'xchacha20-poly1305',

              createdAt: createdAt,
            ),
          );
        },
      );

      // ============================================================
      // ACTIVE OBJECT
      // ============================================================

      test(
        'cria objeto ativo',
        () {
          final object = BrainVaultObject.active(
            header: header,
            encryptedPayload: payload,
          );

          expect(
            object.isActive,
            true,
          );

          expect(
            object.isDeleted,
            false,
          );

          expect(
            object.encryptedPayload,
            isNotNull,
          );

          expect(
            object.tombstone,
            isNull,
          );
        },
      );

      // ============================================================
      // HEADER
      // ============================================================

      test(
        'objeto ativo preserva header',
        () {
          final object = BrainVaultObject.active(
            header: header,
            encryptedPayload: payload,
          );

          expect(
            object.header.objectId,
            'obj_test_001',
          );

          expect(
            object.header.vaultId,
            'vault_test_001',
          );

          expect(
            object.header.objectVersion.value,
            1,
          );

          expect(
            object.header.cryptoVersion,
            BrainCryptoVersion.current,
          );

          expect(
            object.header.keyVersion,
            1,
          );

          expect(
            object.header.createdAt,
            createdAt,
          );

          expect(
            object.header.updatedAt,
            createdAt,
          );
        },
      );

      // ============================================================
      // TOMBSTONE
      // ============================================================

      test(
        'cria tombstone',
        () {
          final deletedAt = DateTime.utc(
            2026,
            9,
            3,
          );

          final version = BrainVaultObjectVersion(
            2,
          );

          final tombstone = BrainVaultTombstone(
            objectId: header.objectId,

            vaultId: header.vaultId,

            objectVersion: version,

            deletedAt: deletedAt,
          );

          final deletedHeader = BrainVaultObjectHeader(
            objectId: header.objectId,

            vaultId: header.vaultId,

            objectVersion: version,

            cryptoVersion: BrainCryptoVersion.current,

            keyVersion: 1,

            createdAt: header.createdAt,

            updatedAt: deletedAt,
          );

          final object = BrainVaultObject.deleted(
            header: deletedHeader,

            tombstone: tombstone,
          );

          expect(
            object.isDeleted,
            true,
          );

          expect(
            object.isActive,
            false,
          );

          expect(
            object.encryptedPayload,
            isNull,
          );

          expect(
            object.tombstone,
            isNotNull,
          );

          expect(
            object.tombstone!.objectVersion.value,
            2,
          );

          expect(
            object.tombstone!.objectId,
            header.objectId,
          );

          expect(
            object.tombstone!.vaultId,
            header.vaultId,
          );

          expect(
            object.tombstone!.deletedAt,
            deletedAt,
          );
        },
      );

      // ============================================================
      // ACTIVE JSON ROUND TRIP
      // ============================================================

      test(
        'round trip JSON preserva objeto ativo',
        () {
          final original = BrainVaultObject.active(
            header: header,

            encryptedPayload: payload,
          );

          final json = original.toJson();

          final restored = BrainVaultObject.fromJson(
            json,
          );

          expect(
            restored.header.objectId,
            original.header.objectId,
          );

          expect(
            restored.header.vaultId,
            original.header.vaultId,
          );

          expect(
            restored.header.objectVersion.value,
            1,
          );

          expect(
            restored.header.cryptoVersion,
            original.header.cryptoVersion,
          );

          expect(
            restored.header.keyVersion,
            original.header.keyVersion,
          );

          expect(
            restored.header.createdAt,
            original.header.createdAt,
          );

          expect(
            restored.header.updatedAt,
            original.header.updatedAt,
          );

          expect(
            restored.isActive,
            true,
          );

          expect(
            restored.isDeleted,
            false,
          );

          expect(
            restored.encryptedPayload,
            isNotNull,
          );

          expect(
            restored.tombstone,
            isNull,
          );
        },
      );

      // ============================================================
      // ENCRYPTED PAYLOAD ROUND TRIP
      // ============================================================

      test(
        'round trip JSON preserva encrypted payload',
        () {
          final original = BrainVaultObject.active(
            header: header,

            encryptedPayload: payload,
          );

          final restored = BrainVaultObject.fromJson(
            original.toJson(),
          );

          expect(
            restored.encryptedPayload,
            isNotNull,
          );

          expect(
            restored.encryptedPayload!.cipherText,
            original.encryptedPayload!.cipherText,
          );

          expect(
            restored.encryptedPayload!.nonce,
            original.encryptedPayload!.nonce,
          );

          expect(
            restored.encryptedPayload!.mac,
            original.encryptedPayload!.mac,
          );

          expect(
            restored.encryptedPayload!.metadata.version,
            original.encryptedPayload!.metadata.version,
          );

          expect(
            restored.encryptedPayload!.metadata.algorithm,
            original.encryptedPayload!.metadata.algorithm,
          );

          expect(
            restored.encryptedPayload!.metadata.createdAt,
            original.encryptedPayload!.metadata.createdAt,
          );
        },
      );

      // ============================================================
      // TOMBSTONE JSON ROUND TRIP
      // ============================================================

      test(
        'round trip JSON preserva tombstone',
        () {
          final version = BrainVaultObjectVersion(
            2,
          );

          final deletedAt = DateTime.utc(
            2026,
            9,
            3,
          );

          final deletedHeader = BrainVaultObjectHeader(
            objectId: header.objectId,

            vaultId: header.vaultId,

            objectVersion: version,

            cryptoVersion: BrainCryptoVersion.current,

            keyVersion: 1,

            createdAt: header.createdAt,

            updatedAt: deletedAt,
          );

          final original = BrainVaultObject.deleted(
            header: deletedHeader,

            tombstone: BrainVaultTombstone(
              objectId: header.objectId,

              vaultId: header.vaultId,

              objectVersion: version,

              deletedAt: deletedAt,
            ),
          );

          final restored = BrainVaultObject.fromJson(
            original.toJson(),
          );

          expect(
            restored.isDeleted,
            true,
          );

          expect(
            restored.isActive,
            false,
          );

          expect(
            restored.encryptedPayload,
            isNull,
          );

          expect(
            restored.tombstone,
            isNotNull,
          );

          expect(
            restored.tombstone!.objectId,
            original.header.objectId,
          );

          expect(
            restored.tombstone!.vaultId,
            original.header.vaultId,
          );

          expect(
            restored.tombstone!.objectVersion.value,
            2,
          );

          expect(
            restored.tombstone!.deletedAt,
            deletedAt,
          );
        },
      );

      // ============================================================
      // VERSION INITIAL
      // ============================================================

      test(
        'BrainVaultObjectVersion initial começa em 1',
        () {
          final version = BrainVaultObjectVersion.initial;

          expect(
            version.value,
            1,
          );
        },
      );

      // ============================================================
      // VERSION NEXT
      // ============================================================

      test(
        'next incrementa versão',
        () {
          final version = BrainVaultObjectVersion.initial;

          final next = version.next();

          expect(
            next.value,
            2,
          );

          expect(
            version.value,
            1,
          );
        },
      );

      // ============================================================
      // MULTIPLE VERSION INCREMENTS
      // ============================================================

      test(
        'next pode incrementar versões sequencialmente',
        () {
          final version1 = BrainVaultObjectVersion.initial;

          final version2 = version1.next();

          final version3 = version2.next();

          expect(
            version1.value,
            1,
          );

          expect(
            version2.value,
            2,
          );

          expect(
            version3.value,
            3,
          );
        },
      );

      // ============================================================
      // VERSION VALUE
      // ============================================================

      test(
        'BrainVaultObjectVersion preserva valor informado',
        () {
          final version = BrainVaultObjectVersion(
            42,
          );

          expect(
            version.value,
            42,
          );
        },
      );
    },
  );
}
