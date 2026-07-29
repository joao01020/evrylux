import 'package:flutter/material.dart';

import '../investment_form/investment_form.dart';

class FinancePlanningResult {
  final double invested;
  final double minimumGoal;
  final double mediumGoal;
  final double maximumGoal;
  final int projectionYears;

  const FinancePlanningResult({
    required this.invested,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,
    required this.projectionYears,
  });
}

Future<
  FinancePlanningResult?
>
showFinancePlanningDialog({
  required BuildContext context,
  required double invested,
  required double minimumGoal,
  required double mediumGoal,
  required double maximumGoal,
  required int projectionYears,
}) async {
  final investedController = TextEditingController(
    text: invested.toStringAsFixed(
      2,
    ),
  );

  final minimumController = TextEditingController(
    text: minimumGoal.toStringAsFixed(
      2,
    ),
  );

  final mediumController = TextEditingController(
    text: mediumGoal.toStringAsFixed(
      2,
    ),
  );

  final maximumController = TextEditingController(
    text: maximumGoal.toStringAsFixed(
      2,
    ),
  );

  final yearsController = TextEditingController(
    text: projectionYears.toString(),
  );

  try {
    return await showDialog<
      FinancePlanningResult
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              title: const Text(
                'Planejamento financeiro',
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                18,
                12,
                18,
                8,
              ),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: InvestmentForm(
                    investedController: investedController,
                    minimumController: minimumController,
                    mediumController: mediumController,
                    maximumController: maximumController,
                    yearsController: yearsController,
                    onSave: () {
                      final result = FinancePlanningResult(
                        invested: _parseMoney(
                          investedController.text,
                        ),
                        minimumGoal: _parseMoney(
                          minimumController.text,
                        ),
                        mediumGoal: _parseMoney(
                          mediumController.text,
                        ),
                        maximumGoal: _parseMoney(
                          maximumController.text,
                        ),
                        projectionYears:
                            int.tryParse(
                              yearsController.text.trim(),
                            ) ??
                            projectionYears,
                      );

                      Navigator.of(
                        dialogContext,
                      ).pop(
                        result,
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Fechar',
                  ),
                ),
              ],
            );
          },
    );
  } finally {
    investedController.dispose();
    minimumController.dispose();
    mediumController.dispose();
    maximumController.dispose();
    yearsController.dispose();
  }
}

double
_parseMoney(
  String value,
) {
  var normalized = value
      .trim()
      .replaceAll(
        'R\$',
        '',
      )
      .replaceAll(
        ' ',
        '',
      );

  if (normalized.isEmpty) {
    return 0;
  }

  final hasComma = normalized.contains(
    ',',
  );

  final hasDot = normalized.contains(
    '.',
  );

  if (hasComma &&
      hasDot) {
    final lastComma = normalized.lastIndexOf(
      ',',
    );

    final lastDot = normalized.lastIndexOf(
      '.',
    );

    if (lastComma >
        lastDot) {
      normalized = normalized
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    } else {
      normalized = normalized.replaceAll(
        ',',
        '',
      );
    }
  } else if (hasComma) {
    normalized = normalized.replaceAll(
      ',',
      '.',
    );
  }

  return double.tryParse(
        normalized,
      ) ??
      0;
}
