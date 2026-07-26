import 'package:flutter/material.dart';

class FinanceSectionHeader
    extends
        StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const FinanceSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (subtitle !=
                  null) ...[
                const SizedBox(
                  height: 4,
                ),

                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (trailing !=
            null) ...[
          const SizedBox(
            width: 12,
          ),

          trailing!,
        ],
      ],
    );
  }
}
