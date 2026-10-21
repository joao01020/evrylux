import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/brain_repository_web.dart';
import '../trails/brain_trail_store.dart';

class BrainImportResult {
  const BrainImportResult({
    required this.noteCount,
    required this.previouslyImported,
  });
  final int noteCount;
  final bool previouslyImported;
}

/// Importa apenas snapshots deliberadamente públicos; nunca acessa o Vault
/// do autor. A criptografia das novas notas usa BrainRepository Web.
class BrainPublicImportService {
  BrainPublicImportService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;
  final BrainRepository _repository = BrainRepository();
  final BrainTrailStore _trailStore = BrainTrailStore();

  Future<BrainImportResult> importPublication(String publicationId) async {
    if (_client.auth.currentUser == null) {
      throw StateError('Faça login no EVRYLUX antes de importar.');
    }
    // Sempre revalidar no servidor: a permissão pode mudar desde a visualização.
    final raw = await _client.rpc(
      'get_brain_publication',
      params: {'publication_id': publicationId},
    );
    if (raw is! Map) {
      throw StateError('A publicação foi removida ou não está disponível.');
    }
    final publication = Map<String, dynamic>.from(raw);
    if (publication['allow_import'] != true) {
      throw StateError('O autor não permite importar esta publicação.');
    }
    final snapshot = publication['snapshot'];
    if (snapshot is! Map ||
        snapshot['schema'] != 1 ||
        snapshot['nodes'] is! List) {
      throw const FormatException('Formato da publicação não suportado.');
    }
    final rawNodes = snapshot['nodes'] as List;
    if (rawNodes.isEmpty || rawNodes.length > 150) {
      throw const FormatException('A publicação deve conter de 1 a 150 notas.');
    }
    final nodes = <Map<String, dynamic>>[];
    final ids = <String>{};
    var totalBytes = 0;
    for (final value in rawNodes) {
      if (value is! Map) {
        throw const FormatException('Item de publicação inválido.');
      }
      final node = Map<String, dynamic>.from(value);
      final id = node['id'];
      final note = node['note'];
      if (id is! String || id.isEmpty || !ids.add(id) || note is! Map) {
        throw const FormatException('Identificadores de publicação inválidos.');
      }
      final data = Map<String, dynamic>.from(note);
      final title = data['title'];
      final content = data['content'];
      if (title is! String ||
          content is! String ||
          title.trim().isEmpty ||
          content.trim().isEmpty) {
        throw const FormatException('Nota sem título ou conteúdo.');
      }
      totalBytes += title.length + content.length;
      if (totalBytes > 1500000) {
        throw const FormatException('Publicação excede o tamanho permitido.');
      }
      nodes.add(node);
    }
    // Valida pais antes de gravar qualquer objeto, evitando uma árvore corrupta.
    final parents = {
      for (final node in nodes) node['id'] as String: node['parent'],
    };
    final roots = nodes.where((n) => n['parent'] == null).toList();
    if (roots.length != 1) {
      throw const FormatException('A publicação deve possuir uma única raiz.');
    }
    for (final node in nodes) {
      final parent = node['parent'];
      if (parent != null && (parent is! String || !ids.contains(parent))) {
        throw const FormatException('A publicação possui pai inválido.');
      }
      final visited = <String>{node['id'] as String};
      var current = parent;
      while (current is String) {
        if (!visited.add(current)) {
          throw const FormatException('Ciclo detectado na Trilha pública.');
        }
        current = parents[current];
      }
    }

    // Um recibo E2EE armazena o progresso para que uma falha de conexão
    // não duplique notas em uma nova tentativa.
    final receipts = await _repository.loadImportMetadata(
      'brain_public_import_v1',
    );
    Map<String, dynamic>? receipt;
    for (final item in receipts) {
      if (item['publication_id'] == publicationId) {
        receipt = item;
        break;
      }
    }
    if (receipt?['complete'] == true) {
      return BrainImportResult(
        noteCount: nodes.length,
        previouslyImported: true,
      );
    }
    final initialReceipt =
        receipt ??
        <String, dynamic>{
          'model': 'brain_public_import_v1',
          'publication_id': publicationId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'note_ids': <String, dynamic>{},
          'complete': false,
        };
    var progress = await _repository.saveImportMetadata(
      initialReceipt,
      vaultObjectId: initialReceipt['_vault_object_id'] as String?,
    );
    final created = Map<String, dynamic>.from(progress['note_ids'] as Map);
    for (final node in nodes) {
      final sourceId = node['id'] as String;
      if (created.containsKey(sourceId)) continue;
      final note = Map<String, dynamic>.from(node['note'] as Map);
      final saved = await _repository.saveNote(
        topic: '',
        title: (note['title'] as String).trim(),
        content: (note['content'] as String).trim(),
      );
      final newId = saved['id']?.toString();
      if (newId == null || newId.isEmpty) {
        throw StateError('Não foi possível confirmar a nota importada.');
      }
      created[sourceId] = newId;
      progress['note_ids'] = created;
      progress = await _repository.saveImportMetadata(
        progress,
        vaultObjectId: progress['_vault_object_id'] as String?,
      );
    }

    if (snapshot['kind'] == 'trail' &&
        nodes.length > 1 &&
        progress['trail_saved'] != true) {
      final root = roots.single;
      final rootId = created[root['id']] as String;
      final trailName =
          '${publication['title'] ?? root['title'] ?? 'Trilha importada'}';
      Map<String, dynamic>? foundTrail;
      final priorTrailObjectId = progress['trail_object_id'];
      if (priorTrailObjectId is String) {
        for (final existing in await _trailStore.load()) {
          if (existing['_vault_object_id'] == priorTrailObjectId) {
            foundTrail = existing;
            break;
          }
        }
      }
      var trail =
          foundTrail ??
          await _trailStore.create(
            rootId,
            trailName,
            _client.auth.currentUser!.id,
          );
      progress['trail_object_id'] = trail['_vault_object_id'];
      progress = await _repository.saveImportMetadata(
        progress,
        vaultObjectId: progress['_vault_object_id'] as String?,
      );
      final pending = nodes.where((n) => n['id'] != root['id']).toList();
      final nodeIds = <String, String>{
        root['id'] as String:
            ((trail['nodes'] as List).single as Map)['id'] as String,
      };
      while (pending.isNotEmpty) {
        final length = pending.length;
        for (final item in pending.toList()) {
          final parent = item['parent'] as String;
          final targetParentId = nodeIds[parent];
          if (targetParentId == null) continue;
          final targetId = created[item['id']] as String;
          final existingNode = (trail['nodes'] as List)
              .cast<Map>()
              .where((n) => n['object_id'] == targetId)
              .toList();
          if (existingNode.isEmpty) {
            trail = await _trailStore.addNode(trail, targetParentId, targetId);
          }
          final added = (trail['nodes'] as List).cast<Map>();
          final newNode = added.firstWhere(
            (n) => n['object_id'] == created[item['id']],
          );
          nodeIds[item['id'] as String] = newNode['id'] as String;
          final alias = '${item['title'] ?? ''}'.trim();
          final original = '${(item['note'] as Map)['title'] ?? ''}'.trim();
          if (alias.isNotEmpty && alias != original) {
            trail = await _trailStore.renameNode(
              trail,
              newNode['id'] as String,
              alias,
            );
          }
          pending.remove(item);
        }
        if (pending.length == length) {
          throw StateError('Não foi possível reconstruir a hierarquia.');
        }
      }
      progress['trail_saved'] = true;
      progress = await _repository.saveImportMetadata(
        progress,
        vaultObjectId: progress['_vault_object_id'] as String?,
      );
    }
    progress['complete'] = true;
    await _repository.saveImportMetadata(
      progress,
      vaultObjectId: progress['_vault_object_id'] as String?,
    );
    return BrainImportResult(
      noteCount: nodes.length,
      previouslyImported: false,
    );
  }
}
