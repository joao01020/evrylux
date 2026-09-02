import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/security/crypto/brain_crypto_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_header.dart';
import 'package:EVRYLUX/study/brain/vault/models/brain_vault_object_version.dart';
import 'package:EVRYLUX/study/brain/vault/services/brain_vault_serializer.dart';

void
main() {
  group(
    'BrainVaultSerializer',
    () {
      // ============================================================
      // DEPENDÊNCIAS
      // ============================================================

      const serializer = BrainVaultSerializer();

      late BrainKeyService keyService;

      late BrainCryptoService cryptoService;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () {
          keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          cryptoService = BrainCryptoService();
        },
      );

      // ============================================================
      // SERIALIZE / DESERIALIZE
      // ============================================================

      test(
        'serializa e desserializa BrainVaultObject ativo',
        () async {
          final bundle = keyService.createKeyBundle();

          final now = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          final plaintext = jsonEncode(
            {
              'teste': 'conteúdo',
            },
          );

          final encrypted = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBundle: bundle,
          );

          final header = BrainVaultObjectHeader(
            objectId: 'obj_serializer_001',
            vaultId: 'vault_serializer_001',
            objectVersion: BrainVaultObjectVersion.initial,
            cryptoVersion: encrypted.metadata.version,
            keyVersion: bundle.keyVersion,
            createdAt: now,
            updatedAt: now,
          );

          final object = BrainVaultObject.active(
            header: header,
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          final restored = serializer.deserializeObject(
            serialized,
          );

          expect(
            restored.header.objectId,
            object.header.objectId,
          );

          expect(
            restored.header.vaultId,
            object.header.vaultId,
          );

          expect(
            restored.header.objectVersion.value,
            1,
          );

          expect(
            restored.header.cryptoVersion,
            object.header.cryptoVersion,
          );

          expect(
            restored.header.keyVersion,
            object.header.keyVersion,
          );

          expect(
            restored.header.createdAt,
            object.header.createdAt,
          );

          expect(
            restored.header.updatedAt,
            object.header.updatedAt,
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
      // PLAINTEXT NÃO PODE APARECER
      // ============================================================

      test(
        'serialização física não contém plaintext',
        () async {
          final bundle = keyService.createKeyBundle();

          const secret = 'CONTEUDO_SUPER_SECRETO_EVRYLUX';

          final encrypted = await cryptoService.encryptString(
            plaintext: secret,
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final object = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_secret_001',
              vaultId: 'vault_secret_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          expect(
            serialized.contains(
              secret,
            ),
            false,
          );
        },
      );

      // ============================================================
      // JSON VÁLIDO
      // ============================================================

      test(
        'serializeObject produz JSON válido',
        () async {
          final bundle = keyService.createKeyBundle();

          final encrypted = await cryptoService.encryptString(
            plaintext: 'Teste JSON válido',
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final object = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_json_001',
              vaultId: 'vault_json_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          final decoded = jsonDecode(
            serialized,
          );

          expect(
            decoded,
            isA<
              Map
            >(),
          );
        },
      );

      // ============================================================
      // HEADER VISÍVEL
      // ============================================================

      test(
        'serialização preserva header físico do objeto',
        () async {
          final bundle = keyService.createKeyBundle();

          final encrypted = await cryptoService.encryptString(
            plaintext: 'Payload criptografado',
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
            14,
          );

          final object = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_header_001',
              vaultId: 'vault_header_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          final restored = serializer.deserializeObject(
            serialized,
          );

          expect(
            restored.header.objectId,
            'obj_header_001',
          );

          expect(
            restored.header.vaultId,
            'vault_header_001',
          );

          expect(
            restored.header.objectVersion.value,
            1,
          );

          expect(
            restored.header.keyVersion,
            bundle.keyVersion,
          );
        },
      );

      // ============================================================
      // ENCRYPTED PAYLOAD
      // ============================================================

      test(
        'round trip preserva encrypted payload',
        () async {
          final bundle = keyService.createKeyBundle();

          final encrypted = await cryptoService.encryptString(
            plaintext: 'Payload para round trip',
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final original = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_payload_001',
              vaultId: 'vault_payload_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            original,
          );

          final restored = serializer.deserializeObject(
            serialized,
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
        },
      );

      // ============================================================
      // DADOS SENSÍVEIS
      // ============================================================

      test(
        'serialização não expõe título conteúdo pergunta ou resposta',
        () async {
          final bundle = keyService.createKeyBundle();

          const title = 'TITULO_PRIVADO_SERIALIZER';

          const content = 'CONTEUDO_PRIVADO_SERIALIZER';

          const question = 'PERGUNTA_PRIVADA_SERIALIZER';

          const answer = 'RESPOSTA_PRIVADA_SERIALIZER';

          final plaintext = jsonEncode(
            {
              'title': title,
              'content': content,
              'question': question,
              'answer': answer,
            },
          );

          final encrypted = await cryptoService.encryptString(
            plaintext: plaintext,
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final object = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_private_001',
              vaultId: 'vault_private_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          expect(
            serialized.contains(
              title,
            ),
            false,
          );

          expect(
            serialized.contains(
              content,
            ),
            false,
          );

          expect(
            serialized.contains(
              question,
            ),
            false,
          );

          expect(
            serialized.contains(
              answer,
            ),
            false,
          );
        },
      );

      // ============================================================
      // UNICODE
      // ============================================================

      test(
        'serialização física não expõe plaintext Unicode',
        () async {
          final bundle = keyService.createKeyBundle();

          const secret = 'Olá çãõ — Привет — 日本語 — 🧠🔐';

          final encrypted = await cryptoService.encryptString(
            plaintext: secret,
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final object = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_unicode_001',
              vaultId: 'vault_unicode_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            object,
          );

          expect(
            serialized.contains(
              secret,
            ),
            false,
          );
        },
      );

      // ============================================================
      // ROUND TRIP COMPLETO
      // ============================================================

      test(
        'objeto serializado pode ser descriptografado após round trip',
        () async {
          final bundle = keyService.createKeyBundle();

          const originalPlaintext = 'Conhecimento EVRYLUX persistente e protegido.';

          final encrypted = await cryptoService.encryptString(
            plaintext: originalPlaintext,
            keyBundle: bundle,
          );

          final now = DateTime.utc(
            2026,
            9,
            2,
          );

          final originalObject = BrainVaultObject.active(
            header: BrainVaultObjectHeader(
              objectId: 'obj_decrypt_001',
              vaultId: 'vault_decrypt_001',
              objectVersion: BrainVaultObjectVersion.initial,
              cryptoVersion: encrypted.metadata.version,
              keyVersion: bundle.keyVersion,
              createdAt: now,
              updatedAt: now,
            ),
            encryptedPayload: encrypted,
          );

          final serialized = serializer.serializeObject(
            originalObject,
          );

          final restoredObject = serializer.deserializeObject(
            serialized,
          );

          expect(
            restoredObject.encryptedPayload,
            isNotNull,
          );

          final decrypted = await cryptoService.decryptString(
            payload: restoredObject.encryptedPayload!,
            keyBundle: bundle,
          );

          expect(
            decrypted,
            originalPlaintext,
          );
        },
      );

      // ============================================================
      // JSON INVÁLIDO
      // ============================================================

      test(
        'deserializeObject rejeita JSON inválido',
        () {
          expect(
            () {
              serializer.deserializeObject(
                '{isso_nao_e_json_valido',
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );
    },
  );
}
