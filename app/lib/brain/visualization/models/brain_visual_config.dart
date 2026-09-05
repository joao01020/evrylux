import 'package:flutter/material.dart';

@immutable
class BrainVisualConfig {
  const BrainVisualConfig({
    this.birthDuration = const Duration(milliseconds: 7200),
    this.branchGrowthDuration = const Duration(milliseconds: 1900),
    this.branchSettleDuration = const Duration(milliseconds: 380),
    this.searchPulseDuration = const Duration(milliseconds: 2500),
    this.strokeWidth = 5.8,
    this.connectionStrokeWidth = 4.4,
    this.pulseRadius = 2.7,
    this.baseColor,
    this.connectionColor,
    this.activeConnectionColor,
    this.pulseColor,
  });

  final Duration birthDuration;
  final Duration branchGrowthDuration;
  final Duration branchSettleDuration;
  final Duration searchPulseDuration;

  final double strokeWidth;
  final double connectionStrokeWidth;
  final double pulseRadius;

  final Color? baseColor;
  final Color? connectionColor;
  final Color? activeConnectionColor;
  final Color? pulseColor;

  BrainVisualConfig copyWith({
    Duration? birthDuration,
    Duration? branchGrowthDuration,
    Duration? branchSettleDuration,
    Duration? searchPulseDuration,
    double? strokeWidth,
    double? connectionStrokeWidth,
    double? pulseRadius,
    Color? baseColor,
    Color? connectionColor,
    Color? activeConnectionColor,
    Color? pulseColor,
  }) {
    return BrainVisualConfig(
      birthDuration: birthDuration ?? this.birthDuration,
      branchGrowthDuration:
          branchGrowthDuration ?? this.branchGrowthDuration,
      branchSettleDuration:
          branchSettleDuration ?? this.branchSettleDuration,
      searchPulseDuration:
          searchPulseDuration ?? this.searchPulseDuration,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      connectionStrokeWidth:
          connectionStrokeWidth ?? this.connectionStrokeWidth,
      pulseRadius: pulseRadius ?? this.pulseRadius,
      baseColor: baseColor ?? this.baseColor,
      connectionColor: connectionColor ?? this.connectionColor,
      activeConnectionColor:
          activeConnectionColor ?? this.activeConnectionColor,
      pulseColor: pulseColor ?? this.pulseColor,
    );
  }
}
