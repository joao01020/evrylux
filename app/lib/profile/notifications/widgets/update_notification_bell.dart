import 'package:flutter/material.dart';

import '../controllers/update_notification_controller.dart';

class UpdateNotificationBell
    extends
        StatelessWidget {
  const UpdateNotificationBell({
    super.key,
    required this.controller,
    required this.onTap,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final UpdateNotificationController controller;

  // ============================================================
  // AÇÃO
  // ============================================================
  //
  // O widget NÃO abre o painel diretamente.
  //
  // Isso é proposital porque ele é exibido na barra global criada
  // pelo MaterialApp.builder, acima do Navigator.
  //
  // O GhostApp recebe o clique e usa o Navigator global para abrir
  // o painel corretamente.
  //
  // ============================================================

  final VoidCallback onTap;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _primary = Color(
    0xFF198754,
  );

  static const Color _muted = Color(
    0xFF68746B,
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
            final unread = controller.hasUnread;

            return Semantics(
              button: true,
              label: unread
                  ? 'Nova atualização disponível'
                  : 'Notificações',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: Icon(
                          unread
                              ? Icons.notifications_active_outlined
                              : Icons.notifications_none_rounded,
                          color: unread
                              ? _primary
                              : _muted,
                          size: 21,
                        ),
                      ),

                      // ==========================================
                      // INDICADOR NÃO LIDO
                      // ==========================================
                      if (unread)
                        Positioned(
                          right: 3,
                          top: 3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: _primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }
}
