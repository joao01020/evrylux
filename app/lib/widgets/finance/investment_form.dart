import 'package:flutter/material.dart';

import 'investment_form/investment_form_calculator.dart';
import 'investment_form/investment_form_formatter.dart';
import 'investment_form/investment_form_validation.dart';
import 'investment_form/investment_money_field.dart';
import 'investment_form/investment_projection_card.dart';
import 'investment_form/investment_validation_box.dart';

class InvestmentForm
    extends
        StatefulWidget {
  final TextEditingController investedController;
  final TextEditingController minimumController;
  final TextEditingController mediumController;
  final TextEditingController maximumController;
  final TextEditingController yearsController;

  final VoidCallback onSave;

  const InvestmentForm({
    super.key,
    required this.investedController,
    required this.minimumController,
    required this.mediumController,
    required this.maximumController,
    required this.yearsController,
    required this.onSave,
  });

  @override
  State<
    InvestmentForm
  >
  createState() {
    return _InvestmentFormState();
  }
}

class _InvestmentFormState
    extends
        State<
          InvestmentForm
        > {
  List<
    TextEditingController
  >
  get _controllers {
    return [
      widget.investedController,
      widget.minimumController,
      widget.mediumController,
      widget.maximumController,
      widget.yearsController,
    ];
  }

  // =========================================================
  // CICLO DE VIDA
  // =========================================================

  @override
  void initState() {
    super.initState();

    for (final controller in _controllers) {
      controller.addListener(
        _updatePreview,
      );
    }
  }

  @override
  void didUpdateWidget(
    covariant InvestmentForm oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    final oldControllers = [
      oldWidget.investedController,
      oldWidget.minimumController,
      oldWidget.mediumController,
      oldWidget.maximumController,
      oldWidget.yearsController,
    ];

    final controllersChanged =
        oldWidget.investedController !=
            widget.investedController ||
        oldWidget.minimumController !=
            widget.minimumController ||
        oldWidget.mediumController !=
            widget.mediumController ||
        oldWidget.maximumController !=
            widget.maximumController ||
        oldWidget.yearsController !=
            widget.yearsController;

    if (!controllersChanged) {
      return;
    }

    for (final controller in oldControllers) {
      controller.removeListener(
        _updatePreview,
      );
    }

    for (final controller in _controllers) {
      controller.addListener(
        _updatePreview,
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.removeListener(
        _updatePreview,
      );
    }

    super.dispose();
  }

  void _updatePreview() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // =========================================================
  // VALORES
  // =========================================================

  double get _currentPatrimony {
    return InvestmentFormFormatter.parseMoney(
      widget.investedController.text,
    );
  }

  double get _minimumGoal {
    return InvestmentFormFormatter.parseMoney(
      widget.minimumController.text,
    );
  }

  double get _mediumGoal {
    return InvestmentFormFormatter.parseMoney(
      widget.mediumController.text,
    );
  }

  double get _maximumGoal {
    return InvestmentFormFormatter.parseMoney(
      widget.maximumController.text,
    );
  }

  int get _projectionYears {
    return InvestmentFormFormatter.parseYears(
      widget.yearsController.text,
    );
  }

  InvestmentFormCalculator get _calculator {
    return InvestmentFormCalculator(
      currentPatrimony: _currentPatrimony,
      projectionYears: _projectionYears,
    );
  }

  InvestmentFormValidation get _validation {
    return InvestmentFormValidation(
      currentPatrimony: _currentPatrimony,
      minimumGoal: _minimumGoal,
      mediumGoal: _mediumGoal,
      maximumGoal: _maximumGoal,
      projectionYears: _projectionYears,
    );
  }

  // =========================================================
  // SALVAMENTO
  // =========================================================

  void _handleSave() {
    FocusScope.of(
      context,
    ).unfocus();

    if (!_validation.isValid) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            _validation.message ??
                'Preencha corretamente o planejamento.',
          ),
        ),
      );

      return;
    }

    widget.onSave();
  }

  // =========================================================
  // CAMPOS
  // =========================================================

  Widget _formFields() {
    return Column(
      children: [
        InvestmentMoneyField(
          controller: widget.investedController,
          label: 'Patrimônio atual',
          hint: 'Ex.: 10.000,00',
          icon: Icons.account_balance_wallet_outlined,
        ),

        const SizedBox(
          height: 14,
        ),

        InvestmentMoneyField(
          controller: widget.minimumController,
          label: 'Ritmo tranquilo',
          hint: 'Ex.: 300,00 por mês',
          icon: Icons.eco_outlined,
        ),

        const SizedBox(
          height: 14,
        ),

        InvestmentMoneyField(
          controller: widget.mediumController,
          label: 'Ritmo normal',
          hint: 'Ex.: 700,00 por mês',
          icon: Icons.directions_walk_outlined,
        ),

        const SizedBox(
          height: 14,
        ),

        InvestmentMoneyField(
          controller: widget.maximumController,
          label: 'Ritmo forte',
          hint: 'Ex.: 1.500,00 por mês',
          icon: Icons.local_fire_department_outlined,
        ),

        const SizedBox(
          height: 14,
        ),

        TextField(
          controller: widget.yearsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tempo da projeção',
            hintText: 'Ex.: 10 anos',
            prefixIcon: Icon(
              Icons.calendar_month_outlined,
            ),
            suffixText: 'anos',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // PROJEÇÕES
  // =========================================================

  Widget _projections() {
    return Column(
      children: [
        InvestmentProjectionCard(
          color: Colors.green,
          title: 'Ritmo tranquilo',
          description: 'Um caminho leve para manter a constância mesmo nos meses mais difíceis.',
          monthlyContribution: _minimumGoal,
          contributed: _calculator.totalContributed(
            _minimumGoal,
          ),
          projectedPatrimony: _calculator.projection(
            _minimumGoal,
          ),
          projectionYears: _projectionYears,
        ),

        InvestmentProjectionCard(
          color: Colors.blue,
          title: 'Ritmo normal',
          description: 'Um caminho equilibrado entre conforto financeiro e velocidade.',
          monthlyContribution: _mediumGoal,
          contributed: _calculator.totalContributed(
            _mediumGoal,
          ),
          projectedPatrimony: _calculator.projection(
            _mediumGoal,
          ),
          projectionYears: _projectionYears,
        ),

        InvestmentProjectionCard(
          color: Colors.purple,
          title: 'Ritmo forte',
          description: 'Um caminho acelerado para aproximar o objetivo mais rapidamente.',
          monthlyContribution: _maximumGoal,
          contributed: _calculator.totalContributed(
            _maximumGoal,
          ),
          projectedPatrimony: _calculator.projection(
            _maximumGoal,
          ),
          projectionYears: _projectionYears,
        ),
      ],
    );
  }

  // =========================================================
  // TELA
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: BorderSide(
          color: Theme.of(
            context,
          ).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planejamento financeiro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Defina três ritmos possíveis. Nenhum deles representa fracasso: apenas caminhos com velocidades diferentes.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            _formFields(),

            InvestmentValidationBox(
              message: _validation.message,
            ),

            const SizedBox(
              height: 28,
            ),

            const Text(
              'Projeções',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              'As projeções consideram o patrimônio atual e aportes mensais durante todo o período.',
              style: TextStyle(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            _projections(),

            const SizedBox(
              height: 8,
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _validation.isValid
                    ? _handleSave
                    : null,
                icon: const Icon(
                  Icons.save_outlined,
                ),
                label: const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  child: Text(
                    'Salvar planejamento',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
