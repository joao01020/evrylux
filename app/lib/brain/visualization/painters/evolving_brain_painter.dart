import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/brain_connection.dart';
import '../models/brain_visual_config.dart';
import 'brain_paths.dart';

class EvolvingBrainPainter extends CustomPainter {
  const EvolvingBrainPainter({
    required this.birthProgress,

    // ==========================================================
    // LEGADO
    // ==========================================================
    //
    // Mantidos temporariamente para o EvolvingBrain atual.
    //
    // Depois que finalizarmos a migração semântica,
    // esses campos poderão ser removidos.
    //
    // ==========================================================
    required this.visibleConnections,
    required this.growingConnectionIndex,

    // ==========================================================
    // ANIMAÇÃO
    // ==========================================================
    required this.growingConnectionProgress,
    required this.searchPulseProgress,
    required this.isSearching,

    // ==========================================================
    // VISUAL
    // ==========================================================
    required this.config,
    required this.baseColor,
    required this.connectionColor,
    required this.activeConnectionColor,
    required this.pulseColor,

    // ==========================================================
    // NOVA ARQUITETURA SEMÂNTICA
    // ==========================================================
    //
    // Exemplo:
    //
    // {
    //   0: 3, // branch_0 nível 3
    //   4: 1, // branch_4 nível 1
    //   6: 2, // branch_6 nível 2
    // }
    //
    // ==========================================================
    this.semanticMode = false,
    this.branchLevels = const <int, int>{},
    this.growingBranchIndex,
    this.growingBranchStageIndex,

    // ==========================================================
    // SEARCH RESULT
    // ==========================================================
    this.resolvedBranchIndex,
    this.resolvedConnectionIndex,
    this.searchResolveProgress = 0,
    this.matchGlowProgress = 0,
  });

  // ============================================================
  // BIRTH
  // ============================================================

  final double birthProgress;

  // ============================================================
  // LEGACY CONNECTION STATE
  // ============================================================

  final int visibleConnections;

  final int? growingConnectionIndex;

  // ============================================================
  // SEMANTIC CONNECTION STATE
  // ============================================================

  /// Quando true, o painter ignora a lógica linear antiga.
  ///
  /// Nesse modo:
  ///
  /// branchLevels decide exatamente quais ramos aparecem.
  final bool semanticMode;

  /// branchIndex -> nível atual.
  ///
  /// Exemplo:
  ///
  /// 0: 3
  ///
  /// significa:
  ///
  /// branch_0
  /// estágio 0
  /// estágio 1
  /// estágio 2
  ///
  /// visíveis.
  final Map<int, int> branchLevels;

  /// Ramo que está crescendo neste momento.
  final int? growingBranchIndex;

  /// Estágio daquele ramo que está crescendo.
  ///
  /// Exemplo:
  ///
  /// branch 0:
  ///
  /// nível 2 -> nível 3
  ///
  /// growingBranchStageIndex = 2
  final int? growingBranchStageIndex;

  // ============================================================
  // SEARCH RESULT
  // ============================================================

  final int? resolvedBranchIndex;

  /// Conexão legada exata vinculada ao BrainFile encontrado.
  final int? resolvedConnectionIndex;

  final double searchResolveProgress;

  final double matchGlowProgress;

  // ============================================================
  // ANIMATION
  // ============================================================

  final double growingConnectionProgress;

  final double searchPulseProgress;

  final bool isSearching;

  // ============================================================
  // CONFIG
  // ============================================================

  final BrainVisualConfig config;

  // ============================================================
  // COLORS
  // ============================================================

  final Color baseColor;

  final Color connectionColor;

  final Color activeConnectionColor;

  final Color pulseColor;

  // ============================================================
  // PAINT
  // ============================================================

