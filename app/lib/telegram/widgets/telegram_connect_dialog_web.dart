import 'package:flutter/material.dart';

class TelegramConnectDialog extends StatelessWidget {
  const TelegramConnectDialog({super.key, required this.controller});

  /// No Web recebemos o controller compatível do runtime Web.
  ///
  /// Usamos dynamic propositalmente aqui porque o controller nativo
  /// TelegramConnectionController não deve entrar no bundle do navegador.
  final dynamic controller;

  static Future<bool?> show(
    BuildContext context, {
    required dynamic controller,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return TelegramConnectDialog(controller: controller);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: <Widget>[
          Icon(Icons.telegram),
          SizedBox(width: 10),
          Text('Telegram'),
        ],
      ),
      content: const SizedBox(
        width: 460,
        child: Text(
          'A conexão do Telegram está disponível no aplicativo desktop. '
          'No navegador, seus lembretes continuam funcionando normalmente '
          'dentro do EVRYLUX.',
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text('Entendi'),
        ),
      ],
    );
  }
}
