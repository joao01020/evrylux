import 'package:flutter/material.dart';

import '../../../models/finance/crypto_transaction_model.dart';

class AddCryptoDialog
    extends
        StatefulWidget {
  final String symbol;

  final Future<
    void
  >
  Function(
    CryptoTransactionModel transaction,
  )
  onSave;

  const AddCryptoDialog({
    super.key,
    required this.symbol,
    required this.onSave,
  });

  @override
  State<
    AddCryptoDialog
  >
  createState() => _AddCryptoDialogState();
}

class _AddCryptoDialogState
    extends
        State<
          AddCryptoDialog
        > {
  final quantityController = TextEditingController();

  final investedController = TextEditingController();

  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    quantityController.dispose();
    investedController.dispose();
    super.dispose();
  }

  Future<
    void
  >
  chooseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(
        2009,
      ),
      lastDate: DateTime.now(),
    );

    if (picked !=
        null) {
      setState(
        () {
          selectedDate = picked;
        },
      );
    }
  }

  Future<
    void
  >
  save() async {
    final quantity =
        double.tryParse(
          quantityController.text.replaceAll(
            ",",
            ".",
          ),
        ) ??
        0;

    final invested =
        double.tryParse(
          investedController.text.replaceAll(
            ",",
            ".",
          ),
        ) ??
        0;

    if (quantity <=
            0 ||
        invested <=
            0) {
      return;
    }

    final transaction = CryptoTransactionModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      symbol: widget.symbol,
      quantity: quantity,
      invested: invested,
      date: selectedDate,
    );

    await widget.onSave(
      transaction,
    );

    if (!mounted) return;

    Navigator.pop(
      context,
    );
  }

  String formatDate(
    DateTime date,
  ) {
    String
    two(
      int value,
    ) => value.toString().padLeft(
      2,
      "0",
    );

    return "${two(date.day)}/${two(date.month)}/${date.year}";
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      title: Text(
        "Adicionar ${widget.symbol}",
      ),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: chooseDate,
              borderRadius: BorderRadius.circular(
                10,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Text(
                  formatDate(
                    selectedDate,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "Quantidade (${widget.symbol})",
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            TextField(
              controller: investedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Valor investido (R\$)",
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
          child: const Text(
            "Cancelar",
          ),
        ),

        ElevatedButton.icon(
          onPressed: save,
          icon: const Icon(
            Icons.add,
          ),
          label: const Text(
            "Adicionar",
          ),
        ),
      ],
    );
  }
}
