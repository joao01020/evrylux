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

  // ============================================================
  // DADOS
  // ============================================================

  final BoardBlock block;

  final ValueChanged<
    CheckItem
  >
  onToggle;

  final VoidCallback onAddTask;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF256B32,
  );

  static const Color _greenLight = Color(
    0xFFF1F8F2,
  );

  static const Color _greenBorder = Color(
    0xFFC7DFC9,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _doneBackground = Color(
    0xFFF6FAF6,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _greenLight,
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color: _greenBorder,
          ),
        ),
        child: Column(
          children: [
            // ==================================================
            // EMPTY STATE
            // ==================================================
            if (block.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Nenhuma tarefa adicionada.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            // ==================================================
            // TASKS
            // ==================================================
            for (final item in block.items)
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: item.done
                      ? _doneBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  border: Border.all(
                    color: item.done
                        ? _greenBorder
                        : const Color(
                            0xFFE2EAE2,
                          ),
                  ),
                ),
                child: CheckboxListTile(
                  key: ValueKey(
                    item.id ??
                        '${block.id}-${item.text}',
                  ),
                  value: item.done,
                  onChanged:
                      (
                        _,
                      ) {
                        onToggle(
                          item,
                        );
                      },
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  activeColor: _green,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  side: const BorderSide(
                    color: _greenBorder,
                    width: 1.4,
                  ),
                  title: Text(
                    item.text,
                    style: TextStyle(
                      color: item.done
                          ? _muted
                          : _text,
                      fontSize: 13,
                      fontWeight: item.done
                          ? FontWeight.w500
                          : FontWeight.w600,
                      decoration: item.done
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: _muted,
                    ),
                  ),
                ),
              ),

            // ==================================================
            // ADD TASK
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                8,
                6,
                8,
                8,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onAddTask,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE6F2E8,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: _greenBorder,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: _green,
                          size: 18,
                        ),

                        SizedBox(
                          width: 8,
                        ),

                        Text(
                          'Adicionar tarefa',
                          style: TextStyle(
                            color: _green,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
