import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/body_region.dart';

// ============================================================
// BODY MAP PAINTER
// ============================================================
//
// Corpo humano frontal simplificado.
//
// O desenho utiliza um sistema virtual de:
//
// 300 x 620
//
// Isso permite redimensionar mantendo proporção.
//
// Também fornece:
//
// hitTestRegion()
//
// para descobrir qual região está embaixo do mouse.
//
// ============================================================

class BodyMapPainter
    extends
        CustomPainter {
  const BodyMapPainter({
    this.hoveredRegion,
    this.selectedRegion,
    this.configuredRegions =
        const <
          BodyRegion
        >{},
  });

  // ============================================================
  // STATE
  // ============================================================

  final BodyRegion? hoveredRegion;

  final BodyRegion? selectedRegion;

  final Set<
    BodyRegion
  >
  configuredRegions;

  // ============================================================
  // DESIGN SIZE
  // ============================================================

  static const Size designSize = Size(
    300,
    620,
  );

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _bodyColor = Color(
    0xFFE4E8E3,
  );

  static const Color _bodyOutline = Color(
    0xFFBAC4BA,
  );

  static const Color _bodyShadow = Color(
    0x22000000,
  );

  static const Color _available = Color(
    0xFFDDF3D8,
  );

  static const Color _hover = Color(
    0xFFBCF0B4,
  );

  static const Color _selected = Color(
    0xFF72C56B,
  );

  static const Color _configured = Color(
    0xFF9EDB94,
  );

  static const Color _regionOutline = Color(
    0xFF79B873,
  );

  // ============================================================
  // PAINT
  // ============================================================

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final transform = _BodyMapTransform(
      size: size,
    );

    canvas.save();

    canvas.translate(
      transform.offset.dx,
      transform.offset.dy,
    );

    canvas.scale(
      transform.scale,
    );

    _paintShadow(
      canvas,
    );

    _paintBaseBody(
      canvas,
    );

    _paintRegions(
      canvas,
    );

    canvas.restore();
  }

  // ============================================================
  // SHADOW
  // ============================================================

  void _paintShadow(
    Canvas canvas,
  ) {
    final paint = Paint()
      ..color = _bodyShadow
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        12,
      );

    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(
          150,
          596,
        ),
        width: 150,
        height: 18,
      ),
      paint,
    );
  }

  // ============================================================
  // BASE BODY
  // ============================================================

  void _paintBaseBody(
    Canvas canvas,
  ) {
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = _bodyColor;

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = _bodyOutline;

    final paths = _BodyGeometry.baseBodyPaths;

    for (final path in paths) {
      canvas.drawPath(
        path,
        fill,
      );

      canvas.drawPath(
        path,
        outline,
      );
    }
  }

  // ============================================================
  // PAINT REGIONS
  // ============================================================

  void _paintRegions(
    Canvas canvas,
  ) {
    for (final region in BodyRegion.values) {
      final paths = _BodyGeometry.regionPaths(
        region,
      );

      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = _colorFor(
          region,
        );

      final outline = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _regionOutline.withValues(
          alpha: 0.55,
        );

      for (final path in paths) {
        canvas.drawPath(
          path,
          fill,
        );

        canvas.drawPath(
          path,
          outline,
        );
      }
    }
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color _colorFor(
    BodyRegion region,
  ) {
    if (selectedRegion ==
        region) {
      return _selected;
    }

    if (hoveredRegion ==
        region) {
      return _hover;
    }

    if (configuredRegions.contains(
      region,
    )) {
      return _configured;
    }

    return _available.withValues(
      alpha: 0.50,
    );
  }

  // ============================================================
  // HIT TEST
  // ============================================================
  //
  // Converte a posição real do mouse para o espaço virtual
  // 300 x 620 e verifica qual Path contém aquele ponto.
  //
  // ============================================================

  static BodyRegion? hitTestRegion({
    required Size size,
    required Offset position,
  }) {
    final transform = _BodyMapTransform(
      size: size,
    );

    final local = Offset(
      (position.dx -
              transform.offset.dx) /
          transform.scale,
      (position.dy -
              transform.offset.dy) /
          transform.scale,
    );

    // Ordem proposital.
    //
    // Regiões menores são testadas primeiro para evitar
    // que uma região maior capture o clique indevidamente.

    const hitOrder =
        <
          BodyRegion
        >[
          BodyRegion.shoulders,
          BodyRegion.chest,
          BodyRegion.arms,
          BodyRegion.abdomen,
          BodyRegion.calves,
          BodyRegion.quadriceps,
        ];

    for (final region in hitOrder) {
      final paths = _BodyGeometry.regionPaths(
        region,
      );

      for (final path in paths) {
        if (path.contains(
          local,
        )) {
          return region;
        }
      }
    }

    return null;
  }

  // ============================================================
  // SHOULD REPAINT
  // ============================================================

  @override
  bool shouldRepaint(
    covariant BodyMapPainter oldDelegate,
  ) {
    return oldDelegate.hoveredRegion !=
            hoveredRegion ||
        oldDelegate.selectedRegion !=
            selectedRegion ||
        !setEquals(
          oldDelegate.configuredRegions,
          configuredRegions,
        );
  }
}

