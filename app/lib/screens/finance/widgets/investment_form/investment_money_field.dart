import 'package:flutter/material.dart';

class InvestmentMoneyField
    extends
        StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;

  const InvestmentMoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