  @override
  void paint(Canvas canvas, Size size) {
    // ==========================================================
    // BASE PAINT
    // ==========================================================

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = baseColor;

    // ==========================================================
    // CONNECTION PAINT
    // ==========================================================

    final connectionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = connectionColor;

    // ==========================================================
    // ACTIVE PAINT
    // ==========================================================

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = activeConnectionColor;

    // ==========================================================
    // BIRTH
    // ==========================================================

    _drawBirth(canvas, size, basePaint);

    if (birthProgress < 1) {
      return;
    }

    // ==========================================================
    // CONNECTIONS
    // ==========================================================

    if (semanticMode) {
      _drawSemanticConnections(canvas, size, connectionPaint, activePaint);
    } else {
      _drawLegacyConnections(canvas, size, connectionPaint, activePaint);
    }

    // ==========================================================
    // SEARCH
    // ==========================================================

    if (isSearching) {
      _drawSearchPulses(canvas, size);
    }

    // ==========================================================
    // RESULTADO ENCONTRADO
    // ==========================================================

    if (resolvedBranchIndex != null || resolvedConnectionIndex != null) {
      if (matchGlowProgress > 0) {
        if (resolvedConnectionIndex != null) {
          _drawMatchedConnectionGlow(canvas, size);
        } else {
          _drawMatchedBranchGlow(canvas, size);
        }
      }

      if (searchResolveProgress > 0) {
        if (resolvedConnectionIndex != null) {
          _drawResolvedConnectionPulse(canvas, size);
        } else {
          _drawResolvedSearchPulse(canvas, size);
        }
      }
    }
  }

  // ============================================================
  // BIRTH
  // ============================================================

  void _drawBirth(Canvas canvas, Size size, Paint paint) {
    final progress = Curves.easeInOutCubic.transform(
      birthProgress.clamp(0.0, 1.0),
    );

    final basePaths = BrainPaths.basePaths(size);

    // ========================================================
    // HEMISFÉRIOS
    // ========================================================
    //
    // Ambos são desenhados juntos.
    //
    // Isso evita o efeito antigo:
    //
    // ponto
    //   ↓
    // linha subindo pelo meio
    //
    // ========================================================

    for (final path in basePaths) {
      _drawPartialPath(canvas, path, progress, paint);
    }
  }

  // ============================================================
  // SEMANTIC CONNECTIONS
  // ============================================================

  void _drawSemanticConnections(
    Canvas canvas,
    Size size,
    Paint connectionPaint,
    Paint activePaint,
  ) {
    if (branchLevels.isEmpty && growingBranchIndex == null) {
      return;
    }

    // ========================================================
    // RAMOS EXISTENTES
    // ========================================================

    final branchIndexes = branchLevels.keys.toList()..sort();

    for (final branchIndex in branchIndexes) {
      final level = branchLevels[branchIndex] ?? 0;

      if (level <= 0) {
        continue;
      }

      BrainBranchDefinition branch;

      try {
        branch = BrainPaths.branchAt(branchIndex);
      } catch (_) {
        continue;
      }

      final safeLevel = level.clamp(0, branch.stages.length);

      for (var stageIndex = 0; stageIndex < safeLevel; stageIndex += 1) {
        // ====================================================
        // NÃO DESENHAR O ESTÁGIO ATIVO DUAS VEZES
        // ====================================================

        final isActiveStage =
            growingBranchIndex == branchIndex &&
            growingBranchStageIndex == stageIndex;

        if (isActiveStage) {
          continue;
        }

        final definition = _definitionForStage(branch.stages[stageIndex]);

        final path = definition.build(size);

        canvas.drawPath(path, connectionPaint);
      }
    }

    // ========================================================
    // ESTÁGIO QUE ESTÁ NASCENDO
    // ========================================================

    final activeBranchIndex = growingBranchIndex;

    final activeStageIndex = growingBranchStageIndex;

    if (activeBranchIndex == null || activeStageIndex == null) {
      return;
    }

    BrainBranchDefinition branch;

    try {
      branch = BrainPaths.branchAt(activeBranchIndex);
    } catch (_) {
      return;
    }

    if (activeStageIndex < 0 || activeStageIndex >= branch.stages.length) {
      return;
    }

    final definition = _definitionForStage(branch.stages[activeStageIndex]);

    final path = definition.build(size);

    // ========================================================
    // RAMIFICAÇÃO NASCENDO
    // ========================================================

    _drawPartialPath(canvas, path, growingConnectionProgress, activePaint);

    // ========================================================
    // PULSO ACOMPANHANDO A EXTREMIDADE
    // ========================================================

    _drawPulseOnPath(canvas, path, growingConnectionProgress, intensity: 1);
  }

