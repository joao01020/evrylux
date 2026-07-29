import 'package:flutter/material.dart';

import '../../utils/finance_screen_formatter.dart';

Future<
  double?
>
showContributionDialog({
  required BuildContext context,
}) async {
  final controller = TextEditingController();

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
              title: const Text(
                'Registrar aporte',
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Valor do aporte',
                  hintText: 'Ex.: 500,00',
                  prefixText: 'R\$ ',
                  prefixIcon: Icon(
                    Icons.savings_outlined,
                  ),
                  border: OutlineInputBorder(),
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

                FilledButton.icon(
                  onPressed: () {
                    final contribution = FinanceScreenFormatter.parseMoney(
                      controller.text,
                    );

                    if (contribution <=
                        0) {
                      ScaffoldMessenger.of(
                        dialogContext,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Informe um valor maior que zero.',
                          ),
                        ),
                      );

                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(
                      contribution,
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Registrar',
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
