import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controllers/body_map_controller.dart';
import '../models/body_region.dart';

// ============================================================
// BODY MAP FRONT
// ============================================================
//
// Corpo frontal interativo.
//
// CORREÇÃO DE ALINHAMENTO:
//
// Todos os SVGs novos usam exatamente:
//
// viewBox="0 0 505 985"
//
// Por isso:
//
// - corpo base;
// - peito;
// - ombros;
// - braços;
// - abdômen;
// - quadríceps;
// - panturrilhas;
//
// são desenhados dentro do MESMO Rect.
//
// O hit-test também usa exatamente o mesmo sistema 505 x 985.
//
// Não usamos mais BodyMapPainter para detectar a região porque
// ele trabalhava no sistema antigo 300 x 620.
//
// ============================================================

class BodyMapFront
    extends
        StatefulWidget {
  const BodyMapFront({
    super.key,
    required this.controller,
    this.width = 360,
    this.height = 560,
    this.showHoverLabel = true,
  });

  // ============================================================
  // DATA
  // ============================================================

  final BodyMapController controller;

  final double width;

  final double height;

  final bool showHoverLabel;

  @override
  State<
    BodyMapFront
  >
  createState() => _BodyMapFrontState();
}

class _BodyMapFrontState
    extends
        State<
          BodyMapFront
        > {
  // ============================================================
  // DESIGN SIZE
  // ============================================================
  //
  // Precisa ser exatamente igual ao viewBox dos SVGs.
  //
  // ============================================================

  static const Size _designSize = Size(
    505,
    985,
  );

  // ============================================================
  // ASSETS
  // ============================================================

  static const String _bodyBaseAsset = 'assets/body_map/body_front_base.svg';

  static const Map<
    BodyRegion,
    String
  >
  _regionAssets =
      <
        BodyRegion,
        String
      >{
        BodyRegion.shoulders: 'assets/body_map/shoulders.svg',

        BodyRegion.chest: 'assets/body_map/chest.svg',

        BodyRegion.arms: 'assets/body_map/arms.svg',

        BodyRegion.abdomen: 'assets/body_map/abdomen.svg',

        BodyRegion.quadriceps: 'assets/body_map/quadriceps.svg',

        BodyRegion.calves: 'assets/body_map/calves.svg',
      };

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _availableColor = Color(
    0xFFBCF0B4,
  );

  static const Color _hoverColor = Color(
    0xFF8ADB81,
  );

  static const Color _configuredColor = Color(
    0xFF66C863,
  );

  static const Color _selectedColor = Color(
    0xFF4FB84C,
  );

  static const Color _selectedDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // HOVER
  // ============================================================

  Offset? _hoverPosition;

  // ============================================================
  // BODY RECT
  // ============================================================
  //
  // Retorna o retângulo exato onde o corpo é desenhado.
  //
  // Isso garante que:
  //
  // SVG base
  // SVG overlays
  // hit test
  //
  // usem exatamente o mesmo espaço.
  //
  // ============================================================

  Rect _bodyRectFor(
    Size viewport,
  ) {
    if (viewport.width <=
            0 ||
        viewport.height <=
            0) {
      return Rect.zero;
    }

    final scale =
        (viewport.width /
                _designSize.width) <
            (viewport.height /
                _designSize.height)
        ? viewport.width /
              _designSize.width
        : viewport.height /
              _designSize.height;

    final width =
        _designSize.width *
        scale;

    final height =
        _designSize.height *
        scale;

    final left =
        (viewport.width -
            width) /
        2;

    final top =
        (viewport.height -
            height) /
        2;

    return Rect.fromLTWH(
      left,
      top,
      width,
      height,
    );
  }

  // ============================================================
  // LOCAL -> DESIGN
  // ============================================================

  Offset? _toDesignPosition({
    required Offset localPosition,
    required Size viewport,
  }) {
    final bodyRect = _bodyRectFor(
      viewport,
    );

    if (bodyRect.isEmpty ||
        !bodyRect.contains(
          localPosition,
        )) {
      return null;
    }

    final dx =
        (localPosition.dx -
            bodyRect.left) /
        bodyRect.width *
        _designSize.width;

    final dy =
        (localPosition.dy -
            bodyRect.top) /
        bodyRect.height *
        _designSize.height;

    return Offset(
      dx,
      dy,
    );
  }

  // ============================================================
  // HIT TEST
  // ============================================================
  //
  // Os Paths abaixo seguem as mesmas áreas usadas nos SVGs.
  //
  // ============================================================

  BodyRegion? _hitTestRegion({
    required Offset localPosition,
    required Size viewport,
  }) {
    final position = _toDesignPosition(
      localPosition: localPosition,
      viewport: viewport,
    );

    if (position ==
        null) {
      return null;
    }

    // Selecionamos regiões menores antes das maiores para evitar
    // conflitos nas bordas.

    if (_abdomenPath().contains(
      position,
    )) {
      return BodyRegion.abdomen;
    }

    if (_chestPath().contains(
      position,
    )) {
      return BodyRegion.chest;
    }

    if (_shouldersPath().contains(
      position,
    )) {
      return BodyRegion.shoulders;
    }

    if (_armsPath().contains(
      position,
    )) {
      return BodyRegion.arms;
    }

    if (_quadricepsPath().contains(
      position,
    )) {
      return BodyRegion.quadriceps;
    }

    if (_calvesPath().contains(
      position,
    )) {
      return BodyRegion.calves;
    }

    return null;
  }

  // ============================================================
  // POINTER MOVE
  // ============================================================

  void _handleHover(
    PointerHoverEvent event,
    Size size,
  ) {
    final region = _hitTestRegion(
      localPosition: event.localPosition,
      viewport: size,
    );

    if (region !=
        widget.controller.hoveredRegion) {
      widget.controller.hoverRegion(
        region,
      );
    }

    if (!widget.showHoverLabel) {
      return;
    }

    if (region ==
        null) {
      if (_hoverPosition !=
              null &&
          mounted) {
        setState(
          () {
            _hoverPosition = null;
          },
        );
      }

      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _hoverPosition = event.localPosition;
      },
    );
  }

  // ============================================================
  // EXIT
  // ============================================================

  void _handleExit(
    PointerExitEvent event,
  ) {
    widget.controller.clearHover();

    if (_hoverPosition ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        _hoverPosition = null;
      },
    );
  }

  // ============================================================
  // TAP
  // ============================================================

  void _handleTap(
    TapDownDetails details,
    Size size,
  ) {
    final region = _hitTestRegion(
      localPosition: details.localPosition,
      viewport: size,
    );

    if (region ==
        null) {
      return;
    }

    widget.controller.selectRegion(
      region,
    );
  }

  // ============================================================
  // REGION COLOR
  // ============================================================

  Color _regionColor(
    BodyRegion region,
  ) {
    if (widget.controller.selectedRegion ==
        region) {
      return _selectedColor;
    }

    if (widget.controller.hoveredRegion ==
        region) {
      return _hoverColor;
    }

    if (widget.controller.configuredRegions.contains(
      region,
    )) {
      return _configuredColor;
    }

    return _availableColor;
  }

  // ============================================================
  // REGION OPACITY
  // ============================================================

  double _regionOpacity(
    BodyRegion region,
  ) {
    if (widget.controller.selectedRegion ==
        region) {
      return 1;
    }

    if (widget.controller.hoveredRegion ==
        region) {
      return 0.88;
    }

    if (widget.controller.configuredRegions.contains(
      region,
    )) {
      return 0.82;
    }

    // Quase invisível quando disponível.
    //
    // Assim o corpo humano continua sendo o protagonista e não
    // fica todo verde o tempo inteiro.
    return 0.06;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder:
          (
            context,
            _,
          ) {
            return LayoutBuilder(
              builder:
                  (
                    context,
                    constraints,
                  ) {
                    final resolvedWidth = constraints.hasBoundedWidth
                        ? constraints.maxWidth
                        : widget.width;

                    final resolvedHeight = constraints.hasBoundedHeight
                        ? constraints.maxHeight
                        : widget.height;

                    final size = Size(
                      resolvedWidth,
                      resolvedHeight,
                    );

                    final bodyRect = _bodyRectFor(
                      size,
                    );

                    return MouseRegion(
                      cursor:
                          widget.controller.hoveredRegion !=
                              null
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      onHover:
                          (
                            event,
                          ) {
                            _handleHover(
                              event,
                              size,
                            );
                          },
                      onExit: _handleExit,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown:
                            (
                              details,
                            ) {
                              _handleTap(
                                details,
                                size,
                              );
                            },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // ==========================================
                            // BODY + REGIONS
                            // ==========================================
                            Positioned.fromRect(
                              rect: bodyRect,
                              child: _BodySvgLayers(
                                regionColor: _regionColor,
                                regionOpacity: _regionOpacity,
                              ),
                            ),

                            // ==========================================
                            // SELECTED REGION
                            // ==========================================
                            if (widget.controller.selectedRegion !=
                                null)
                              Positioned(
                                left: 12,
                                bottom: 12,
                                child: _SelectedRegionBadge(
                                  region: widget.controller.selectedRegion!,
                                ),
                              ),

                            // ==========================================
                            // HOVER LABEL
                            // ==========================================
                            if (widget.showHoverLabel &&
                                widget.controller.hoveredRegion !=
                                    null &&
                                _hoverPosition !=
                                    null)
                              _HoverLabel(
                                region: widget.controller.hoveredRegion!,
                                position: _hoverPosition!,
                                bounds: size,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // PATH - CHEST
  // ============================================================

  Path _chestPath() {
    return Path()
      ..addPath(
        Path()
          ..moveTo(
            116,
            214,
          )
          ..cubicTo(
            145,
            190,
            192,
            191,
            237,
            211,
          )
          ..cubicTo(
            243,
            235,
            242,
            273,
            236,
            302,
          )
          ..cubicTo(
            199,
            320,
            154,
            315,
            127,
            292,
          )
          ..cubicTo(
            111,
            270,
            106,
            237,
            116,
            214,
          )
          ..close(),
        Offset.zero,
      )
      ..addPath(
        Path()
          ..moveTo(
            389,
            214,
          )
          ..cubicTo(
            360,
            190,
            313,
            191,
            268,
            211,
          )
          ..cubicTo(
            262,
            235,
            263,
            273,
            269,
            302,
          )
          ..cubicTo(
            306,
            320,
            351,
            315,
            378,
            292,
          )
          ..cubicTo(
            394,
            270,
            399,
            237,
            389,
            214,
          )
          ..close(),
        Offset.zero,
      );
  }

  // ============================================================
  // PATH - SHOULDERS
  // ============================================================

  Path _shouldersPath() {
    return Path()
      ..addOval(
        const Rect.fromLTWH(
          46,
          195,
          80,
          120,
        ),
      )
      ..addOval(
        const Rect.fromLTWH(
          379,
          195,
          80,
          120,
        ),
      );
  }

  // ============================================================
  // PATH - ARMS
  // ============================================================

  Path _armsPath() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            27,
            273,
            88,
            290,
          ),
          const Radius.circular(
            40,
          ),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            390,
            273,
            88,
            290,
          ),
          const Radius.circular(
            40,
          ),
        ),
      );
  }

  // ============================================================
  // PATH - ABDOMEN
  // ============================================================

  Path _abdomenPath() {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          194,
          300,
          117,
          305,
        ),
        const Radius.circular(
          34,
        ),
      ),
    );
  }

  // ============================================================
  // PATH - QUADRICEPS
  // ============================================================

  Path _quadricepsPath() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            96,
            560,
            110,
            315,
          ),
          const Radius.circular(
            48,
          ),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            299,
            560,
            110,
            315,
          ),
          const Radius.circular(
            48,
          ),
        ),
      );
  }

  // ============================================================
  // PATH - CALVES
  // ============================================================

  Path _calvesPath() {
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            99,
            810,
            103,
            170,
          ),
          const Radius.circular(
            40,
          ),
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(
            303,
            810,
            103,
            170,
          ),
          const Radius.circular(
            40,
          ),
        ),
      );
  }
}

