import 'package:flutter/material.dart';

import '../../../controllers/mind_map_controller.dart';
import '../../../models/board_block.dart';

import 'mind_map_connections_painter.dart';
import 'mind_map_node_widget.dart';

class MindMapCanvas
    extends
        StatefulWidget {
  const MindMapCanvas({
    super.key,
    required this.block,
    required this.controller,
    this.height = 330,
  });

  final BoardBlock block;

  final MindMapController controller;

  final double height;

  @override
  State<
    MindMapCanvas
  >
  createState() {
    return _MindMapCanvasState();
  }
}

class _MindMapCanvasState
    extends
        State<
          MindMapCanvas
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF347A3D,
  );

  static const Color _canvasBackground = Color(
    0xFF0D0F15,
  );

  static const Color _canvasBorder = Color(
    0xFF272B36,
  );

  static const Color _hintBackground = Color(
    0xCC171A22,
  );

  static const Color _muted = Color(
    0xFF9298A6,
  );

  // ============================================================
  // STATE
  // ============================================================

  String? _hoveredNodeId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(
      _refresh,
    );

    _ensureRootAfterBuild();
  }

  // ============================================================
  // DID UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant MindMapCanvas oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.controller !=
        widget.controller) {
      oldWidget.controller.removeListener(
        _refresh,
      );

      widget.controller.addListener(
        _refresh,
      );
    }

    if (oldWidget.block !=
        widget.block) {
      _ensureRootAfterBuild();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.controller.removeListener(
      _refresh,
    );

    super.dispose();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void _refresh() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // ROOT
  // ============================================================

  void _ensureRootAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        widget.controller.ensureRoot(
          widget.block,
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
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final canvasWidth = constraints.maxWidth;

            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: _canvasBackground,
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: _canvasBorder,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(
                      0x33000000,
                    ),
                    blurRadius: 12,
                    offset: Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  15,
                ),
                child: Stack(
                  children: [
                    // =================================================
                    // FUNDO
                    // =================================================
                    const Positioned.fill(
                      child: ColoredBox(
                        color: _canvasBackground,
                      ),
                    ),

                    // =================================================
                    // GRID
                    // =================================================
                    const Positioned.fill(
                      child: CustomPaint(
                        painter: _MindMapGridPainter(),
                      ),
                    ),

                    // =================================================
                    // CONEXÕES
                    // =================================================
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MindMapConnectionsPainter(
                          nodes: widget.block.mindNodes,
                          color: _green,
                          nodeWidth: MindMapController.nodeWidth,
                          nodeHeight: MindMapController.nodeHeight,
                        ),
                      ),
                    ),

                    // =================================================
                    // NÓS
                    // =================================================
                    for (final node in widget.block.mindNodes)
                      Positioned(
                        key: ValueKey(
                          node.id,
                        ),
                        left: node.position.dx,
                        top: node.position.dy,
                        width: MindMapController.nodeWidth,
                        height: MindMapController.nodeHeight,
                        child: MindMapNodeWidget(
                          block: widget.block,
                          node: node,
                          controller: widget.controller,
                          canvasWidth: canvasWidth,
                          canvasHeight: widget.height,
                          hovered:
                              _hoveredNodeId ==
                              node.id,
                          onHoverChanged:
                              (
                                hovered,
                              ) {
                                if (!mounted) {
                                  return;
                                }

                                setState(
                                  () {
                                    _hoveredNodeId = hovered
                                        ? node.id
                                        : null;
                                  },
                                );
                              },
                        ),
                      ),

                    // =================================================
                    // DICA
                    // =================================================
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _hintBackground,
                          borderRadius: BorderRadius.circular(
                            9,
                          ),
                          border: Border.all(
                            color: _canvasBorder,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_tree_outlined,
                              color: _green,
                              size: 13,
                            ),

                            SizedBox(
                              width: 6,
                            ),

                            Text(
                              'Passe o mouse • escolha uma porta • arraste os nós',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

// ============================================================
// GRID
// ============================================================

class _MindMapGridPainter
    extends
        CustomPainter {
  const _MindMapGridPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const spacing = 24.0;

    final paint = Paint()
      ..color =
          const Color(
            0xFF242731,
          ).withValues(
            alpha: .55,
          )
      ..strokeWidth = 1;

    for (
      double x = spacing;
      x <
          size.width;
      x += spacing
    ) {
      for (
        double y = spacing;
        y <
            size.height;
        y += spacing
      ) {
        canvas.drawCircle(
          Offset(
            x,
            y,
          ),
          1,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _MindMapGridPainter oldDelegate,
  ) {
    return false;
  }
}
