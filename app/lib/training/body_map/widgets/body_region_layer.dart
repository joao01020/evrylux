import 'package:flutter/material.dart';

import '../models/body_region.dart';

// ============================================================
// BODY REGION LAYER
// ============================================================
//
// Camada visual genérica para uma região corporal.
//
// Este widget é útil quando quisermos complementar o
// CustomPainter com overlays posicionados, SVGs ou imagens.
//
// Pode representar:
//
// - região disponível;
// - região em hover;
// - região configurada;
// - região selecionada.
//
// ============================================================

class BodyRegionLayer
    extends
        StatelessWidget {
  const BodyRegionLayer({
    super.key,
    required this.region,
    required this.child,
    required this.onTap,
    this.onHover,
    this.selected = false,
    this.hovered = false,
    this.configured = false,
    this.enabled = true,
    this.borderRadius = const BorderRadius.all(
      Radius.circular(
        12,
      ),
    ),
  });

  final BodyRegion region;

  final Widget child;

  final VoidCallback onTap;

  final ValueChanged<
    bool
  >?
  onHover;

  final bool selected;

  final bool hovered;

  final bool configured;

  final bool enabled;

  final BorderRadius borderRadius;

  static const Color _available = Color(
    0x18BCF0B4,
  );

  static const Color _hover = Color(
    0x44BCF0B4,
  );

  static const Color _configured = Color(
    0x669EDB94,
  );

  static const Color _selected = Color(
    0x8872C56B,
  );

  static const Color _outline = Color(
    0xAA3B6939,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final background = _resolveBackground();

    final borderColor =
        selected ||
            hovered
        ? _outline
        : Colors.transparent;

    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter:
          (
            _,
          ) {
            if (!enabled) {
              return;
            }

            onHover?.call(
              true,
            );
          },
      onExit:
          (
            _,
          ) {
            if (!enabled) {
              return;
            }

            onHover?.call(
              false,
            );
          },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? onTap
            : null,
        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 140,
          ),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor,
              width: selected
                  ? 1.6
                  : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color _resolveBackground() {
    if (!enabled) {
      return Colors.transparent;
    }

    if (selected) {
      return _selected;
    }

    if (hovered) {
      return _hover;
    }

    if (configured) {
      return _configured;
    }

    return _available;
  }
}
