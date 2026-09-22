import 'package:supabase_flutter/supabase_flutter.dart';

import '../../vault/services/brain_vault_serializer.dart';

import '../models/brain_remote_deletion_floor.dart';
import '../models/brain_remote_gc.dart';
import '../models/brain_sync_payload.dart';
import '../ports/brain_remote_object_source.dart';

// ============================================================
// BRAIN SUPABASE E2EE SERVICE
// ============================================================
//
// O Supabase recebe SOMENTE:
//
// - metadata técnica;
// - BrainVaultObject serializado já criptografado;
// - tombstone quando excluído.
//
// O Supabase NÃO recebe:
//
// - Master Key;
// - pergunta;
// - resposta;
// - título;
// - conteúdo;
// - sourceNotePath;
// - model lógico.
//
// ============================================================

class BrainSupabaseE2eeService extends BrainRemoteObjectSource {
  BrainSupabaseE2eeService({
    SupabaseClient? client,
    BrainVaultSerializer? serializer,
  }) : _client = client ?? Supabase.instance.client,
       _serializer = serializer ?? const BrainVaultSerializer();

  static const String tableName = 'brain_objects';

  static const String upsertFunctionName = 'upsert_brain_object_e2ee';

  final SupabaseClient _client;
  final BrainVaultSerializer _serializer;

  bool get isAuthenticated {
    return _client.auth.currentUser != null;
  }

  String? get currentUserId {
    return _client.auth.currentUser?.id;
  }

  User _requireUser() {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw StateError('Usuário não autenticado para Brain E2EE.');
    }

    return user;
  }

  // ============================================================
  // UPSERT FROM QUEUE
  // ============================================================

  Future<void> upsertQueuePayload(Map<String, dynamic> queuePayload) async {
    _requireUser();

    final payload = BrainSyncPayload.fromQueuePayload(
      queuePayload,
      serializer: _serializer,
    );

    await upsertPayload(payload);
  }

  // ============================================================
  // UPSERT
  // ============================================================
  //
  // O RPC faz UPSERT monotônico por object_version.
  //
  // Backup antigo / dispositivo atrasado não pode sobrescrever
  // uma versão remota mais nova.
  //
  // ============================================================

  Future<void> upsertPayload(BrainSyncPayload payload) async {
    _requireUser();

    payload.validate(serializer: _serializer);

    await _client.rpc(
      upsertFunctionName,
      params: <String, dynamic>{
        'p_vault_id': payload.vaultId,
        'p_object_id': payload.objectId,
        'p_object_version': payload.objectVersion,
        'p_crypto_version': payload.cryptoVersion,
        'p_key_version': payload.keyVersion,
        'p_is_deleted': payload.isDeleted,
        'p_encrypted_object': payload.encryptedObject,
        'p_created_at': payload.createdAt.toUtc().toIso8601String(),
        'p_updated_at': payload.updatedAt.toUtc().toIso8601String(),
      },
    );
  }


  // ============================================================
  // CONFIRM REMOTE TOMBSTONE FOR LOCAL COMPACTION
  // ============================================================
  //
  // Este RPC nasce na mesma migration que torna tombstones
  // irreversíveis no Cloud. Se a migration ainda não foi aplicada,
  // a chamada falha e a compaction falha fechado.
  //
  // ============================================================

  Future<bool> confirmRemoteTombstone({
    required String vaultId,
    required String objectId,
    required int minimumObjectVersion,
  }) async {
    _requireUser();

    final normalizedVaultId = vaultId.trim();
    final normalizedObjectId = objectId.trim();

    if (normalizedVaultId.isEmpty || normalizedObjectId.isEmpty) {
      return false;
    }

    if (minimumObjectVersion <= 0) {
      throw ArgumentError.value(
        minimumObjectVersion,
        'minimumObjectVersion',
        'A versão deve ser maior que zero.',
      );
    }

    final result = await _client.rpc(
      'confirm_brain_tombstone_for_local_compaction',
      params: <String, dynamic>{
        'p_vault_id': normalizedVaultId,
        'p_object_id': normalizedObjectId,
        'p_min_object_version': minimumObjectVersion,
      },
    );

    return result == true;
  }

  // ============================================================
  // LOAD VAULT OBJECTS
  // ============================================================

  @override
  Future<List<BrainSyncPayload>> loadVaultObjects({
    required String vaultId,
  }) async {
    final user = _requireUser();

    final normalizedVaultId = vaultId.trim();

    if (normalizedVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final rows = await _client
        .from(tableName)
        .select()
        .eq('user_id', user.id)
        .eq('vault_id', normalizedVaultId)
        .order('object_id');

    final result = <BrainSyncPayload>[];

    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);

      result.add(BrainSyncPayload.fromRemoteRow(row, serializer: _serializer));
    }

    return result;
  }

  // ============================================================
  // PHASE 3 — REMOTE DELETION FLOORS / DEVICE ACKS / GC
  // ============================================================

  @override
  Future<List<BrainRemoteDeletionFloor>> loadDeletionFloors({
    required String vaultId,
  }) async {
    final user = _requireUser();
    final normalizedVaultId = vaultId.trim();
    if (normalizedVaultId.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    final rows = await _client
        .from('brain_deletion_floors')
        .select('vault_id,object_id,object_version,deleted_at,compacted_at')
        .eq('user_id', user.id)
        .eq('vault_id', normalizedVaultId)
        .order('object_id');

    return rows
        .map((row) => BrainRemoteDeletionFloor.fromMap(
              Map<String, dynamic>.from(row),
            ))
        .toList(growable: false);
  }

  Future<int> acknowledgeDeletionObservations({
    required String vaultId,
    required String deviceId,
    required String authorizationSecretBase64,
    required List<BrainDeletionObservation> observations,
  }) async {
    _requireUser();
    if (observations.isEmpty) return 0;

    final result = await _client.rpc(
      'acknowledge_brain_tombstones',
      params: <String, dynamic>{
        'p_vault_id': vaultId.trim(),
        'p_device_id': deviceId.trim(),
        'p_auth_secret': authorizationSecretBase64,
        'p_observations': observations.map((item) => item.toMap()).toList(),
      },
    );

    return result is int ? result : int.tryParse(result.toString()) ?? 0;
  }

  Future<List<BrainRemoteGcCandidate>> loadRemoteGcCandidates({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
    required int retentionDays,
    required int limit,
  }) async {
    _requireUser();

    final result = await _client.rpc(
      'list_brain_remote_gc_candidates',
      params: <String, dynamic>{
        'p_vault_id': vaultId.trim(),
        'p_requester_device_id': requesterDeviceId.trim(),
        'p_requester_secret': requesterAuthorizationSecretBase64,
        'p_retention_days': retentionDays,
        'p_limit': limit,
      },
    );

    if (result == null) return const <BrainRemoteGcCandidate>[];
    if (result is! List) {
      throw const FormatException('Lista de candidatos de GC remoto inválida.');
    }

    return result
        .map((row) => BrainRemoteGcCandidate.fromMap(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  }

  Future<bool> garbageCollectRemoteTombstone({
    required String vaultId,
    required String objectId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
    required int retentionDays,
  }) async {
    _requireUser();

    final result = await _client.rpc(
      'gc_brain_remote_tombstone',
      params: <String, dynamic>{
        'p_vault_id': vaultId.trim(),
        'p_object_id': objectId.trim(),
        'p_requester_device_id': requesterDeviceId.trim(),
        'p_requester_secret': requesterAuthorizationSecretBase64,
        'p_retention_days': retentionDays,
      },
    );

    return result == true;
  }

}
