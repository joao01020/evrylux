import 'package:flutter/material.dart';

class HistoryButton
    extends
        StatelessWidget {
  const HistoryButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.history,
        ),
        label: const Text(
          "Histórico 📚",
        ),
      ),
    );
  }
}
