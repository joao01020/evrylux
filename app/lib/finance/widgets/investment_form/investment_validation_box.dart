import 'package:flutter/material.dart';

class InvestmentValidationBox
    extends
        StatelessWidget {
  final String? message;

  const InvestmentValidationBox({
    super.key,
    required this.message,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (message ==
        null) {
      return const SizedBox.shrink();
    }

    final color = Theme.of(
      context,
    ).colorScheme.error;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 16,
      ),
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 20,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              message!,
              style: TextStyle(
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
