import 'package:flutter/material.dart';

class JourneyDayCard
    extends
        StatelessWidget {
  final DateTime date;

  final bool selected;

  final bool completed;

  final VoidCallback onTap;

  const JourneyDayCard({
    super.key,

    required this.date,

    required this.selected,

    required this.completed,

    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? Colors.blue
              : completed
              ? Colors.green
              : Colors.grey.shade200,

          borderRadius: BorderRadius.circular(
            10,
          ),
        ),

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Text(
                "${date.day}",

                style: TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,

                  color:
                      selected ||
                          completed
                      ? Colors.white
                      : Colors.black,
                ),
              ),

              if (completed)
                const Icon(
                  Icons.check,

                  size: 14,

                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
