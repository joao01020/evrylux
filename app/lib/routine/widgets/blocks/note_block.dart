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

  // ============================================================
  // CORES
  // ============================================================

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _greenLight = Color(
    0xFFF1F8F2,
  );

  static const Color _greenBorder = Color(
    0xFFD5E8D8,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final content = block.content.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _greenLight,
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: _greenBorder,
          ),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            content.isEmpty
                ? 'Anotação vazia.'
                : content,
            style: TextStyle(
              color: content.isEmpty
                  ? _muted
                  : _text,
              height: 1.55,
              fontSize: 13,
              fontStyle: content.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ),
      ),
    );
  }
}
