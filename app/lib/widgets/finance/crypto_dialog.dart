import 'package:flutter/material.dart';

class CryptoDialog
    extends
        StatelessWidget {
  final String name;

  final String symbol;

  final Function(
    double,
  )
  onSave;

  const CryptoDialog({
    super.key,

    required this.name,

    required this.symbol,

    required this.onSave,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(
              symbol,

              style: const TextStyle(
                fontSize: 42,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              "Adicionar $name",

              style: const TextStyle(
                fontSize: 18,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            TextField(
              controller: controller,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                labelText: "Quantidade $symbol",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  final value =
                      double.tryParse(
                        controller.text.replaceAll(
                          ",",
                          ".",
                        ),
                      ) ??
                      0.0;

                  onSave(
                    value,
                  );

                  Navigator.pop(
                    context,
                  );
                },

                child: const Text(
                  "Salvar",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
