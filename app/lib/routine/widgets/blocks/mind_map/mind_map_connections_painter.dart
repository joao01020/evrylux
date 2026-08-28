import 'package:flutter/material.dart';

import '../../../models/mind_map_node.dart';
import '../../../models/node_port.dart';

class MindMapConnectionsPainter
    extends
        CustomPainter {
  const MindMapConnectionsPainter({
    required this.nodes,
    required this.color,
    required this.nodeWidth,
    required this.nodeHeight,
  });

  final List<
    MindMapNode
  >
  nodes;
  final Color color;
  final double nodeWidth;
  final double nodeHeight;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final linePaint = Paint()
      ..color = color.withValues(
        alpha: .72,
      )
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()..color = color;
    final nodesById =
        <
          String,
          MindMapNode
        >{
          for (final node in nodes) node.id: node,
        };

    for (final node in nodes) {
      if (node.parentId ==
          null) {
        continue;
      }

      final parent = nodesById[node.parentId];
      if (parent ==
          null) {
        continue;
      }

      final start = _portOffset(
        parent,
        node.sourcePort,
      );
      final end = _portOffset(
        node,
        node.targetPort,
      );
      final distance =
          (end -
                  start)
              .distance;
      final handleLength =
          (distance *
                  .42)
              .clamp(
                36.0,
                110.0,
              )
              .toDouble();
      final control1 =
          start +
          _portDirection(
                node.sourcePort,
              ) *
              handleLength;
      final control2 =
          end +
          _portDirection(
                node.targetPort,
              ) *
              handleLength;

      final path = Path()
        ..moveTo(
          start.dx,
          start.dy,
        )
        ..cubicTo(
          control1.dx,
          control1.dy,
          control2.dx,
          control2.dy,
          end.dx,
          end.dy,
        );

      canvas.drawPath(
        path,
        linePaint,
      );
      canvas.drawCircle(
        start,
        3.5,
        pointPaint,
      );
      canvas.drawCircle(
        end,
        3.5,
        pointPaint,
      );
    }
  }

  Offset _portOffset(
    MindMapNode node,
    NodePort port,
  ) {
    return switch (port) {
      NodePort.top => Offset(
        node.position.dx +
            nodeWidth /
                2,
        node.position.dy,
      ),
      NodePort.right => Offset(
        node.position.dx +
            nodeWidth,
        node.position.dy +
            nodeHeight /
                2,
      ),
      NodePort.bottom => Offset(
        node.position.dx +
            nodeWidth /
                2,
        node.position.dy +
            nodeHeight,
      ),
      NodePort.left => Offset(
        node.position.dx,
        node.position.dy +
            nodeHeight /
                2,
      ),
    };
  }

  Offset _portDirection(
    NodePort port,
  ) {
    return switch (port) {
      NodePort.top => const Offset(
        0,
        -1,
      ),
      NodePort.right => const Offset(
        1,
        0,
      ),
      NodePort.bottom => const Offset(
        0,
        1,
      ),
      NodePort.left => const Offset(
        -1,
        0,
      ),
    };
  }

  @override
  bool shouldRepaint(
    covariant MindMapConnectionsPainter oldDelegate,
  ) {
    return true;
  }
}
