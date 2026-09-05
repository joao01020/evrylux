import 'package:flutter/material.dart';

import '../models/brain_connection.dart';

/// ============================================================
/// EVRYLUX — BRAIN PATHS
/// ============================================================
///
/// Base visual derivada da V4 Distributed Arbor.
///
/// Mantém:
///
/// - ramos nascendo diretamente da base;
/// - arborização curta e orgânica;
/// - bifurcações fixas;
/// - hemisférios separados;
/// - crescimento por níveis;
///
/// Agora possui 16 slots:
///
/// 0  -> direita / lateral superior
/// 1  -> esquerda / lateral superior
/// 2  -> direita / lateral inferior
/// 3  -> esquerda / lateral inferior
/// 4  -> direita / centro superior
/// 5  -> esquerda / centro superior
/// 6  -> direita / centro inferior
/// 7  -> esquerda / centro inferior
/// 8  -> direita / lateral média
/// 9  -> esquerda / lateral média
/// 10 -> direita / centro médio
/// 11 -> esquerda / centro médio
/// 12 -> direita / centro topo
/// 13 -> esquerda / centro topo
/// 14 -> direita / centro base
/// 15 -> esquerda / centro base
///
/// Crescimento:
///
/// 1 item  -> nível 1
/// 3 itens -> nível 2
/// 6 itens -> nível 3
/// 10 itens -> nível 4
/// 15 itens -> nível 5
///
/// ============================================================

class BrainPaths {
  const BrainPaths._();

  // ============================================================
  // QUANTIDADE DE RAMOS
  // ============================================================

  static const int mainBranchCount = 16;

  // ============================================================
  // NÍVEIS
  // ============================================================

  static int branchLevelForItemCount(
    int count,
  ) {
    if (count <=
        0) {
      return 0;
    }

    if (count <
        3) {
      return 1;
    }

    if (count <
        6) {
      return 2;
    }

    if (count <
        10) {
      return 3;
    }

    if (count <
        15) {
      return 4;
    }

    return 5;
  }

  // ============================================================
  // BASE
  // ============================================================

