import 'package:flutter/material.dart';

class TextDocumentViewer
    extends
        StatelessWidget {
  const TextDocumentViewer({
    super.key,
    required this.content,
    this.padding = const EdgeInsets.all(
      20,
    ),
  });

  final String content;

  final EdgeInsetsGeometry padding;

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    if (content.isEmpty) {
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

    return SingleChildScrollView(
      padding: padding,
      child: SelectableText(
        content,
        style: const TextStyle(
          color: _text,
          fontSize: 14,
          height: 1.55,
        ),
      ),
    );
  }
}
