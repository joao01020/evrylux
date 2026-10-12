import 'package:flutter/material.dart';

import '../models/routine_board_tab.dart';

class RoutineBoardTabBar extends StatelessWidget {
  const RoutineBoardTabBar({
    super.key,
    required this.tabs,
    required this.activeTabId,
    required this.onSelect,
    required this.onCreate,
    required this.onRename,
    this.onRenameInline,
    required this.onDelete,
    this.expanded = false,
  });

  final List<RoutineBoardTab> tabs;
  final String? activeTabId;
  final ValueChanged<RoutineBoardTab> onSelect;
  final VoidCallback onCreate;
  final ValueChanged<RoutineBoardTab> onRename;
  final Future<void> Function(RoutineBoardTab tab, String value)?
  onRenameInline;
  final ValueChanged<RoutineBoardTab> onDelete;
  final bool expanded;

  static const _primary = Color(0xFF198754);
  static const _text = Color(0xFF172019);
  static const _muted = Color(0xFF68746B);
  static const _border = Color(0xFFD7E3D9);
  static const _surface = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final effectiveTabs = tabs.isEmpty
        ? <RoutineBoardTab>[RoutineBoardTab.localDefault()]
        : tabs;
    final selectedId = activeTabId ?? effectiveTabs.first.id;

    return Container(
      width: double.infinity,
      height: expanded ? 47 : 43,
      padding: EdgeInsets.fromLTRB(expanded ? 16 : 4, 5, expanded ? 16 : 4, 0),
      decoration: BoxDecoration(
        color: expanded ? const Color(0xFFFAFCFA) : Colors.transparent,
        border: expanded
            ? const Border(bottom: BorderSide(color: _border))
            : null,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final tab in effectiveTabs)
              _RoutineBoardTabChip(
                key: ValueKey(tab.id),
                tab: tab,
                selected: tab.id == selectedId,
                onTap: () => onSelect(tab),
                onCreate: onCreate,
                onRename: (value) async {
                  final inlineHandler = onRenameInline;
                  if (inlineHandler != null) {
                    await inlineHandler(tab, value);
                    return;
                  }

                  onRename(tab);
                },
                onDelete: tab.isDefault ? null : () => onDelete(tab),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineBoardTabChip extends StatefulWidget {
  const _RoutineBoardTabChip({
    super.key,
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onCreate,
    required this.onRename,
    this.onDelete,
  });

  final RoutineBoardTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onCreate;
  final Future<void> Function(String value) onRename;
  final VoidCallback? onDelete;

  @override
  State<_RoutineBoardTabChip> createState() => _RoutineBoardTabChipState();
}

class _RoutineBoardTabChipState extends State<_RoutineBoardTabChip> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tab.name);
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _RoutineBoardTabChip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_editing && oldWidget.tab.name != widget.tab.name) {
      _controller.text = widget.tab.name;
    }
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus && _editing && !_saving) {
      _submitRename();
    }
  }

  Future<void> _startEditing() async {
    if (_saving) {
      return;
    }

    setState(() {
      _editing = true;
      _controller.text = widget.tab.name;
    });

    await Future<void>.delayed(Duration.zero);

    if (!mounted) {
      return;
    }

    _focusNode.requestFocus();
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  Future<void> _submitRename() async {
    if (!_editing || _saving) {
      return;
    }

    final value = _controller.text.trim();

    if (value.isEmpty) {
      setState(() {
        _editing = false;
        _controller.text = widget.tab.name;
      });
      return;
    }

    if (value == widget.tab.name) {
      setState(() {
        _editing = false;
      });
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await widget.onRename(value);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _editing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _editing ? null : widget.onTap,
          onDoubleTap: _editing ? null : _startEditing,
          onLongPress: _editing ? null : widget.onDelete,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
          child: Container(
            constraints: const BoxConstraints(minWidth: 92, maxWidth: 210),
            height: 35,
            padding: const EdgeInsets.only(left: 12, right: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? RoutineBoardTabBar._surface
                  : const Color(0xFFF1F5F1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              border: Border.all(
                color: widget.selected
                    ? RoutineBoardTabBar._primary
                    : RoutineBoardTabBar._border,
                width: widget.selected ? 1.25 : 1,
              ),
              boxShadow: widget.selected
                  ? const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 4,
                        offset: Offset(0, -1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selected)
                  const Padding(
                    padding: EdgeInsets.only(right: 7),
                    child: Icon(
                      Icons.space_dashboard_outlined,
                      size: 15,
                      color: RoutineBoardTabBar._primary,
                    ),
                  ),
                Flexible(
                  child: _editing
                      ? TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: (_) {
                            _submitRename();
                          },
                          textInputAction: TextInputAction.done,
                          maxLines: 1,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: widget.selected
                                ? RoutineBoardTabBar._text
                                : RoutineBoardTabBar._muted,
                            fontSize: 12.5,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        )
                      : Text(
                          widget.tab.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: widget.selected
                                ? RoutineBoardTabBar._text
                                : RoutineBoardTabBar._muted,
                            fontSize: 12.5,
                            fontWeight: widget.selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                        ),
                ),
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(left: 6, right: 2),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: RoutineBoardTabBar._primary,
                      ),
                    ),
                  )
                else if (widget.selected)
                  IconButton(
                    tooltip: 'Nova aba',
                    onPressed: widget.onCreate,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 22,
                      height: 22,
                    ),
                    iconSize: 17,
                    icon: const Icon(
                      Icons.add_rounded,
                      color: RoutineBoardTabBar._primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
