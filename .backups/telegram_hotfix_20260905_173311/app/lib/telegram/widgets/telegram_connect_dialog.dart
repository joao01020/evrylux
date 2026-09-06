import 'dart:async';

import 'package:flutter/material.dart';

import '../controllers/telegram_connection_controller.dart';

class TelegramConnectDialog extends StatefulWidget {
  const TelegramConnectDialog({
    super.key,
    required this.controller,
  });

  final TelegramConnectionController controller;

  static Future<bool?> show(
    BuildContext context, {
    required TelegramConnectionController controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return TelegramConnectDialog(
          controller: controller,
        );
      },
    );
  }

  @override
  State<TelegramConnectDialog> createState() => _TelegramConnectDialogState();
}

class _TelegramConnectDialogState extends State<TelegramConnectDialog> {
  static const Color _background = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFFF7FBF1);
  static const Color _border = Color(0xFFC7DFC9);
  static const Color _primary = Color(0xFFBCF0B4);
  static const Color _primaryDark = Color(0xFF3B6939);
  static const Color _text = Color(0xFF172019);
  static const Color _muted = Color(0xFF68746B);
  static const Color _danger = Color(0xFFB3261E);

  bool _waiting = false;
  String? _localMessage;

  @override
  void dispose() {
    widget.controller.cancelWaiting();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_waiting || widget.controller.connecting) {
      return;
    }

    setState(() {
      _localMessage = null;
    });

    final opened = await widget.controller.beginConnection();

    if (!mounted || !opened) {
      setState(() {});
      return;
    }

    setState(() {
      _waiting = true;
      _localMessage = 'Telegram aberto. Toque em Iniciar para concluir a conexão.';
    });

    final connected = await widget.controller.waitForConnection();

    if (!mounted) {
      return;
    }

    if (connected) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _waiting = false;
      _localMessage = 'Ainda não encontramos a conexão. Você pode verificar novamente.';
    });
  }

  Future<void> _verify() async {
    if (_waiting) {
      return;
    }

    setState(() {
      _waiting = true;
      _localMessage = null;
    });

    final connected = await widget.controller.refreshConnection();

    if (!mounted) {
      return;
    }

    if (connected) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _waiting = false;
      _localMessage = 'Telegram ainda não conectado. Abra o bot e toque em Iniciar.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final busy = _waiting || widget.controller.connecting;
        final error = widget.controller.errorMessage;

        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 440,
            ),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _primary,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Conecte seu Telegram',
                              style: TextStyle(
                                color: _text,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Você só precisa fazer isso uma vez.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Para receber este lembrete no Telegram, conecte sua conta ao EVRYLUX.',
                    style: TextStyle(
                      color: _text,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ao clicar em Conectar Telegram, o bot será aberto. Toque em Iniciar e o EVRYLUX identificará sua conta automaticamente.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                  if (_localMessage != null || error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: error != null
                            ? _danger.withValues(alpha: 0.06)
                            : _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: error != null
                              ? _danger.withValues(alpha: 0.22)
                              : _border,
                        ),
                      ),
                      child: Text(
                        error ?? _localMessage!,
                        style: TextStyle(
                          color: error != null ? _danger : _muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: busy
                            ? null
                            : () {
                                Navigator.of(context).pop(false);
                              },
                        child: const Text('Agora não'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: busy ? null : _verify,
                        child: const Text('Já conectei'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: busy ? null : _connect,
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 17),
                        label: Text(
                          busy ? 'Aguardando...' : 'Conectar Telegram',
                        ),
                      ),
                    ],
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
