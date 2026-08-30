import 'package:flutter/material.dart';

import '../../models/comments/board_comment.dart';

class BoardCommentPin
    extends
        StatefulWidget {
  const BoardCommentPin({
    super.key,
    required this.comment,
    required this.onTap,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final BoardComment comment;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onTap;

  final ValueChanged<
    Offset
  >
  onDragUpdate;

  final VoidCallback onDragEnd;

  @override
  State<
    BoardCommentPin
  >
  createState() => _BoardCommentPinState();
}

class _BoardCommentPinState
    extends
        State<
          BoardCommentPin
        > {
  // ============================================================
  // STATE
  // ============================================================

  bool _hovered = false;

  bool _dragging = false;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _blue = Color(
    0xFF3859FF,
  );

  static const Color _blueSoft = Color(
    0xFFE9EDFF,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _border = Color(
    0xFFE2E6EA,
  );

  // ============================================================
  // TAMANHOS
  // ============================================================

  static const double _collapsedSize = 38;

  static const double _expandedWidth = 250;

  static const double _expandedHeight = 58;

  static const double _iconSize = 30;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final expanded =
        _hovered &&
        !_dragging;

    return MouseRegion(
      cursor: _dragging
          ? SystemMouseCursors.grabbing
          : SystemMouseCursors.grab,

      // ========================================================
      // HOVER ENTER
      // ========================================================
      onEnter:
          (
            _,
          ) {
            if (_dragging) {
              return;
            }

            setState(
              () {
                _hovered = true;
              },
            );
          },

      // ========================================================
      // HOVER EXIT
      // ========================================================
      onExit:
          (
            _,
          ) {
            if (_dragging) {
              return;
            }

            setState(
              () {
                _hovered = false;
              },
            );
          },

      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ======================================================
        // CLICK
        // ======================================================
        onTap: widget.onTap,

        // ======================================================
        // DRAG START
        // ======================================================
        onPanStart:
            (
              _,
            ) {
              if (!mounted) {
                return;
              }

              setState(
                () {
                  _dragging = true;
                  _hovered = false;
                },
              );
            },

        // ======================================================
        // DRAG
        // ======================================================
        onPanUpdate:
            (
              details,
            ) {
              widget.onDragUpdate(
                details.delta,
              );
            },

        // ======================================================
        // DRAG END
        // ======================================================
        onPanEnd:
            (
              _,
            ) {
              if (!mounted) {
                return;
              }

              setState(
                () {
                  _dragging = false;
                  _hovered = false;
                },
              );

              widget.onDragEnd();
            },

        // ======================================================
        // DRAG CANCEL
        // ======================================================
        onPanCancel: () {
          if (!mounted) {
            return;
          }

          setState(
            () {
              _dragging = false;
              _hovered = false;
            },
          );

          widget.onDragEnd();
        },

        // ======================================================
        // CONTAINER
        // ======================================================
        child: AnimatedContainer(
          duration: Duration(
            milliseconds: _dragging
                ? 0
                : 160,
          ),

          curve: Curves.easeOutCubic,

          width: expanded
              ? _expandedWidth
              : _collapsedSize,

          height: expanded
              ? _expandedHeight
              : _collapsedSize,

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              expanded
                  ? 13
                  : 19,
            ),

            border: Border.all(
              color: _dragging
                  ? _blue
                  : _border,

              width: _dragging
                  ? 1.5
                  : 1,
            ),

            boxShadow: [
              BoxShadow(
                color: _dragging
                    ? const Color(
                        0x33000000,
                      )
                    : const Color(
                        0x24000000,
                      ),

                blurRadius: _dragging
                    ? 16
                    : 12,

                offset: Offset(
                  0,
                  _dragging
                      ? 6
                      : 4,
                ),
              ),
            ],
          ),

          // ====================================================
          // CONTEÚDO RESPONSIVO
          // ====================================================
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              expanded
                  ? 13
                  : 19,
            ),

            child: LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    // ==============================================
                    // PIN PEQUENO
                    // ==============================================
                    //
                    // Durante a animação, enquanto ainda não existe
                    // espaço suficiente, mostramos somente o ícone.
                    //
                    // Isso impede qualquer RenderFlex overflow.
                    //
                    // ==============================================

                    if (constraints.maxWidth <
                        90) {
                      return Center(
                        child: _buildIcon(),
                      );
                    }

                    // ==============================================
                    // PREVIEW EXPANDIDO
                    // ==============================================

                    return _buildExpandedContent();
                  },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTEÚDO EXPANDIDO
  // ============================================================

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),

      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          _buildIcon(),

          const SizedBox(
            width: 9,
          ),

          // ====================================================
          // TEXTO
          // ====================================================
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  widget.comment.authorName,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _text,

                    fontSize: 11,

                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  widget.comment.message,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    color: _muted,

                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ÍCONE
  // ============================================================

  Widget _buildIcon() {
    return SizedBox(
      width: _iconSize,
      height: _iconSize,

      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _dragging
              ? const Color(
                  0xFFDDE3FF,
                )
              : _blueSoft,

          shape: BoxShape.circle,
        ),

        child: Center(
          child: Icon(
            _dragging
                ? Icons.drag_indicator_rounded
                : Icons.chat_bubble_outline_rounded,

            color: _blue,

            size: _dragging
                ? 18
                : 17,
          ),
        ),
      ),
    );
  }
}
