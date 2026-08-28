import 'package:flutter/material.dart';

class JourneyDetails
    extends
        StatelessWidget {
  final String date;

  final List<
    String
  >
  data;

  final VoidCallback onAdd;

  const JourneyDetails({
    super.key,

    required this.date,

    required this.data,

    required this.onAdd,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: [
            const Text(
              "Registro do dia",

              style: TextStyle(
                fontSize: 22,

                fontWeight: FontWeight.bold,
              ),
            ),

            IconButton(
              onPressed: onAdd,

              icon: const Icon(
                Icons.add,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        if (data.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(
                20,
              ),

              child: Text(
                "Nenhum registro nesse dia.",
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(
                20,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    "📅 $date",
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  ...data.map(
                    (
                      item,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 10,
                        ),

                        child: Text(
                          "📝 $item",
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