  // ============================================================
  // LEGACY CONNECTIONS
  // ============================================================
  //
  // Mantido temporariamente.
  //
  // Depois que EvolvingBrain estiver 100% migrado,
  // podemos remover este método.
  //
  // ============================================================

  void _drawLegacyConnections(
    Canvas canvas,
    Size size,
    Paint connectionPaint,
    Paint activePaint,
  ) {
    final definitions = BrainPaths.connections;

    final safeVisible = visibleConnections.clamp(0, definitions.length);

    // ========================================================
    // JÁ VISÍVEIS
    // ========================================================

    for (var index = 0; index < safeVisible; index += 1) {
      if (index == growingConnectionIndex) {
        continue;
      }

      final path = definitions[index].build(size);

      canvas.drawPath(path, connectionPaint);
    }

    // ========================================================
    // CRESCENDO
    // ========================================================

    final activeIndex = growingConnectionIndex;

    if (activeIndex == null ||
        activeIndex < 0 ||
        activeIndex >= definitions.length) {
      return;
    }

    final path = definitions[activeIndex].build(size);

    _drawPartialPath(canvas, path, growingConnectionProgress, activePaint);

    _drawPulseOnPath(canvas, path, growingConnectionProgress, intensity: 1);
  }

  // ============================================================
  // SEARCH PULSES
  // ============================================================

  void _drawSearchPulses(Canvas canvas, Size size) {
    final definitions = semanticMode
        ? _semanticVisibleDefinitions()
        : _legacyVisibleDefinitions();

    if (definitions.isEmpty) {
      return;
    }

    // ========================================================
    // FASES
    // ========================================================
    //
    // Os pulsos começam em momentos diferentes.
    //
    // Isso evita parecer que todos os neurônios disparam
    // simultaneamente.
    //
    // ========================================================

    const phases = <double>[0.00, 0.37, 0.71];

    for (var i = 0; i < phases.length; i += 1) {
      final phase = (searchPulseProgress + phases[i]) % 1.0;

      // ======================================================
      // QUAL CONEXÃO
      // ======================================================

      final pathIndex =
          ((phase * definitions.length).floor() + (i * 3)) % definitions.length;

      final definition = definitions[pathIndex];

      final path = definition.build(size);

      // ======================================================
      // POSIÇÃO DENTRO DO TRAÇO
      // ======================================================

      final localProgress = (phase * definitions.length) % 1.0;

      // ======================================================
      // FADE
      // ======================================================

      final fade = 0.42 + (0.58 * math.sin(localProgress * math.pi));

      _drawPulseOnPath(canvas, path, localProgress, intensity: fade);
    }
  }

  // ============================================================
  // FINAL SEARCH PULSE — CONEXÃO EXATA
  // ============================================================
  //
  // No fluxo legado cada BrainFile criado faz nascer exatamente uma
  // entrada de BrainPaths.connections. Quando a busca local encontra
  // esse arquivo, percorremos a MESMA Path que nasceu naquela posição,
  // em vez de converter o resultado em um branchIndex por hash.
  //
  // ============================================================

  void _drawResolvedConnectionPulse(Canvas canvas, Size size) {
    final connectionIndex = resolvedConnectionIndex;

    if (connectionIndex == null ||
        connectionIndex < 0 ||
        connectionIndex >= BrainPaths.connections.length) {
      return;
    }

    final definition = BrainPaths.connections[connectionIndex];
    final path = definition.build(size);
    final progress = searchResolveProgress.clamp(0.0, 1.0);

    _drawPulseOnPath(canvas, path, progress, intensity: 1);

    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final metric = metrics.first;
    final head = metric.length * progress;
    final tail = math.max(0.0, head - (metric.length * 0.30));

    if (head > tail) {
      final electricPath = metric.extractPath(tail, head);

      final electricPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.connectionStrokeWidth * 1.85
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = pulseColor.withValues(alpha: 0.96)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);

      canvas.drawPath(electricPath, electricPaint);
    }

