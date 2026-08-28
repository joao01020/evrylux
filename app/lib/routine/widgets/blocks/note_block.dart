import 'package:flutter/material.dart';

import '../../models/board_block.dart';

class NoteBlock
    extends
        StatelessWidget {
  const NoteBlock({
    super.key,
    required this.block,
  });

  final BoardBlock block;

  @override
  Widget build(
    BuildContext context,
  ) {
    final content = block.content.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          content.isEmpty
              ? 'Anotação vazia.'
              : content,
          style: TextStyle(
            color: content.isEmpty
                ? const Color(
                    0xFF9298A6,
                  )
                : const Color(
                    0xFFF5F7FA,
                  ),
            height: 1.55,
            fontSize: 13,
            fontStyle: content.isEmpty
                ? FontStyle.italic
                : FontStyle.normal,
          ),
        ),
      ),
    );
  }
}
