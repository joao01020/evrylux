import 'package:flutter/material.dart';

import '../utils/finance_screen_formatter.dart';

Future<
  double?
>
showEditFinanceValueDialog({
  required BuildContext context,
  required String title,
  required String label,
  required double currentValue,
}) async {
  final controller = TextEditingController(
    text: currentValue.toStringAsFixed(
      2,
    ),
  );

  try {
    return await showDialog<
      double
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              title: Text(
                title,
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  prefixText: 'R\$ ',
                  border: const OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),

                FilledButton(
                  onPressed: () {
                    final value = FinanceScreenFormatter.parseMoney(
                      controller.text,
                    );

                    if (value <
                        0) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe um valor válido.',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      value,
                    );
                  },
                  child: const Text(
                    'Salvar',
                  ),
                ),
              ],
            );
          },
    );
  } finally {
    controller.dispose();
  }
}
