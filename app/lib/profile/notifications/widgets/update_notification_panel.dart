import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/update_notification_controller.dart';
import '../models/app_update_notification.dart';

class UpdateNotificationPanel
    extends
        StatelessWidget {
  const UpdateNotificationPanel({
    super.key,
    required this.controller,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final UpdateNotificationController controller;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFF198754,
  );

  static const Color _primarySoft = Color(
    0xFFE8F5EC,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _error = Color(
    0xFFB3261E,
  );

  // ============================================================
  // OPEN DOWNLOAD
  // ============================================================

  Future<
    void
  >
  _openDownload(
    BuildContext context,
    AppUpdateNotification notification,
  ) async {
    final rawUrl = notification.downloadUrl?.trim();

    // ==========================================================
    // SEM URL
    // ==========================================================

    if (rawUrl ==
            null ||
        rawUrl.isEmpty) {
      _showMessage(
        context,
        'Esta atualização ainda não possui um link de download.',
      );

      return;
    }

    // ==========================================================
    // PARSE
    // ==========================================================

    final uri = Uri.tryParse(
      rawUrl,
    );

    if (uri ==
            null ||
        !uri.hasScheme) {
      _showMessage(
        context,
        'O link desta atualização é inválido.',
      );

      return;
    }

    // ==========================================================
    // OPEN EXTERNAL
    // ==========================================================
    //
    // Abre no navegador padrão do sistema.
    //
    // Exemplo:
    //
    // https://updates.evrylux.com/evrylux-1.1.0-linux.tar.gz
    //
    // ou:
    //
    // https://pub-xxxxx.r2.dev/evrylux-1.1.0-linux.tar.gz
    //
    // ==========================================================

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        if (!context.mounted) {
          return;
        }

        _showMessage(
          context,
          'Não foi possível abrir o download.',
        );
      }
    } catch (
      error
    ) {
      debugPrint(
        '[APP UPDATE] '
        'Erro ao abrir download: $error',
      );

      if (!context.mounted) {
        return;
      }

      _showMessage(
        context,
        'Não foi possível abrir o link da atualização.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    BuildContext context,
    String message,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(
      context,
    );

    if (messenger ==
        null) {
      debugPrint(
        '[APP UPDATE] $message',
      );

      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            message,
          ),
        ),
      );
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(
    DateTime value,
  ) {
    // ==========================================================
    // BRASÍLIA
    // ==========================================================
    //
    // Datas internas permanecem UTC.
    //
    // Para exibição:
    //
    // UTC - 3
    //
    // ==========================================================

    final brasilia = value.toUtc().subtract(
      const Duration(
        hours: 3,
      ),
    );

    final day = brasilia.day.toString().padLeft(
      2,
      '0',
    );

    final month = brasilia.month.toString().padLeft(
      2,
      '0',
    );

    final hour = brasilia.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = brasilia.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${brasilia.year} • $hour:$minute';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 390,
        constraints: const BoxConstraints(
          maxHeight: 480,
        ),
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color: _border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x1F000000,
              ),
              blurRadius: 30,
              offset: Offset(
                0,
                10,
              ),
            ),
          ],
        ),
        child: AnimatedBuilder(
          animation: controller,
          builder:
              (
                context,
                _,
              ) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==========================================
                    // HEADER
                    // ==========================================
                    _buildHeader(
                      context,
                    ),

                    const Divider(
                      height: 1,
                      color: _border,
                    ),

                    // ==========================================
                    // CONTENT
                    // ==========================================
                    Flexible(
                      child: _buildContent(
                        context,
                      ),
                    ),
                  ],
                );
              },
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        10,
        14,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                SizedBox(
                  height: 2,
                ),

                Text(
                  'Atualizações do aplicativo',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // REFRESH
          // ==========================================
          IconButton(
            tooltip: 'Verificar atualizações',
            onPressed: controller.loading
                ? null
                : controller.checkForUpdates,
            icon: controller.loading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primary,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 20,
                  ),
          ),

          // ==========================================
          // CLOSE
          // ==========================================
          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (controller.loading &&
        controller.notification ==
            null) {
      return const Padding(
        padding: EdgeInsets.all(
          36,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (controller.hasError) {
      return _buildError();
    }

    // ==========================================================
    // EMPTY
    // ==========================================================

    final notification = controller.notification;

    if (notification ==
        null) {
      return _buildEmpty();
    }

    // ==========================================================
    // UPDATE
    // ==========================================================

    return _buildUpdate(
      context,
      notification,
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 34,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: _primary,
            size: 34,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Tudo atualizado',
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          SizedBox(
            height: 5,
          ),

          Text(
            'Nenhuma nova versão está disponível.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(
        24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _error,
            size: 32,
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Não foi possível verificar atualizações.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),

          if (controller.errorMessage !=
              null) ...[
            const SizedBox(
              height: 6,
            ),

            Text(
              controller.errorMessage ??
                  '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _muted,
                fontSize: 10,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(
            height: 12,
          ),

          TextButton.icon(
            onPressed: controller.checkForUpdates,
            icon: const Icon(
              Icons.refresh_rounded,
              size: 17,
            ),
            label: const Text(
              'Tentar novamente',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // UPDATE CARD
  // ============================================================

  Widget _buildUpdate(
    BuildContext context,
    AppUpdateNotification notification,
  ) {
    final hasDownload =
        notification.downloadUrl?.trim().isNotEmpty ==
        true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(
          15,
        ),
        decoration: BoxDecoration(
          color: _surfaceSoft,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: _border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==========================================
            // VERSION
            // ==========================================
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primarySoft,
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Text(
                    'v${notification.version}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),

                const Spacer(),

                if (notification.isUnread)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            // ==========================================
            // TITLE
            // ==========================================
            Text(
              notification.title,
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            // ==========================================
            // MESSAGE
            // ==========================================
            Text(
              notification.message,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            // ==========================================
            // DATE
            // ==========================================
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: _muted,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  _formatDate(
                    notification.publishedAt,
                  ),
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // ==========================================
            // DOWNLOAD
            // ==========================================
            if (hasDownload) ...[
              const SizedBox(
                height: 16,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _openDownload(
                      context,
                      notification,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.download_rounded,
                    size: 18,
                  ),
                  label: const Text(
                    'Baixar atualização',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
