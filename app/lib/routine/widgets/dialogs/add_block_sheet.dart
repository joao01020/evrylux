import 'package:flutter/material.dart';

import '../../models/block_type.dart';

class AddBlockSheet
    extends
        StatelessWidget {
  const AddBlockSheet({
    super.key,
    required this.onSelected,
  });

  final ValueChanged<
    BlockType
  >
  onSelected;

  static Future<
    BlockType?
  >
  show(
    BuildContext context,
  ) {
    return showModalBottomSheet<
      BlockType
    >(
      context: context,
      backgroundColor: const Color(
        0xFF171A22,
      ),
      barrierColor: Colors.black.withValues(
        alpha: 0.68,
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: 660,
        maxHeight:
            MediaQuery.sizeOf(
              context,
            ).height *
            0.82,
      ),
      builder:
          (
            sheetContext,
          ) {
            return AddBlockSheet(
              onSelected:
                  (
                    type,
                  ) {
                    Navigator.pop(
                      sheetContext,
                      type,
                    );
                  },
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.sizeOf(
      context,
    ).width;
    final columns =
        screenWidth >=
            560
        ? 3
        : 2;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        0,
        18,
        18 +
            MediaQuery.viewInsetsOf(
              context,
            ).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adicionar à lousa',
            style: TextStyle(
              color: Color(
                0xFFF5F7FA,
              ),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            'Escolha o tipo de bloco que deseja criar.',
            style: TextStyle(
              color: Color(
                0xFF9298A6,
              ),
              fontSize: 12,
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          GridView.count(
            crossAxisCount: columns,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio:
                screenWidth >=
                    560
                ? 1.45
                : 1.25,
            children: BlockType.values.map(
              (
                type,
              ) {
                return _BlockOption(
                  type: type,
                  onTap: () {
                    onSelected(
                      type,
                    );
                  },
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }
}

class _BlockOption
    extends
        StatelessWidget {
  const _BlockOption({
    required this.type,
    required this.onTap,
  });

  final BlockType type;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(
            0xFF111319,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: const Color(
              0xFF272B36,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: type.color.withValues(
                  alpha: 0.13,
                ),
                borderRadius: BorderRadius.circular(
                  11,
                ),
              ),
              child: Icon(
                type.icon,
                color: type.color,
                size: 20,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              type.label,
              style: const TextStyle(
                color: Color(
                  0xFFF5F7FA,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
