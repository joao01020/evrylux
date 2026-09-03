import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../connectivity_service.dart';
import '../sync_service.dart';

// ============================================================
// SYNC STATUS INDICATOR
// ============================================================
//
// Indicador global minimalista.
//
// NOVA UX:
//
// - nenhum texto visível;
// - nenhum contador;
// - apenas ícone;
// - animação suave durante sync/verificação;
// - mantém cores por estado.
//
// Estados:
//
// Online
//   -> nuvem verde
//
// Sincronizando
//   -> sync amarelo girando
//
// Verificando
//   -> nuvem/sync cinza girando
//
// Offline
//   -> nuvem desligada
//
// Erro
//   -> ícone de erro vermelho
//
// ============================================================

class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    required this.syncService,
    required this.connectivityService,
    this.compact = false,
  });

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final SyncService syncService;

  final ConnectivityService connectivityService;

  final bool compact;

  @override
  State<SyncStatusIndicator> createState() {
    return _SyncStatusIndicatorState();
  }
}

class _SyncStatusIndicatorState
    extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // TAMANHO
  // ============================================================

  static const double _size = 32;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF3B6939,
  );

  static const Color _greenLight = Color(
    0xFFBCF0B4,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _warning = Color(
    0xFF9A6700,
  );

  static const Color _warningSoft = Color(
    0xFFFFF4CC,
  );

  static const Color _error = Color(
    0xFFB3261E,
  );

  static const Color _errorSoft = Color(
    0xFFFFE9E7,
  );

  static const Color _offlineSoft = Color(
    0xFFF3F8EE,
  );

  // ============================================================
  // ANIMATION
  // ============================================================

  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    widget.syncService.addListener(
      _handleStateChanged,
    );

    widget.connectivityService.addListener(
      _handleStateChanged,
    );

    _syncAnimationState();
  }

  @override
  void didUpdateWidget(
    covariant SyncStatusIndicator oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.syncService !=
        widget.syncService) {
      oldWidget.syncService.removeListener(
        _handleStateChanged,
      );

      widget.syncService.addListener(
        _handleStateChanged,
      );
    }

    if (oldWidget.connectivityService !=
        widget.connectivityService) {
      oldWidget.connectivityService.removeListener(
        _handleStateChanged,
      );

      widget.connectivityService.addListener(
        _handleStateChanged,
      );
    }

    _syncAnimationState();
  }

  @override
  void dispose() {
    widget.syncService.removeListener(
      _handleStateChanged,
    );

    widget.connectivityService.removeListener(
      _handleStateChanged,
    );

    _rotationController.dispose();

    super.dispose();
  }

  void _handleStateChanged() {
    if (!mounted) {
      return;
    }

    _syncAnimationState();

    setState(
      () {},
    );
  }

  void _syncAnimationState() {
    final visual = _resolveVisual();

    if (visual.animate) {
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }

      return;
    }

    if (_rotationController.isAnimating) {
      _rotationController.stop();
    }

    _rotationController.value = 0;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final visual = _resolveVisual();

    return Semantics(
      label: visual.semanticLabel,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 220,
        ),
        curve: Curves.easeOutCubic,
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: visual.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: visual.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: visual.foreground.withValues(
                alpha: 0.07,
              ),
              blurRadius: 8,
              offset: const Offset(
                0,
                2,
              ),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 180,
            ),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (
              child,
              animation,
            ) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.88,
                    end: 1,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: visual.animate
                ? AnimatedBuilder(
                    key: ValueKey<String>(
                      visual.key,
                    ),
                    animation: _rotationController,
                    builder: (
                      context,
                      child,
                    ) {
                      return Transform.rotate(
                        angle:
                            _rotationController.value *
                            2 *
                            math.pi,
                        child: child,
                      );
                    },
                    child: Icon(
                      visual.icon,
                      size: 17,
                      color: visual.foreground,
                    ),
                  )
                : Icon(
                    key: ValueKey<String>(
                      visual.key,
                    ),
                    visual.icon,
                    size: 17,
                    color: visual.foreground,
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESOLVER VISUAL
  // ============================================================

  _SyncVisual _resolveVisual() {
    // ==========================================================
    // OFFLINE
    // ==========================================================

    if (widget.connectivityService.isOffline) {
      return const _SyncVisual(
        key: 'offline',
        icon: Icons.cloud_off_rounded,
        semanticLabel: 'Offline',
        foreground: _muted,
        background: _offlineSoft,
        border: _border,
      );
    }

    // ==========================================================
    // VERIFICANDO
    // ==========================================================

    if (widget.connectivityService.isChecking ||
        widget.syncService.state ==
            SyncServiceState.checking) {
      return const _SyncVisual(
        key: 'checking',
        icon: Icons.cloud_sync_rounded,
        semanticLabel: 'Verificando conexão e sincronização',
        foreground: _muted,
        background: _offlineSoft,
        border: _border,
        animate: true,
      );
    }

    // ==========================================================
    // SINCRONIZANDO
    // ==========================================================

    if (widget.syncService.isSyncing ||
        widget.syncService.state ==
            SyncServiceState.syncing) {
      return const _SyncVisual(
        key: 'syncing',
        icon: Icons.sync_rounded,
        semanticLabel: 'Sincronizando',
        foreground: _warning,
        background: _warningSoft,
        border: _warning,
        animate: true,
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (widget.syncService.hasError ||
        widget.syncService.state ==
            SyncServiceState.error) {
      return const _SyncVisual(
        key: 'error',
        icon: Icons.sync_problem_rounded,
        semanticLabel: 'Erro de sincronização',
        foreground: _error,
        background: _errorSoft,
        border: _error,
      );
    }

    // ==========================================================
    // ONLINE
    // ==========================================================

    return const _SyncVisual(
      key: 'online',
      icon: Icons.cloud_done_rounded,
      semanticLabel: 'Online',
      foreground: _green,
      background: _greenLight,
      border: _green,
    );
  }
}

// ============================================================
// VISUAL
// ============================================================

class _SyncVisual {
  const _SyncVisual({
    required this.key,
    required this.icon,
    required this.semanticLabel,
    required this.foreground,
    required this.background,
    required this.border,
    this.animate = false,
  });

  final String key;

  final IconData icon;

  final String semanticLabel;

  final Color foreground;

  final Color background;

  final Color border;

  final bool animate;
}
