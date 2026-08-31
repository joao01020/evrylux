import 'package:flutter/material.dart';

import '../connectivity_service.dart';
import '../sync_service.dart';

class SyncStatusIndicator
    extends
        StatelessWidget {
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

  // ============================================================
  // TAMANHO
  // ============================================================
  //
  // Todos os estados usam exatamente o mesmo tamanho.
  //
  // ============================================================

  static const double _normalWidth = 205;

  static const double _normalHeight = 32;

  static const double _compactSize = 32;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF3B6939,
  );

  static const Color _greenLight = Color(
    0xFFBCF0B4,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          syncService,
          connectivityService,
        ],
      ),
      builder:
          (
            context,
            _,
          ) {
            final visual = _resolveVisual();

            return Semantics(
              label: visual.tooltip,
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),

                // =================================================
                // TAMANHO FIXO
                // =================================================
                width: compact
                    ? _compactSize
                    : _normalWidth,

                height: compact
                    ? _compactSize
                    : _normalHeight,

                padding: EdgeInsets.symmetric(
                  horizontal: compact
                      ? 7
                      : 10,
                ),

                decoration: BoxDecoration(
                  color: visual.background,
                  borderRadius: BorderRadius.circular(
                    999,
                  ),
                  border: Border.all(
                    color: visual.border,
                  ),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // =============================================
                    // ÍCONE / LOADING
                    // =============================================
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: visual.showProgress
                          ? CircularProgressIndicator(
                              strokeWidth: 2,
                              color: visual.foreground,
                            )
                          : Icon(
                              visual.icon,
                              size: 15,
                              color: visual.foreground,
                            ),
                    ),

                    // =============================================
                    // TEXTO
                    // =============================================
                    if (!compact) ...[
                      const SizedBox(
                        width: 7,
                      ),

                      Expanded(
                        child: Text(
                          visual.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: visual.foreground,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],

                    // =============================================
                    // CONTADOR
                    // =============================================
                    if (!compact &&
                        syncService.pendingCount >
                            0) ...[
                      const SizedBox(
                        width: 6,
                      ),

                      Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color: visual.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${syncService.pendingCount}',
                          style: TextStyle(
                            color: visual.foreground,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // RESOLVER VISUAL
  // ============================================================

  _SyncVisual _resolveVisual() {
    // ==========================================================
    // OFFLINE
    // ==========================================================

    if (connectivityService.isOffline) {
      final pending = syncService.pendingCount;

      return _SyncVisual(
        icon: Icons.cloud_off_rounded,
        label:
            pending >
                0
            ? 'Offline • salvo localmente'
            : 'Offline',
        tooltip:
            pending >
                0
            ? '$pending alteração'
                  '${pending == 1 ? '' : 'ões'} '
                  'salva${pending == 1 ? '' : 's'} '
                  'neste dispositivo.'
            : 'Sem conexão com a internet.',
        foreground: _muted,
        background: _offlineSoft,
        border: _border,
      );
    }

    // ==========================================================
    // VERIFICANDO
    // ==========================================================

    if (connectivityService.isChecking ||
        syncService.state ==
            SyncServiceState.checking) {
      return const _SyncVisual(
        icon: Icons.cloud_sync_rounded,
        label: 'Verificando...',
        tooltip: 'Verificando conexão e sincronização.',
        foreground: _muted,
        background: _offlineSoft,
        border: _border,
        showProgress: true,
      );
    }

    // ==========================================================
    // SINCRONIZANDO
    // ==========================================================

    if (syncService.isSyncing ||
        syncService.state ==
            SyncServiceState.syncing) {
      final pending = syncService.pendingCount;

      return _SyncVisual(
        icon: Icons.sync_rounded,
        label:
            pending >
                0
            ? 'Sincronizando'
            : 'Sincronizando...',
        tooltip: 'Enviando alterações locais para o servidor.',
        foreground: _warning,
        background: _warningSoft,
        border: _warning,
        showProgress: true,
      );
    }

    // ==========================================================
    // ERRO
    // ==========================================================

    if (syncService.hasError ||
        syncService.state ==
            SyncServiceState.error) {
      return _SyncVisual(
        icon: Icons.sync_problem_rounded,
        label: 'Erro ao sincronizar',
        tooltip:
            syncService.lastError ??
            'Ocorreu um erro durante a sincronização.',
        foreground: _error,
        background: _errorSoft,
        border: _error,
      );
    }

    // ==========================================================
    // PENDENTE
    // ==========================================================

    if (syncService.pendingCount >
        0) {
      final pending = syncService.pendingCount;

      return _SyncVisual(
        icon: Icons.cloud_upload_outlined,
        label:
            pending ==
                1
            ? 'Pendente'
            : 'Pendentes',
        tooltip: 'Online. Existem alterações aguardando sincronização.',
        foreground: _warning,
        background: _warningSoft,
        border: _warning,
      );
    }

    // ==========================================================
    // SINCRONIZADO
    // ==========================================================

    return const _SyncVisual(
      icon: Icons.cloud_done_rounded,
      label: 'Online • sincronizado',
      tooltip: 'Conectado e com todos os dados sincronizados.',
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
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.foreground,
    required this.background,
    required this.border,
    this.showProgress = false,
  });

  final IconData icon;

  final String label;

  final String tooltip;

  final Color foreground;

  final Color background;

  final Color border;

  final bool showProgress;
}
