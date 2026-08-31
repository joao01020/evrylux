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
// CORREÇÃO PRINCIPAL:
//
// Antes:
//
// body_front_base.svg
// + chest.svg
// + shoulders.svg
// + arms.svg
// + abdomen.svg
// + quadriceps.svg
// + calves.svg
//
// Mesmo usando o mesmo viewBox, pequenas diferenças nos SVGs
// geravam áreas verdes fora do corpo.
//
// Agora:
//
// body_front_base.svg
// + CustomPaint com os músculos
//
// Assim:
//
// - desenho;
// - hover;
// - clique;
// - seleção;
//
// usam EXATAMENTE os mesmos Paths.
//
// Isso elimina o desalinhamento visual.
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

  static const Size _designSize = Size(
    505,
    985,
  );

  // ============================================================
  // ASSET
  // ============================================================

  static const String _bodyBaseAsset = 'assets/body_map/body_front_base.svg';

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

  // ============================================================
  // HOVER
  // ============================================================

  Offset? _hoverPosition;

  // ============================================================
  // BODY RECT
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

    final scaleX =
        viewport.width /
        _designSize.width;

    final scaleY =
        viewport.height /
        _designSize.height;

    final scale =
        scaleX <
            scaleY
        ? scaleX
        : scaleY;

    final width =
        _designSize.width *
        scale;

    final height =
        _designSize.height *
        scale;

    return Rect.fromLTWH(
      (viewport.width -
              width) /
          2,
      (viewport.height -
              height) /
          2,
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
    final rect = _bodyRectFor(
      viewport,
    );

    if (rect.isEmpty ||
        !rect.contains(
          localPosition,
        )) {
      return null;
    }

    return Offset(
      (localPosition.dx -
              rect.left) /
          rect.width *
          _designSize.width,
      (localPosition.dy -
              rect.top) /
          rect.height *
          _designSize.height,
    );
  }

  // ============================================================
  // HIT TEST
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

    // Ordem importante:
    //
    // regiões centrais/menores primeiro.

    if (_BodyRegionPaths.pathFor(
      BodyRegion.abdomen,
    ).contains(
      position,
    )) {
      return BodyRegion.abdomen;
    }

    if (_BodyRegionPaths.pathFor(
      BodyRegion.chest,
    ).contains(
      position,
    )) {
      return BodyRegion.chest;
    }

    if (_BodyRegionPaths.pathFor(
      BodyRegion.shoulders,
    ).contains(
      position,
    )) {
      return BodyRegion.shoulders;
    }

    if (_BodyRegionPaths.pathFor(
      BodyRegion.arms,
    ).contains(
      position,
    )) {
      return BodyRegion.arms;
    }

    if (_BodyRegionPaths.pathFor(
      BodyRegion.quadriceps,
    ).contains(
      position,
    )) {
      return BodyRegion.quadriceps;
    }

    if (_BodyRegionPaths.pathFor(
      BodyRegion.calves,
    ).contains(
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
      return 0.90;
    }

    if (widget.controller.hoveredRegion ==
        region) {
      return 0.68;
    }

    if (widget.controller.configuredRegions.contains(
      region,
    )) {
      return 0.72;
    }

    // Disponível = invisível.
    //
    // Evita aquele efeito de todas as áreas verdes aparecendo
    // ao mesmo tempo.
    return 0.0;
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
                            // BODY
                            // ==========================================
                            Positioned.fromRect(
                              rect: bodyRect,
                              child: SvgPicture.asset(
                                _bodyBaseAsset,
                                fit: BoxFit.fill,
                                alignment: Alignment.center,
                              ),
                            ),

                            // ==========================================
                            // MUSCLE OVERLAYS
                            // ==========================================
                            //
                            // CustomPaint usa o MESMO Rect e os MESMOS
                            // Paths do hit-test.
                            //
                            // ==========================================
                            Positioned.fromRect(
                              rect: bodyRect,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _BodyRegionOverlayPainter(
                                    selectedRegion: widget.controller.selectedRegion,
                                    hoveredRegion: widget.controller.hoveredRegion,
                                    configuredRegions: widget.controller.configuredRegions,
                                    regionColor: _regionColor,
                                    regionOpacity: _regionOpacity,
                                  ),
                                  size: Size.infinite,
                                ),
                              ),
                            ),

                            // ==========================================
                            // SELECTED REGION BADGE
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
}

