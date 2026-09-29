import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../web_app/services/web_brain_secure_storage.dart';
import '../models/brain_review_item.dart';
import '../security/crypto/brain_crypto_service.dart';
import '../security/models/brain_crypto_version.dart';
import '../security/models/brain_key_bundle.dart';
import '../sync/models/brain_sync_payload.dart';
import '../sync/services/brain_supabase_e2ee_service.dart';
import '../vault/mappers/brain_review_vault_mapper.dart';
import '../vault/models/brain_vault_object.dart';
import '../vault/models/brain_vault_object_header.dart';
import '../vault/models/brain_vault_object_type.dart';
import '../vault/models/brain_vault_object_version.dart';
import '../vault/models/brain_vault_tombstone.dart';
import '../vault/services/brain_vault_id_service.dart';
import '../vault/services/brain_vault_serializer.dart';

class _ReviewObject {
  const _ReviewObject(this.object, this.review);
  final BrainVaultObject object;
  final BrainReviewItem review;
}

class ReviewRepository {
  ReviewRepository({WebBrainSecureStorage? storage, SupabaseClient? client})
    : _storage = storage ?? WebBrainSecureStorage(),
      _remote = BrainSupabaseE2eeService(
        client: client ?? Supabase.instance.client,
      );

  final WebBrainSecureStorage _storage;
  final BrainSupabaseE2eeService _remote;
  final BrainCryptoService _crypto = BrainCryptoService();
  final BrainVaultSerializer _serializer = const BrainVaultSerializer();
  final BrainReviewVaultMapper _mapper = const BrainReviewVaultMapper();
  final BrainVaultIdService _ids = BrainVaultIdService();

  bool get isAuthenticated => Supabase.instance.client.auth.currentUser != null;
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<String> _vaultId() async {
    final value = await _storage.loadVaultId();
    if (value == null || value.trim().isEmpty) {
      throw StateError('Vault do Cérebro indisponível neste navegador.');
    }
    return value.trim();
  }

  Future<BrainKeyBundle> _key(String vaultId) async {
    final key = await _storage.loadKeyBundle(vaultId: vaultId);
    if (key == null) {
      throw StateError('Master Key do Cérebro indisponível neste navegador.');
    }
    return key;
  }

