import 'package:flutter/material.dart';

import '../../models/board_block.dart';
import '../../models/check_item.dart';

class TaskBlock
    extends
        StatelessWidget {
  const TaskBlock({
    super.key,
    required this.block,
    required this.onToggle,
    required this.onAddTask,
  });

  final BoardBlock block;
  final ValueChanged<
    CheckItem
  >
  onToggle;
  final VoidCallback onAddTask;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        if (block.items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nenhuma tarefa adicionada.',
                style: TextStyle(
                  color: Color(
                    0xFF9298A6,
                  ),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        for (final item in block.items)
          CheckboxListTile(
            key: ValueKey(
              item.id ??
                  '${block.id}-${item.text}',
            ),
            value: item.done,
            onChanged:
                (
                  _,
                ) => onToggle(
                  item,
                ),
            dense: true,
            visualDensity: VisualDensity.compact,
            activeColor: block.color,
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            title: Text(
              item.text,
              style: TextStyle(
                color: item.done
                    ? const Color(
                        0xFF9298A6,
                      )
                    : const Color(
                        0xFFF5F7FA,
                      ),
                fontSize: 13,
                decoration: item.done
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: const Color(
                  0xFF9298A6,
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
          ),
          child: InkWell(
            onTap: onAddTask,
            borderRadius: BorderRadius.circular(
              10,
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 9,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: Color(
                      0xFF9298A6,
                    ),
                    size: 18,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Text(
                    'Adicionar tarefa',
                    style: TextStyle(
                      color: Color(
                        0xFF9298A6,
                      ),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
