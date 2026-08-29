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

  // ============================================================
  // DADOS
  // ============================================================

  final List<
    MindMapNode
  >
  nodes;

  /// Mantido no construtor por compatibilidade.
  ///
  /// As conexões agora usam o verde padrão do mapa mental
  /// para manter contraste com a lousa escura.
  final Color color;

  final double nodeWidth;

  final double nodeHeight;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF3F914A,
  );

  static const Color _greenBright = Color(
    0xFF76BD7D,
  );

  // ============================================================
  // PAINT
  // ============================================================

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ==========================================================
    // LINHA PRINCIPAL
    // ==========================================================

    final linePaint = Paint()
      ..color = _green.withValues(
        alpha: .95,
      )
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // ==========================================================
    // BRILHO / CONTRASTE
    // ==========================================================

    final glowPaint = Paint()
      ..color = _greenBright.withValues(
        alpha: .18,
      )
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        4,
      );

    // ==========================================================
    // PONTOS DAS CONEXÕES
    // ==========================================================

    final pointPaint = Paint()..color = _greenBright;

    final pointBorderPaint = Paint()
      ..color = _green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // ==========================================================
    // MAPA DOS NÓS
    // ==========================================================

    final nodesById =
        <
          String,
          MindMapNode
        >{
          for (final node in nodes) node.id: node,
        };

    // ==========================================================
    // CONEXÕES
    // ==========================================================

    for (final node in nodes) {
      final parentId = node.parentId;

      if (parentId ==
          null) {
        continue;
      }

      final parent = nodesById[parentId];

      if (parent ==
          null) {
        continue;
      }

      // ========================================================
      // INÍCIO / FIM
      // ========================================================

      final start = _portOffset(
        parent,
        node.sourcePort,
      );

      final end = _portOffset(
        node,
        node.targetPort,
      );

      // ========================================================
      // DISTÂNCIA
      // ========================================================

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

      // ========================================================
      // CONTROLES BEZIER
      // ========================================================

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

      // ========================================================
      // PATH
      // ========================================================

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

      // ========================================================
      // DESENHAR BRILHO PRIMEIRO
      // ========================================================

      canvas.drawPath(
        path,
        glowPaint,
      );

      // ========================================================
      // LINHA PRINCIPAL
      // ========================================================

      canvas.drawPath(
        path,
        linePaint,
      );

      // ========================================================
      // PONTO INICIAL
      // ========================================================

      canvas.drawCircle(
        start,
        4,
        pointPaint,
      );

      canvas.drawCircle(
        start,
        4,
        pointBorderPaint,
      );

      // ========================================================
      // PONTO FINAL
      // ========================================================

      canvas.drawCircle(
        end,
        4,
        pointPaint,
      );

      canvas.drawCircle(
        end,
        4,
        pointBorderPaint,
      );
    }
  }

  // ============================================================
  // OFFSET DA PORTA
  // ============================================================

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

  // ============================================================
  // DIREÇÃO DA PORTA
  // ============================================================

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

  // ============================================================
  // REPAINT
  // ============================================================

  @override
  bool shouldRepaint(
    covariant MindMapConnectionsPainter oldDelegate,
  ) {
    return oldDelegate.nodes !=
            nodes ||
        oldDelegate.nodeWidth !=
            nodeWidth ||
        oldDelegate.nodeHeight !=
            nodeHeight ||
        oldDelegate.color !=
            color;
  }
}
