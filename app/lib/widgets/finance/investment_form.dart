import 'package:flutter/material.dart';

class InvestmentForm
    extends
        StatelessWidget {
  final TextEditingController investedController;

  final TextEditingController monthlyController;

  final TextEditingController goalController;

  final VoidCallback onSave;

  const InvestmentForm({
    super.key,

    required this.investedController,

    required this.monthlyController,

    required this.goalController,

    required this.onSave,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),

        child: Column(
          children: [
            TextField(
              controller: investedController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Valor investido hoje",
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller: monthlyController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Meta mensal",
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller: goalController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Meta patrimônio",
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: onSave,

                child: const Text(
                  "Salvar investimento",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