    if (progress > 0.72) {
      final tangent = metric.getTangentForOffset(metric.length);

      if (tangent == null) {
        return;
      }

      final impactProgress = ((progress - 0.72) / 0.28).clamp(0.0, 1.0);
      final pulse = math.sin(impactProgress * math.pi);

      final haloPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = pulseColor.withValues(alpha: 0.42 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = pulseColor.withValues(alpha: 0.82 * pulse);

      canvas.drawCircle(
        tangent.position,
        config.pulseRadius * (3.0 + (impactProgress * 3.0)),
        haloPaint,
      );

      canvas.drawCircle(
        tangent.position,
        config.pulseRadius * (1.4 + (impactProgress * 2.5)),
        ringPaint,
      );
    }
  }

  // ============================================================
  // MATCHED CONNECTION GLOW
  // ============================================================

  void _drawMatchedConnectionGlow(Canvas canvas, Size size) {
    final connectionIndex = resolvedConnectionIndex;

    if (connectionIndex == null ||
        connectionIndex < 0 ||
        connectionIndex >= BrainPaths.connections.length) {
      return;
    }

    final glow = matchGlowProgress.clamp(0.0, 1.0);

    if (glow <= 0) {
      return;
    }

    final definition = BrainPaths.connections[connectionIndex];
    final path = definition.build(size);

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth * 5.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = pulseColor.withValues(alpha: 0.34 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final activeGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth * 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = activeConnectionColor.withValues(alpha: 0.92 * glow);

    canvas.drawPath(path, haloPaint);
    canvas.drawPath(path, activeGlowPaint);

    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final tangent = metrics.first.getTangentForOffset(metrics.first.length);

    if (tangent == null) {
      return;
    }

    final regionHaloPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pulseColor.withValues(alpha: 0.30 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);

    final regionCorePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pulseColor.withValues(alpha: 0.82 * glow);

    canvas.drawCircle(
      tangent.position,
      config.pulseRadius * 5.0,
      regionHaloPaint,
    );

    canvas.drawCircle(
      tangent.position,
      config.pulseRadius * 1.15,
      regionCorePaint,
    );
  }

  // ============================================================
  // FINAL SEARCH PULSE
  // ============================================================
  //
  // O pulso final percorre sequencialmente todos os estágios
  // do ramo localizado.
  //
  // Ao chegar ao final, desenhamos também um pequeno impacto
  // luminoso para dar sensação de "memória encontrada".
  //
  // ============================================================

  void _drawResolvedSearchPulse(Canvas canvas, Size size) {
    final branchIndex = resolvedBranchIndex;

    if (branchIndex == null ||
        branchIndex < 0 ||
        branchIndex >= BrainPaths.mainBranchCount) {
      return;
    }

    BrainBranchDefinition branch;

    try {
      branch = BrainPaths.branchAt(branchIndex);
    } catch (_) {
      return;
    }

    if (branch.stages.isEmpty) {
      return;
    }

    final progress = searchResolveProgress.clamp(0.0, 1.0);

    final scaled = progress * branch.stages.length;

    var stageIndex = scaled.floor();

    if (stageIndex >= branch.stages.length) {
      stageIndex = branch.stages.length - 1;
    }

    final localProgress =
        stageIndex == branch.stages.length - 1 && progress >= 1
        ? 1.0
        : (scaled - stageIndex).clamp(0.0, 1.0);

    final definition = _definitionForStage(branch.stages[stageIndex]);

    final path = definition.build(size);

    _drawPulseOnPath(canvas, path, localProgress, intensity: 1);

    // ========================================================
    // TRAÇO ELÉTRICO CURTO ATRÁS DO PULSO
    // ========================================================

    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final metric = metrics.first;

    final head = metric.length * localProgress;

    final tail = math.max(0.0, head - (metric.length * 0.30));

    if (head > tail) {
      final electricPath = metric.extractPath(tail, head);

      final electricPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = config.connectionStrokeWidth * 1.85
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = pulseColor.withValues(alpha: 0.96)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.2);

      canvas.drawPath(electricPath, electricPaint);
    }

    // ========================================================
    // IMPACTO FINAL
    // ========================================================

    if (stageIndex == branch.stages.length - 1 && localProgress > 0.72) {
      final tangent = metric.getTangentForOffset(metric.length);

      if (tangent == null) {
        return;
      }

      final impactProgress = ((localProgress - 0.72) / 0.28).clamp(0.0, 1.0);

      final pulse = math.sin(impactProgress * math.pi);

      final haloPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = pulseColor.withValues(alpha: 0.42 * pulse)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = pulseColor.withValues(alpha: 0.82 * pulse);

      final position = tangent.position;

      canvas.drawCircle(
        position,
        config.pulseRadius * (3.0 + (impactProgress * 3.0)),
        haloPaint,
      );

      canvas.drawCircle(
        position,
        config.pulseRadius * (1.4 + (impactProgress * 2.5)),
        ringPaint,
      );
    }
  }

