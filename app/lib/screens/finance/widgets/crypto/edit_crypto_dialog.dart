import 'package:flutter/material.dart';

import '../../../../models/finance/crypto_transaction_model.dart';

class EditCryptoDialog extends StatefulWidget {
  final CryptoTransactionModel transaction;

  final Future<void> Function(CryptoTransactionModel transaction) onSave;

  const EditCryptoDialog({
    super.key,

    required this.transaction,

    required this.onSave,
  });

  @override
  State<EditCryptoDialog> createState() => _EditCryptoDialogState();
}

class _EditCryptoDialogState extends State<EditCryptoDialog> {
  late TextEditingController quantityController;

  late TextEditingController investedController;

  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();

    quantityController = TextEditingController(
      text: widget.transaction.quantity.toString(),
    );

    investedController = TextEditingController(
      text: widget.transaction.invested.toString(),
    );

    selectedDate = widget.transaction.date;
  }

  @override
  void dispose() {
    quantityController.dispose();

    investedController.dispose();

    super.dispose();
  }

  Future<void> chooseDate() async {
    final picked = await showDatePicker(
      context: context,

      initialDate: selectedDate,

      firstDate: DateTime(2009),

      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  double parseValue(String value) {
    return double.tryParse(value.replaceAll(".", "").replaceAll(",", ".")) ?? 0;
  }

  Future<void> save() async {
    final quantity = parseValue(quantityController.text);

    final invested = parseValue(investedController.text);

    if (quantity <= 0 || invested <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Informe valores válidos.")));

      return;
    }

    final updated = CryptoTransactionModel(
      id: widget.transaction.id,

      symbol: widget.transaction.symbol,

      quantity: quantity,

      invested: invested,

      date: selectedDate,
    );

    await widget.onSave(updated);

    if (!mounted) return;

    Navigator.pop(context);
  }

  String formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, "0");

    return "${two(date.day)}/${two(date.month)}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Editar ${widget.transaction.symbol}"),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            InkWell(
              onTap: chooseDate,

              child: Container(
                width: double.infinity,

                padding: const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    Text(formatDate(selectedDate)),

                    const Icon(Icons.calendar_month),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: quantityController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                labelText: "Quantidade ${widget.transaction.symbol}",

                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: investedController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: const InputDecoration(
                labelText: "Valor investido (R\$)",

                prefixText: "R\$ ",

                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text("Cancelar"),
        ),

        ElevatedButton.icon(
          onPressed: save,

          icon: const Icon(Icons.save),

          label: const Text("Salvar"),
        ),
      ],
    );
  }
}
