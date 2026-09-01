import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'training_history_records.dart';

class TrainingHistoryPieChart
    extends
        StatefulWidget {
  const TrainingHistoryPieChart({
    super.key,
    required this.entries,
    this.selectedActivity,
    this.onActivitySelected,
  });

  final List<
    TrainingHistoryEntry
  >
  entries;

  final String? selectedActivity;

  final ValueChanged<
    String
  >?
  onActivitySelected;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _soft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const List<
    Color
  >
  _colors = [
    Color(
      0xFF3B6939,
    ),
    Color(
      0xFF5B8E55,
    ),
    Color(
      0xFF7BAE73,
    ),
    Color(
      0xFF9CCB94,
    ),
    Color(
      0xFFBCF0B4,
    ),
    Color(
      0xFF6C8A5B,
    ),
    Color(
      0xFF4F7A72,
    ),
    Color(
      0xFF7E9070,
    ),
  ];

  @override
  State<
    TrainingHistoryPieChart
  >
  createState() => _TrainingHistoryPieChartState();
}

class _TrainingHistoryPieChartState
    extends
        State<
          TrainingHistoryPieChart
        > {
  // ============================================================
  // TAMANHOS DO GRÁFICO
  // ============================================================

  static const double _chartBoxSize = 260;

  static const double _paintSize = 240;

  static const double _paintInset =
      (_chartBoxSize -
          _paintSize) /
      2;

  static const double _baseRadius =
      _paintSize /
          2 -
      8;

  static const double _holeRadius =
      _baseRadius *
      0.47;

  static const double _selectedExtraRadius = 5;

  // ============================================================
  // HOVER
  // ============================================================

  String? _hoveredActivity;

  Offset? _hoverPosition;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final slices = _buildSlices(
      widget.entries,
    );

    if (slices.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 34,
        ),
        decoration: BoxDecoration(
          color: TrainingHistoryPieChart._surface,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: TrainingHistoryPieChart._border,
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.pie_chart_outline_rounded,
              size: 38,
              color: TrainingHistoryPieChart._muted,
            ),

            SizedBox(
              height: 10,
            ),

            Text(
              'Sem dados para o gráfico.',
              style: TextStyle(
                color: TrainingHistoryPieChart._text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(
              height: 4,
            ),

            Text(
              'Registre treinos ou altere o período selecionado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TrainingHistoryPieChart._muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: TrainingHistoryPieChart._surface,
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: TrainingHistoryPieChart._border,
        ),
      ),
      child: LayoutBuilder(
        builder:
            (
              context,
              constraints,
            ) {
              final chart = _buildChart(
                slices,
              );

              final legend = _buildLegend(
                slices,
              );

              if (constraints.maxWidth <
                  660) {
                return Column(
                  children: [
                    Center(
                      child: chart,
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    legend,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  chart,

                  const SizedBox(
                    width: 24,
                  ),

                  Expanded(
                    child: legend,
                  ),
                ],
              );
            },
      ),
    );
  }

  // ============================================================
  // GRÁFICO
  // ============================================================

  Widget _buildChart(
    List<
      _PieSlice
    >
    slices,
  ) {
    final hoveredSlice = _findSliceByActivity(
      slices,
      _hoveredActivity,
    );

    return MouseRegion(
      cursor:
          _hoveredActivity ==
              null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onExit:
          (
            _,
          ) {
            if (_hoveredActivity ==
                    null &&
                _hoverPosition ==
                    null) {
              return;
            }

            setState(
              () {
                _hoveredActivity = null;

                _hoverPosition = null;
              },
            );
          },
      onHover:
          (
            event,
          ) {
            _updateHover(
              event.localPosition,
              slices,
            );
          },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp:
            (
              details,
            ) {
              final slice = _sliceAtPosition(
                details.localPosition,
                slices,
              );

              if (slice ==
                  null) {
                return;
              }

              widget.onActivitySelected?.call(
                slice.activity,
              );
            },
        child: SizedBox(
          width: _chartBoxSize,
          height: _chartBoxSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: _paintInset,
                top: _paintInset,
                child: CustomPaint(
                  size: const Size.square(
                    _paintSize,
                  ),
                  painter: _PiePainter(
                    slices: slices,
                    selectedActivity: widget.selectedActivity,
                    hoveredActivity: _hoveredActivity,
                  ),
                ),
              ),

              Center(
                child: IgnorePointer(
                  child: Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: TrainingHistoryPieChart._surface,
                      border: Border.all(
                        color: TrainingHistoryPieChart._border,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.entries.length}',
                          style: const TextStyle(
                            color: TrainingHistoryPieChart._text,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height: 2,
                        ),

                        const Text(
                          'treinos',
                          style: TextStyle(
                            color: TrainingHistoryPieChart._muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (hoveredSlice !=
                      null &&
                  _hoverPosition !=
                      null)
                _buildHoverTooltip(
                  hoveredSlice,
                  _hoverPosition!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TOOLTIP DO HOVER
  // ============================================================

  Widget _buildHoverTooltip(
    _PieSlice slice,
    Offset mousePosition,
  ) {
    const tooltipWidth = 150.0;

    const tooltipHeight = 58.0;

    const margin = 8.0;

    var left =
        mousePosition.dx +
        12;

    var top =
        mousePosition.dy -
        16;

    if (left +
            tooltipWidth >
        _chartBoxSize -
            margin) {
      left =
          mousePosition.dx -
          tooltipWidth -
          12;
    }

    if (left <
        margin) {
      left = margin;
    }

    if (top +
            tooltipHeight >
        _chartBoxSize -
            margin) {
      top =
          _chartBoxSize -
          tooltipHeight -
          margin;
    }

    if (top <
        margin) {
      top = margin;
    }

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: tooltipWidth,
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: TrainingHistoryPieChart._surface,
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: slice.color.withValues(
                alpha: 0.42,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x22000000,
                ),
                blurRadius: 12,
                offset: Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(
                    width: 7,
                  ),

                  Expanded(
                    child: Text(
                      slice.activity,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: TrainingHistoryPieChart._text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 5,
              ),

              Text(
                '${slice.count} ${slice.count == 1 ? 'treino' : 'treinos'} • '
                '${slice.percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: TrainingHistoryPieChart._muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HOVER HIT TEST
  // ============================================================

  void _updateHover(
    Offset position,
    List<
      _PieSlice
    >
    slices,
  ) {
    final slice = _sliceAtPosition(
      position,
      slices,
    );

    final nextActivity = slice?.activity;

    if (nextActivity ==
            _hoveredActivity &&
        _hoverPosition ==
            position) {
      return;
    }

    setState(
      () {
        _hoveredActivity = nextActivity;

        _hoverPosition =
            slice ==
                null
            ? null
            : position;
      },
    );
  }

  _PieSlice? _sliceAtPosition(
    Offset position,
    List<
      _PieSlice
    >
    slices,
  ) {
    final center = const Offset(
      _chartBoxSize /
          2,
      _chartBoxSize /
          2,
    );

    final delta =
        position -
        center;

    final distance = delta.distance;

    if (distance <
            _holeRadius ||
        distance >
            _baseRadius +
                _selectedExtraRadius) {
      return null;
    }

    var angle = math.atan2(
      delta.dy,
      delta.dx,
    );

    // O gráfico começa em -90° (12 horas).
    // Transformamos o ângulo para intervalo 0..2π,
    // também começando no topo.
    angle +=
        math.pi /
        2;

    if (angle <
        0) {
      angle +=
          math.pi *
          2;
    }

    var accumulated = 0.0;

    for (final slice in slices) {
      final sweep =
          slice.percent /
          100 *
          math.pi *
          2;

      final end =
          accumulated +
          sweep;

      if (angle >=
              accumulated &&
          angle <
              end) {
        return slice;
      }

      accumulated = end;
    }

    if (slices.isNotEmpty &&
        angle <=
            math.pi *
                2) {
      return slices.last;
    }

    return null;
  }

  // ============================================================
  // LEGENDA
  // ============================================================

  Widget _buildLegend(
    List<
      _PieSlice
    >
    slices,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Distribuição por atividade',
          style: TextStyle(
            color: TrainingHistoryPieChart._text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        const Text(
          'Passe o mouse no gráfico ou clique em uma atividade.',
          style: TextStyle(
            color: TrainingHistoryPieChart._muted,
            fontSize: 10,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        for (final slice in slices)
          Padding(
            padding: const EdgeInsets.only(
              bottom: 7,
            ),
            child: MouseRegion(
              onEnter:
                  (
                    _,
                  ) {
                    setState(
                      () {
                        _hoveredActivity = slice.activity;

                        _hoverPosition = null;
                      },
                    );
                  },
              onExit:
                  (
                    _,
                  ) {
                    if (_hoveredActivity !=
                        slice.activity) {
                      return;
                    }

                    setState(
                      () {
                        _hoveredActivity = null;

                        _hoverPosition = null;
                      },
                    );
                  },
              child: InkWell(
                borderRadius: BorderRadius.circular(
                  10,
                ),
                onTap:
                    widget.onActivitySelected ==
                        null
                    ? null
                    : () {
                        widget.onActivitySelected!(
                          slice.activity,
                        );
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _isHighlighted(
                          slice.activity,
                        )
                        ? TrainingHistoryPieChart._soft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    border: Border.all(
                      color:
                          _isHighlighted(
                            slice.activity,
                          )
                          ? TrainingHistoryPieChart._border
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: slice.color,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Expanded(
                        child: Text(
                          slice.activity,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TrainingHistoryPieChart._text,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Text(
                        '${slice.count}',
                        style: const TextStyle(
                          color: TrainingHistoryPieChart._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      Text(
                        '${slice.percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: TrainingHistoryPieChart._primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // HIGHLIGHT
  // ============================================================

  bool _isHighlighted(
    String activity,
  ) {
    return widget.selectedActivity ==
            activity ||
        _hoveredActivity ==
            activity;
  }

  // ============================================================
  // SLICE BY ACTIVITY
  // ============================================================

  _PieSlice? _findSliceByActivity(
    List<
      _PieSlice
    >
    slices,
    String? activity,
  ) {
    if (activity ==
        null) {
      return null;
    }

    for (final slice in slices) {
      if (slice.activity ==
          activity) {
        return slice;
      }
    }

    return null;
  }

  // ============================================================
  // CONSTRUIR FATIAS
  // ============================================================

  static List<
    _PieSlice
  >
  _buildSlices(
    List<
      TrainingHistoryEntry
    >
    entries,
  ) {
    final counts =
        <
          String,
          int
        >{};

    for (final entry in entries) {
      final activity = entry.activity.trim();

      if (activity.isEmpty) {
        continue;
      }

      counts.update(
        activity,
        (
          value,
        ) =>
            value +
            1,
        ifAbsent: () => 1,
      );
    }

    if (counts.isEmpty) {
      return const [];
    }

    final ordered = counts.entries.toList()
      ..sort(
        (
          first,
          second,
        ) => second.value.compareTo(
          first.value,
        ),
      );

    final total =
        ordered.fold<
          int
        >(
          0,
          (
            sum,
            item,
          ) =>
              sum +
              item.value,
        );

    return List<
      _PieSlice
    >.generate(
      ordered.length,
      (
        index,
      ) {
        final item = ordered[index];

        return _PieSlice(
          activity: item.key,
          count: item.value,
          percent:
              total ==
                  0
              ? 0
              : (item.value /
                        total) *
                    100,
          color:
              TrainingHistoryPieChart._colors[index %
                  TrainingHistoryPieChart._colors.length],
        );
      },
      growable: false,
    );
  }
}

class _PieSlice {
  const _PieSlice({
    required this.activity,
    required this.count,
    required this.percent,
    required this.color,
  });

  final String activity;

  final int count;

  final double percent;

  final Color color;
}

class _PiePainter
    extends
        CustomPainter {
  const _PiePainter({
    required this.slices,
    required this.selectedActivity,
    required this.hoveredActivity,
  });

  final List<
    _PieSlice
  >
  slices;

  final String? selectedActivity;

  final String? hoveredActivity;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width /
          2,
      size.height /
          2,
    );

    final baseRadius =
        math.min(
              size.width,
              size.height,
            ) /
            2 -
        8;

    const gap = 0.018;

    var startAngle =
        -math.pi /
        2;

    for (final slice in slices) {
      final sweep =
          slice.percent /
          100 *
          math.pi *
          2;

      final highlighted =
          selectedActivity ==
              slice.activity ||
          hoveredActivity ==
              slice.activity;

      final radius = highlighted
          ? baseRadius +
                5
          : baseRadius;

      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      canvas.drawArc(
        Rect.fromCircle(
          center: center,
          radius: radius,
        ),
        startAngle +
            gap,
        math.max(
          0,
          sweep -
              gap *
                  2,
        ),
        true,
        paint,
      );

      startAngle += sweep;
    }

    canvas.drawCircle(
      center,
      baseRadius *
          0.47,
      Paint()
        ..color = TrainingHistoryPieChart._surface
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(
    covariant _PiePainter oldDelegate,
  ) {
    return oldDelegate.selectedActivity !=
            selectedActivity ||
        oldDelegate.hoveredActivity !=
            hoveredActivity ||
        oldDelegate.slices !=
            slices;
  }
}
