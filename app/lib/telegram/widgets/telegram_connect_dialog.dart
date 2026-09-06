import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/telegram_connection_controller.dart';

class TelegramConnectDialog
    extends
        StatefulWidget {
  const TelegramConnectDialog({
    super.key,
    required this.controller,
  });

  final TelegramConnectionController controller;

  static Future<
    bool?
  >
  show(
    BuildContext context, {
    required TelegramConnectionController controller,
  }) {
    return showDialog<
      bool
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            _,
          ) {
            return TelegramConnectDialog(
              controller: controller,
            );
          },
    );
  }

  @override
  State<
    TelegramConnectDialog
  >
  createState() => _TelegramConnectDialogState();
}

class _TelegramConnectDialogState
    extends
        State<
          TelegramConnectDialog
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7F9F8,
  );

  static const Color _surfaceGreen = Color(
    0xFFF4FAF1,
  );

  static const Color _border = Color(
    0xFFE3E9E5,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primarySoft = Color(
    0xFFEAF8E7,
  );

  static const Color _primaryDark = Color(
    0xFF345B32,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _mutedLight = Color(
    0xFF98A29A,
  );

  static const Color _danger = Color(
    0xFFB3261E,
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _waiting = false;

  bool _checkingManually = false;

  String? _localMessage;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    widget.controller.cancelWaiting();

    super.dispose();
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _close() {
    widget.controller.cancelWaiting();

    Navigator.of(
      context,
    ).pop(
      false,
    );
  }

  // ============================================================
  // CONNECT
  // ============================================================

  Future<
    void
  >
  _connect() async {
    if (_waiting ||
        _checkingManually ||
        widget.controller.connecting) {
      return;
    }

    setState(
      () {
        _localMessage = null;
      },
    );

    final opened = await widget.controller.beginConnection();

    if (!mounted) {
      return;
    }

    if (!opened) {
      setState(
        () {},
      );

      return;
    }

    setState(
      () {
        _waiting = true;

        _localMessage = 'Telegram aberto. Agora toque em Iniciar para concluir.';
      },
    );

    // ==========================================================
    // AUTO WAIT
    // ==========================================================
    //
    // Não deixamos o usuário preso por vários minutos.
    //
    // Durante esses 30 segundos:
    //
    // - o EVRYLUX verifica silenciosamente;
    // - "Agora não" continua disponível;
    // - "Já conectei" continua disponível;
    //
    // ==========================================================

    final connected = await widget.controller.waitForConnection(
      timeout: const Duration(
        seconds: 30,
      ),
      interval: const Duration(
        seconds: 2,
      ),
    );

    if (!mounted) {
      return;
    }

    if (connected) {
      Navigator.of(
        context,
      ).pop(
        true,
      );

      return;
    }

    setState(
      () {
        _waiting = false;

        _localMessage =
            'Ainda não encontramos a conexão. '
            'Se você já tocou em Iniciar no Telegram, '
            'clique em Já conectei.';
      },
    );
  }

  // ============================================================
  // VERIFY
  // ============================================================

  Future<
    void
  >
  _verify() async {
    if (_checkingManually ||
        widget.controller.connecting) {
      return;
    }

    setState(
      () {
        _checkingManually = true;
        _localMessage = null;
      },
    );

    try {
      final connected = await widget.controller.refreshConnection();

      if (!mounted) {
        return;
      }

      if (connected) {
        widget.controller.cancelWaiting();

        Navigator.of(
          context,
        ).pop(
          true,
        );

        return;
      }

      setState(
        () {
          _localMessage =
              'Telegram ainda não conectado. '
              'Abra o bot e toque em Iniciar.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _checkingManually = false;
          },
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: widget.controller,

      builder:
          (
            context,
            _,
          ) {
            // ======================================================
            // INDEPENDENT STATES
            // ======================================================

            final opening = widget.controller.connecting;

            final waiting = _waiting;

            final checking = _checkingManually;

            final showingProgress =
                opening ||
                waiting ||
                checking;

            final error = widget.controller.errorMessage;

            return Dialog(
              backgroundColor: Colors.transparent,

              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),

              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 470,
                ),

                child: Container(
                  decoration: BoxDecoration(
                    color: _background,

                    borderRadius: BorderRadius.circular(
                      24,
                    ),

                    border: Border.all(
                      color: _border,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.06,
                        ),
                        blurRadius: 40,
                        offset: const Offset(
                          0,
                          16,
                        ),
                      ),
                    ],
                  ),

                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      24,
                    ),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        // ==================================================
                        // HEADER
                        // ==================================================
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.fromLTRB(
                            24,
                            24,
                            24,
                            20,
                          ),

                          decoration: const BoxDecoration(
                            color: _surfaceGreen,
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Container(
                                width: 52,
                                height: 52,

                                decoration: BoxDecoration(
                                  color: _primary,

                                  borderRadius: BorderRadius.circular(
                                    16,
                                  ),
                                ),

                                child: const Icon(
                                  Icons.send_rounded,
                                  color: _primaryDark,
                                  size: 24,
                                ),
                              ),

                              const SizedBox(
                                width: 14,
                              ),

                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      'Conecte seu Telegram',
                                      style: TextStyle(
                                        color: _text,
                                        fontSize: 20,
                                        height: 1.15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),

                                    SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      'Conecte uma vez e receba seus lembretes diretamente no Telegram.',
                                      style: TextStyle(
                                        color: _muted,
                                        fontSize: 12,
                                        height: 1.45,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ==================================================
                        // BODY
                        // ==================================================
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            24,
                            22,
                            24,
                            24,
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              const Text(
                                'Como funciona',
                                style: TextStyle(
                                  color: _text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              const _TelegramStep(
                                number: '1',
                                title: 'Abrimos o bot',
                                description: 'O Telegram será aberto no seu navegador.',
                                icon: Icons.open_in_new_rounded,
                              ),

                              const _TelegramStepDivider(),

                              const _TelegramStep(
                                number: '2',
                                title: 'Toque em Iniciar',
                                description: 'Isso permite identificar sua conta de forma segura.',
                                icon: Icons.touch_app_rounded,
                              ),

                              const _TelegramStepDivider(),

                              const _TelegramStep(
                                number: '3',
                                title: 'Pronto',
                                description: 'O EVRYLUX detecta a conexão automaticamente.',
                                icon: Icons.check_rounded,
                              ),

                              // ================================================
                              // STATUS
                              // ================================================
                              if (_localMessage !=
                                      null ||
                                  error !=
                                      null ||
                                  showingProgress) ...[
                                const SizedBox(
                                  height: 20,
                                ),

                                AnimatedContainer(
                                  duration: const Duration(
                                    milliseconds: 220,
                                  ),

                                  width: double.infinity,

                                  padding: const EdgeInsets.all(
                                    14,
                                  ),

                                  decoration: BoxDecoration(
                                    color:
                                        error !=
                                            null
                                        ? _danger.withValues(
                                            alpha: 0.055,
                                          )
                                        : _surface,

                                    borderRadius: BorderRadius.circular(
                                      14,
                                    ),

                                    border: Border.all(
                                      color:
                                          error !=
                                              null
                                          ? _danger.withValues(
                                              alpha: 0.18,
                                            )
                                          : _border,
                                    ),
                                  ),

                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,

                                        decoration: BoxDecoration(
                                          color:
                                              error !=
                                                  null
                                              ? _danger.withValues(
                                                  alpha: 0.08,
                                                )
                                              : _primarySoft,

                                          shape: BoxShape.circle,
                                        ),

                                        child: Center(
                                          child:
                                              error !=
                                                  null
                                              ? const Icon(
                                                  Icons.error_outline_rounded,
                                                  size: 16,
                                                  color: _danger,
                                                )
                                              : showingProgress
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: _primaryDark,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.info_outline_rounded,
                                                  size: 16,
                                                  color: _primaryDark,
                                                ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 10,
                                      ),

                                      Expanded(
                                        child: Text(
                                          error ??
                                              _localMessage ??
                                              _progressMessage(
                                                opening: opening,
                                                waiting: waiting,
                                                checking: checking,
                                              ),

                                          style: TextStyle(
                                            color:
                                                error !=
                                                    null
                                                ? _danger
                                                : _muted,

                                            fontSize: 11.5,

                                            height: 1.45,

                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(
                                height: 22,
                              ),

                              // ================================================
                              // ACTIONS
                              // ================================================
                              Row(
                                children: [
                                  // ============================================
                                  // CLOSE
                                  // ============================================
                                  //
                                  // Importante:
                                  //
                                  // nunca fica bloqueado enquanto aguardamos o
                                  // Telegram.
                                  //
                                  // ============================================
                                  TextButton(
                                    onPressed: _close,

                                    style: TextButton.styleFrom(
                                      foregroundColor: _muted,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 13,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                    ),

                                    child: const Text(
                                      'Agora não',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // ============================================
                                  // MANUAL VERIFY
                                  // ============================================
                                  //
                                  // Pode ser usado mesmo enquanto o polling
                                  // automático estiver ativo.
                                  //
                                  // ============================================
                                  OutlinedButton.icon(
                                    onPressed:
                                        opening ||
                                            checking
                                        ? null
                                        : _verify,

                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: _text,

                                      side: const BorderSide(
                                        color: _border,
                                      ),

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          13,
                                        ),
                                      ),
                                    ),

                                    icon: checking
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _primaryDark,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.refresh_rounded,
                                            size: 16,
                                          ),

                                    label: Text(
                                      checking
                                          ? 'Verificando...'
                                          : 'Já conectei',

                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  // ============================================
                                  // OPEN TELEGRAM
                                  // ============================================
                                  FilledButton.icon(
                                    onPressed:
                                        opening ||
                                            waiting ||
                                            checking
                                        ? null
                                        : _connect,

                                    style: FilledButton.styleFrom(
                                      backgroundColor: _primary,

                                      foregroundColor: _primaryDark,

                                      disabledBackgroundColor: _surface,

                                      disabledForegroundColor: _mutedLight,

                                      elevation: 0,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 14,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          13,
                                        ),
                                      ),
                                    ),

                                    icon:
                                        opening ||
                                            waiting
                                        ? const SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: _primaryDark,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 16,
                                          ),

                                    label: Text(
                                      opening
                                          ? 'Abrindo...'
                                          : waiting
                                          ? 'Aguardando...'
                                          : 'Abrir Telegram',

                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // PROGRESS MESSAGE
  // ============================================================

  String _progressMessage({
    required bool opening,
    required bool waiting,
    required bool checking,
  }) {
    if (opening) {
      return 'Abrindo Telegram no navegador...';
    }

    if (checking) {
      return 'Verificando sua conexão com o Telegram...';
    }

    if (waiting) {
      return 'Aguardando você tocar em Iniciar no Telegram...';
    }

    return 'Aguardando conexão com o Telegram...';
  }
}

// ============================================================
// STEP
// ============================================================

class _TelegramStep
    extends
        StatelessWidget {
  const _TelegramStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String number;

  final String title;

  final String description;

  final IconData icon;

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF345B32,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Stack(
          alignment: Alignment.center,

          children: [
            Container(
              width: 38,
              height: 38,

              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
            ),

            Icon(
              icon,
              size: 17,
              color: _primaryDark,
            ),
          ],
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 1,
            ),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),

                      decoration: BoxDecoration(
                        color: _primary.withValues(
                          alpha: 0.45,
                        ),

                        borderRadius: BorderRadius.circular(
                          5,
                        ),
                      ),

                      child: Text(
                        number,
                        style: const TextStyle(
                          color: _primaryDark,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// STEP DIVIDER
// ============================================================

class _TelegramStepDivider
    extends
        StatelessWidget {
  const _TelegramStepDivider();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Padding(
      padding: EdgeInsets.only(
        left: 18,
      ),

      child: SizedBox(
        height: 14,

        child: VerticalDivider(
          width: 1,
          thickness: 1,
          color: Color(
            0xFFE3E9E5,
          ),
        ),
      ),
    );
  }
}
