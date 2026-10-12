import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import 'brain_trail_store.dart';

/// A Trilha é uma visualização de notas reais; não cria pastas ou cópias.
class BrainTrailPanel extends StatefulWidget {
  const BrainTrailPanel({
    super.key,
    required this.currentId,
    required this.notes,
    required this.onOpen,
    required this.onCreateChild,
    this.ownerId,
  });

  final String currentId;
  final List<BrainFile> notes;
  final Future<void> Function(BrainFile note) onOpen;
  final Future<BrainFile?> Function() onCreateChild;
  final String? ownerId;

  @override
  State<BrainTrailPanel> createState() => _BrainTrailPanelState();
}

class _BrainTrailPanelState extends State<BrainTrailPanel> {
  final _store = BrainTrailStore();
  Map<String, dynamic>? _trail;
  bool _loading = true;
  bool _collapsed = false;
  String? _error;
  final Set<String> _folded = <String>{};
  String? _hoveredNode;

  static const _green = Color(0xFF079457);
  static const _line = Color(0xFFC7CDD2);
  static const _indent = 22.0;
  static const _minimumNodeContentWidth = 148.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant BrainTrailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentId != widget.currentId ||
        !_sameNoteSet(oldWidget.notes, widget.notes)) {
      _load();
    }
  }

  bool _sameNoteSet(List<BrainFile> a, List<BrainFile> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    final ids = a.map((note) => note.path).toSet();
    for (final note in b) {
      if (!ids.remove(note.path)) return false;
    }
    return ids.isEmpty;
  }

  Set<String> _existingNoteIds() => widget.notes
      .map((note) => note.path)
      .where((id) => id.trim().isNotEmpty)
      .toSet();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trails = await _store.load();
      Map<String, dynamic>? found;
      for (final trail in trails) {
        if ((trail['nodes'] as List).any(
          (node) => node['object_id'] == widget.currentId,
        )) {
          found = trail;
          break;
        }
      }
      if (found != null) {
        found = await _store.pruneMissingObjects(found, _existingNoteIds());
        // Se a limpeza removeu o vínculo da nota atual por algum motivo,
        // tratamos como trilha ausente para não exibir estado quebrado.
        final stillContainsCurrent = (found['nodes'] as List).any(
          (node) => node['object_id'] == widget.currentId,
        );
        if (!stillContainsCurrent) {
          found = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _trail = found;
        if (found == null) {
          _folded.clear();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  BrainFile? _note(String id) {
    for (final note in widget.notes) {
      if (note.path == id) return note;
    }
    return null;
  }

  String _noteTitle(String id) => _note(id)?.title ?? 'Nota indisponível';

  void _notify(String value) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value)));
    }
  }

  Future<String?> _askName(String label, String initial) async {
    final input = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(label),
          content: TextField(
            autofocus: true,
            controller: input,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nome exibido'),
            onSubmitted: (value) => Navigator.pop(ctx, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, input.text.trim()),
              child: const Text('Salvar'),
            ),
          ],
        ),
      );
    } finally {
      input.dispose();
    }
  }

  Future<void> _createTrail() async {
    final name = await _askName('Criar Trilha', _noteTitle(widget.currentId));
    if (name == null || name.isEmpty) return;
    try {
      final trail = await _store.create(widget.currentId, name, widget.ownerId);
      if (mounted) {
        setState(() => _trail = trail);
      }
    } catch (e) {
      _notify('Não foi possível criar Trilha: $e');
    }
  }

  Future<void> _renameTrail() async {
    if (_trail == null) return;
    final name = await _askName('Renomear Trilha', '${_trail!['name']}');
    if (name == null || name.isEmpty) return;
    try {
      final result = await _store.updateTrail(_trail!, name: name);
      if (mounted) {
        setState(() => _trail = result);
      }
    } catch (e) {
      _notify('Não foi possível renomear Trilha: $e');
    }
  }

  Future<void> _renameNode(Map<String, dynamic> node) async {
    final name = await _askName(
      'Renomear na Trilha',
      (node['display_name'] as String?) ??
          _noteTitle(node['object_id'] as String),
    );
    if (name == null) return;
    try {
      final result = await _store.renameNode(
        _trail!,
        node['id'] as String,
        name,
      );
      if (mounted) {
        setState(() => _trail = result);
      }
    } catch (e) {
      _notify('Não foi possível renomear tópico: $e');
    }
  }

  Future<void> _removeNode(Map<String, dynamic> node) async {
    if (node['parent_node_id'] == null) {
      _notify('A nota raiz não pode ser desvinculada.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular da Trilha?'),
        content: const Text(
          'O tópico e seus subtópicos sairão desta Trilha. '
          'Nenhuma anotação será apagada do Cérebro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final result = await _store.removeBranch(_trail!, node['id'] as String);
      if (mounted) {
        setState(() => _trail = result);
      }
    } catch (e) {
      _notify('Não foi possível desvincular: $e');
    }
  }

  Future<void> _add(String parentId, {required bool existing}) async {
    if (_trail == null) return;
    BrainFile? selected;
    if (existing) {
      final current = _trail!['nodes'] as List;
      final candidates = widget.notes
          .where(
            (note) => !current.any((node) => node['object_id'] == note.path),
          )
          .toList();
      selected = await showDialog<BrainFile>(
        context: context,
        builder: (ctx) {
          var search = '';
          return StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
              title: const Text('Vincular nota existente'),
              content: SizedBox(
                width: 420,
                height: 350,
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar conceito',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => update(() => search = value),
                    ),
                    Expanded(
                      child: ListView(
                        children: candidates
                            .where(
                              (note) => note.title.toLowerCase().contains(
                                search.toLowerCase(),
                              ),
                            )
                            .map(
                              (note) => ListTile(
                                title: Text(note.title),
                                onTap: () => Navigator.pop(ctx, note),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          );
        },
      );
    } else {
      selected = await widget.onCreateChild();
    }
    if (selected == null) return;
    try {
      final result = await _store.addNode(_trail!, parentId, selected.path);
      if (mounted) {
        setState(() {
          _trail = result;
          _folded.remove(parentId);
        });
      }
    } catch (e) {
      _notify('Não foi possível adicionar: $e');
    }
  }

  List<Map<String, dynamic>> _nodes() => (_trail!['nodes'] as List)
      .map((node) => Map<String, dynamic>.from(node as Map))
      .toList();

  List<Map<String, dynamic>> _children(
    List<Map<String, dynamic>> nodes,
    String? parent,
  ) {
    final result = nodes
        .where((node) => node['parent_node_id'] == parent)
        .toList();
    result.sort(
      (a, b) => ((a['position'] as num?)?.toInt() ?? 0).compareTo(
        (b['position'] as num?)?.toInt() ?? 0,
      ),
    );
    return result;
  }

  Widget _nodeAction(Map<String, dynamic> node, {bool prominent = false}) {
    return PopupMenuButton<String>(
      tooltip: 'Opções do tópico',
      padding: EdgeInsets.zero,
      icon: Icon(
        prominent ? Icons.add : Icons.more_horiz,
        color: prominent ? _green : const Color(0xFF6F7882),
        size: prominent ? 23 : 19,
      ),
      onSelected: (action) {
        final id = node['id'] as String;
        switch (action) {
          case 'new':
            _add(id, existing: false);
            break;
          case 'existing':
            _add(id, existing: true);
            break;
          case 'rename':
            _renameNode(node);
            break;
          case 'remove':
            _removeNode(node);
            break;
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'new',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.note_add_outlined),
            title: Text('Criar...'),
          ),
        ),
        const PopupMenuItem(
          value: 'existing',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.link),
            title: Text('Vincular...'),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.edit_outlined),
            title: Text('Renomear'),
          ),
        ),
        if (node['parent_node_id'] != null)
          const PopupMenuItem(
            value: 'remove',
            child: ListTile(
              dense: true,
              leading: Icon(Icons.link_off),
              title: Text('Desvincular'),
            ),
          ),
      ],
    );
  }

  Widget _nodeRow(
    Map<String, dynamic> node,
    List<Map<String, dynamic>> all,
    List<bool> ancestors,
    bool isLast,
    Set<String> visited,
  ) {
    final key = node['id'] as String;
    if (ancestors.length > 32 || !visited.add(key))
      return const SizedBox.shrink();
    final objectId = node['object_id'] as String;
    final note = _note(objectId);
    if (note == null) {
      return const SizedBox.shrink();
    }
    final children = _children(
      all,
      key,
    ).where((child) => _note(child['object_id'] as String) != null).toList();
    final isRoot = node['parent_node_id'] == null;
    final expandable = children.isNotEmpty;
    final open = !_folded.contains(key);
    final active = widget.currentId == objectId;
    final hovered = _hoveredNode == key;
    final displayName = (node['display_name'] as String?)?.trim();
    final text = displayName == null || displayName.isEmpty
        ? note.title
        : displayName;
    final indent = ancestors.length * _indent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredNode = key),
          onExit: (_) => setState(() {
            if (_hoveredNode == key) _hoveredNode = null;
          }),
          child: Stack(
            children: [
              if (!isRoot)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TreeLines(
                        ancestors: ancestors,
                        isLast: isLast,
                        indent: _indent,
                        color: _line,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(left: indent),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? _green.withValues(alpha: 0.11)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 23,
                        height: 42,
                        child: expandable
                            ? IconButton(
                                padding: EdgeInsets.zero,
                                tooltip: open
                                    ? 'Recolher tópicos'
                                    : 'Expandir tópicos',
                                onPressed: () => setState(() {
                                  if (open) {
                                    _folded.add(key);
                                  } else {
                                    _folded.remove(key);
                                  }
                                }),
                                icon: Icon(
                                  open
                                      ? Icons.keyboard_arrow_down
                                      : Icons.chevron_right,
                                  size: 19,
                                ),
                              )
                            : null,
                      ),
                      Icon(
                        isRoot
                            ? Icons.radio_button_checked
                            : expandable
                            ? Icons.folder_outlined
                            : Icons.insert_drive_file_outlined,
                        color: isRoot || active || expandable
                            ? _green
                            : const Color(0xFF727B86),
                        size: isRoot ? 20 : 19,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: InkWell(
                          onTap: () => widget.onOpen(note),
                          borderRadius: BorderRadius.circular(7),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.28,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: active ? const Color(0xFF075F3B) : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (active || hovered)
                        SizedBox(
                          width: 36,
                          child: _nodeAction(node, prominent: true),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (open)
          for (var i = 0; i < children.length; i++)
            _nodeRow(
              children[i],
              all,
              [...ancestors, !isLast],
              i == children.length - 1,
              {...visited},
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final availableWidth = viewportWidth.isFinite ? viewportWidth : 900.0;
    final expandedWidth = (availableWidth * 0.36).clamp(180.0, 300.0);
    // A largura muda de forma atômica: durante AnimatedContainer o Row
    // expandido era renderizado com apenas 52 px e gerava RenderFlex overflow.
    return SizedBox(
      width: _collapsed ? 52 : expandedWidth,
      child: Material(
        color: scheme.surfaceContainerLowest,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      padding: EdgeInsets.zero,
                      tooltip: _collapsed
                          ? 'Mostrar Trilha'
                          : 'Recolher Trilha',
                      icon: Icon(
                        _collapsed ? Icons.chevron_right : Icons.chevron_left,
                        size: 19,
                      ),
                      onPressed: () => setState(() => _collapsed = !_collapsed),
                    ),
                    if (!_collapsed) ...[
                      const Expanded(
                        child: Text(
                          'TRILHA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.9,
                          ),
                        ),
                      ),
                      if (_trail != null)
                        IconButton(
                          onPressed: _renameTrail,
                          tooltip: 'Renomear Trilha',
                          icon: const Icon(Icons.edit_outlined, size: 17),
                        ),
                    ],
                  ],
                ),
              ),
              if (!_collapsed)
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(_error!),
                          ),
                        )
                      : _trail == null
                      ? Center(
                          child: TextButton.icon(
                            onPressed: _createTrail,
                            icon: const Icon(Icons.account_tree_outlined),
                            label: const Text('Criar Trilha'),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final all = _nodes()
                                .where(
                                  (node) =>
                                      _note(node['object_id'] as String) !=
                                      null,
                                )
                                .toList();
                            final roots = _children(all, null);
                            int maxDepth = 0;
                            void measure(
                              String? parent,
                              int depth,
                              Set<String> visited,
                            ) {
                              if (depth > 32) return;
                              for (final node in _children(all, parent)) {
                                final id = node['id'] as String;
                                if (visited.contains(id)) continue;
                                if (depth > maxDepth) maxDepth = depth;
                                measure(id, depth + 1, {...visited, id});
                              }
                            }

                            measure(null, 0, <String>{});
                            final visibleWidth = (constraints.maxWidth - 19)
                                .clamp(0.0, double.infinity);
                            final treeWidth =
                                (maxDepth * _indent + _minimumNodeContentWidth)
                                    .clamp(visibleWidth, double.infinity);
                            return ListView(
                              padding: const EdgeInsets.fromLTRB(9, 4, 10, 20),
                              children: [
                                Text(
                                  '${_trail!['name']}',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: treeWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (var i = 0; i < roots.length; i++)
                                          _nodeRow(
                                            roots[i],
                                            all,
                                            const <bool>[],
                                            i == roots.length - 1,
                                            <String>{},
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TreeLines extends CustomPainter {
  const _TreeLines({
    required this.ancestors,
    required this.isLast,
    required this.indent,
    required this.color,
  });

  final List<bool> ancestors;
  final bool isLast;
  final double indent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;
    final y = size.height / 2;
    for (var i = 0; i < ancestors.length - 1; i++) {
      if (!ancestors[i]) continue;
      final x = (i + 1) * indent - indent / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pen);
    }
    final depth = ancestors.length;
    if (depth == 0) return;
    final x = depth * indent - indent / 2;
    canvas.drawLine(Offset(x, 0), Offset(x, isLast ? y : size.height), pen);
    canvas.drawLine(Offset(x, y), Offset(depth * indent + 3, y), pen);
  }

  @override
  bool shouldRepaint(covariant _TreeLines oldDelegate) =>
      oldDelegate.isLast != isLast ||
      oldDelegate.indent != indent ||
      oldDelegate.color != color ||
      oldDelegate.ancestors.length != ancestors.length ||
      !Iterable.generate(
        ancestors.length,
      ).every((index) => ancestors[index] == oldDelegate.ancestors[index]);
}