// ============================================================
// TRANSFORM
// ============================================================

class _BodyMapTransform {
  _BodyMapTransform({
    required Size size,
  }) {
    final scaleX =
        size.width /
        BodyMapPainter.designSize.width;

    final scaleY =
        size.height /
        BodyMapPainter.designSize.height;

    scale =
        scaleX <
            scaleY
        ? scaleX
        : scaleY;

    final contentWidth =
        BodyMapPainter.designSize.width *
        scale;

    final contentHeight =
        BodyMapPainter.designSize.height *
        scale;

    offset = Offset(
      (size.width -
              contentWidth) /
          2,
      (size.height -
              contentHeight) /
          2,
    );
  }

  late final double scale;

  late final Offset offset;
}

// ============================================================
// BODY GEOMETRY
// ============================================================

class _BodyGeometry {
  _BodyGeometry._();

  // ============================================================
  // BASE BODY PATHS
  // ============================================================

  static List<
    Path
  >
  get baseBodyPaths {
    return [
      _head(),
      _neck(),
      _torso(),
      _leftUpperArm(),
      _rightUpperArm(),
      _leftForearm(),
      _rightForearm(),
      _pelvis(),
      _leftThigh(),
      _rightThigh(),
      _leftLowerLeg(),
      _rightLowerLeg(),
      _leftFoot(),
      _rightFoot(),
    ];
  }

  // ============================================================
  // REGION PATHS
  // ============================================================

  static List<
    Path
  >
  regionPaths(
    BodyRegion region,
  ) {
    switch (region) {
      case BodyRegion.chest:
        return [
          _leftChest(),
          _rightChest(),
        ];

      case BodyRegion.shoulders:
        return [
          _leftShoulder(),
          _rightShoulder(),
        ];

      case BodyRegion.arms:
        return [
          _leftArmRegion(),
          _rightArmRegion(),
        ];

      case BodyRegion.abdomen:
        return [
          _abdomen(),
        ];

      case BodyRegion.quadriceps:
        return [
          _leftQuadriceps(),
          _rightQuadriceps(),
        ];

      case BodyRegion.calves:
        return [
          _leftCalf(),
          _rightCalf(),
        ];
    }
  }

  // ============================================================
  // HEAD
  // ============================================================

  static Path _head() {
    return Path()..addOval(
      const Rect.fromLTWH(
        118,
        20,
        64,
        82,
      ),
    );
  }

  // ============================================================
  // NECK
  // ============================================================

  static Path _neck() {
    return Path()
      ..moveTo(
        132,
        92,
      )
      ..lineTo(
        168,
        92,
      )
      ..lineTo(
        171,
        126,
      )
      ..lineTo(
        129,
        126,
      )
      ..close();
  }

  // ============================================================
  // TORSO
  // ============================================================

  static Path _torso() {
    return Path()
      ..moveTo(
        105,
        120,
      )
      ..quadraticBezierTo(
        150,
        103,
        195,
        120,
      )
      ..quadraticBezierTo(
        207,
        164,
        194,
        223,
      )
      ..quadraticBezierTo(
        183,
        270,
        177,
        296,
      )
      ..lineTo(
        123,
        296,
      )
      ..quadraticBezierTo(
        117,
        270,
        106,
        223,
      )
      ..quadraticBezierTo(
        93,
        164,
        105,
        120,
      )
      ..close();
  }

  // ============================================================
  // PELVIS
  // ============================================================

  static Path _pelvis() {
    return Path()
      ..moveTo(
        123,
        286,
      )
      ..lineTo(
        177,
        286,
      )
      ..quadraticBezierTo(
        187,
        316,
        176,
        344,
      )
      ..lineTo(
        124,
        344,
      )
      ..quadraticBezierTo(
        113,
        316,
        123,
        286,
      )
      ..close();
  }

  // ============================================================
  // ARMS BASE
  // ============================================================

