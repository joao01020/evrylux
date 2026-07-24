import 'package:flutter/material.dart';

class ProgressBar
    extends
        StatelessWidget {
  final double current;

  final double goal;

  final String title;

  const ProgressBar({
    super.key,

    required this.current,

    required this.goal,

    required this.title,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    double progress =
        current /
        goal;

    if (progress >
        1) {
      progress = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            Text(
              title,

              style: const TextStyle(
                fontSize: 18,

                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "${(progress * 100).toInt()}%",
            ),
          ],
        ),

        const SizedBox(
          height: 10,
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(
            20,
          ),

          child: LinearProgressIndicator(
            value: progress,

            minHeight: 12,

            backgroundColor: Colors.grey.shade300,
          ),
        ),
      ],
    );
  }
}
