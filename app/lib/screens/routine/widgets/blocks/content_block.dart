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

  final BoardBlock block;
  final ValueChanged<
    ContentStatus
  >
  onStatusChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            block.content.trim().isEmpty
                ? 'Nenhuma ideia de conteúdo registrada.'
                : block.content,
            style: TextStyle(
              color: block.content.trim().isEmpty
                  ? const Color(
                      0xFF9298A6,
                    )
                  : const Color(
                      0xFFF5F7FA,
                    ),
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 12,
          ),
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
                      ) => onStatusChanged(
                        status,
                      ),
                  label: Text(
                    status.label,
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : const Color(
                            0xFF9298A6,
                          ),
                    fontSize: 11,
                  ),
                  selectedColor: block.color,
                  backgroundColor: const Color(
                    0xFF111319,
                  ),
                  side: BorderSide(
                    color: selected
                        ? block.color
                        : const Color(
                            0xFF272B36,
                          ),
                  ),
                  showCheckmark: false,
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}
