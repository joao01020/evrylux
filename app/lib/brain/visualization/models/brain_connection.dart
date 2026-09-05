import 'package:flutter/material.dart';

@immutable
class BrainConnectionDefinition {
  const BrainConnectionDefinition({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;

  Path build(Size size) {
    Offset map(Offset value) {
      return Offset(
        value.dx * size.width,
        value.dy * size.height,
      );
    }

    final path = Path();
    final s = map(start);
    final c1 = map(control1);
    final c2 = map(control2);
    final e = map(end);

    path.moveTo(s.dx, s.dy);
    path.cubicTo(
      c1.dx,
      c1.dy,
      c2.dx,
      c2.dy,
      e.dx,
      e.dy,
    );

    return path;
  }
}
