import 'package:flutter/material.dart';

class StudyHeader
    extends
        StatelessWidget {
  const StudyHeader({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sua evolução mental começa aqui.",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Text(
          "Construa conhecimento um pouco todos os dias.",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}
