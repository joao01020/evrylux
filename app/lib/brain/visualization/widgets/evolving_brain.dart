import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/brain_visual_controller.dart';
import '../models/brain_growth_planner.dart';
import '../models/brain_visual_config.dart';
import '../painters/brain_paths.dart';
import '../painters/evolving_brain_painter.dart';

class EvolvingBrain extends StatefulWidget {
  const EvolvingBrain({
    super.key,
    required this.controller,
    this.size = 300,
    this.config = const BrainVisualConfig(),
    this.onBirthCompleted,
  });

  final BrainVisualController controller;

  final double size;

  final BrainVisualConfig config;

  final FutureOr<void> Function()? onBirthCompleted;

  @override
  State<EvolvingBrain> createState() => _EvolvingBrainState();
}

class _EvolvingBrainState extends State<EvolvingBrain>
    with TickerProviderStateMixin {
  // ============================================================
  // ANIMATION CONTROLLERS
  // ============================================================

  late final AnimationController _birthController;

  late final AnimationController _branchController;

  late final AnimationController _settleController;

  late final AnimationController _searchController;

  late final AnimationController _searchResolveController;

  late final AnimationController _matchGlowController;

  // ============================================================
  // LEGACY VISUAL STATE
  // ============================================================
  //
  // Mantido temporariamente para não quebrar fluxos antigos.
  //
  // Assim que BrainScreen estiver 100% usando semantic growth,
  // estes campos poderão ser removidos.
  //
  // ============================================================

  int _visibleConnections = 0;

  int? _growingConnectionIndex;

  // ============================================================
  // SEMANTIC VISUAL STATE
  // ============================================================
  //
  // branchIndex -> level
  //
  // Exemplo:
  //
  // {
  //   0: 3,
  //   4: 1,
  // }
  //
  // significa:
  //
  // branch_0 nível 3
  // branch_4 nível 1
  //
  // ============================================================

  Map<int, int> _branchLevels = <int, int>{};

  int? _growingBranchIndex;

  int? _growingBranchStageIndex;

  BrainGrowthResult? _pendingSemanticGrowth;

  int? _resolvedBranchIndex;

  int? _resolvedConnectionIndex;

  // ============================================================
  // EVENT STATE
  // ============================================================

  int _lastEventRevision = -1;

  bool _animatingGrowth = false;

  bool _growthPendingAfterBirth = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _birthController = AnimationController(
      vsync: this,
      duration: widget.config.birthDuration,
    );

    _branchController = AnimationController(
      vsync: this,
      duration: widget.config.branchGrowthDuration,
    );

    _settleController = AnimationController(
      vsync: this,
      duration: widget.config.branchSettleDuration,
    );

    _searchController = AnimationController(
      vsync: this,
      duration: widget.config.searchPulseDuration,
    );

    _searchResolveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _matchGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    widget.controller.addListener(_handleControllerChanged);

    // ========================================================
    // RESTAURAR ESTADO SEMÂNTICO
    // ========================================================

    _syncBranchLevelsFromController();

    // ========================================================
    // FALLBACK LEGADO
    // ========================================================

    final initialLegacyTarget = _currentLegacyVisualTarget();

    // ========================================================
    // BIRTH
    // ========================================================

    if (widget.controller.introSeen) {
      _birthController.value = 1;

      _visibleConnections = initialLegacyTarget;
    } else {
      _visibleConnections = 0;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        unawaited(_playBirth());
      });
    }

    // ========================================================
    // SEARCH
    // ========================================================

    if (widget.controller.isSearching && widget.controller.introSeen) {
      _searchController.repeat();
    }
  }

  // ============================================================
  // DID UPDATE WIDGET
  // ============================================================

  @override
  void didUpdateWidget(covariant EvolvingBrain oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);

      widget.controller.addListener(_handleControllerChanged);

      _syncBranchLevelsFromController();

      if (_birthController.value >= 1 && !_semanticMode) {
        _visibleConnections = _currentLegacyVisualTarget();
      }
    }
  }

  // ============================================================
  // SEMANTIC MODE
  // ============================================================
  //
  // Se existir ao menos um topic semântico, o painter passa a
  // usar branchIndex + level diretamente.
  //
  // ============================================================

  bool get _semanticMode {
    return _branchLevels.isNotEmpty ||
        _growingBranchIndex != null ||
        widget.controller.growthState.topics.isNotEmpty;
  }

  // ============================================================
  // SYNC BRANCH LEVELS
  // ============================================================

  void _syncBranchLevelsFromController() {
    final next = <int, int>{};

    for (final topic in widget.controller.growthState.topics) {
      if (topic.branchIndex < 0 ||
          topic.branchIndex >= BrainPaths.mainBranchCount) {
        continue;
      }

      final branch = BrainPaths.branchAt(topic.branchIndex);

      final safeLevel = topic.level.clamp(0, branch.maxLevel);

      if (safeLevel <= 0) {
        continue;
      }

      next[topic.branchIndex] = safeLevel;
    }

    _branchLevels = next;
  }

  // ============================================================
  // CURRENT LEGACY TARGET
  // ============================================================

  int _currentLegacyVisualTarget() {
    return BrainPaths.connectionCountForKnowledge(
      widget.controller.knowledgeCount,
    );
  }

  // ============================================================
  // BIRTH
  // ============================================================

  Future<void> _playBirth() async {
    _branchController.stop();

    _settleController.stop();

    _searchController.stop();

    _searchResolveController.stop();

    _matchGlowController.stop();

    _resolvedBranchIndex = null;
    _resolvedConnectionIndex = null;

    _growingConnectionIndex = null;

    _growingBranchIndex = null;

    _growingBranchStageIndex = null;

    _visibleConnections = 0;

    _birthController.value = 0;

    await _birthController.forward();

    if (!mounted) {
      return;
    }

    widget.controller.markIntroSeen();

    // ========================================================
    // CALLBACK
    // ========================================================

    await widget.onBirthCompleted?.call();

    if (!mounted) {
      return;
    }

    // ========================================================
    // RESTAURAR O ESTADO QUE JÁ EXISTE
    // ========================================================

    _syncBranchLevelsFromController();

    if (_growthPendingAfterBirth) {
      _growthPendingAfterBirth = false;

      final pending = _pendingSemanticGrowth;

      _pendingSemanticGrowth = null;

      if (pending != null) {
        await _animateSemanticGrowth(pending);
      } else {
        await _animateLegacyTowardTarget();
      }
    } else if (!_semanticMode) {
      setState(() {
        _visibleConnections = _currentLegacyVisualTarget();
      });
    } else {
      setState(() {});
    }

    if (!mounted) {
      return;
    }

    if (widget.controller.isSearching) {
      _searchController.repeat();
    }
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }

    final event = widget.controller.event;

    if (event != null && event.revision != _lastEventRevision) {
      _lastEventRevision = event.revision;

      switch (event.type) {
        // ======================================================
        // LEGADO
        // ======================================================

        case BrainVisualEventType.knowledgeAdded:
        case BrainVisualEventType.knowledgeCountChanged:
          _handleLegacyGrowthEvent();
          break;

        // ======================================================
        // SEMÂNTICO
        // ======================================================

        case BrainVisualEventType.semanticGrowthChanged:
          _handleSemanticGrowthEvent(event);
          break;

        // ======================================================
        // SEARCH
        // ======================================================

        case BrainVisualEventType.searchingChanged:
          _syncSearchAnimation();
          break;

        case BrainVisualEventType.searchResolved:
          unawaited(
            _playSearchResolved(
              branchIndex: event.matchedBranchIndex,
              connectionIndex: event.matchedConnectionIndex,
            ),
          );
          break;

        // ======================================================
        // REPLAY
        // ======================================================

        case BrainVisualEventType.replayBirth:
          unawaited(_playBirth());
          break;
      }
    }

    _syncSearchAnimation();

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // HANDLE LEGACY GROWTH
  // ============================================================

  void _handleLegacyGrowthEvent() {
    // Se já estamos usando o sistema semântico,
    // uma alteração de contagem global não deve escolher
    // aleatoriamente qual linha aparecer.
    if (_semanticMode) {
      _syncBranchLevelsFromController();

      return;
    }

    if (_birthController.value < 1) {
      _growthPendingAfterBirth = true;

      return;
    }

    unawaited(_animateLegacyTowardTarget());
  }

  // ============================================================
  // HANDLE SEMANTIC GROWTH
  // ============================================================

  void _handleSemanticGrowthEvent(BrainVisualEvent event) {
    final result = event.growthResult;

    if (result == null) {
      _syncBranchLevelsFromController();

      return;
    }

    // ========================================================
    // NÃO ATINGIU NOVO MARCO
    // ========================================================
    //
    // Exemplo:
    //
    // 1 item -> nível 1
    // 2 itens -> continua nível 1
    //
    // Nesse caso salvamos o estado, mas não desenhamos um
    // segmento novo.
    //
    // ========================================================

    if (!result.createdNewBranch && !result.levelChanged) {
      _syncBranchLevelsFromController();

      return;
    }

    // ========================================================
    // BIRTH AINDA EM ANDAMENTO
    // ========================================================

    if (_birthController.value < 1) {
      _growthPendingAfterBirth = true;

      _pendingSemanticGrowth = result;

      return;
    }

    unawaited(_animateSemanticGrowth(result));
  }

  // ============================================================
  // ANIMATE SEMANTIC GROWTH
  // ============================================================
  //
  // Esta é a mudança principal:
  //
  // NÃO usamos mais:
  //
  // nextIndex = visibleConnections
  //
  // Agora usamos:
  //
  // result.updatedTopic.branchIndex
  // result.currentLevel
  //
  // Então o mesmo assunto SEMPRE cresce no mesmo ramo.
  //
  // ============================================================

  Future<void> _animateSemanticGrowth(BrainGrowthResult result) async {
    if (_animatingGrowth || _birthController.value < 1) {
      _pendingSemanticGrowth = result;

      return;
    }

    final branchIndex = result.updatedTopic.branchIndex;

    if (branchIndex < 0 || branchIndex >= BrainPaths.mainBranchCount) {
      _syncBranchLevelsFromController();

      return;
    }

    final branch = BrainPaths.branchAt(branchIndex);

    final previousLevel = result.previousLevel.clamp(0, branch.maxLevel);

    final currentLevel = result.currentLevel.clamp(0, branch.maxLevel);

    if (currentLevel <= previousLevel) {
      _syncBranchLevelsFromController();

      return;
    }

    _animatingGrowth = true;

    try {
      // ======================================================
      // GARANTIR O ESTADO ANTERIOR
      // ======================================================
      //
      // Enquanto o novo estágio cresce, o mapa do painter fica
      // no nível anterior.
      //
      // ======================================================

      final before = Map<int, int>.from(_branchLevels);

      if (previousLevel > 0) {
        before[branchIndex] = previousLevel;
      } else {
        before.remove(branchIndex);
      }

      if (mounted) {
        setState(() {
          _branchLevels = before;
        });
      }

      // ======================================================
      // PODE EXISTIR MAIS DE UM NÍVEL A RECUPERAR
      // ======================================================
      //
      // Normalmente será somente um.
      //
      // Mas se houve sincronização/importação:
      //
      // nível 1 -> nível 3
      //
      // animamos stage 1 e depois stage 2.
      //
      // ======================================================

      for (var level = previousLevel + 1; level <= currentLevel; level += 1) {
        if (!mounted) {
          return;
        }

        final stageIndex = level - 1;

        setState(() {
          _growingBranchIndex = branchIndex;

          _growingBranchStageIndex = stageIndex;
        });

        _branchController.value = 0;

        await _branchController.forward();

        if (!mounted) {
          return;
        }

        _settleController.value = 0;

        await _settleController.forward();

        if (!mounted) {
          return;
        }

        setState(() {
          _branchLevels[branchIndex] = level;

          _growingBranchIndex = null;

          _growingBranchStageIndex = null;
        });

        await Future<void>.delayed(const Duration(milliseconds: 120));
      }

      // ======================================================
      // RECONCILIAR COM CONTROLLER
      // ======================================================

      _syncBranchLevelsFromController();

      if (mounted) {
        setState(() {});
      }
    } finally {
      _growingBranchIndex = null;

      _growingBranchStageIndex = null;

      _animatingGrowth = false;

      // ======================================================
      // SE OUTRO CRESCIMENTO CHEGOU DURANTE A ANIMAÇÃO
      // ======================================================

      final pending = _pendingSemanticGrowth;

      _pendingSemanticGrowth = null;

      if (pending != null && mounted && _birthController.value >= 1) {
        unawaited(_animateSemanticGrowth(pending));
      }
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _syncSearchAnimation() {
    if (_birthController.value < 1) {
      return;
    }

    if (widget.controller.isSearching) {
      if (!_searchController.isAnimating) {
        _searchController.repeat();
      }
    } else {
      if (_searchController.isAnimating) {
        _searchController.stop();
      }
    }
  }

  // ============================================================
  // SEARCH RESOLVED
  // ============================================================
  //
  // Pulso final:
  //
  // pesquisa distribuída
  //        ↓
  // encontra o ramo
  //        ↓
  // pulso forte percorre o ramo encontrado
  //        ↓
  // região fica acesa por alguns instantes
  //
  // ============================================================

  Future<void> _playSearchResolved({
    int? branchIndex,
    int? connectionIndex,
  }) async {
    final validBranch =
        branchIndex != null &&
        branchIndex >= 0 &&
        branchIndex < BrainPaths.mainBranchCount;

    final validConnection =
        connectionIndex != null &&
        connectionIndex >= 0 &&
        connectionIndex < BrainPaths.connections.length;

    if ((!validBranch && !validConnection) || _birthController.value < 1) {
      return;
    }

    debugPrint(
      '[BRAIN VISUAL] Executando pulso final '
      'branch=$branchIndex connection=$connectionIndex.',
    );

    _searchController.stop();

    _searchResolveController.stop();

    _matchGlowController.stop();

    if (mounted) {
      setState(() {
        _resolvedBranchIndex = validBranch ? branchIndex : null;
        _resolvedConnectionIndex = validConnection ? connectionIndex : null;
      });
    }

    _searchResolveController.value = 0;

    await _searchResolveController.forward();

    if (!mounted) {
      return;
    }

    _matchGlowController.value = 0;

    await _matchGlowController.forward();

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 520));

    if (!mounted) {
      return;
    }

    await _matchGlowController.reverse();

    if (!mounted) {
      return;
    }

    setState(() {
      _resolvedBranchIndex = null;
      _resolvedConnectionIndex = null;
    });

    _searchResolveController.value = 0;
  }

  // ============================================================
  // LEGACY ANIMATION
  // ============================================================

  Future<void> _animateLegacyTowardTarget() async {
    if (_animatingGrowth || _birthController.value < 1 || _semanticMode) {
      return;
    }

    _animatingGrowth = true;

    try {
      while (mounted) {
        final target = _currentLegacyVisualTarget();

        if (_visibleConnections > target) {
          setState(() {
            _visibleConnections = target;

            _growingConnectionIndex = null;
          });

          break;
        }

        if (_visibleConnections >= target) {
          break;
        }

        final nextIndex = _visibleConnections;

        if (nextIndex < 0 || nextIndex >= BrainPaths.connections.length) {
          break;
        }

        setState(() {
          _growingConnectionIndex = nextIndex;
        });

        _branchController.value = 0;

        await _branchController.forward();

        if (!mounted) {
          return;
        }

        _settleController.value = 0;

        await _settleController.forward();

        if (!mounted) {
          return;
        }

        setState(() {
          _visibleConnections += 1;

          _growingConnectionIndex = null;
        });

        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _animatingGrowth = false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);

    _birthController.dispose();

    _branchController.dispose();

    _settleController.dispose();

    _searchController.dispose();

    _searchResolveController.dispose();

    _matchGlowController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    // ==========================================================
    // BASE COLOR
    // ==========================================================

    final baseColor =
        widget.config.baseColor ??
        (isDark ? const Color(0xFFE7EAE7) : const Color(0xFF283028));

    // ==========================================================
    // CONNECTION COLOR
    // ==========================================================

    final connectionColor =
        widget.config.connectionColor ?? baseColor.withValues(alpha: 0.82);

    // ==========================================================
    // ACTIVE COLOR
    // ==========================================================

    final activeConnectionColor =
        widget.config.activeConnectionColor ?? const Color(0xFF76C66A);

    // ==========================================================
    // PULSE COLOR
    // ==========================================================

    final pulseColor = widget.config.pulseColor ?? const Color(0xFF8DEB7E);

    // ==========================================================
    // PAINTER
    // ==========================================================

    final child = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _birthController,
        _branchController,
        _settleController,
        _searchController,
        _searchResolveController,
        _matchGlowController,
      ]),
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: EvolvingBrainPainter(
            // ==================================================
            // BIRTH
            // ==================================================
            birthProgress: _birthController.value,

            // ==================================================
            // LEGACY
            // ==================================================
            visibleConnections: _visibleConnections,

            growingConnectionIndex: _growingConnectionIndex,

            // ==================================================
            // SEMANTIC
            // ==================================================
            semanticMode: _semanticMode,

            branchLevels: Map<int, int>.unmodifiable(_branchLevels),

            growingBranchIndex: _growingBranchIndex,

            growingBranchStageIndex: _growingBranchStageIndex,

            // ==================================================
            // ANIMATION
            // ==================================================
            growingConnectionProgress: Curves.easeInOutCubic.transform(
              _branchController.value,
            ),

            searchPulseProgress: _searchController.value,

            isSearching:
                widget.controller.isSearching && _birthController.value >= 1,

            resolvedBranchIndex: _resolvedBranchIndex,

            resolvedConnectionIndex: _resolvedConnectionIndex,

            searchResolveProgress: Curves.easeInOutCubic.transform(
              _searchResolveController.value,
            ),

            matchGlowProgress: Curves.easeInOutCubic.transform(
              _matchGlowController.value,
            ),

            // ==================================================
            // CONFIG
            // ==================================================
            config: widget.config,

            // ==================================================
            // COLORS
            // ==================================================
            baseColor: baseColor,

            connectionColor: connectionColor,

            activeConnectionColor: activeConnectionColor,

            pulseColor: pulseColor,
          ),
        );
      },
    );

    // ==========================================================
    // OUTPUT
    // ==========================================================

    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(child: child),
    );
  }
}
