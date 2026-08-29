import 'package:flutter/material.dart';

import '../../models/block_type.dart';

class AddBlockSheet
    extends
        StatelessWidget {
  const AddBlockSheet({
    super.key,
    required this.onSelected,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  // Card cinza
  static const Color _surface = Color(
    0xFFE2E4E8,
  );

  // Hover um pouco mais escuro
  static const Color _surfaceHover = Color(
    0xFFD4D7DC,
  );

  static const Color _border = Color(
    0xFFBCC1C9,
  );

  static const Color _green = Color(
    0xFF198754,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // CALLBACK
  // ============================================================

  final ValueChanged<
    BlockType
  >
  onSelected;

  // ============================================================
  // SHOW
  // ============================================================

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
      backgroundColor: _background,
      barrierColor: Colors.black.withValues(
        alpha: 0.35,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            22,
          ),
        ),
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
                    Navigator.of(
                      sheetContext,
                    ).pop(
                      type,
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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

    return Container(
      color: _background,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          2,
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
            // ==================================================
            // TÍTULO
            // ==================================================
            const Text(
              'Adicionar à lousa',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            // ==================================================
            // SUBTÍTULO
            // ==================================================
            const Text(
              'Escolha o tipo de bloco que deseja criar.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // GRID
            // ==================================================
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
      ),
    );
  }
}

// ============================================================
// BLOCK OPTION
// ============================================================

class _BlockOption
    extends
        StatefulWidget {
  const _BlockOption({
    required this.type,
    required this.onTap,
  });

  final BlockType type;

  final VoidCallback onTap;

  @override
  State<
    _BlockOption
  >
  createState() {
    return _BlockOptionState();
  }
}

class _BlockOptionState
    extends
        State<
          _BlockOption
        > {
  // ============================================================
  // HOVER
  // ============================================================

  bool _hovered = false;

  // ============================================================
  // COR PRINCIPAL DO ÍCONE
  // ============================================================

  Color _iconColor(
    BlockType type,
  ) {
    switch (type) {
      // ========================================================
      // TAREFAS
      // ========================================================

      case BlockType.tasks:
        return const Color(
          0xFF198754,
        );

      // ========================================================
      // ANOTAÇÃO
      // ========================================================

      case BlockType.note:
        return const Color(
          0xFFD97706,
        );

      // ========================================================
      // OUTROS
      // ========================================================

      default:
        return type.color;
    }
  }

  // ============================================================
  // FUNDO DO ÍCONE
  // ============================================================

  Color _iconBackground(
    BlockType type,
  ) {
    switch (type) {
      // ========================================================
      // TAREFAS
      // ========================================================

      case BlockType.tasks:
        return const Color(
          0xFFD7F0DF,
        );

      // ========================================================
      // ANOTAÇÃO
      // ========================================================

      case BlockType.note:
        return const Color(
          0xFFFFE6C4,
        );

      // ========================================================
      // OUTROS
      // ========================================================

      default:
        return type.color.withValues(
          alpha: 0.15,
        );
    }
  }

  // ============================================================
  // BORDA DO ÍCONE
  // ============================================================

  Color _iconBorder(
    BlockType type,
  ) {
    switch (type) {
      case BlockType.tasks:
        return const Color(
          0xFF9FD5AE,
        );

      case BlockType.note:
        return const Color(
          0xFFF2C078,
        );

      default:
        return type.color.withValues(
          alpha: .28,
        );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final type = widget.type;

    final iconColor = _iconColor(
      type,
    );

    final iconBackground = _iconBackground(
      type,
    );

    final iconBorder = _iconBorder(
      type,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter:
          (
            _,
          ) {
            setState(
              () {
                _hovered = true;
              },
            );
          },

      onExit:
          (
            _,
          ) {
            setState(
              () {
                _hovered = false;
              },
            );
          },

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,

          borderRadius: BorderRadius.circular(
            14,
          ),

          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 150,
            ),

            decoration: BoxDecoration(
              // ==================================================
              // CARD CINZA
              // ==================================================
              color: _hovered
                  ? AddBlockSheet._surfaceHover
                  : AddBlockSheet._surface,

              borderRadius: BorderRadius.circular(
                14,
              ),

              border: Border.all(
                color: _hovered
                    ? AddBlockSheet._green.withValues(
                        alpha: .45,
                      )
                    : AddBlockSheet._border,
              ),

              boxShadow: _hovered
                  ? const [
                      BoxShadow(
                        color: Color(
                          0x16000000,
                        ),
                        blurRadius: 8,
                        offset: Offset(
                          0,
                          3,
                        ),
                      ),
                    ]
                  : null,
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==============================================
                // ÍCONE
                // ==============================================
                Container(
                  width: 42,
                  height: 42,

                  decoration: BoxDecoration(
                    color: iconBackground,

                    borderRadius: BorderRadius.circular(
                      11,
                    ),

                    border: Border.all(
                      color: iconBorder,
                    ),
                  ),

                  child: Icon(
                    type.icon,
                    color: iconColor,
                    size: 21,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                // ==============================================
                // LABEL
                // ==============================================
                Text(
                  type.label,
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    color: AddBlockSheet._text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
