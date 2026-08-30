import 'package:flutter/material.dart';

import '../../models/block_type.dart';

class AddBlockSheet
    extends
        StatelessWidget {
  const AddBlockSheet({
    super.key,
    required this.onSelected,
    this.onComment,
  });

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFE2E4E8,
  );

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
  // COMENTÁRIO
  // ============================================================

  static const Color _commentColor = Color(
    0xFF3859FF,
  );

  static const Color _commentBackground = Color(
    0xFFE9EDFF,
  );

  static const Color _commentBorder = Color(
    0xFFBFC9FF,
  );

  // ============================================================
  // CALLBACKS
  // ============================================================

  final ValueChanged<
    BlockType
  >
  onSelected;

  /// Quando informado, exibe a opção "Comentário".
  ///
  /// Comentário NÃO vira um BoardBlock. Ele apenas fecha este modal
  /// e avisa a tela para ativar o modo de comentário da lousa.
  final VoidCallback? onComment;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    BlockType?
  >
  show(
    BuildContext context, {
    VoidCallback? onComment,
  }) {
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
              onComment:
                  onComment ==
                      null
                  ? null
                  : () {
                      Navigator.of(
                        sheetContext,
                      ).pop();

                      onComment();
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

    final items =
        <
          Widget
        >[
          for (final type in BlockType.values)
            _BlockOption(
              type: type,
              onTap: () {
                onSelected(
                  type,
                );
              },
            ),

          if (onComment !=
              null)
            _CommentOption(
              onTap: onComment!,
            ),
        ];

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
              'Escolha o que deseja adicionar à lousa.',
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
              children: items,
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
      case BlockType.tasks:
        return const Color(
          0xFF198754,
        );

      case BlockType.note:
        return const Color(
          0xFFD97706,
        );

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
      case BlockType.tasks:
        return const Color(
          0xFFD7F0DF,
        );

      case BlockType.note:
        return const Color(
          0xFFFFE6C4,
        );

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

    return _OptionShell(
      hovered: _hovered,
      onEnter: () {
        setState(
          () {
            _hovered = true;
          },
        );
      },
      onExit: () {
        setState(
          () {
            _hovered = false;
          },
        );
      },
      onTap: widget.onTap,
      icon: type.icon,
      iconColor: _iconColor(
        type,
      ),
      iconBackground: _iconBackground(
        type,
      ),
      iconBorder: _iconBorder(
        type,
      ),
      label: type.label,
    );
  }
}

// ============================================================
// COMMENT OPTION
// ============================================================

class _CommentOption
    extends
        StatefulWidget {
  const _CommentOption({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  State<
    _CommentOption
  >
  createState() {
    return _CommentOptionState();
  }
}

class _CommentOptionState
    extends
        State<
          _CommentOption
        > {
  bool _hovered = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    return _OptionShell(
      hovered: _hovered,
      onEnter: () {
        setState(
          () {
            _hovered = true;
          },
        );
      },
      onExit: () {
        setState(
          () {
            _hovered = false;
          },
        );
      },
      onTap: widget.onTap,
      icon: Icons.add_comment_outlined,
      iconColor: AddBlockSheet._commentColor,
      iconBackground: AddBlockSheet._commentBackground,
      iconBorder: AddBlockSheet._commentBorder,
      label: 'Comentário',
      hoverBorder: AddBlockSheet._commentColor,
    );
  }
}

// ============================================================
// OPTION SHELL
// ============================================================

class _OptionShell
    extends
        StatelessWidget {
  const _OptionShell({
    required this.hovered,
    required this.onEnter,
    required this.onExit,
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.iconBorder,
    required this.label,
    this.hoverBorder,
  });

  final bool hovered;

  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onTap;

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color iconBorder;
  final Color? hoverBorder;

  final String label;

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter:
          (
            _,
          ) {
            onEnter();
          },
      onExit:
          (
            _,
          ) {
            onExit();
          },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            14,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 150,
            ),
            decoration: BoxDecoration(
              color: hovered
                  ? AddBlockSheet._surfaceHover
                  : AddBlockSheet._surface,
              borderRadius: BorderRadius.circular(
                14,
              ),
              border: Border.all(
                color: hovered
                    ? (hoverBorder ??
                              AddBlockSheet._green)
                          .withValues(
                            alpha: .48,
                          )
                    : AddBlockSheet._border,
              ),
              boxShadow: hovered
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
                    icon,
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
                  label,
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
