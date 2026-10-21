import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../study/brain/widgets/brain_rich_content.dart';
import '../../study/brain/widgets/brain_code_block.dart';

/// Search UI shared by the public title and its paragraphs/code blocks.
/// Does not read or change the private Vault.
List<int> brainSearchOffsets(String source, String query) {
  if (query.isEmpty) return const [];
  final text = source.toLowerCase();
  final needle = query.toLowerCase();
  final positions = <int>[];
  var start = 0;
  while (true) {
    final found = text.indexOf(needle, start);
    if (found < 0 || positions.length >= 5000) break;
    positions.add(found);
    start = found + needle.length;
  }
  return positions;
}

List<InlineSpan> _markedSpans(
  String text,
  String query,
  TextStyle? style,
  int activeOccurrence,
) {
  if (query.isEmpty) {
    return BrainInlineTextParser.parseBold(text, baseStyle: style);
  }
  final base = BrainInlineTextParser.parseBold(text, baseStyle: style);
  final result = <InlineSpan>[];
  var absolute = 0;
  var occurrence = 0;
  // Preserve bold styling from the application's existing parser.
  // The ** delimiters are omitted by parseBold.
  final plain = base.whereType<TextSpan>().map((s) => s.text ?? '').join();
  final positions = brainSearchOffsets(plain, query);
  final spans = base.whereType<TextSpan>();
  for (final span in spans) {
    final value = span.text ?? '';
    var cursor = 0;
    while (cursor < value.length) {
      final start = absolute + cursor;
      final hit = positions.where(
        (i) => i <= start && start < i + query.length,
      );
      final next = positions.where((i) => i > start);
      if (hit.isNotEmpty) {
        final index = hit.first;
        final length = (index + query.length - start).clamp(
          0,
          value.length - cursor,
        );
        occurrence = positions.indexOf(index);
        result.add(
          TextSpan(
            text: value.substring(cursor, cursor + length),
            style:
                span.style?.copyWith(
                  backgroundColor: occurrence == activeOccurrence
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFFFFE082),
                  color: Colors.black,
                ) ??
                TextStyle(
                  backgroundColor: occurrence == activeOccurrence
                      ? const Color(0xFFFFB74D)
                      : const Color(0xFFFFE082),
                  color: Colors.black,
                ),
          ),
        );
        cursor += length;
      } else {
        final end = next.isEmpty
            ? value.length
            : (next.first - absolute).clamp(cursor, value.length);
        if (end == cursor) {
          cursor++;
          continue;
        }
        result.add(
          TextSpan(text: value.substring(cursor, end), style: span.style),
        );
        cursor = end;
      }
    }
    absolute += value.length;
  }
  return result;
}

class BrainSearchableTitle extends StatelessWidget {
  const BrainSearchableTitle({
    super.key,
    required this.text,
    required this.query,
    required this.activeIndex,
    this.style,
  });
  final String text;
  final String query;
  final int activeIndex;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: _markedSpans(text, query, style, activeIndex)),
    );
  }
}

class BrainSearchableRichContent extends StatefulWidget {
  const BrainSearchableRichContent({
    super.key,
    required this.content,
    required this.query,
    required this.activeMatch,
  });

  final String content;
  final String query;
  final int activeMatch;

  @override
  BrainSearchableRichContentState createState() =>
      BrainSearchableRichContentState();
}

class BrainSearchableRichContentState
    extends State<BrainSearchableRichContent> {
  final Map<int, GlobalKey> _segmentKeys = {};

  void scrollToMatch(int matchIndex) {
    if (matchIndex < 0 || widget.query.isEmpty) return;
    final segments = BrainRichContentParser.parse(widget.content);
    var offset = 0;
    for (var i = 0; i < segments.length; i++) {
      final count = brainSearchOffsets(
        _segmentText(segments[i]),
        widget.query,
      ).length;
      if (matchIndex < offset + count) {
        final target = _segmentKeys[i]?.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: 0.2,
          );
        }
        return;
      }
      offset += count;
    }
  }

  static String _segmentText(BrainRichContentSegment segment) {
    if (segment is BrainCodeSegment) return segment.code;
    // Match the user's rendered text, omitting bold delimiters.
    return BrainInlineTextParser.parseBold(
      (segment as BrainTextSegment).text,
    ).whereType<TextSpan>().map((span) => span.text ?? '').join();
  }

  @override
  Widget build(BuildContext context) {
    final segments = BrainRichContentParser.parse(widget.content);
    if (segments.isEmpty) return const SizedBox.shrink();
    var countBefore = 0;
    final children = <Widget>[];

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final key = _segmentKeys.putIfAbsent(i, GlobalKey.new);
      final count = brainSearchOffsets(
        _segmentText(segment),
        widget.query,
      ).length;
      final localIndex = widget.activeMatch - countBefore;

      Widget content;
      if (segment is BrainCodeSegment) {
        content = widget.query.isEmpty
            ? BrainCodeBlock(language: segment.language, code: segment.code)
            : _SearchCodeBlock(
                language: segment.language,
                code: segment.code,
                query: widget.query,
                activeIndex: localIndex,
              );
      } else {
        final text = (segment as BrainTextSegment).text;
        final style = Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(height: 1.55);
        content = SelectableText.rich(
          TextSpan(
            children: _markedSpans(text, widget.query, style, localIndex),
          ),
        );
      }

      children.add(Container(key: key, child: content));
      if (i != segments.length - 1) children.add(const SizedBox(height: 6));
      countBefore += count;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _SearchCodeBlock extends StatelessWidget {
  const _SearchCodeBlock({
    required this.language,
    required this.code,
    required this.query,
    required this.activeIndex,
  });
  final String language;
  final String code;
  final String query;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF111315) : const Color(0xFFF7F8FA);
    final header = dark ? const Color(0xFF191B1E) : const Color(0xFFEEF0F3);
    final textColor = dark ? const Color(0xFFE9EAEC) : const Color(0xFF202124);
    final border = dark ? Colors.white12 : Colors.black12;
    final style = TextStyle(
      color: textColor,
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.55,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.only(left: 14, right: 7),
            color: header,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    language,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado.')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copiar'),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: SelectableText.rich(
              TextSpan(children: _markedSpans(code, query, style, activeIndex)),
            ),
          ),
        ],
      ),
    );
  }
}
