import 'package:flutter/material.dart';

class WeekTracker
    extends
        StatelessWidget {
  final List<
    bool
  >
  completedDays;

  final Function(
    int,
  )
  onDayTap;

  const WeekTracker({
    super.key,

    required this.completedDays,

    required this.onDayTap,
  });

  final List<
    String
  >
  days = const [
    "S",

    "T",

    "Q",

    "Q",

    "S",

    "S",

    "D",
  ];

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Text(
          "Esta semana",

          style: TextStyle(
            fontSize: 20,

            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: List.generate(
            7,

            (
              index,
            ) {
              return GestureDetector(
                onTap: () {
                  onDayTap(
                    index,
                  );
                },

                child: Column(
                  children: [
                    Text(
                      days[index],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Container(
                      width: 35,

                      height: 35,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: completedDays[index]
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
