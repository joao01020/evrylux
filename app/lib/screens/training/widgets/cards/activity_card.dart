import 'package:flutter/material.dart';

class ActivityCard
    extends
        StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.selected,
    required this.onTap,
  });

  final String activity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final parts = activity.split(
      ' ',
    );

    final emoji = parts.first;
    final title = parts
        .skip(
          1,
        )
        .join(
          ' ',
        );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? Colors.green.shade50
              : Theme.of(
                  context,
                ).cardColor,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: selected
                ? Colors.green
                : Colors.grey.shade300,
            width: selected
                ? 2
                : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(
                fontSize: 30,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            AnimatedOpacity(
              duration: const Duration(
                milliseconds: 180,
              ),
              opacity: selected
                  ? 1
                  : 0,
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
