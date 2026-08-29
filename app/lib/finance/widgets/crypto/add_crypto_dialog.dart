import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/dependencies/app_dependencies.dart';

import '../../models/crypto/crypto_transaction_model.dart';

class AddCryptoDialog
    extends
        StatefulWidget {
  const AddCryptoDialog({
    super.key,
    required this.symbol,
    required this.onSave,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String symbol;

  final Future<
    void
  >
  Function(
    CryptoTransactionModel transaction,
  )
  onSave;

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    AddCryptoDialog
  >
  createState() {
    return _AddCryptoDialogState();
  }
}

class _AddCryptoDialogState
    extends
        State<
          AddCryptoDialog
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController quantityController = TextEditingController();

  final TextEditingController investedController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  DateTime selectedDate = DateTime.now();

  bool _isSaving = false;

  String? _errorMessage;

  bool _cryptoListenerAttached = false;

  // ============================================================
  // SYMBOL
  // ============================================================

  String get normalizedSymbol {
    return widget.symbol.trim().toUpperCase();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    quantityController.addListener(
      _onValuesChanged,
    );

    investedController.addListener(
      _onValuesChanged,
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _attachCryptoListener();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    quantityController.removeListener(
      _onValuesChanged,
    );

    investedController.removeListener(
      _onValuesChanged,
    );

    _detachCryptoListener();

    quantityController.dispose();

    investedController.dispose();

    super.dispose();
  }

  // ============================================================
  // CRYPTO LISTENER
  // ============================================================

  void _attachCryptoListener() {
    if (_cryptoListenerAttached) {
      return;
    }

    cryptoController.addListener(
      _onCryptoChanged,
    );

    _cryptoListenerAttached = true;
  }

  void _detachCryptoListener() {
    if (!_cryptoListenerAttached) {
      return;
    }

    cryptoController.removeListener(
      _onCryptoChanged,
    );

    _cryptoListenerAttached = false;
  }

  void _onCryptoChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // INPUT CHANGE
  // ============================================================

  void _onValuesChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _errorMessage = null;
      },
    );
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  double get quantity {
    return _parseNumber(
          quantityController.text,
        ) ??
        0;
  }

  // ============================================================
  // INVESTED
  // ============================================================

  double get invested {
    return _parseNumber(
          investedController.text,
        ) ??
        0;
  }

  // ============================================================
  // CURRENT PRICE
  // ============================================================

  double get currentPrice {
    try {
      final value = cryptoController.priceFor(
        normalizedSymbol,
      );

      if (!value.isFinite ||
          value <=
              0) {
        return 0;
      }

      return value;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ADD CRYPTO]'
        '[PRICE]'
        '[$normalizedSymbol] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 0;
    }
  }

  // ============================================================
  // PURCHASE PRICE
  // ============================================================
  //
  // Quanto foi pago por 1 unidade da moeda.
  //
  // Exemplo:
  //
  // R$ 478,36 / 0.00118671 BTC
  //
  // ============================================================

  double get purchasePrice {
    if (quantity <=
            0 ||
        invested <=
            0) {
      return 0;
    }

    final result =
        invested /
        quantity;

    if (!result.isFinite ||
        result <
            0) {
      return 0;
    }

    return result;
  }

  // ============================================================
  // CURRENT VALUE
  // ============================================================
  //
  // Quantidade × cotação atual.
  //
  // ============================================================

  double get estimatedCurrentValue {
    if (quantity <=
            0 ||
        currentPrice <=
            0) {
      return 0;
    }

    final result =
        quantity *
        currentPrice;

    if (!result.isFinite ||
        result <
            0) {
      return 0;
    }

    return result;
  }

  // ============================================================
  // RESULT
  // ============================================================

  double get estimatedResult {
    if (invested <=
        0) {
      return 0;
    }

    final result =
        estimatedCurrentValue -
        invested;

    if (!result.isFinite) {
      return 0;
    }

    return result;
  }

  // ============================================================
  // RESULT %
  // ============================================================

  double get estimatedResultPercent {
    if (invested <=
        0) {
      return 0;
    }

    final result =
        (estimatedResult /
            invested) *
        100;

    if (!result.isFinite) {
      return 0;
    }

    return result;
  }

  // ============================================================
  // CHOOSE DATE
  // ============================================================

  Future<
    void
  >
  chooseDate() async {
    if (_isSaving) {
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(
        2009,
      ),
      lastDate: DateTime.now(),
    );

    if (picked ==
            null ||
        !mounted) {
      return;
    }

    setState(
      () {
        selectedDate = picked;
      },
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  save() async {
    if (_isSaving) {
      return;
    }

    final parsedQuantity = _parseNumber(
      quantityController.text,
    );

    final parsedInvested = _parseNumber(
      investedController.text,
    );

    // ==========================================================
    // VALIDAR QUANTIDADE
    // ==========================================================

    if (parsedQuantity ==
            null ||
        !parsedQuantity.isFinite ||
        parsedQuantity <=
            0) {
      setState(
        () {
          _errorMessage =
              'Informe uma quantidade válida de '
              '$normalizedSymbol.';
        },
      );

      return;
    }

    // ==========================================================
    // VALIDAR INVESTIDO
    // ==========================================================

    if (parsedInvested ==
            null ||
        !parsedInvested.isFinite ||
        parsedInvested <=
            0) {
      setState(
        () {
          _errorMessage = 'Informe um valor investido válido.';
        },
      );

      return;
    }

    // ==========================================================
    // START
    // ==========================================================

    setState(
      () {
        _isSaving = true;
        _errorMessage = null;
      },
    );

    try {
      final transaction = CryptoTransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),

        symbol: normalizedSymbol,

        quantity: parsedQuantity,

        invested: parsedInvested,

        date: selectedDate,
      );

      await widget.onSave(
        transaction,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ADD CRYPTO]'
        '[SAVE] '
        '$error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = 'Não foi possível salvar a compra.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSaving = false;
          },
        );
      }
    }
  }

  // ============================================================
  // PARSE NUMBER
  // ============================================================
  //
  // Aceita:
  //
  // 478
  // 478.36
  // 478,36
  // 1.234,56
  //
  // ============================================================

  double? _parseNumber(
    String raw,
  ) {
    var value = raw.trim().replaceAll(
      ' ',
      '',
    );

    if (value.isEmpty) {
      return null;
    }

    // ==========================================================
    // TEM VÍRGULA
    // ==========================================================
    //
    // Consideramos a vírgula como separador decimal.
    //
    // 1.234,56
    //
    // vira:
    //
    // 1234.56
    //
    // ==========================================================

    if (value.contains(
      ',',
    )) {
      value = value
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    }

    final parsed = double.tryParse(
      value,
    );

    if (parsed ==
            null ||
        !parsed.isFinite) {
      return null;
    }

    return parsed;
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String formatDate(
    DateTime date,
  ) {
    String two(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${two(date.day)}/'
        '${two(date.month)}/'
        '${date.year}';
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  String _currency(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final negative =
        safeValue <
        0;

    final absolute = safeValue.abs();

    final parts = absolute
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integer = parts.first;

    final decimal =
        parts.length >
            1
        ? parts[1]
        : '00';

    final reversed = integer
        .split(
          '',
        )
        .reversed
        .toList();

    final buffer = StringBuffer();

    for (
      var index = 0;
      index <
          reversed.length;
      index++
    ) {
      if (index >
              0 &&
          index %
                  3 ==
              0) {
        buffer.write(
          '.',
        );
      }

      buffer.write(
        reversed[index],
      );
    }

    final formattedInteger = buffer
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    return '${negative ? '-' : ''}'
        'R\$ $formattedInteger,$decimal';
  }

  // ============================================================
  // SIGNED CURRENCY
  // ============================================================

  String _signedCurrency(
    double value,
  ) {
    if (!value.isFinite) {
      return 'R\$ 0,00';
    }

    if (value >
        0) {
      return '+ ${_currency(value)}';
    }

    if (value <
        0) {
      return '- ${_currency(value.abs())}';
    }

    return _currency(
      0,
    );
  }

  // ============================================================
  // PERCENT
  // ============================================================

  String _percent(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final sign =
        safeValue >
            0
        ? '+'
        : '';

    return '$sign'
        '${safeValue.toStringAsFixed(2).replaceAll('.', ',')}%';
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final hasQuantity =
        quantity >
        0;

    final hasInvested =
        invested >
        0;

    final hasCurrentPrice =
        currentPrice >
        0;

    if (!hasQuantity &&
        !hasInvested) {
      return const SizedBox.shrink();
    }

    final positive =
        estimatedResult >
        0;

    final negative =
        estimatedResult <
        0;

    final resultColor = positive
        ? Colors.green
        : negative
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // TITLE
          // ====================================================
          const Text(
            'Resumo da compra',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // QUANTIDADE
          // ====================================================
          _summaryRow(
            context: context,
            label: 'Quantidade',
            value:
                '${quantity.toStringAsFixed(8)} '
                '$normalizedSymbol',
          ),

          // ====================================================
          // INVESTIDO
          // ====================================================
          if (hasInvested)
            _summaryRow(
              context: context,
              label: 'Investido',
              value: _currency(
                invested,
              ),
            ),

          // ====================================================
          // PREÇO MÉDIO DA COMPRA
          // ====================================================
          if (purchasePrice >
              0)
            _summaryRow(
              context: context,
              label: 'Preço da compra',
              value:
                  '${_currency(purchasePrice)} / '
                  '$normalizedSymbol',
            ),

          // ====================================================
          // COTAÇÃO ATUAL
          // ====================================================
          if (hasCurrentPrice)
            _summaryRow(
              context: context,
              label: 'Cotação atual',
              value:
                  '${_currency(currentPrice)} / '
                  '$normalizedSymbol',
            ),

          // ====================================================
          // VALOR ATUAL
          // ====================================================
          if (hasQuantity &&
              hasCurrentPrice)
            _summaryRow(
              context: context,
              label: 'Valor atual estimado',
              value: _currency(
                estimatedCurrentValue,
              ),
            ),

          // ====================================================
          // RESULTADO
          // ====================================================
          if (hasQuantity &&
              hasInvested &&
              hasCurrentPrice) ...[
            const Divider(
              height: 22,
            ),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultado estimado',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _signedCurrency(
                        estimatedResult,
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: resultColor,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      _percent(
                        estimatedResultPercent,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: resultColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow({
    required BuildContext context,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      // ========================================================
      // TITLE
      // ========================================================
      title: Row(
        children: [
          const Icon(
            Icons.currency_bitcoin_rounded,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              'Adicionar $normalizedSymbol',
            ),
          ),
        ],
      ),

      // ========================================================
      // CONTENT
      // ========================================================
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // DATE
              // =================================================
              const Text(
                'Data da compra',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(
                height: 6,
              ),

              InkWell(
                onTap: _isSaving
                    ? null
                    : chooseDate,
                borderRadius: BorderRadius.circular(
                  10,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 19,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          formatDate(
                            selectedDate,
                          ),
                        ),
                      ),

                      const Icon(
                        Icons.arrow_drop_down_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 18,
              ),

              // =================================================
              // QUANTITY
              // =================================================
              TextField(
                controller: quantityController,
                enabled: !_isSaving,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r'[0-9.,]',
                    ),
                  ),
                ],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Quantidade ($normalizedSymbol)',
                  hintText: _quantityHint(),
                  suffixText: normalizedSymbol,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // INVESTED
              // =================================================
              TextField(
                controller: investedController,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(
                      r'[0-9.,]',
                    ),
                  ),
                ],
                textInputAction: TextInputAction.done,
                onSubmitted:
                    (
                      _,
                    ) {
                      save();
                    },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Valor investido',
                  prefixText: 'R\$ ',
                  hintText: '0,00',
                ),
              ),

              // =================================================
              // ERROR
              // =================================================
              if (_errorMessage !=
                  null) ...[
                const SizedBox(
                  height: 10,
                ),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: colorScheme.error,
                    ),

                    const SizedBox(
                      width: 7,
                    ),

                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // =================================================
              // SUMMARY
              // =================================================
              if (quantity >
                      0 ||
                  invested >
                      0) ...[
                const SizedBox(
                  height: 18,
                ),

                _buildSummary(
                  context,
                ),
              ],

              // =================================================
              // INFO
              // =================================================
              const SizedBox(
                height: 12,
              ),

              Text(
                'O valor investido deve ser o valor total pago '
                'pela quantidade informada.',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // ACTIONS
      // ========================================================
      actions: [
        TextButton(
          onPressed: _isSaving
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop();
                },
          child: const Text(
            'Cancelar',
          ),
        ),

        FilledButton.icon(
          onPressed: _isSaving
              ? null
              : save,
          icon: _isSaving
              ? const SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.add_rounded,
                ),
          label: Text(
            _isSaving
                ? 'Salvando...'
                : 'Adicionar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // QUANTITY HINT
  // ============================================================

  String _quantityHint() {
    switch (normalizedSymbol) {
      case 'BTC':
        return '0,00100000';

      case 'ETH':
        return '0,01000000';

      case 'SOL':
        return '1,00000000';

      case 'USDT':
        return '10,00000000';

      default:
        return '0,00000000';
    }
  }
}
