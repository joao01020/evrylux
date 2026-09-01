import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownDocumentViewer
    extends
        StatelessWidget {
  const MarkdownDocumentViewer({
    super.key,
    required this.content,
    this.padding = const EdgeInsets.all(
      20,
    ),
  });

  // ============================================================
  // CONTENT
  // ============================================================

  final String content;

  // ============================================================
  // PADDING
  // ============================================================
  //
  // flutter_markdown espera EdgeInsets especificamente.
  //
  // Antes estava como EdgeInsetsGeometry, o que causava:
  //
  // EdgeInsetsGeometry can't be assigned to EdgeInsets
  //
  // ============================================================

  final EdgeInsets padding;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _soft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // EMPTY
    // ==========================================================

    if (content.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(
            28,
          ),
          child: Text(
            'Este documento está vazio.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // BASE TEXT
    // ==========================================================

    final baseTextStyle =
        Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(
          color: _text,
          fontSize: 14,
          height: 1.55,
        ) ??
        const TextStyle(
          color: _text,
          fontSize: 14,
          height: 1.55,
        );

    // ==========================================================
    // MARKDOWN
    // ==========================================================

    return Markdown(
      data: content,

      selectable: true,

      padding: padding,

      styleSheet: MarkdownStyleSheet(
        // ======================================================
        // PARAGRAPH
        // ======================================================
        p: baseTextStyle,

        // ======================================================
        // HEADINGS
        // ======================================================
        h1: const TextStyle(
          color: _text,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),

        h2: const TextStyle(
          color: _text,
          fontSize: 23,
          fontWeight: FontWeight.w900,
          height: 1.25,
        ),

        h3: const TextStyle(
          color: _text,
          fontSize: 19,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),

        h4: const TextStyle(
          color: _text,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),

        // ======================================================
        // EMPHASIS
        // ======================================================
        strong: const TextStyle(
          color: _text,
          fontWeight: FontWeight.w800,
        ),

        em: const TextStyle(
          color: _text,
          fontStyle: FontStyle.italic,
        ),

        // ======================================================
        // LINKS
        // ======================================================
        a: const TextStyle(
          color: _primary,
          decoration: TextDecoration.underline,
          decorationColor: _primary,
          fontWeight: FontWeight.w700,
        ),

        // ======================================================
        // BLOCKQUOTE
        // ======================================================
        blockquote: baseTextStyle.copyWith(
          color: _muted,
          fontStyle: FontStyle.italic,
        ),

        blockquoteDecoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(
            8,
          ),
          border: const Border(
            left: BorderSide(
              color: _primary,
              width: 3,
            ),
          ),
        ),

        // ======================================================
        // CODE
        // ======================================================
        code: const TextStyle(
          color: _text,
          fontSize: 12,
          fontFamily: 'monospace',
        ),

        codeblockDecoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(
            10,
          ),
          border: Border.all(
            color: _border,
          ),
        ),

        codeblockPadding: const EdgeInsets.all(
          14,
        ),

        // ======================================================
        // LIST
        // ======================================================
        listBullet: baseTextStyle.copyWith(
          color: _primary,
          fontWeight: FontWeight.w800,
        ),

        // ======================================================
        // DIVIDER
        // ======================================================
        horizontalRuleDecoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: _border,
            ),
          ),
        ),

        // ======================================================
        // TABLE
        // ======================================================
        tableHead: const TextStyle(
          color: _text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),

        tableBody: const TextStyle(
          color: _text,
          fontSize: 12,
        ),

        tableBorder: TableBorder.all(
          color: _border,
        ),

        tableCellsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
    );
  }
}
