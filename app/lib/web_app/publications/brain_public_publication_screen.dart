import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../study/brain/sharing/brain_public_import_service.dart';
import 'brain_searchable_rich_content.dart';
import '../../study/brain/widgets/brain_rich_content.dart';

/// Public, read-only view. Never accesses the private Brain Vault.
class BrainPublicPublicationScreen extends StatefulWidget {
  const BrainPublicPublicationScreen({super.key, required this.publicationId});
  final String? publicationId;

  @override
  State<BrainPublicPublicationScreen> createState() =>
      _BrainPublicPublicationScreenState();
}

class _BrainPublicPublicationScreenState
    extends State<BrainPublicPublicationScreen> {
  Map<String, dynamic>? _publication;
  bool _loading = true;
  String? _error;
  int _selectedIndex = 0;
  bool _importing = false;
  String? _importMessage;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  bool _showSearch = false;
  int _activeMatch = 0;
  final ScrollController _contentScroll = ScrollController();
  final GlobalKey _searchContentKey = GlobalKey();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _contentScroll.dispose();
    super.dispose();
  }

  String get _searchTerm => _searchController.text.trim();

  List<int> _matchOffsets(String content, String term) {
    if (term.isEmpty) return [];
    final lower = content.toLowerCase();
    final needle = term.toLowerCase();
    final result = <int>[];
    var index = 0;
    while ((index = lower.indexOf(needle, index)) != -1) {
      result.add(index);
      index += needle.length;
      if (result.length >= 5000) break;
    }
    return result;
  }

  String _visibleSearchText(Map<String, dynamic> note) {
    final content = '${note['content'] ?? ''}';
    final segments = BrainRichContentParser.parse(content);
    final plain = segments
        .map((segment) {
          if (segment is BrainCodeSegment) return segment.code;
          return BrainInlineTextParser.parseBold(
            (segment as BrainTextSegment).text,
          ).whereType<TextSpan>().map((s) => s.text ?? '').join();
        })
        .join('\n');
    return '${note['title'] ?? _publication?['title'] ?? ''}\n$plain';
  }

  void _openSearch() {
    setState(() => _showSearch = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _searchController.clear();
      _activeMatch = 0;
    });
  }

  void _onSearchChanged(String _) {
    setState(() => _activeMatch = 0);
    _scrollToMatch();
  }

  void _stepMatch(int direction, int count) {
    if (count == 0) return;
    setState(() => _activeMatch = (_activeMatch + direction + count) % count);
    _scrollToMatch();
  }

  void _scrollToMatch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_contentScroll.hasClients) return;
      final text = _searchTerm;
      if (text.isEmpty) return;
      final selected = _nodes.isEmpty
          ? null
          : _nodes[_selectedIndex.clamp(0, _nodes.length - 1)];
      final note = selected?['note'];
      final map = note is Map
          ? Map<String, dynamic>.from(note)
          : <String, dynamic>{};
      final title = '${map['title'] ?? _publication?['title'] ?? 'Nota'}';
      final titleMatches = _matchOffsets(title, text).length;
      if (_activeMatch < titleMatches) {
        _contentScroll.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        // Scroll to the matching paragraph/code block after layout.
        final state = _searchContentKey.currentState;
        if (state is BrainSearchableRichContentState) {
          state.scrollToMatch(_activeMatch - titleMatches);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final id = widget.publicationId;
    final valid =
        id != null &&
        RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id);
    if (!valid) {
      setState(() {
        _loading = false;
        _error = 'Link inválido ou publicação não informada.';
      });
      return;
    }
    try {
      final response = await Supabase.instance.client.rpc(
        'get_brain_publication',
        params: {'publication_id': id},
      );
      if (!mounted) return;
      setState(() {
        _publication = response is Map
            ? Map<String, dynamic>.from(response)
            : null;
        _loading = false;
        if (_publication == null) {
          _error = 'Publicação não encontrada ou retirada do ar.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível consultar a publicação. Tente novamente.';
      });
    }
  }

  Future<void> _import() async {
    final id = widget.publicationId;
    if (id == null || _importing || _publication?['allow_import'] != true) {
      return;
    }
    if (Supabase.instance.client.auth.currentUser == null) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Entre no EVRYLUX'),
          content: const Text(
            'Para importar, entre na sua conta e conecte/desbloqueie '
            'o Cérebro neste navegador. Depois reabra o link da publicação.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Abrir EVRYLUX'),
            ),
          ],
        ),
      );
      if (go == true) {
        await launchUrl(
          Uri.parse(Uri.base.origin),
          webOnlyWindowName: '_blank',
        );
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Adicionar ao meu Cérebro?'),
        content: Text(
          'Serão criadas ${_nodes.length} nota(s) no seu Vault E2EE, '
          'com novos identificadores. A importação não altera o original. '
          'Você precisa ter o Cérebro desbloqueado neste navegador.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _importing = true;
      _importMessage = null;
    });
    try {
      final result = await BrainPublicImportService().importPublication(id);
      if (!mounted) return;
      setState(() {
        _importMessage = result.previouslyImported
            ? 'Esta publicação já foi importada para seu Cérebro.'
            : '${result.noteCount} nota(s) adicionada(s) ao seu Cérebro. '
                  'Abra o aplicativo para pesquisar ou visualizar a Trilha.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _importMessage = 'Importação não concluída: $e';
      });
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  List<Map<String, dynamic>> get _nodes {
    final snap = _publication?['snapshot'];
    if (snap is! Map || snap['schema'] != 1 || snap['nodes'] is! List) {
      return [];
    }
    final result = <Map<String, dynamic>>[];
    for (final item in snap['nodes'] as List) {
      if (item is Map && item['id'] is String && item['note'] is Map) {
        result.add(Map<String, dynamic>.from(item));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF147D50);
    final nodes = _nodes;
    final selected = nodes.isEmpty
        ? null
        : nodes[_selectedIndex.clamp(0, nodes.length - 1)];
    final note = selected?['note'];
    final noteMap = note is Map
        ? Map<String, dynamic>.from(note)
        : <String, dynamic>{};
    return Scaffold(
      appBar: AppBar(
        title: const Text('EVRYLUX · Conhecimento compartilhado'),
        actions: [
          IconButton(
            tooltip: 'Pesquisar nesta anotação',
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'Copiar link',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: Uri.base.toString()));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Link copiado.')));
            },
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : nodes.isEmpty
          ? const Center(
              child: Text('Esta publicação não contém notas compatíveis.'),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 740;
                final list = _buildList(nodes);
                final content = _buildContent(noteMap, green);
                final layout = compact
                    ? Column(
                        children: [
                          SizedBox(height: 180, child: list),
                          const Divider(height: 1),
                          Expanded(child: content),
                        ],
                      )
                    : Row(
                        children: [
                          SizedBox(width: 280, child: list),
                          const VerticalDivider(width: 1),
                          Expanded(child: content),
                        ],
                      );
                final matches = _matchOffsets(
                  _visibleSearchText(noteMap),
                  _searchTerm,
                ).length;
                if (!_showSearch) return layout;
                return Stack(
                  children: [
                    layout,
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Material(
                        elevation: 3,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(13),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: compact ? constraints.maxWidth - 24 : 380,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search, size: 19),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: compact ? 100 : 155,
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocus,
                                    onChanged: _onSearchChanged,
                                    onSubmitted: (_) => _stepMatch(1, matches),
                                    decoration: const InputDecoration(
                                      hintText: 'Pesquisar',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                Text(
                                  _searchTerm.isEmpty
                                      ? '0 de 0'
                                      : '${matches == 0 ? 0 : _activeMatch + 1} de $matches',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                                IconButton(
                                  tooltip: 'Resultado anterior',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: matches == 0
                                      ? null
                                      : () => _stepMatch(-1, matches),
                                  icon: const Icon(Icons.keyboard_arrow_up),
                                ),
                                IconButton(
                                  tooltip: 'Próximo resultado',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: matches == 0
                                      ? null
                                      : () => _stepMatch(1, matches),
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                ),
                                IconButton(
                                  tooltip: 'Fechar pesquisa',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: _closeSearch,
                                  icon: const Icon(Icons.close),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      bottomNavigationBar: _publication == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_publication!['allow_import'] == true)
                    FilledButton.icon(
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: Text(
                        _importing
                            ? 'Importando para o Cérebro...'
                            : 'Adicionar ao meu Cérebro',
                      ),
                    )
                  else
                    Text(
                      'O autor disponibilizou este conteúdo somente para leitura.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  if (_importMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _importMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> nodes) {
    final ids = {for (final node in nodes) node['id']: node};
    int depth(Map<String, dynamic> node) {
      var count = 0;
      var parent = node['parent'];
      final visited = <dynamic>{node['id']};
      while (parent is String &&
          ids.containsKey(parent) &&
          visited.add(parent) &&
          count < 12) {
        count++;
        parent = ids[parent]!['parent'];
      }
      return count;
    }

    return ListView.builder(
      itemCount: nodes.length,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final indent = depth(node) * 14.0;
        return Padding(
          padding: EdgeInsets.only(left: indent.clamp(0, 168)),
          child: ListTile(
            dense: true,
            selected: index == _selectedIndex,
            leading: const Icon(Icons.description_outlined, size: 18),
            title: Text(
              '${node['title'] ?? 'Nota'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              setState(() {
                _selectedIndex = index;
                _activeMatch = 0;
              });
              if (_contentScroll.hasClients) _contentScroll.jumpTo(0);
              _scrollToMatch();
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> note, Color green) {
    return SelectionArea(
      child: SingleChildScrollView(
        controller: _contentScroll,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrainSearchableTitle(
                  text: '${note['title'] ?? _publication?['title'] ?? 'Nota'}',
                  query: _showSearch ? _searchTerm : '',
                  activeIndex: _activeMatch,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: green,
                  ),
                ),
                const SizedBox(height: 20),
                BrainSearchableRichContent(
                  key: _searchContentKey,
                  content: '${note['content'] ?? ''}',
                  query: _showSearch ? _searchTerm : '',
                  activeMatch:
                      _activeMatch -
                      _matchOffsets(
                        '${note['title'] ?? _publication?['title'] ?? 'Nota'}',
                        _searchTerm,
                      ).length,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