  // ============================================================
  // MATCHED REGION GLOW
  // ============================================================
  //
  // Depois do pulso final, o ramo inteiro fica iluminado
  // temporariamente.
  //
  // Mantemos o desenho original do cérebro e adicionamos apenas
  // duas camadas:
  //
  // - halo difuso;
  // - linha ativa mais clara.
  //
  // ============================================================

  void _drawMatchedBranchGlow(Canvas canvas, Size size) {
    final branchIndex = resolvedBranchIndex;

    if (branchIndex == null ||
        branchIndex < 0 ||
        branchIndex >= BrainPaths.mainBranchCount) {
      return;
    }

    BrainBranchDefinition branch;

    try {
      branch = BrainPaths.branchAt(branchIndex);
    } catch (_) {
      return;
    }

    final glow = matchGlowProgress.clamp(0.0, 1.0);

    if (glow <= 0) {
      return;
    }

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth * 5.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = pulseColor.withValues(alpha: 0.34 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final activeGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.connectionStrokeWidth * 1.75
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = activeConnectionColor.withValues(alpha: 0.92 * glow);

    for (final stage in branch.stages) {
      final definition = _definitionForStage(stage);

      final path = definition.build(size);

      canvas.drawPath(path, haloPaint);

      canvas.drawPath(path, activeGlowPaint);
    }

    // Pequeno "acendimento" concentrado na extremidade final
    // da região encontrada. Isso deixa evidente que a busca
    // realmente chegou a um conteúdo específico.
    final end = branch.stages.last.end;

    final center = Offset(end.dx * size.width, end.dy * size.height);

    final regionHaloPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pulseColor.withValues(alpha: 0.30 * glow)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 13);

    final regionCorePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = pulseColor.withValues(alpha: 0.82 * glow);

    canvas.drawCircle(center, config.pulseRadius * 5.0, regionHaloPaint);

    canvas.drawCircle(center, config.pulseRadius * 1.15, regionCorePaint);
  }

  // ============================================================
  // SEMANTIC VISIBLE DEFINITIONS
  // ============================================================

  List<BrainConnectionDefinition> _semanticVisibleDefinitions() {
    final result = <BrainConnectionDefinition>[];

    final indexes = branchLevels.keys.toList()..sort();

    for (final branchIndex in indexes) {
      final level = branchLevels[branchIndex] ?? 0;

      if (level <= 0) {
        continue;
      }

      BrainBranchDefinition branch;

      try {
        branch = BrainPaths.branchAt(branchIndex);
      } catch (_) {
        continue;
      }

      final safeLevel = level.clamp(0, branch.stages.length);

      for (var stageIndex = 0; stageIndex < safeLevel; stageIndex += 1) {
        result.add(_definitionForStage(branch.stages[stageIndex]));
      }
    }

    return result;
  }