  static Path _leftUpperArm() {
    return Path()
      ..moveTo(
        105,
        126,
      )
      ..quadraticBezierTo(
        80,
        128,
        72,
        158,
      )
      ..lineTo(
        58,
        236,
      )
      ..quadraticBezierTo(
        55,
        255,
        70,
        260,
      )
      ..quadraticBezierTo(
        86,
        260,
        91,
        239,
      )
      ..lineTo(
        108,
        168,
      )
      ..close();
  }

  static Path _rightUpperArm() {
    return Path()
      ..moveTo(
        195,
        126,
      )
      ..quadraticBezierTo(
        220,
        128,
        228,
        158,
      )
      ..lineTo(
        242,
        236,
      )
      ..quadraticBezierTo(
        245,
        255,
        230,
        260,
      )
      ..quadraticBezierTo(
        214,
        260,
        209,
        239,
      )
      ..lineTo(
        192,
        168,
      )
      ..close();
  }

  static Path _leftForearm() {
    return Path()
      ..moveTo(
        58,
        232,
      )
      ..lineTo(
        72,
        236,
      )
      ..lineTo(
        60,
        336,
      )
      ..quadraticBezierTo(
        56,
        358,
        43,
        352,
      )
      ..quadraticBezierTo(
        34,
        347,
        40,
        327,
      )
      ..close();
  }

  static Path _rightForearm() {
    return Path()
      ..moveTo(
        242,
        232,
      )
      ..lineTo(
        228,
        236,
      )
      ..lineTo(
        240,
        336,
      )
      ..quadraticBezierTo(
        244,
        358,
        257,
        352,
      )
      ..quadraticBezierTo(
        266,
        347,
        260,
        327,
      )
      ..close();
  }

  // ============================================================
  // LEGS BASE
  // ============================================================

  static Path _leftThigh() {
    return Path()
      ..moveTo(
        124,
        334,
      )
      ..lineTo(
        149,
        336,
      )
      ..lineTo(
        142,
        468,
      )
      ..quadraticBezierTo(
        136,
        490,
        115,
        478,
      )
      ..quadraticBezierTo(
        100,
        430,
        104,
        374,
      )
      ..close();
  }

  static Path _rightThigh() {
    return Path()
      ..moveTo(
        176,
        334,
      )
      ..lineTo(
        151,
        336,
      )
      ..lineTo(
        158,
        468,
      )
      ..quadraticBezierTo(
        164,
        490,
        185,
        478,
      )
      ..quadraticBezierTo(
        200,
        430,
        196,
        374,
      )
      ..close();
  }

  static Path _leftLowerLeg() {
    return Path()
      ..moveTo(
        115,
        472,
      )
      ..quadraticBezierTo(
        134,
        462,
        142,
        478,
      )
      ..lineTo(
        136,
        574,
      )
      ..quadraticBezierTo(
        128,
        586,
        115,
        576,
      )
      ..quadraticBezierTo(
        104,
        526,
        115,
        472,
      )
      ..close();
  }

  static Path _rightLowerLeg() {
    return Path()
      ..moveTo(
        185,
        472,
      )
      ..quadraticBezierTo(
        166,
        462,
        158,
        478,
      )
      ..lineTo(
        164,
        574,
      )
      ..quadraticBezierTo(
        172,
        586,
        185,
        576,
      )
      ..quadraticBezierTo(
        196,
        526,
        185,
        472,
      )
      ..close();
  }

  // ============================================================
  // FEET
  // ============================================================

  static Path _leftFoot() {
    return Path()
      ..moveTo(
        114,
        570,
      )
      ..lineTo(
        136,
        570,
      )
      ..quadraticBezierTo(
        142,
        591,
        128,
        600,
      )
      ..lineTo(
        102,
        600,
      )
      ..quadraticBezierTo(
        98,
        590,
        114,
        570,
      )
      ..close();
  }

  static Path _rightFoot() {
    return Path()
      ..moveTo(
        186,
        570,
      )
      ..lineTo(
        164,
        570,
      )
      ..quadraticBezierTo(
        158,
        591,
        172,
        600,
      )
      ..lineTo(
        198,
        600,
      )
      ..quadraticBezierTo(
        202,
        590,
        186,
        570,
      )
      ..close();
  }

  // ============================================================
  // SHOULDERS
  // ============================================================

  static Path _leftShoulder() {
    return Path()
      ..moveTo(
        105,
        122,
      )
      ..quadraticBezierTo(
        82,
        124,
        77,
        147,
      )
      ..quadraticBezierTo(
        79,
        166,
        98,
        168,
      )
      ..quadraticBezierTo(
        107,
        153,
        114,
        132,
      )
      ..close();
  }

