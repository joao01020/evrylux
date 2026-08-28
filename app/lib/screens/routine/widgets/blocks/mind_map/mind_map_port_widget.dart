import 'package:flutter/material.dart';

import '../../../models/node_port.dart';

class MindMapPortWidget
    extends
        StatelessWidget {
  const MindMapPortWidget({
    super.key,
    required this.port,
    required this.color,
    required this.onTap,
    this.visible = true,
  });

  static const double size = 15;

  final NodePort port;
  final Color color;
  final VoidCallback onTap;
  final bool visible;

  @override
  Widget build(
    BuildContext context,
  ) {
    final dot = AnimatedOpacity(
      duration: const Duration(
        milliseconds: 120,
      ),
      opacity: visible
          ? 1
          : 0,
      child: IgnorePointer(
        ignoring: !visible,
        child: Tooltip(
          message: 'Criar conexão ${port.label}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF0D0F15,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(
                        alpha: .45,
                      ),
                      blurRadius: 7,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: color,
                  size: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return switch (port) {
      NodePort.top => Positioned(
        top: 1,
        left: 58.5,
        child: dot,
      ),
      NodePort.right => Positioned(
        right: 1,
        top: 15.5,
        child: dot,
      ),
      NodePort.bottom => Positioned(
        bottom: 1,
        left: 58.5,
        child: dot,
      ),
      NodePort.left => Positioned(
        left: 1,
        top: 15.5,
        child: dot,
      ),
    };
  }
}