  // ============================================================
  // LEGACY VISIBLE DEFINITIONS
  // ============================================================

  List<BrainConnectionDefinition> _legacyVisibleDefinitions() {
    final definitions = BrainPaths.connections;

    if (definitions.isEmpty) {
      return const <BrainConnectionDefinition>[];
    }

    final safeVisible = visibleConnections.clamp(0, definitions.length);

    return definitions.take(safeVisible).toList(growable: false);
  }

  // ============================================================
  // BRANCH STAGE -> CONNECTION DEFINITION
  // ============================================================

  BrainConnectionDefinition _definitionForStage(BrainBranchStage stage) {
    return BrainConnectionDefinition(
      start: stage.start,
      control1: stage.control1,
      control2: stage.control2,
      end: stage.end,
    );
  }

  // ============================================================
  // PULSE
  // ============================================================

  void _drawPulseOnPath(
    Canvas canvas,
    Path path,
    double progress, {
    required double intensity,
  }) {
    final metrics = path.computeMetrics().toList();

    if (metrics.isEmpty) {
      return;
    }

    final metric = metrics.first;

    final safeProgress = progress.clamp(0.0, 1.0);

    final tangent = metric.getTangentForOffset(metric.length * safeProgress);

    if (tangent == null) {
      return;
    }

    final position = tangent.position;

    // ========================================================
    // HALO
    // ========================================================

    final haloPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.18 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    // ========================================================
    // MEDIUM
    // ========================================================

    final mediumPaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.40 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    // ========================================================
    // CORE
    // ========================================================

    final corePaint = Paint()
      ..color = pulseColor.withValues(alpha: 0.95 * intensity);

    // ========================================================
    // DRAW
    // ========================================================

    canvas.drawCircle(position, config.pulseRadius * 2.4, haloPaint);

    canvas.drawCircle(position, config.pulseRadius * 1.35, mediumPaint);

    canvas.drawCircle(position, config.pulseRadius * 0.62, corePaint);
  }

  // ============================================================
  // PARTIAL PATH
  // ============================================================

  void _drawPartialPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
  ) {
    final safeProgress = progress.clamp(0.0, 1.0);

    for (final metric in path.computeMetrics()) {
      final extracted = metric.extractPath(0, metric.length * safeProgress);

      canvas.drawPath(extracted, paint);
    }
  }

  // ============================================================
  // SHOULD REPAINT
  // ============================================================

  @override
  bool shouldRepaint(covariant EvolvingBrainPainter oldDelegate) {
    return oldDelegate.birthProgress != birthProgress ||
        // ======================================================
        // LEGACY
        // ======================================================
        oldDelegate.visibleConnections != visibleConnections ||
        oldDelegate.growingConnectionIndex != growingConnectionIndex ||
        // ======================================================
        // SEMANTIC
        // ======================================================
        oldDelegate.semanticMode != semanticMode ||
        !mapEquals(oldDelegate.branchLevels, branchLevels) ||
        oldDelegate.growingBranchIndex != growingBranchIndex ||
        oldDelegate.growingBranchStageIndex != growingBranchStageIndex ||
        // ======================================================
        // ANIMATION
        // ======================================================
        oldDelegate.growingConnectionProgress != growingConnectionProgress ||
        oldDelegate.searchPulseProgress != searchPulseProgress ||
        oldDelegate.isSearching != isSearching ||
        oldDelegate.resolvedBranchIndex != resolvedBranchIndex ||
        oldDelegate.resolvedConnectionIndex != resolvedConnectionIndex ||
        oldDelegate.searchResolveProgress != searchResolveProgress ||
        oldDelegate.matchGlowProgress != matchGlowProgress ||
        // ======================================================
        // COLORS / CONFIG
        // ======================================================
        oldDelegate.baseColor != baseColor ||
        oldDelegate.connectionColor != connectionColor ||
        oldDelegate.activeConnectionColor != activeConnectionColor ||
        oldDelegate.pulseColor != pulseColor ||
        oldDelegate.config != config;
  }
}