// ============================================================
// BODY REGION OVERLAY PAINTER
// ============================================================

class _BodyRegionOverlayPainter
    extends
        CustomPainter {
  const _BodyRegionOverlayPainter({
    required this.selectedRegion,
    required this.hoveredRegion,
    required this.configuredRegions,
    required this.regionColor,
    required this.regionOpacity,
  });

  final BodyRegion? selectedRegion;

  final BodyRegion? hoveredRegion;

  final Set<
    BodyRegion
  >
  configuredRegions;

  final Color Function(
    BodyRegion region,
  )
  regionColor;

  final double Function(
    BodyRegion region,
  )
  regionOpacity;

  static const Size _designSize = Size(
    505,
    985,
  );

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (size.width <=
            0 ||
        size.height <=
            0) {
      return;
    }

    final sx =
        size.width /
        _designSize.width;

    final sy =
        size.height /
        _designSize.height;

    canvas.save();

    canvas.scale(
      sx,
      sy,
    );

    for (final region in BodyRegion.values) {
      final opacity = regionOpacity(
        region,
      );

      if (opacity <=
          0) {
        continue;
      }

      final path = _BodyRegionPaths.pathFor(
        region,
      );

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..color =
            regionColor(
              region,
            ).withValues(
              alpha: opacity,
            );

      final strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            region ==
                selectedRegion
            ? 2.4
            : 1.5
        ..isAntiAlias = true
        ..color =
            regionColor(
              region,
            ).withValues(
              alpha:
                  (opacity +
                          0.16)
                      .clamp(
                        0.0,
                        1.0,
                      ),
            );

      canvas.drawPath(
        path,
        fillPaint,
      );

      canvas.drawPath(
        path,
        strokePaint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(
    covariant _BodyRegionOverlayPainter oldDelegate,
  ) {
    return oldDelegate.selectedRegion !=
            selectedRegion ||
        oldDelegate.hoveredRegion !=
            hoveredRegion ||
        !_sameRegions(
          oldDelegate.configuredRegions,
          configuredRegions,
        );
  }

  bool _sameRegions(
    Set<
      BodyRegion
    >
    first,
    Set<
      BodyRegion
    >
    second,
  ) {
    if (first.length !=
        second.length) {
      return false;
    }

    for (final region in first) {
      if (!second.contains(
        region,
      )) {
        return false;
      }
    }

    return true;
  }
}

// ============================================================
// BODY REGION PATHS
// ============================================================
//
// Estes Paths são usados por:
//
// 1. desenho;
// 2. hover;
// 3. clique.
//
// Portanto não existe mais risco de o hit-test usar uma região
// diferente da região que aparece na tela.
//
// ============================================================

class _BodyRegionPaths {
  _BodyRegionPaths._();

  static Path pathFor(
    BodyRegion region,
  ) {
    switch (region) {
      case BodyRegion.chest:
        return _chest();

      case BodyRegion.shoulders:
        return _shoulders();

      case BodyRegion.arms:
        return _arms();

      case BodyRegion.abdomen:
        return _abdomen();

      case BodyRegion.quadriceps:
        return _quadriceps();

      case BodyRegion.calves:
        return _calves();
    }
  }

  // ============================================================
  // CHEST
  // ============================================================

  static Path _chest() {
    final path = Path();

    path.addPath(
      Path()
        ..moveTo(
          112,
          222,
        )
        ..cubicTo(
          139,
          204,
          181,
          205,
          236,
          222,
        )
        ..cubicTo(
          241,
          236,
          242,
          253,
          238,
          274,
        )
        ..cubicTo(
          225,
          293,
          196,
          304,
          164,
          302,
        )
        ..cubicTo(
          137,
          300,
          117,
          289,
          108,
          272,
        )
        ..cubicTo(
          103,
          253,
          104,
          236,
          112,
          222,
        )
        ..close(),
      Offset.zero,
    );

    path.addPath(
      Path()
        ..moveTo(
          393,
          222,
        )
        ..cubicTo(
          366,
          204,
          324,
          205,
          269,
          222,
        )
        ..cubicTo(
          264,
          236,
          263,
          253,
          267,
          274,
        )
        ..cubicTo(
          280,
          293,
          309,
          304,
          341,
          302,
        )
        ..cubicTo(
          368,
          300,
          388,
          289,
          397,
          272,
        )
        ..cubicTo(
          402,
          253,
          401,
          236,
          393,
          222,
        )
        ..close(),
      Offset.zero,
    );

    return path;
  }

  // ============================================================
  // SHOULDERS
  // ============================================================

  static Path _shoulders() {
    final path = Path();

    path.addPath(
      Path()
        ..moveTo(
          100,
          216,
        )
        ..cubicTo(
          78,
          219,
          65,
          231,
          60,
          248,
        )
        ..cubicTo(
          57,
          264,
          62,
          278,
          74,
          286,
        )
        ..cubicTo(
          88,
          287,
          99,
          279,
          106,
          266,
        )
        ..cubicTo(
          112,
          252,
          112,
          236,
          107,
          225,
        )
        ..cubicTo(
          105,
          220,
          103,
          217,
          100,
          216,
        )
        ..close(),
      Offset.zero,
    );

    path.addPath(
      Path()
        ..moveTo(
          405,
          216,
        )
        ..cubicTo(
          427,
          219,
          440,
          231,
          445,
          248,
        )
        ..cubicTo(
          448,
          264,
          443,
          278,
          431,
          286,
        )
        ..cubicTo(
          417,
          287,
          406,
          279,
          399,
          266,
        )
        ..cubicTo(
          393,
          252,
          393,
          236,
          398,
          225,
        )
        ..cubicTo(
          400,
          220,
          402,
          217,
          405,
          216,
        )
        ..close(),
      Offset.zero,
    );

    return path;
  }

  // ============================================================
  // ARMS
  // ============================================================

  static Path _arms() {
    final path = Path();

    // LEFT UPPER ARM

    path.addPath(
      Path()
        ..moveTo(
          91,
          278,
        )
        ..cubicTo(
          76,
          283,
          66,
          297,
          62,
          316,
        )
        ..cubicTo(
          58,
          337,
          61,
          358,
          72,
          371,
        )
        ..cubicTo(
          85,
          370,
          97,
          355,
          103,
          337,
        )
        ..cubicTo(
          109,
          318,
          107,
          297,
          99,
          285,
        )
        ..cubicTo(
          97,
          281,
          94,
          279,
          91,
          278,
        )
        ..close(),
      Offset.zero,
    );

    // LEFT FOREARM

    path.addPath(
      Path()
        ..moveTo(
          67,
          374,
        )
        ..cubicTo(
          56,
          384,
          49,
          404,
          44,
          426,
        )
        ..cubicTo(
          38,
          453,
          37,
          480,
          44,
          500,
        )
        ..cubicTo(
          51,
          508,
          59,
          499,
          66,
          485,
        )
        ..cubicTo(
          75,
          466,
          80,
          440,
          80,
          416,
        )
        ..cubicTo(
          79,
          395,
          74,
          380,
          67,
          374,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT UPPER ARM

    path.addPath(
      Path()
        ..moveTo(
          414,
          278,
        )
        ..cubicTo(
          429,
          283,
          439,
          297,
          443,
          316,
        )
        ..cubicTo(
          447,
          337,
          444,
          358,
          433,
          371,
        )
        ..cubicTo(
          420,
          370,
          408,
          355,
          402,
          337,
        )
        ..cubicTo(
          396,
          318,
          398,
          297,
          406,
          285,
        )
        ..cubicTo(
          408,
          281,
          411,
          279,
          414,
          278,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT FOREARM

    path.addPath(
      Path()
        ..moveTo(
          438,
          374,
        )
        ..cubicTo(
          449,
          384,
          456,
          404,
          461,
          426,
        )
        ..cubicTo(
          467,
          453,
          468,
          480,
          461,
          500,
        )
        ..cubicTo(
          454,
          508,
          446,
          499,
          439,
          485,
        )
        ..cubicTo(
          430,
          466,
          425,
          440,
          425,
          416,
        )
        ..cubicTo(
          426,
          395,
          431,
          380,
          438,
          374,
        )
        ..close(),
      Offset.zero,
    );

    return path;
  }

  // ============================================================
  // ABDOMEN
  // ============================================================

  static Path _abdomen() {
    final path = Path();

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          207,
          311,
          39,
          43,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          259,
          311,
          39,
          43,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          205,
          359,
          41,
          44,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          259,
          359,
          41,
          44,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          208,
          408,
          38,
          43,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    path.addRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
          259,
          408,
          38,
          43,
        ),
        const Radius.circular(
          11,
        ),
      ),
    );

    // LEFT OBLIQUE

    path.addPath(
      Path()
        ..moveTo(
          190,
          321,
        )
        ..cubicTo(
          182,
          343,
          181,
          373,
          184,
          404,
        )
        ..cubicTo(
          187,
          432,
          194,
          452,
          206,
          463,
        )
        ..cubicTo(
          211,
          452,
          212,
          434,
          210,
          414,
        )
        ..cubicTo(
          208,
          384,
          208,
          352,
          214,
          325,
        )
        ..cubicTo(
          205,
          320,
          197,
          319,
          190,
          321,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT OBLIQUE

    path.addPath(
      Path()
        ..moveTo(
          315,
          321,
        )
        ..cubicTo(
          323,
          343,
          324,
          373,
          321,
          404,
        )
        ..cubicTo(
          318,
          432,
          311,
          452,
          299,
          463,
        )
        ..cubicTo(
          294,
          452,
          293,
          434,
          295,
          414,
        )
        ..cubicTo(
          297,
          384,
          297,
          352,
          291,
          325,
        )
        ..cubicTo(
          300,
          320,
          308,
          319,
          315,
          321,
        )
        ..close(),
      Offset.zero,
    );

    return path;
  }

  // ============================================================
  // QUADRICEPS
  // ============================================================

  static Path _quadriceps() {
    final path = Path();

    // LEFT OUTER

    path.addPath(
      Path()
        ..moveTo(
          133,
          574,
        )
        ..cubicTo(
          122,
          594,
          117,
          625,
          118,
          658,
        )
        ..cubicTo(
          119,
          691,
          127,
          724,
          139,
          745,
        )
        ..cubicTo(
          149,
          757,
          159,
          745,
          164,
          724,
        )
        ..cubicTo(
          169,
          699,
          170,
          667,
          166,
          636,
        )
        ..cubicTo(
          162,
          606,
          151,
          581,
          141,
          574,
        )
        ..cubicTo(
          138,
          572,
          135,
          572,
          133,
          574,
        )
        ..close(),
      Offset.zero,
    );

    // LEFT INNER

    path.addPath(
      Path()
        ..moveTo(
          181,
          578,
        )
        ..cubicTo(
          191,
          598,
          195,
          628,
          194,
          660,
        )
        ..cubicTo(
          193,
          692,
          188,
          720,
          179,
          741,
        )
        ..cubicTo(
          171,
          748,
          165,
          733,
          163,
          711,
        )
        ..cubicTo(
          160,
          681,
          162,
          646,
          167,
          616,
        )
        ..cubicTo(
          171,
          593,
          176,
          580,
          181,
          578,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT OUTER

    path.addPath(
      Path()
        ..moveTo(
          372,
          574,
        )
        ..cubicTo(
          383,
          594,
          388,
          625,
          387,
          658,
        )
        ..cubicTo(
          386,
          691,
          378,
          724,
          366,
          745,
        )
        ..cubicTo(
          356,
          757,
          346,
          745,
          341,
          724,
        )
        ..cubicTo(
          336,
          699,
          335,
          667,
          339,
          636,
        )
        ..cubicTo(
          343,
          606,
          354,
          581,
          364,
          574,
        )
        ..cubicTo(
          367,
          572,
          370,
          572,
          372,
          574,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT INNER

    path.addPath(
      Path()
        ..moveTo(
          324,
          578,
        )
        ..cubicTo(
          314,
          598,
          310,
          628,
          311,
          660,
        )
        ..cubicTo(
          312,
          692,
          317,
          720,
          326,
          741,
        )
        ..cubicTo(
          334,
          748,
          340,
          733,
          342,
          711,
        )
        ..cubicTo(
          345,
          681,
          343,
          646,
          338,
          616,
        )
        ..cubicTo(
          334,
          593,
          329,
          580,
          324,
          578,
        )
        ..close(),
      Offset.zero,
    );

    return path;
  }

  // ============================================================
  // CALVES
  // ============================================================

  static Path _calves() {
    final path = Path();

    // LEFT OUTER

    path.addPath(
      Path()
        ..moveTo(
          125,
          743,
        )
        ..cubicTo(
          115,
          760,
          111,
          786,
          112,
          815,
        )
        ..cubicTo(
          113,
          846,
          120,
          874,
          130,
          891,
        )
        ..cubicTo(
          139,
          900,
          147,
          887,
          151,
          868,
        )
        ..cubicTo(
          155,
          844,
          155,
          816,
          151,
          790,
        )
        ..cubicTo(
          147,
          764,
          137,
          746,
          128,
          743,
        )
        ..cubicTo(
          127,
          743,
          126,
          743,
          125,
          743,
        )
        ..close(),
      Offset.zero,
    );

    // LEFT INNER

    path.addPath(
      Path()
        ..moveTo(
          176,
          744,
        )
        ..cubicTo(
          185,
          761,
          189,
          787,
          188,
          815,
        )
        ..cubicTo(
          187,
          844,
          181,
          872,
          172,
          889,
        )
        ..cubicTo(
          164,
          897,
          158,
          883,
          156,
          864,
        )
        ..cubicTo(
          153,
          839,
          155,
          811,
          159,
          786,
        )
        ..cubicTo(
          163,
          762,
          169,
          746,
          176,
          744,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT OUTER

    path.addPath(
      Path()
        ..moveTo(
          380,
          743,
        )
        ..cubicTo(
          390,
          760,
          394,
          786,
          393,
          815,
        )
        ..cubicTo(
          392,
          846,
          385,
          874,
          375,
          891,
        )
        ..cubicTo(
          366,
          900,
          358,
          887,
          354,
          868,
        )
        ..cubicTo(
          350,
          844,
          350,
          816,
          354,
          790,
        )
        ..cubicTo(
          358,
          764,
          368,
          746,
          377,
          743,
        )
        ..cubicTo(
          378,
          743,
          379,
          743,
          380,
          743,
        )
        ..close(),
      Offset.zero,
    );

    // RIGHT INNER

    path.addPath(
      Path()
        ..moveTo(
          329,
          744,
        )
        ..cubicTo(
          320,
          761,
          316,
          787,
          317,
          815,
        )
        ..cubicTo(
          318,
          844,
          324,
          872,
          333,
          889,
        )
        ..cubicTo(
          341,
          897,
          347,
          883,
          349,
          864,
        )
        ..cubicTo(
          352,
          839,
          350,
          811,
          346,
          786,
        )
        ..cubicTo(
          342,
          762,
          336,
          746,
          329,
          744,
        )
        ..close(),
      Offset.zero,
    );

    return path;
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
