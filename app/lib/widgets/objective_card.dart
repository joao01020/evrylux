import 'package:flutter/material.dart';

import '../models/objective.dart';

class ObjectiveCard
    extends
        StatelessWidget {
  final Objective objective;

  final bool selected;

  final VoidCallback onTap;

  const ObjectiveCard({
    super.key,

    required this.objective,

    required this.selected,

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Card(
        color: selected
            ? Colors.green.shade100
            : null,

        child: ListTile(
          title: Text(
            objective.title,

            style: TextStyle(
              fontSize: 20,

              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),

          subtitle: Text(
            objective.description,
          ),

          trailing: selected
              ? const Icon(
                  Icons.check_circle,

                  color: Colors.green,
                )
              : null,
        ),
      ),
    );
  }
}
