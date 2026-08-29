import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvestmentMoneyField
    extends
        StatelessWidget {
  const InvestmentMoneyField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.onChanged,
    this.enabled = true,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final TextEditingController controller;

  final String label;

  final String hint;

  final IconData icon;

  final ValueChanged<
    String
  >?
  onChanged;

  final bool enabled;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: controller,

      enabled: enabled,

      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),

      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(
            r'^\d*[.,]?\d{0,2}',
          ),
        ),
      ],

      onChanged: onChanged,

      decoration: InputDecoration(
        labelText: label,

        hintText: hint,

        prefixIcon: Icon(
          icon,
        ),

        border: const OutlineInputBorder(),

        enabledBorder: const OutlineInputBorder(),

        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