  static Path _rightShoulder() {
    return Path()
      ..moveTo(
        195,
        122,
      )
      ..quadraticBezierTo(
        218,
        124,
        223,
        147,
      )
      ..quadraticBezierTo(
        221,
        166,
        202,
        168,
      )
      ..quadraticBezierTo(
        193,
        153,
        186,
        132,
      )
      ..close();
  }

  // ============================================================
  // CHEST
  // ============================================================

  static Path _leftChest() {
    return Path()
      ..moveTo(
        113,
        135,
      )
      ..quadraticBezierTo(
        132,
        124,
        148,
        132,
      )
      ..lineTo(
        148,
        183,
      )
      ..quadraticBezierTo(
        126,
        194,
        107,
        178,
      )
      ..quadraticBezierTo(
        103,
        153,
        113,
        135,
      )
      ..close();
  }

  static Path _rightChest() {
    return Path()
      ..moveTo(
        187,
        135,
      )
      ..quadraticBezierTo(
        168,
        124,
        152,
        132,
      )
      ..lineTo(
        152,
        183,
      )
      ..quadraticBezierTo(
        174,
        194,
        193,
        178,
      )
      ..quadraticBezierTo(
        197,
        153,
        187,
        135,
      )
      ..close();
  }

  // ============================================================
  // ARMS REGION
  // ============================================================

  static Path _leftArmRegion() {
    return Path()
      ..moveTo(
        83,
        165,
      )
      ..quadraticBezierTo(
        96,
        161,
        99,
        178,
      )
      ..lineTo(
        87,
        235,
      )
      ..quadraticBezierTo(
        82,
        253,
        67,
        247,
      )
      ..quadraticBezierTo(
        61,
        238,
        66,
        218,
      )
      ..close();
  }

  static Path _rightArmRegion() {
    return Path()
      ..moveTo(
        217,
        165,
      )
      ..quadraticBezierTo(
        204,
        161,
        201,
        178,
      )
      ..lineTo(
        213,
        235,
      )
      ..quadraticBezierTo(
        218,
        253,
        233,
        247,
      )
      ..quadraticBezierTo(
        239,
        238,
        234,
        218,
      )
      ..close();
  }

  // ============================================================
  // ABDOMEN
  // ============================================================

  static Path _abdomen() {
    return Path()
      ..moveTo(
        126,
        193,
      )
      ..quadraticBezierTo(
        150,
        183,
        174,
        193,
      )
      ..lineTo(
        173,
        276,
      )
      ..quadraticBezierTo(
        150,
        289,
        127,
        276,
      )
      ..close();
  }

  // ============================================================
  // QUADRICEPS
  // ============================================================

  static Path _leftQuadriceps() {
    return Path()
      ..moveTo(
        113,
        347,
      )
      ..quadraticBezierTo(
        129,
        336,
        146,
        347,
      )
      ..lineTo(
        140,
        455,
      )
      ..quadraticBezierTo(
        132,
        475,
        116,
        461,
      )
      ..quadraticBezierTo(
        105,
        408,
        113,
        347,
      )
      ..close();
  }

  static Path _rightQuadriceps() {
    return Path()
      ..moveTo(
        187,
        347,
      )
      ..quadraticBezierTo(
        171,
        336,
        154,
        347,
      )
      ..lineTo(
        160,
        455,
      )
      ..quadraticBezierTo(
        168,
        475,
        184,
        461,
      )
      ..quadraticBezierTo(
        195,
        408,
        187,
        347,
      )
      ..close();
  }

  // ============================================================
  // CALVES
  // ============================================================

  static Path _leftCalf() {
    return Path()
      ..moveTo(
        117,
        480,
      )
      ..quadraticBezierTo(
        132,
        469,
        139,
        487,
      )
      ..lineTo(
        133,
        558,
      )
      ..quadraticBezierTo(
        125,
        570,
        116,
        557,
      )
      ..quadraticBezierTo(
        108,
        518,
        117,
        480,
      )
      ..close();
  }

  static Path _rightCalf() {
    return Path()
      ..moveTo(
        183,
        480,
      )
      ..quadraticBezierTo(
        168,
        469,
        161,
        487,
      )
      ..lineTo(
        167,
        558,
      )
      ..quadraticBezierTo(
        175,
        570,
        184,
        557,
      )
      ..quadraticBezierTo(
        192,
        518,
        183,
        480,
      )
      ..close();
  }
}