// ============================================================
// SVG LAYERS
// ============================================================

class _BodySvgLayers
    extends
        StatelessWidget {
  const _BodySvgLayers({
    required this.regionColor,
    required this.regionOpacity,
  });

  final Color Function(
    BodyRegion region,
  )
  regionColor;

  final double Function(
    BodyRegion region,
  )
  regionOpacity;

  static const String _bodyBaseAsset = 'assets/body_map/body_front_base.svg';

  static const Map<
    BodyRegion,
    String
  >
  _regionAssets =
      <
        BodyRegion,
        String
      >{
        BodyRegion.shoulders: 'assets/body_map/shoulders.svg',

        BodyRegion.chest: 'assets/body_map/chest.svg',

        BodyRegion.arms: 'assets/body_map/arms.svg',

        BodyRegion.abdomen: 'assets/body_map/abdomen.svg',

        BodyRegion.quadriceps: 'assets/body_map/quadriceps.svg',

        BodyRegion.calves: 'assets/body_map/calves.svg',
      };

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ======================================================
        // BASE BODY
        // ======================================================
        SvgPicture.asset(
          _bodyBaseAsset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
          alignment: Alignment.center,
        ),

        // ======================================================
        // REGIONS
        // ======================================================
        for (final entry in _regionAssets.entries)
          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 140,
            ),
            curve: Curves.easeOut,
            opacity: regionOpacity(
              entry.key,
            ),
            child: SvgPicture.asset(
              entry.value,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.fill,
              alignment: Alignment.center,
              colorFilter: ColorFilter.mode(
                regionColor(
                  entry.key,
                ),
                BlendMode.srcIn,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================
// SELECTED REGION BADGE
// ============================================================

class _SelectedRegionBadge
    extends
        StatelessWidget {
  const _SelectedRegionBadge({
    required this.region,
  });

  final BodyRegion region;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(
            999,
          ),
          border: Border.all(
            color: _border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x16000000,
              ),
              blurRadius: 12,
              offset: Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                region.icon,
                size: 13,
                color: _primaryDark,
              ),
            ),
            const SizedBox(
              width: 7,
            ),
            Text(
              region.label,
              style: const TextStyle(
                color: _text,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// HOVER LABEL
// ============================================================

class _HoverLabel
    extends
        StatelessWidget {
  const _HoverLabel({
    required this.region,
    required this.position,
    required this.bounds,
  });

  final BodyRegion region;

  final Offset position;

  final Size bounds;

  static const double _width = 138;

  static const double _height = 42;

  static const Color _background = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFFAEB8B0,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    final rawLeft =
        position.dx +
        14;

    final rawTop =
        position.dy -
        50;

    final maxLeft =
        bounds.width -
        _width;

    final maxTop =
        bounds.height -
        _height;

    final safeMaxLeft =
        maxLeft <
            0
        ? 0.0
        : maxLeft;

    final safeMaxTop =
        maxTop <
            0
        ? 0.0
        : maxTop;

    final left = rawLeft
        .clamp(
          0.0,
          safeMaxLeft,
        )
        .toDouble();

    final top = rawTop
        .clamp(
          0.0,
          safeMaxTop,
        )
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: _width,
          height: _height,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              11,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x24000000,
                ),
                blurRadius: 12,
                offset: Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                region.icon,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(
                width: 8,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      region.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'Clique para selecionar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
