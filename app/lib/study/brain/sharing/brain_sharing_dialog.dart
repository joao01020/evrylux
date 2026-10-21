import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/brain_file.dart';
import '../trails/brain_trail_store.dart';
import 'brain_publication_service.dart';

class BrainSharingDialog extends StatefulWidget {
  const BrainSharingDialog({
    super.key,
    required this.note,
    required this.notes,
  });
  final BrainFile note;
  final List<BrainFile> notes;
  @override
  State<BrainSharingDialog> createState() => _BrainSharingDialogState();
}

class _BrainSharingDialogState extends State<BrainSharingDialog> {
  final _service = BrainPublicationService();
  bool _busy = false;
  bool _includeTrail = false;
  bool _allowImport = true;
  String? _error;
  String? _createdId;
  List<Map<String, dynamic>> _mine = [];
  bool _showLegacy = false;
  Map<String, dynamic>? _trail;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final trails = await BrainTrailStore().load();
      Map<String, dynamic>? matched;
      for (final trail in trails) {
        if (trail['root_object_id'] == widget.note.path) {
          matched = trail;
          break;
        }
      }
      final mine = await _service.mine();
      if (mounted)
        setState(() {
          _trail = matched;
          _mine = mine;
          final current = mine.where(
            (row) =>
                row['source_note_id'] == widget.note.path &&
                row['published'] == true,
          );
          _createdId = current.isEmpty ? null : current.first['id'] as String;
        });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _publish() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final noteMap = {for (final note in widget.notes) note.path: note};
      final nodes = <Map<String, dynamic>>[];
      final included = <String>{};
      if (_includeTrail && _trail != null) {
        final raw = (_trail!['nodes'] as List)
            .map((x) => Map<String, dynamic>.from(x as Map))
            .toList();
        // Only export reachable nodes with an existing note. Never export private unrelated notes.
        final root = raw
            .where(
              (x) =>
                  x['parent_node_id'] == null &&
                  x['object_id'] == widget.note.path,
            )
            .toList();
        void visit(
          Map<String, dynamic> node,
          String? parent,
          Set<String> seen,
        ) {
          final nid = node['id'] as String;
          final oid = node['object_id'] as String;
          if (seen.contains(nid) || !noteMap.containsKey(oid)) return;
          final publicId = 'n${nodes.length}';
          nodes.add({
            'id': publicId,
            'parent': parent,
            'title':
                (node['display_name'] as String?)?.trim().isNotEmpty == true
                ? node['display_name']
                : noteMap[oid]!.title,
            'note': {
              'title': noteMap[oid]!.title,
              'content': noteMap[oid]!.content,
            },
          });
          included.add(oid);
          for (final child in raw.where((x) => x['parent_node_id'] == nid)) {
            visit(child, publicId, {...seen, nid});
          }
        }

        for (final rootNode in root) {
          visit(rootNode, null, <String>{});
        }
      }
      if (nodes.isEmpty) {
        nodes.add({
          'id': 'n0',
          'parent': null,
          'title': widget.note.title,
          'note': {'title': widget.note.title, 'content': widget.note.content},
        });
      }
      final id = await _service.publish(
        notePath: widget.note.path,
        title: widget.note.title,
        snapshot: {
          'schema': 1,
          'kind': _includeTrail && _trail != null ? 'trail' : 'note',
          'nodes': nodes,
        },
        allowImport: _allowImport,
      );
      if (mounted) {
        await _initialize();
        if (mounted) setState(() => _createdId = id);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> get _legacyPublished => _mine
      .where((row) => row['published'] == true && row['source_note_id'] == null)
      .toList(growable: false);

  Future<void> _attachLegacy(String id) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.attachLegacyLink(
        publicationId: id,
        notePath: widget.note.path,
      );
      await _initialize();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _unpublish(String id) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _service.unpublish(id);
      await _initialize();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const String _publicOrigin = 'https://web.evrylux-colab.workers.dev';

  String _publicationUrl(String id) =>
      '$_publicOrigin/p/?id=${Uri.encodeQueryComponent(id)}';

  Future<void> _openPublication(String id) async {
    final url = _publicationUrl(id);
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Não foi possível abrir o navegador.');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao abrir o link: $e');
    }
  }

  Widget _publicationLinkWidget(String id) {
    final url = _publicationUrl(id);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SelectableText(
              url,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copiar link',
            onPressed: () => Clipboard.setData(ClipboardData(text: url)),
            icon: const Icon(Icons.copy, size: 18),
          ),
          IconButton(
            tooltip: 'Abrir site',
            onPressed: () => _openPublication(id),
            icon: const Icon(Icons.open_in_new, size: 18),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Compartilhar conhecimento'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privado por padrão. Publicar cria uma cópia pública fixa (snapshot) dos textos selecionados.',
            ),
            if (_trail != null)
              SwitchListTile(
                value: _includeTrail,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _includeTrail = v),
                title: const Text('Incluir toda a Trilha'),
                subtitle: const Text(
                  'Inclui os conceitos e subtópicos alcançáveis da raiz.',
                ),
              ),
            SwitchListTile(
              value: _allowImport,
              onChanged: _busy ? null : (v) => setState(() => _allowImport = v),
              title: const Text('Permitir importação'),
            ),
            const Text(
              'Verifique os textos antes de publicar. Anexos e fontes não são incluídos.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Estado da anotação: '),
                Chip(
                  avatar: Icon(
                    _createdId == null ? Icons.lock_outline : Icons.public,
                    size: 16,
                  ),
                  label: Text(_createdId == null ? 'Privada' : 'Pública'),
                ),
              ],
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Divider(),
            const Text('Link atual da anotação'),
            if (_createdId != null)
              _publicationLinkWidget(_createdId!)
            else
              const Text(
                'Nenhum link atual vinculado. Links antigos podem continuar públicos abaixo.',
              ),
            const SizedBox(height: 6),
            if (_createdId != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _unpublish(_createdId!),
                  icon: const Icon(Icons.link_off),
                  label: const Text('Despublicar nota'),
                ),
              ),
            // Snapshots anteriores nao tem source_note_id, e nao e seguro
            // associar pelo titulo. Eles podem permanecer publicos ate revogar.
            if (_legacyPublished.isNotEmpty) ...[
              const Divider(),
              TextButton.icon(
                onPressed: () => setState(() => _showLegacy = !_showLegacy),
                icon: Icon(_showLegacy ? Icons.expand_less : Icons.expand_more),
                label: Text(
                  'Links antigos ainda ativos (${_legacyPublished.length})',
                ),
              ),
              if (_showLegacy)
                for (final entry in _legacyPublished)
                  ListTile(
                    dense: true,
                    title: Text('${entry['title']}'),
                    subtitle: const Text(
                      'Link antigo ainda público. Despublique se não for necessário.',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_createdId == null &&
                            entry['title'] == widget.note.title)
                          IconButton(
                            tooltip: 'Usar este link para esta nota',
                            onPressed: _busy
                                ? null
                                : () => _attachLegacy(entry['id'] as String),
                            icon: const Icon(Icons.link),
                          ),
                        IconButton(
                          tooltip: 'Despublicar link antigo',
                          onPressed: _busy
                              ? null
                              : () => _unpublish(entry['id'] as String),
                          icon: const Icon(Icons.link_off),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Fechar'),
      ),
      FilledButton(
        onPressed: _busy ? null : _publish,
        child: Text(
          _busy
              ? 'Salvando...'
              : _createdId != null
              ? 'Atualizar publicação'
              : 'Publicar snapshot',
        ),
      ),
    ],
  );
}
