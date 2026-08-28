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
  createState() => _MindMapCanvasState();
}

class _MindMapCanvasState
    extends
        State<
          MindMapCanvas
        > {
  String? _hoveredNodeId;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(
      _refresh,
    );
    _ensureRootAfterBuild();
  }

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

  @override
  void dispose() {
    widget.controller.removeListener(
      _refresh,
    );
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(
        () {},
      );
    }
  }

  void _ensureRootAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (mounted) {
          widget.controller.ensureRoot(
            widget.block,
          );
        }
      },
    );
  }

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
                color: const Color(
                  0xFF0D0F15,
                ),
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: const Color(
                    0xFF272B36,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  15,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: MindMapConnectionsPainter(
                          nodes: widget.block.mindNodes,
                          color: widget.block.color,
                          nodeWidth: MindMapController.nodeWidth,
                          nodeHeight: MindMapController.nodeHeight,
                        ),
                      ),
                    ),
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
                    Positioned(
                      left: 12,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xCC171A22,
                          ),
                          borderRadius: BorderRadius.circular(
                            9,
                          ),
                        ),
                        child: const Text(
                          'Passe o mouse • escolha uma porta • arraste os nós',
                          style: TextStyle(
                            color: Color(
                              0xFF9298A6,
                            ),
                            fontSize: 10,
                          ),
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
