import 'package:supabase_flutter/supabase_flutter.dart';

import '../../vault/services/brain_vault_serializer.dart';

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
}