  Future<List<_ReviewObject>> _objects() async {
    final vaultId = await _vaultId();
    final key = await _key(vaultId);
    final payloads = await _remote.loadVaultObjects(vaultId: vaultId);
    final result = <_ReviewObject>[];

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
        if (decoded.type != BrainVaultObjectType.review) continue;
        result.add(
          _ReviewObject(
            object,
            _mapper.fromVaultData(Map<String, dynamic>.from(decoded.data)),
          ),
        );
      } catch (_) {}
    }
    return result;
  }

  Future<BrainVaultObject> _write(
    BrainReviewItem review, {
    BrainVaultObject? previous,
  }) async {
    final vaultId = await _vaultId();
    final key = await _key(vaultId);
    final now = DateTime.now().toUtc();
    final header = previous == null
        ? BrainVaultObjectHeader(
            objectId: _ids.generateObjectId(),
            vaultId: vaultId,
            objectVersion: BrainVaultObjectVersion.initial,
            cryptoVersion: BrainCryptoVersion.current,
            keyVersion: key.keyVersion,
            createdAt: now,
            updatedAt: now,
          )
        : previous.header
              .nextVersion(updatedAt: now)
              .copyWith(
                cryptoVersion: BrainCryptoVersion.current,
                keyVersion: key.keyVersion,
              );

    final logical = _serializer.serializeLogicalPayload(
      type: BrainVaultObjectType.review,
      header: header,
      data: _mapper.toVaultData(review),
    );
    jsonDecode(logical);
    final encrypted = await _crypto.encryptString(
      plaintext: logical,
      keyBundle: key,
    );
    final object = BrainVaultObject.active(
      header: header,
      encryptedPayload: encrypted,
    );
    await _remote.upsertPayload(
      BrainSyncPayload.fromVaultObject(object: object, serializer: _serializer),
    );
    return object;
  }

  Future<void> _delete(BrainVaultObject object) async {
    final now = DateTime.now().toUtc();
    final header = object.header.nextVersion(updatedAt: now);
    final deleted = BrainVaultObject.deleted(
      header: header,
      tombstone: BrainVaultTombstone(
        objectId: header.objectId,
        vaultId: header.vaultId,
        objectVersion: header.objectVersion,
        deletedAt: now,
      ),
    );
    await _remote.upsertPayload(
      BrainSyncPayload.fromVaultObject(
        object: deleted,
        serializer: _serializer,
      ),
    );
  }

  Future<void> initialize() async {}

  Future<List<BrainReviewItem>> loadReviews() async {
    final items = (await _objects()).map((e) => e.review).toList();
    items.sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return List<BrainReviewItem>.unmodifiable(items);
  }

  Future<List<BrainReviewItem>> loadLegacyReviews() => loadReviews();
  Future<List<BrainReviewItem>> refreshFromRemote() => loadReviews();
  Future<List<BrainReviewItem>> importLegacyLocalReviews() => loadReviews();

  Future<BrainReviewItem> saveReview(BrainReviewItem review) async {
    final clean = review.id.trim();
    if (clean.isEmpty) throw StateError('Revisão sem ID.');
    BrainVaultObject? previous;
    for (final item in await _objects()) {
      if (item.review.id == clean) {
        previous = item.object;
        break;
      }
    }
    await _write(review, previous: previous);
    return review;
  }

  Future<void> saveReviews(List<BrainReviewItem> reviews) async {
    for (final review in reviews) {
      await saveReview(review);
    }
  }

  Future<BrainReviewItem?> getReview(String id) async {
    final clean = id.trim();
    for (final item in await _objects()) {
      if (item.review.id == clean) return item.review;
    }
    return null;
  }

  Future<BrainReviewItem?> getReviewByConceptId(String conceptId) async {
    final clean = conceptId.trim();
    for (final item in await _objects()) {
      if (item.review.conceptId == clean) return item.review;
    }
    return null;
  }

  Future<bool> hasReviewForConcept(String conceptId) async =>
      (await getReviewByConceptId(conceptId)) != null;

  Future<List<BrainReviewItem>> loadDueReviews({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    final all = await loadReviews();
    return all
        .where((r) => !r.archived && !r.nextReviewAt.isAfter(ref))
        .toList();
  }

  Future<List<BrainReviewItem>> loadUpcomingReviews({DateTime? now}) async {
    final ref = now ?? DateTime.now();
    final all = await loadReviews();
    return all
        .where((r) => !r.archived && r.nextReviewAt.isAfter(ref))
        .toList();
  }

  Future<List<BrainReviewItem>> loadActiveReviews() async =>
      (await loadReviews()).where((r) => !r.archived).toList();

  Future<List<BrainReviewItem>> loadArchivedReviews() async =>
      (await loadReviews()).where((r) => r.archived).toList();

  Future<BrainReviewItem> updateNextReview({
    required BrainReviewItem review,
    required DateTime nextReviewAt,
  }) => saveReview(review.copyWith(nextReviewAt: nextReviewAt));

  Future<BrainReviewItem> archiveReview(BrainReviewItem review) =>
      saveReview(review.copyWith(archived: true, archivedAt: DateTime.now()));

  Future<BrainReviewItem> restoreReview(BrainReviewItem review) => saveReview(
    review.copyWith(
      archived: false,
      clearArchivedAt: true,
      nextReviewAt: DateTime.now(),
    ),
  );

  Future<BrainReviewItem> postponeReview(
    BrainReviewItem review, {
    Duration duration = const Duration(days: 1),
  }) => saveReview(review.copyWith(nextReviewAt: DateTime.now().add(duration)));

  Future<void> deleteReview(String id) async {
    final clean = id.trim();
    for (final item in await _objects()) {
      if (item.review.id == clean) {
        await _delete(item.object);
        return;
      }
    }
  }

  Future<void> deleteReviewByConceptId(String conceptId) async {
    final clean = conceptId.trim();
    for (final item in await _objects()) {
      if (item.review.conceptId == clean) await _delete(item.object);
    }
  }

  Future<void> deleteReviewsBySourceNotePath(String sourceNotePath) async {
    final clean = sourceNotePath.trim();
    for (final item in await _objects()) {
      if (item.review.sourceNotePath == clean) await _delete(item.object);
    }
  }

  Future<int> count() async => (await loadReviews()).length;
}
