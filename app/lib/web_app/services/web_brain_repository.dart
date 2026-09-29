import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../study/brain/models/brain_concept.dart';
import '../../study/brain/security/crypto/brain_crypto_service.dart';
import '../../study/brain/security/models/brain_crypto_version.dart';
import '../../study/brain/security/models/brain_key_bundle.dart';
import '../../study/brain/sync/models/brain_sync_payload.dart';
import '../../study/brain/sync/services/brain_supabase_e2ee_service.dart';
import '../../study/brain/vault/mappers/brain_concept_vault_mapper.dart';
import '../../study/brain/vault/models/brain_vault_object.dart';
import '../../study/brain/vault/models/brain_vault_object_header.dart';
import '../../study/brain/vault/models/brain_vault_object_type.dart';
import '../../study/brain/vault/models/brain_vault_object_version.dart';
import '../../study/brain/vault/services/brain_vault_id_service.dart';
import '../../study/brain/vault/services/brain_vault_serializer.dart';
import '../models/web_brain_entry.dart';
import 'web_brain_secure_storage.dart';

class WebBrainRepository {
  WebBrainRepository({
    required this.vaultId,
    required WebBrainSecureStorage storage,
    SupabaseClient? client,
  }) : _storage = storage,
       _remote = BrainSupabaseE2eeService(
         client: client ?? Supabase.instance.client,
       );

  final String vaultId;
  final WebBrainSecureStorage _storage;
  final BrainSupabaseE2eeService _remote;
  final BrainCryptoService _crypto = BrainCryptoService();
  final BrainVaultSerializer _serializer = const BrainVaultSerializer();
  final BrainVaultIdService _ids = BrainVaultIdService();
  final BrainConceptVaultMapper _conceptMapper =
      const BrainConceptVaultMapper();
  final Uuid _uuid = const Uuid();

  Future<BrainKeyBundle> _key() async {
    final key = await _storage.loadKeyBundle(vaultId: vaultId);
    if (key == null) {
      throw StateError(
        'Master Key do Brain não está disponível neste navegador.',
      );
    }
    return key;
  }

  Future<List<WebBrainEntry>> loadEntries() async {
    final key = await _key();
    final payloads = await _remote.loadVaultObjects(vaultId: vaultId);
    final result = <WebBrainEntry>[];

    for (final payload in payloads) {
      if (payload.isDeleted) continue;
      try {
        final object = payload.toVaultObject(serializer: _serializer);
        final encrypted = object.encryptedPayload;
        if (encrypted == null) continue;
        final clear = await _crypto.decryptString(
          payload: encrypted,
          keyBundle: key,
        );
        final decoded = _serializer.deserializeLogicalPayload(clear);
        _serializer.verifyBinding(header: object.header, decoded: decoded);

        if (decoded.type != BrainVaultObjectType.concept) continue;
        final concept = _conceptMapper.fromVaultData(decoded.data);
        result.add(
          WebBrainEntry(
            objectId: object.header.objectId,
            title: concept.title,
            description: concept.description,
            type: concept.type,
            updatedAt: object.header.updatedAt.toLocal(),
            reviewEnabled: concept.reviewEnabled,
          ),
        );
      } catch (_) {
        // Um objeto inválido não impede os demais conhecimentos de abrir.
      }
    }

    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<WebBrainEntry>.unmodifiable(result);
  }

  Future<WebBrainEntry> createKnowledge({
    required String title,
    required String description,
    required BrainConceptType type,
    bool reviewEnabled = false,
  }) async {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.isEmpty) throw const FormatException('Informe o título.');
    if (cleanDescription.isEmpty)
      throw const FormatException('Informe o conteúdo.');

    final concept = BrainConcept(
      id: _uuid.v4(),
      title: cleanTitle,
      description: cleanDescription,
      type: type,
      reviewEnabled: reviewEnabled,
    );
    final data = _conceptMapper.toVaultData(concept: concept);
    final object = await _createEncryptedObject(
      type: BrainVaultObjectType.concept,
      data: data,
    );
    await _remote.upsertPayload(
      BrainSyncPayload.fromVaultObject(object: object, serializer: _serializer),
    );

    return WebBrainEntry(
      objectId: object.header.objectId,
      title: concept.title,
      description: concept.description,
      type: concept.type,
      updatedAt: object.header.updatedAt.toLocal(),
      reviewEnabled: concept.reviewEnabled,
    );
  }

  Future<BrainVaultObject> _createEncryptedObject({
    required BrainVaultObjectType type,
    required Map<String, dynamic> data,
  }) async {
    final key = await _key();
    final now = DateTime.now().toUtc();
    final header = BrainVaultObjectHeader(
      objectId: _ids.generateObjectId(),
      vaultId: vaultId,
      objectVersion: BrainVaultObjectVersion.initial,
      cryptoVersion: BrainCryptoVersion.current,
      keyVersion: key.keyVersion,
      createdAt: now,
      updatedAt: now,
    );
    final logical = _serializer.serializeLogicalPayload(
      type: type,
      header: header,
      data: data,
    );
    // Garante que o payload lógico continua sendo JSON válido antes de cifrar.
    jsonDecode(logical);
    final encrypted = await _crypto.encryptString(
      plaintext: logical,
      keyBundle: key,
    );
    return BrainVaultObject.active(header: header, encryptedPayload: encrypted);
  }
}
