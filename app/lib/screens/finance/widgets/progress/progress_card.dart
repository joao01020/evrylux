import 'package:flutter/material.dart';

class ProgressCard
    extends
        StatelessWidget {
  final String title;

  final double value;

  final String text;

  const ProgressCard({
    super.key,

    required this.title,

    required this.value,

    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          title,

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        LinearProgressIndicator(
          value: value,

          minHeight: 10,
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          text,
        ),
      ],
    );
  }
}