  static List<
    Path
  >
  basePaths(
    Size size,
  ) {
    Offset p(
      double x,
      double y,
    ) {
      return Offset(
        x *
            size.width,
        y *
            size.height,
      );
    }

    // ==========================================================
    // HEMISFÉRIO ESQUERDO
    // ==========================================================

    final left = Path()
      ..moveTo(
        p(
          0.465,
          0.190,
        ).dx,
        p(
          0.465,
          0.190,
        ).dy,
      )
      ..cubicTo(
        p(
          0.445,
          0.155,
        ).dx,
        p(
          0.445,
          0.155,
        ).dy,
        p(
          0.408,
          0.138,
        ).dx,
        p(
          0.408,
          0.138,
        ).dy,
        p(
          0.370,
          0.144,
        ).dx,
        p(
          0.370,
          0.144,
        ).dy,
      )
      ..cubicTo(
        p(
          0.330,
          0.148,
        ).dx,
        p(
          0.330,
          0.148,
        ).dy,
        p(
          0.296,
          0.168,
        ).dx,
        p(
          0.296,
          0.168,
        ).dy,
        p(
          0.274,
          0.202,
        ).dx,
        p(
          0.274,
          0.202,
        ).dy,
      )
      ..cubicTo(
        p(
          0.232,
          0.215,
        ).dx,
        p(
          0.232,
          0.215,
        ).dy,
        p(
          0.204,
          0.252,
        ).dx,
        p(
          0.204,
          0.252,
        ).dy,
        p(
          0.206,
          0.296,
        ).dx,
        p(
          0.206,
          0.296,
        ).dy,
      )
      ..cubicTo(
        p(
          0.170,
          0.318,
        ).dx,
        p(
          0.170,
          0.318,
        ).dy,
        p(
          0.154,
          0.362,
        ).dx,
        p(
          0.154,
          0.362,
        ).dy,
        p(
          0.171,
          0.404,
        ).dx,
        p(
          0.171,
          0.404,
        ).dy,
      )
      ..cubicTo(
        p(
          0.139,
          0.438,
        ).dx,
        p(
          0.139,
          0.438,
        ).dy,
        p(
          0.134,
          0.489,
        ).dx,
        p(
          0.134,
          0.489,
        ).dy,
        p(
          0.156,
          0.533,
        ).dx,
        p(
          0.156,
          0.533,
        ).dy,
      )
      ..cubicTo(
        p(
          0.136,
          0.574,
        ).dx,
        p(
          0.136,
          0.574,
        ).dy,
        p(
          0.141,
          0.629,
        ).dx,
        p(
          0.141,
          0.629,
        ).dy,
        p(
          0.167,
          0.671,
        ).dx,
        p(
          0.167,
          0.671,
        ).dy,
      )
      ..cubicTo(
        p(
          0.162,
          0.718,
        ).dx,
        p(
          0.162,
          0.718,
        ).dy,
        p(
          0.183,
          0.764,
        ).dx,
        p(
          0.183,
          0.764,
        ).dy,
        p(
          0.220,
          0.790,
        ).dx,
        p(
          0.220,
          0.790,
        ).dy,
      )
      ..cubicTo(
        p(
          0.234,
          0.832,
        ).dx,
        p(
          0.234,
          0.832,
        ).dy,
        p(
          0.275,
          0.858,
        ).dx,
        p(
          0.275,
          0.858,
        ).dy,
        p(
          0.320,
          0.856,
        ).dx,
        p(
          0.320,
          0.856,
        ).dy,
      )
      ..cubicTo(
        p(
          0.355,
          0.885,
        ).dx,
        p(
          0.355,
          0.885,
        ).dy,
        p(
          0.403,
          0.892,
        ).dx,
        p(
          0.403,
          0.892,
        ).dy,
        p(
          0.438,
          0.878,
        ).dx,
        p(
          0.438,
          0.878,
        ).dy,
      )
      ..cubicTo(
        p(
          0.452,
          0.866,
        ).dx,
        p(
          0.452,
          0.866,
        ).dy,
        p(
          0.460,
          0.851,
        ).dx,
        p(
          0.460,
          0.851,
        ).dy,
        p(
          0.465,
          0.833,
        ).dx,
        p(
          0.465,
          0.833,
        ).dy,
      )
      ..lineTo(
        p(
          0.465,
          0.190,
        ).dx,
        p(
          0.465,
          0.190,
        ).dy,
      );

    // ==========================================================
    // HEMISFÉRIO DIREITO
    // ==========================================================

    final right = Path()
      ..moveTo(
        p(
          0.535,
          0.190,
        ).dx,
        p(
          0.535,
          0.190,
        ).dy,
      )
      ..cubicTo(
        p(
          0.555,
          0.155,
        ).dx,
        p(
          0.555,
          0.155,
        ).dy,
        p(
          0.592,
          0.138,
        ).dx,
        p(
          0.592,
          0.138,
        ).dy,
        p(
          0.630,
          0.144,
        ).dx,
        p(
          0.630,
          0.144,
        ).dy,
      )
      ..cubicTo(
        p(
          0.670,
          0.148,
        ).dx,
        p(
          0.670,
          0.148,
        ).dy,
        p(
          0.704,
          0.168,
        ).dx,
        p(
          0.704,
          0.168,
        ).dy,
        p(
          0.726,
          0.202,
        ).dx,
        p(
          0.726,
          0.202,
        ).dy,
      )
      ..cubicTo(
        p(
          0.768,
          0.215,
        ).dx,
        p(
          0.768,
          0.215,
        ).dy,
        p(
          0.796,
          0.252,
        ).dx,
        p(
          0.796,
          0.252,
        ).dy,
        p(
          0.794,
          0.296,
        ).dx,
        p(
          0.794,
          0.296,
        ).dy,
      )
      ..cubicTo(
        p(
          0.830,
          0.318,
        ).dx,
        p(
          0.830,
          0.318,
        ).dy,
        p(
          0.846,
          0.362,
        ).dx,
        p(
          0.846,
          0.362,
        ).dy,
        p(
          0.829,
          0.404,
        ).dx,
        p(
          0.829,
          0.404,
        ).dy,
      )
      ..cubicTo(
        p(
          0.861,
          0.438,
        ).dx,
        p(
          0.861,
          0.438,
        ).dy,
        p(
          0.866,
          0.489,
        ).dx,
        p(
          0.866,
          0.489,
        ).dy,
        p(
          0.844,
          0.533,
        ).dx,
        p(
          0.844,
          0.533,
        ).dy,
      )
      ..cubicTo(
        p(
          0.864,
          0.574,
        ).dx,
        p(
          0.864,
          0.574,
        ).dy,
        p(
          0.859,
          0.629,
        ).dx,
        p(
          0.859,
          0.629,
        ).dy,
        p(
          0.833,
          0.671,
        ).dx,
        p(
          0.833,
          0.671,
        ).dy,
      )
      ..cubicTo(
        p(
          0.838,
          0.718,
        ).dx,
        p(
          0.838,
          0.718,
        ).dy,
        p(
          0.817,
          0.764,
        ).dx,
        p(
          0.817,
          0.764,
        ).dy,
        p(
          0.780,
          0.790,
        ).dx,
        p(
          0.780,
          0.790,
        ).dy,
      )
      ..cubicTo(
        p(
          0.766,
          0.832,
        ).dx,
        p(
          0.766,
          0.832,
        ).dy,
        p(
          0.725,
          0.858,
        ).dx,
        p(
          0.725,
          0.858,
        ).dy,
        p(
          0.680,
          0.856,
        ).dx,
        p(
          0.680,
          0.856,
        ).dy,
      )
      ..cubicTo(
        p(
          0.645,
          0.885,
        ).dx,
        p(
          0.645,
          0.885,
        ).dy,
        p(
          0.597,
          0.892,
        ).dx,
        p(
          0.597,
          0.892,
        ).dy,
        p(
          0.562,
          0.878,
        ).dx,
        p(
          0.562,
          0.878,
        ).dy,
      )
      ..cubicTo(
        p(
          0.548,
          0.866,
        ).dx,
        p(
          0.548,
          0.866,
        ).dy,
        p(
          0.540,
          0.851,
        ).dx,
        p(
          0.540,
          0.851,
        ).dy,
        p(
          0.535,
          0.833,
        ).dx,
        p(
          0.535,
          0.833,
        ).dy,
      )
      ..lineTo(
        p(
          0.535,
          0.190,
        ).dx,
        p(
          0.535,
          0.190,
        ).dy,
      );

    return <
      Path
    >[
      left,
      right,
    ];
  }

