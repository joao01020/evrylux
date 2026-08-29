import 'package:flutter/material.dart';

import '../../models/board_block.dart';
import '../../models/content_status.dart';

class ContentBlock
    extends
        StatelessWidget {
  const ContentBlock({
    super.key,
    required this.block,
    required this.onStatusChanged,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _chipBackground = Color(
    0xFFE5E7EB,
  );

  static const Color _chipBorder = Color(
    0xFFC7CBD1,
  );

  final BoardBlock block;

  final ValueChanged<
    ContentStatus
  >
  onStatusChanged;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final hasContent = block.content.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // CONTEÚDO
          // ====================================================
          Text(
            hasContent
                ? block.content
                : 'Nenhuma ideia de conteúdo registrada.',
            style: TextStyle(
              color: hasContent
                  ? _text
                  : _muted,
              height: 1.45,
              fontSize: 13,
              fontWeight: hasContent
                  ? FontWeight.w500
                  : FontWeight.w400,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // STATUS
          // ====================================================
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: ContentStatus.values.map(
              (
                status,
              ) {
                final selected =
                    block.status ==
                    status;

                return ChoiceChip(
                  selected: selected,

                  onSelected:
                      (
                        _,
                      ) {
                        onStatusChanged(
                          status,
                        );
                      },

                  label: Text(
                    status.label,
                  ),

                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : _text,
                    fontSize: 11,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w600,
                  ),

                  // ============================================
                  // SELECIONADO
                  // ============================================
                  selectedColor: block.color,

                  // ============================================
                  // NÃO SELECIONADO
                  // ============================================
                  backgroundColor: _chipBackground,

                  side: BorderSide(
                    color: selected
                        ? block.color
                        : _chipBorder,
                  ),

                  showCheckmark: false,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}
