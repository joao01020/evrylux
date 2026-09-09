import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';
import '../../../core/updater/update_download_coordinator.dart';
import '../../../core/updater/update_download_service.dart';
import '../../../core/updater/update_installation_service.dart';

typedef UpdateInstallAction =
    Future<void> Function(UpdateDownloadCoordinator coordinator);

typedef UpdateManagedCheck = Future<bool> Function(String version);

/// One guided flow: confirm, download, verify, hand off and restart.
/// The existing signed-manifest and independent-helper checks remain authoritative.
class UpdateDownloadDialog extends StatefulWidget {
  const UpdateDownloadDialog({
    super.key,
    required this.coordinator,
    required this.version,
    this.installAction,
    this.managedCheck,
  });

  final UpdateDownloadCoordinator coordinator;
  final String version;
  final UpdateInstallAction? installAction;
  final UpdateManagedCheck? managedCheck;

  static Future<void> show(
    BuildContext context, {
    required UpdateDownloadCoordinator coordinator,
    required String version,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          UpdateDownloadDialog(coordinator: coordinator, version: version),
    );
  }

  @override
  State<UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<UpdateDownloadDialog> {
  bool _running = false;
  bool _installing = false;
  bool _cancelRequested = false;
  bool _started = false;
  String? _error;

  Future<bool> _checkManaged() =>
      (widget.managedCheck ?? UpdateInstallationService.isManagedInstallation)(
        widget.coordinator.currentVersion,
      );

  Future<void> _install(UpdateDownloadCoordinator coordinator) async {
    final action = widget.installAction;
    if (action != null) {
      await action(coordinator);
      return;
    }
    await UpdateInstallationService.installReady(
      coordinator: coordinator,
      beforeExit: () async {
        await syncService.stop();
        await appDatabase.close();
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Confirmation is shown once when the notification opens this dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_start());
    });
  }

  Future<void> _start() async {
    if (_running || _installing || widget.coordinator.busy) return;
    if (_started &&
        widget.coordinator.phase == UpdateDownloadPhase.ready &&
        widget.coordinator.ready?.version == widget.version) {
      // Retry an installation without downloading the same verified package.
      await _installReady();
      return;
    }

    setState(() {
      _running = true;
      _cancelRequested = false;
      _error = null;
    });

    try {
      if (!await _checkManaged()) {
        throw StateError(
          'Instalação gerenciada necessária. Execute uma release instalada '
          'pelo atualizador; flutter run não pode substituir o próprio app.',
        );
      }
      if (!mounted || _cancelRequested) return;

      // The user agrees before any download or application shutdown.
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Atualizar o EVRYLUX?'),
          content: const Text(
            'Salve seu trabalho antes de continuar. O pacote será baixado '
            'e verificado; depois o instalador fechará o EVRYLUX, preservará '
            'a versão anterior e abrirá a nova. Atualizações que mudam o '
            'esquema do banco continuam bloqueadas nesta etapa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Agora não'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Baixar, instalar e reiniciar'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted || _cancelRequested) return;

      _started = true;
      await widget.coordinator.start(notificationVersion: widget.version);
      if (!mounted ||
          _cancelRequested ||
          widget.coordinator.phase != UpdateDownloadPhase.ready ||
          widget.coordinator.ready?.version != widget.version) {
        return;
      }
      await _installReady();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _installReady() async {
    if (_installing || _cancelRequested) return;
    if (widget.coordinator.phase != UpdateDownloadPhase.ready ||
        widget.coordinator.ready?.version != widget.version) {
      return;
    }
    setState(() {
      _installing = true;
      _error = null;
    });
    try {
      // installReady revalidates the signed envelope, SHA-256 and schema.
      // Only the installed helper performs the actual handoff.
      await _install(widget.coordinator);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  void _cancel() {
    _cancelRequested = true;
    widget.coordinator.cancel();
  }

  String _bytes(int value) {
    if (value < 1024) return '$value B';
    if (value < 1024 * 1024) {
      return '${(value / 1024).toStringAsFixed(1)} KB';
    }
    return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.coordinator,
      builder: (context, _) {
        final coordinator = widget.coordinator;
        final progress = coordinator.progress;
        final busy = coordinator.busy;
        final phase = coordinator.phase;
        final ready = coordinator.ready;
        final locked = _running || _installing || busy;
        final matchingReady =
            phase == UpdateDownloadPhase.ready &&
            ready != null &&
            ready.version == widget.version;
        final visibleProgress = busy || matchingReady || _installing;

        return PopScope(
          canPop: !locked,
          child: AlertDialog(
            title: const Text('Atualização do EVRYLUX'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Versão ${widget.version}'),
                  const SizedBox(height: 12),
                  if (visibleProgress) ...[
                    LinearProgressIndicator(
                      value: matchingReady || _installing
                          ? 1
                          : progress.total == 0
                          ? null
                          : progress.fraction.clamp(0.0, 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_bytes(progress.received)} / ${_bytes(progress.total)}'
                      '${progress.total > 0 ? ' • ${(progress.fraction * 100).toStringAsFixed(0)}%' : ''}',
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _installing
                        ? 'Preparando o instalador...'
                        : coordinator.message ??
                              'O pacote será baixado e verificado antes da instalação.',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (!locked &&
                      phase == UpdateDownloadPhase.failed &&
                      _error == null) ...[
                    const SizedBox(height: 12),
                    const Text('A atualização não foi concluída.'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: locked ? null : () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
              if (busy && !_installing)
                TextButton(
                  onPressed: _cancelRequested ? null : _cancel,
                  child: Text(
                    _cancelRequested ? 'Cancelando...' : 'Cancelar download',
                  ),
                )
              else if (!locked)
                FilledButton(
                  onPressed: matchingReady ? _installReady : _start,
                  child: Text(
                    matchingReady
                        ? 'Instalar e reiniciar'
                        : _started
                        ? 'Tentar novamente'
                        : 'Atualizar',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
