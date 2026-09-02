import 'package:flutter/material.dart';

import '../controllers/update_notification_controller.dart';
import '../models/app_update_notification.dart';

class UpdateNotificationPanel
    extends
        StatelessWidget {
  const UpdateNotificationPanel({
    super.key,
    required this.controller,
    this.onOpenUpdate,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final UpdateNotificationController controller;

  // ============================================================
  // AÇÃO
  // ============================================================
  //
  // Depois podemos usar isso para:
  //
  // abrir GitHub Release
  // abrir site
  // abrir página "Sobre"
  // iniciar updater
  //
  // ============================================================

  final ValueChanged<
    AppUpdateNotification
  >?
  onOpenUpdate;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7FAF7,
  );

  static const Color _border = Color(
    0xFFD7E3D9,
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

  static const Color _danger = Color(
    0xFFB3261E,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (
            context,
            _,
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
                        0x1A000000,
                      ),
                      blurRadius: 24,
                      offset: Offset(
                        0,
                        10,
                      ),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(
                      context,
                    ),

                    const Divider(
                      height: 1,
                      color: _border,
                    ),

                    Flexible(
                      child: _buildContent(
                        context,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
        13,
        8,
        13,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _primarySoft,
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: _primary,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificações',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

          IconButton(
            tooltip: 'Atualizar',
            onPressed: controller.loading
                ? null
                : () {
                    controller.checkForUpdates();
                  },
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
                    color: _muted,
                    size: 19,
                  ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: () {
              Navigator.of(
                context,
              ).pop();
            },
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
              size: 19,
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
    if (controller.loading &&
        !controller.hasUpdate) {
      return const Padding(
        padding: EdgeInsets.all(
          34,
        ),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: _primary,
          ),
        ),
      );
    }

    if (controller.hasError &&
        !controller.hasUpdate) {
      return _buildError();
    }

    final notification = controller.notification;

    if (notification ==
        null) {
      return _buildEmpty();
    }

    return _buildUpdateCard(
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
        horizontal: 30,
        vertical: 40,
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
            'Nenhuma nova versão do aplicativo está disponível.',
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
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: _danger,
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
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          Text(
            controller.errorMessage ??
                'Tente novamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          TextButton.icon(
            onPressed: () {
              controller.checkForUpdates();
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 16,
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

  Widget _buildUpdateCard(
    BuildContext context,
    AppUpdateNotification notification,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: InkWell(
        onTap: () {
          controller.markAsRead();

          onOpenUpdate?.call(
            notification,
          );
        },
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: notification.isUnread
                ? _primarySoft
                : _surface,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: notification.isUnread
                  ? _primary.withValues(
                      alpha: .30,
                    )
                  : _border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: const Icon(
                      Icons.system_update_alt_rounded,
                      color: _primary,
                      size: 20,
                    ),
                  ),

                  if (notification.isUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title.trim().isEmpty
                          ? 'Nova atualização disponível'
                          : notification.title.trim(),
                      style: const TextStyle(
                        color: _text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      'Versão ${notification.version}',
                      style: const TextStyle(
                        color: _primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    if (notification.message.trim().isNotEmpty) ...[
                      const SizedBox(
                        height: 7,
                      ),

                      Text(
                        notification.message.trim(),
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 9,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
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

                        if (notification.hasDownloadUrl) ...[
                          const Spacer(),

                          const Text(
                            'Ver atualização',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            width: 3,
                          ),

                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: _primary,
                            size: 13,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    final year = brasilia.year.toString();

    return '$day/$month/$year';
  }
}