  // ============================================================
  // RAMOS
  // ============================================================

  static List<
    BrainBranchDefinition
  >
  get branches {
    return const <
      BrainBranchDefinition
    >[
      // ========================================================
      // 0 — DIREITA / LATERAL SUPERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_0',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.800,
                  0.298,
                ),
                control1: Offset(
                  0.780,
                  0.292,
                ),
                control2: Offset(
                  0.755,
                  0.300,
                ),
                end: Offset(
                  0.736,
                  0.321,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.736,
                  0.321,
                ),
                control1: Offset(
                  0.716,
                  0.339,
                ),
                control2: Offset(
                  0.707,
                  0.362,
                ),
                end: Offset(
                  0.713,
                  0.383,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.724,
                  0.333,
                ),
                control1: Offset(
                  0.708,
                  0.318,
                ),
                control2: Offset(
                  0.689,
                  0.316,
                ),
                end: Offset(
                  0.675,
                  0.327,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.713,
                  0.383,
                ),
                control1: Offset(
                  0.696,
                  0.396,
                ),
                control2: Offset(
                  0.682,
                  0.414,
                ),
                end: Offset(
                  0.684,
                  0.432,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.694,
                  0.404,
                ),
                control1: Offset(
                  0.678,
                  0.398,
                ),
                control2: Offset(
                  0.663,
                  0.402,
                ),
                end: Offset(
                  0.652,
                  0.415,
                ),
              ),
            ],
      ),

      // ========================================================
      // 1 — ESQUERDA / LATERAL SUPERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_1',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.200,
                  0.298,
                ),
                control1: Offset(
                  0.220,
                  0.292,
                ),
                control2: Offset(
                  0.245,
                  0.300,
                ),
                end: Offset(
                  0.264,
                  0.321,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.264,
                  0.321,
                ),
                control1: Offset(
                  0.284,
                  0.339,
                ),
                control2: Offset(
                  0.293,
                  0.362,
                ),
                end: Offset(
                  0.287,
                  0.383,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.276,
                  0.333,
                ),
                control1: Offset(
                  0.292,
                  0.318,
                ),
                control2: Offset(
                  0.311,
                  0.316,
                ),
                end: Offset(
                  0.325,
                  0.327,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.287,
                  0.383,
                ),
                control1: Offset(
                  0.304,
                  0.396,
                ),
                control2: Offset(
                  0.318,
                  0.414,
                ),
                end: Offset(
                  0.316,
                  0.432,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.306,
                  0.404,
                ),
                control1: Offset(
                  0.322,
                  0.398,
                ),
                control2: Offset(
                  0.337,
                  0.402,
                ),
                end: Offset(
                  0.348,
                  0.415,
                ),
              ),
            ],
      ),

      // ========================================================
      // 2 — DIREITA / LATERAL INFERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_2',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.840,
                  0.672,
                ),
                control1: Offset(
                  0.814,
                  0.665,
                ),
                control2: Offset(
                  0.788,
                  0.672,
                ),
                end: Offset(
                  0.770,
                  0.691,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.770,
                  0.691,
                ),
                control1: Offset(
                  0.751,
                  0.710,
                ),
                control2: Offset(
                  0.744,
                  0.733,
                ),
                end: Offset(
                  0.750,
                  0.752,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.783,
                  0.682,
                ),
                control1: Offset(
                  0.767,
                  0.666,
                ),
                control2: Offset(
                  0.750,
                  0.661,
                ),
                end: Offset(
                  0.735,
                  0.670,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.750,
                  0.752,
                ),
                control1: Offset(
                  0.731,
                  0.764,
                ),
                control2: Offset(
                  0.713,
                  0.762,
                ),
                end: Offset(
                  0.700,
                  0.748,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.726,
                  0.765,
                ),
                control1: Offset(
                  0.712,
                  0.780,
                ),
                control2: Offset(
                  0.694,
                  0.782,
                ),
                end: Offset(
                  0.681,
                  0.772,
                ),
              ),
            ],
      ),

      // ========================================================
      // 3 — ESQUERDA / LATERAL INFERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_3',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.160,
                  0.672,
                ),
                control1: Offset(
                  0.186,
                  0.665,
                ),
                control2: Offset(
                  0.212,
                  0.672,
                ),
                end: Offset(
                  0.230,
                  0.691,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.230,
                  0.691,
                ),
                control1: Offset(
                  0.249,
                  0.710,
                ),
                control2: Offset(
                  0.256,
                  0.733,
                ),
                end: Offset(
                  0.250,
                  0.752,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.217,
                  0.682,
                ),
                control1: Offset(
                  0.233,
                  0.666,
                ),
                control2: Offset(
                  0.250,
                  0.661,
                ),
                end: Offset(
                  0.265,
                  0.670,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.250,
                  0.752,
                ),
                control1: Offset(
                  0.269,
                  0.764,
                ),
                control2: Offset(
                  0.287,
                  0.762,
                ),
                end: Offset(
                  0.300,
                  0.748,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.274,
                  0.765,
                ),
                control1: Offset(
                  0.288,
                  0.780,
                ),
                control2: Offset(
                  0.306,
                  0.782,
                ),
                end: Offset(
                  0.319,
                  0.772,
                ),
              ),
            ],
      ),

      // ========================================================
      // 4 — DIREITA / CENTRO SUPERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_4',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.535,
                  0.355,
                ),
                control1: Offset(
                  0.555,
                  0.350,
                ),
                control2: Offset(
                  0.577,
                  0.358,
                ),
                end: Offset(
                  0.591,
                  0.377,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.591,
                  0.377,
                ),
                control1: Offset(
                  0.606,
                  0.396,
                ),
                control2: Offset(
                  0.607,
                  0.419,
                ),
                end: Offset(
                  0.597,
                  0.436,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.574,
                  0.365,
                ),
                control1: Offset(
                  0.589,
                  0.348,
                ),
                control2: Offset(
                  0.607,
                  0.345,
                ),
                end: Offset(
                  0.620,
                  0.354,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.597,
                  0.436,
                ),
                control1: Offset(
                  0.610,
                  0.449,
                ),
                control2: Offset(
                  0.628,
                  0.451,
                ),
                end: Offset(
                  0.640,
                  0.440,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.615,
                  0.451,
                ),
                control1: Offset(
                  0.629,
                  0.465,
                ),
                control2: Offset(
                  0.646,
                  0.467,
                ),
                end: Offset(
                  0.657,
                  0.457,
                ),
              ),
            ],
      ),

      // ========================================================
      // 5 — ESQUERDA / CENTRO SUPERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_5',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.465,
                  0.355,
                ),
                control1: Offset(
                  0.445,
                  0.350,
                ),
                control2: Offset(
                  0.423,
                  0.358,
                ),
                end: Offset(
                  0.409,
                  0.377,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.409,
                  0.377,
                ),
                control1: Offset(
                  0.394,
                  0.396,
                ),
                control2: Offset(
                  0.393,
                  0.419,
                ),
                end: Offset(
                  0.403,
                  0.436,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.426,
                  0.365,
                ),
                control1: Offset(
                  0.411,
                  0.348,
                ),
                control2: Offset(
                  0.393,
                  0.345,
                ),
                end: Offset(
                  0.380,
                  0.354,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.403,
                  0.436,
                ),
                control1: Offset(
                  0.390,
                  0.449,
                ),
                control2: Offset(
                  0.372,
                  0.451,
                ),
                end: Offset(
                  0.360,
                  0.440,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.385,
                  0.451,
                ),
                control1: Offset(
                  0.371,
                  0.465,
                ),
                control2: Offset(
                  0.354,
                  0.467,
                ),
                end: Offset(
                  0.343,
                  0.457,
                ),
              ),
            ],
      ),

      // ========================================================
      // 6 — DIREITA / CENTRO INFERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_6',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.535,
                  0.650,
                ),
                control1: Offset(
                  0.556,
                  0.647,
                ),
                control2: Offset(
                  0.579,
                  0.657,
                ),
                end: Offset(
                  0.592,
                  0.678,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.592,
                  0.678,
                ),
                control1: Offset(
                  0.605,
                  0.698,
                ),
                control2: Offset(
                  0.604,
                  0.720,
                ),
                end: Offset(
                  0.593,
                  0.736,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.576,
                  0.663,
                ),
                control1: Offset(
                  0.592,
                  0.649,
                ),
                control2: Offset(
                  0.610,
                  0.649,
                ),
                end: Offset(
                  0.622,
                  0.660,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.593,
                  0.736,
                ),
                control1: Offset(
                  0.607,
                  0.749,
                ),
                control2: Offset(
                  0.625,
                  0.750,
                ),
                end: Offset(
                  0.637,
                  0.738,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.612,
                  0.750,
                ),
                control1: Offset(
                  0.626,
                  0.765,
                ),
                control2: Offset(
                  0.643,
                  0.766,
                ),
                end: Offset(
                  0.654,
                  0.756,
                ),
              ),
            ],
      ),

      // ========================================================
      // 7 — ESQUERDA / CENTRO INFERIOR
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_7',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.465,
                  0.650,
                ),
                control1: Offset(
                  0.444,
                  0.647,
                ),
                control2: Offset(
                  0.421,
                  0.657,
                ),
                end: Offset(
                  0.408,
                  0.678,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.408,
                  0.678,
                ),
                control1: Offset(
                  0.395,
                  0.698,
                ),
                control2: Offset(
                  0.396,
                  0.720,
                ),
                end: Offset(
                  0.407,
                  0.736,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.424,
                  0.663,
                ),
                control1: Offset(
                  0.408,
                  0.649,
                ),
                control2: Offset(
                  0.390,
                  0.649,
                ),
                end: Offset(
                  0.378,
                  0.660,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.407,
                  0.736,
                ),
                control1: Offset(
                  0.393,
                  0.749,
                ),
                control2: Offset(
                  0.375,
                  0.750,
                ),
                end: Offset(
                  0.363,
                  0.738,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.388,
                  0.750,
                ),
                control1: Offset(
                  0.374,
                  0.765,
                ),
                control2: Offset(
                  0.357,
                  0.766,
                ),
                end: Offset(
                  0.346,
                  0.756,
                ),
              ),
            ],
      ),

      // ========================================================
      // 8 — DIREITA / LATERAL MÉDIA
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_8',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.852,
                  0.505,
                ),
                control1: Offset(
                  0.826,
                  0.497,
                ),
                control2: Offset(
                  0.799,
                  0.504,
                ),
                end: Offset(
                  0.780,
                  0.523,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.780,
                  0.523,
                ),
                control1: Offset(
                  0.761,
                  0.542,
                ),
                control2: Offset(
                  0.754,
                  0.565,
                ),
                end: Offset(
                  0.760,
                  0.584,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.793,
                  0.514,
                ),
                control1: Offset(
                  0.777,
                  0.498,
                ),
                control2: Offset(
                  0.760,
                  0.493,
                ),
                end: Offset(
                  0.745,
                  0.502,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.760,
                  0.584,
                ),
                control1: Offset(
                  0.741,
                  0.596,
                ),
                control2: Offset(
                  0.723,
                  0.594,
                ),
                end: Offset(
                  0.710,
                  0.580,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.736,
                  0.597,
                ),
                control1: Offset(
                  0.722,
                  0.612,
                ),
                control2: Offset(
                  0.704,
                  0.614,
                ),
                end: Offset(
                  0.691,
                  0.604,
                ),
              ),
            ],
      ),

      // ========================================================
      // 9 — ESQUERDA / LATERAL MÉDIA
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_9',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.148,
                  0.505,
                ),
                control1: Offset(
                  0.174,
                  0.497,
                ),
                control2: Offset(
                  0.201,
                  0.504,
                ),
                end: Offset(
                  0.220,
                  0.523,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.220,
                  0.523,
                ),
                control1: Offset(
                  0.239,
                  0.542,
                ),
                control2: Offset(
                  0.246,
                  0.565,
                ),
                end: Offset(
                  0.240,
                  0.584,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.207,
                  0.514,
                ),
                control1: Offset(
                  0.223,
                  0.498,
                ),
                control2: Offset(
                  0.240,
                  0.493,
                ),
                end: Offset(
                  0.255,
                  0.502,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.240,
                  0.584,
                ),
                control1: Offset(
                  0.259,
                  0.596,
                ),
                control2: Offset(
                  0.277,
                  0.594,
                ),
                end: Offset(
                  0.290,
                  0.580,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.264,
                  0.597,
                ),
                control1: Offset(
                  0.278,
                  0.612,
                ),
                control2: Offset(
                  0.296,
                  0.614,
                ),
                end: Offset(
                  0.309,
                  0.604,
                ),
              ),
            ],
      ),

      // ========================================================
      // 10 — DIREITA / CENTRO MÉDIO
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_10',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.535,
                  0.505,
                ),
                control1: Offset(
                  0.555,
                  0.500,
                ),
                control2: Offset(
                  0.577,
                  0.508,
                ),
                end: Offset(
                  0.591,
                  0.527,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.591,
                  0.527,
                ),
                control1: Offset(
                  0.606,
                  0.546,
                ),
                control2: Offset(
                  0.607,
                  0.569,
                ),
                end: Offset(
                  0.597,
                  0.586,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.574,
                  0.515,
                ),
                control1: Offset(
                  0.589,
                  0.498,
                ),
                control2: Offset(
                  0.607,
                  0.495,
                ),
                end: Offset(
                  0.620,
                  0.504,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.597,
                  0.586,
                ),
                control1: Offset(
                  0.610,
                  0.599,
                ),
                control2: Offset(
                  0.628,
                  0.601,
                ),
                end: Offset(
                  0.640,
                  0.590,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.615,
                  0.601,
                ),
                control1: Offset(
                  0.629,
                  0.615,
                ),
                control2: Offset(
                  0.646,
                  0.617,
                ),
                end: Offset(
                  0.657,
                  0.607,
                ),
              ),
            ],
      ),

      // ========================================================
      // 11 — ESQUERDA / CENTRO MÉDIO
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_11',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.465,
                  0.505,
                ),
                control1: Offset(
                  0.445,
                  0.500,
                ),
                control2: Offset(
                  0.423,
                  0.508,
                ),
                end: Offset(
                  0.409,
                  0.527,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.409,
                  0.527,
                ),
                control1: Offset(
                  0.394,
                  0.546,
                ),
                control2: Offset(
                  0.393,
                  0.569,
                ),
                end: Offset(
                  0.403,
                  0.586,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.426,
                  0.515,
                ),
                control1: Offset(
                  0.411,
                  0.498,
                ),
                control2: Offset(
                  0.393,
                  0.495,
                ),
                end: Offset(
                  0.380,
                  0.504,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.403,
                  0.586,
                ),
                control1: Offset(
                  0.390,
                  0.599,
                ),
                control2: Offset(
                  0.372,
                  0.601,
                ),
                end: Offset(
                  0.360,
                  0.590,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.385,
                  0.601,
                ),
                control1: Offset(
                  0.371,
                  0.615,
                ),
                control2: Offset(
                  0.354,
                  0.617,
                ),
                end: Offset(
                  0.343,
                  0.607,
                ),
              ),
            ],
      ),

      // ========================================================
      // 12 — DIREITA / CENTRO TOPO
      // ========================================================
      //
      // Novo ramo inspirado nos traços indicados na referência.
      // Nasce na linha central, bem próximo do topo.
      //
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_12',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.535,
                  0.225,
                ),
                control1: Offset(
                  0.551,
                  0.222,
                ),
                control2: Offset(
                  0.570,
                  0.228,
                ),
                end: Offset(
                  0.584,
                  0.243,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.584,
                  0.243,
                ),
                control1: Offset(
                  0.596,
                  0.255,
                ),
                control2: Offset(
                  0.601,
                  0.270,
                ),
                end: Offset(
                  0.598,
                  0.286,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.570,
                  0.236,
                ),
                control1: Offset(
                  0.581,
                  0.224,
                ),
                control2: Offset(
                  0.597,
                  0.219,
                ),
                end: Offset(
                  0.611,
                  0.223,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.592,
                  0.263,
                ),
                control1: Offset(
                  0.606,
                  0.258,
                ),
                control2: Offset(
                  0.620,
                  0.261,
                ),
                end: Offset(
                  0.631,
                  0.272,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.598,
                  0.286,
                ),
                control1: Offset(
                  0.610,
                  0.296,
                ),
                control2: Offset(
                  0.623,
                  0.301,
                ),
                end: Offset(
                  0.637,
                  0.302,
                ),
              ),
            ],
      ),

      // ========================================================
      // 13 — ESQUERDA / CENTRO TOPO
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_13',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              BrainBranchStage(
                start: Offset(
                  0.465,
                  0.225,
                ),
                control1: Offset(
                  0.449,
                  0.222,
                ),
                control2: Offset(
                  0.430,
                  0.228,
                ),
                end: Offset(
                  0.416,
                  0.243,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.416,
                  0.243,
                ),
                control1: Offset(
                  0.404,
                  0.255,
                ),
                control2: Offset(
                  0.399,
                  0.270,
                ),
                end: Offset(
                  0.402,
                  0.286,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.430,
                  0.236,
                ),
                control1: Offset(
                  0.419,
                  0.224,
                ),
                control2: Offset(
                  0.403,
                  0.219,
                ),
                end: Offset(
                  0.389,
                  0.223,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.408,
                  0.263,
                ),
                control1: Offset(
                  0.394,
                  0.258,
                ),
                control2: Offset(
                  0.380,
                  0.261,
                ),
                end: Offset(
                  0.369,
                  0.272,
                ),
              ),
              BrainBranchStage(
                start: Offset(
                  0.402,
                  0.286,
                ),
                control1: Offset(
                  0.390,
                  0.296,
                ),
                control2: Offset(
                  0.377,
                  0.301,
                ),
                end: Offset(
                  0.363,
                  0.302,
                ),
              ),
            ],
      ),

      // ========================================================
      // 14 — DIREITA / CENTRO BASE
      // ========================================================
      //
      // Corrigido para NÃO colidir com o ramo 6.
      //
      // Este ramo agora ocupa somente a faixa inferior:
      //
      // y ≈ 0.790 até 0.845
      //
      // Assim ele permanece visualmente separado do ramo 6,
      // que termina mais acima.
      //
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_14',
        side: BrainBranchSide.right,
        stages:
            <
              BrainBranchStage
            >[
              // Tronco principal.
              BrainBranchStage(
                start: Offset(
                  0.535,
                  0.815,
                ),
                control1: Offset(
                  0.552,
                  0.818,
                ),
                control2: Offset(
                  0.570,
                  0.823,
                ),
                end: Offset(
                  0.585,
                  0.824,
                ),
              ),

              // Continuação curta para fora.
              BrainBranchStage(
                start: Offset(
                  0.585,
                  0.824,
                ),
                control1: Offset(
                  0.598,
                  0.824,
                ),
                control2: Offset(
                  0.611,
                  0.818,
                ),
                end: Offset(
                  0.620,
                  0.808,
                ),
              ),

              // Primeiro galho para baixo.
              BrainBranchStage(
                start: Offset(
                  0.568,
                  0.821,
                ),
                control1: Offset(
                  0.576,
                  0.832,
                ),
                control2: Offset(
                  0.588,
                  0.840,
                ),
                end: Offset(
                  0.602,
                  0.842,
                ),
              ),

              // Segundo galho para cima, mas ainda abaixo
              // da região usada pelo ramo 6.
              BrainBranchStage(
                start: Offset(
                  0.598,
                  0.818,
                ),
                control1: Offset(
                  0.606,
                  0.807,
                ),
                control2: Offset(
                  0.617,
                  0.800,
                ),
                end: Offset(
                  0.629,
                  0.799,
                ),
              ),

              // Terminal externo.
              BrainBranchStage(
                start: Offset(
                  0.620,
                  0.808,
                ),
                control1: Offset(
                  0.630,
                  0.816,
                ),
                control2: Offset(
                  0.642,
                  0.820,
                ),
                end: Offset(
                  0.654,
                  0.817,
                ),
              ),
            ],
      ),

      // ========================================================
      // 15 — ESQUERDA / CENTRO BASE
      // ========================================================
      //
      // Espelho do ramo 14.
      //
      // Também permanece somente na faixa inferior para não
      // colidir com o ramo 7.
      //
      // ========================================================
      BrainBranchDefinition(
        id: 'branch_15',
        side: BrainBranchSide.left,
        stages:
            <
              BrainBranchStage
            >[
              // Tronco principal.
              BrainBranchStage(
                start: Offset(
                  0.465,
                  0.815,
                ),
                control1: Offset(
                  0.448,
                  0.818,
                ),
                control2: Offset(
                  0.430,
                  0.823,
                ),
                end: Offset(
                  0.415,
                  0.824,
                ),
              ),

              // Continuação curta para fora.
              BrainBranchStage(
                start: Offset(
                  0.415,
                  0.824,
                ),
                control1: Offset(
                  0.402,
                  0.824,
                ),
                control2: Offset(
                  0.389,
                  0.818,
                ),
                end: Offset(
                  0.380,
                  0.808,
                ),
              ),

              // Primeiro galho para baixo.
              BrainBranchStage(
                start: Offset(
                  0.432,
                  0.821,
                ),
                control1: Offset(
                  0.424,
                  0.832,
                ),
                control2: Offset(
                  0.412,
                  0.840,
                ),
                end: Offset(
                  0.398,
                  0.842,
                ),
              ),

              // Segundo galho para cima, ainda separado
              // da região do ramo 7.
              BrainBranchStage(
                start: Offset(
                  0.402,
                  0.818,
                ),
                control1: Offset(
                  0.394,
                  0.807,
                ),
                control2: Offset(
                  0.383,
                  0.800,
                ),
                end: Offset(
                  0.371,
                  0.799,
                ),
              ),

              // Terminal externo.
              BrainBranchStage(
                start: Offset(
                  0.380,
                  0.808,
                ),
                control1: Offset(
                  0.370,
                  0.816,
                ),
                control2: Offset(
                  0.358,
                  0.820,
                ),
                end: Offset(
                  0.346,
                  0.817,
                ),
              ),
            ],
      ),
    ];
  }

  // ============================================================
  // COMPATIBILIDADE
  // ============================================================

  static List<
    BrainConnectionDefinition
  >
  get connections {
    final result =
        <
          BrainConnectionDefinition
        >[];

    for (final branch in branches) {
      for (final stage in branch.stages) {
        result.add(
          BrainConnectionDefinition(
            start: stage.start,
            control1: stage.control1,
            control2: stage.control2,
            end: stage.end,
          ),
        );
      }
    }

    return result;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static BrainBranchDefinition branchAt(
    int index,
  ) {
    if (index <
            0 ||
        index >=
            branches.length) {
      throw RangeError.index(
        index,
        branches,
        'index',
      );
    }

    return branches[index];
  }

  static List<
    BrainConnectionDefinition
  >
  connectionsForBranch({
    required int branchIndex,
    required int level,
  }) {
    if (level <=
        0) {
      return const <
        BrainConnectionDefinition
      >[];
    }

    final branch = branchAt(
      branchIndex,
    );

    final safeLevel = level.clamp(
      0,
      branch.stages.length,
    );

    return branch.stages
        .take(
          safeLevel,
        )
        .map(
          (
            stage,
          ) {
            return BrainConnectionDefinition(
              start: stage.start,
              control1: stage.control1,
              control2: stage.control2,
              end: stage.end,
            );
          },
        )
        .toList(
          growable: false,
        );
  }

  // ============================================================
  // LEGADO
  // ============================================================

  static int levelForKnowledgeCount(
    int count,
  ) {
    return branchLevelForItemCount(
      count,
    );
  }

  static int connectionCountForKnowledge(
    int count,
  ) {
    if (count <=
        0) {
      return 0;
    }

    return count.clamp(
      0,
      connections.length,
    );
  }
}

// ============================================================
// BRANCH SIDE
// ============================================================

enum BrainBranchSide {
  left,
  right,
}

// ============================================================
// BRANCH STAGE
// ============================================================

@immutable
class BrainBranchStage {
  const BrainBranchStage({
    required this.start,
    required this.control1,
    required this.control2,
    required this.end,
  });

  final Offset start;
  final Offset control1;
  final Offset control2;
  final Offset end;
}

// ============================================================
// BRANCH DEFINITION
// ============================================================

@immutable
class BrainBranchDefinition {
  const BrainBranchDefinition({
    required this.id,
    required this.side,
    required this.stages,
  });

  final String id;
  final BrainBranchSide side;
  final List<
    BrainBranchStage
  >
  stages;

  int get maxLevel {
    return stages.length;
  }
}
