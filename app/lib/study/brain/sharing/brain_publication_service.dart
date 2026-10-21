import 'package:supabase_flutter/supabase_flutter.dart';

/// Snapshots publicos intencionais. Nunca publica o Vault privado ou chaves.
class BrainPublicationService {
  BrainPublicationService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String _requireUserId() {
    final id = _client.auth.currentUser?.id;
    if (id == null || id.isEmpty) {
      throw StateError('Entre na sua conta para publicar.');
    }
    return id;
  }

  /// Publicar novamente a mesma nota ATUALIZA o snapshot no mesmo UUID.
  /// Por seguranca, nao vincula snapshots antigos pelo titulo (nao e ID).
  Future<String> publish({
    required String notePath,
    required String title,
    required Map<String, dynamic> snapshot,
    required bool allowImport,
  }) async {
    final ownerId = _requireUserId();
    final path = notePath.trim();
    if (path.isEmpty) {
      throw const FormatException('A nota precisa de um identificador valido.');
    }
    final publication = <String, dynamic>{
      'title': title,
      'snapshot': snapshot,
      'allow_import': allowImport,
      'published': true,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Banco: unique (owner_id, source_note_id). Concorrencia entre dispositivos
    // tambem converge para uma so publicacao e um so link.
    final row = await _client
        .from('brain_publications')
        .upsert({
          'owner_id': ownerId,
          'source_note_id': path,
          ...publication,
        }, onConflict: 'owner_id,source_note_id')
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<List<Map<String, dynamic>>> mine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];
    final result = await _client
        .from('brain_publications')
        .select(
          'id,title,source_note_id,allow_import,published,created_at,updated_at',
        )
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return (result as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  /// Explicitly reuses a legacy public link after the owner chooses it.
  /// Do not infer ownership of an old snapshot merely from its title.
  Future<void> attachLegacyLink({
    required String publicationId,
    required String notePath,
  }) async {
    final ownerId = _requireUserId();
    final path = notePath.trim();
    if (path.isEmpty) throw const FormatException('Nota sem ID.');
    await _client
        .from('brain_publications')
        .update({'source_note_id': path})
        .eq('owner_id', ownerId)
        .eq('id', publicationId)
        .eq('published', true)
        .isFilter('source_note_id', null);
    final linked = await _client
        .from('brain_publications')
        .select('id')
        .eq('owner_id', ownerId)
        .eq('source_note_id', path)
        .maybeSingle();
    if (linked == null || linked['id'] != publicationId) {
      throw StateError('Nao foi possivel vincular o link anterior.');
    }
  }

  Future<void> unpublish(String id) async {
    final ownerId = _requireUserId();
    await _client
        .from('brain_publications')
        .update({
          'published': false,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('owner_id', ownerId)
        .eq('id', id);
  }

  Future<Map<String, dynamic>?> read(String id) async {
    final result = await _client.rpc(
      'get_brain_publication',
      params: {'publication_id': id},
    );
    if (result == null) return null;
    return Map<String, dynamic>.from(result as Map);
  }
}
