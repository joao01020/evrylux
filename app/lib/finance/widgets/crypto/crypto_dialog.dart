import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';

import '../../models/crypto/crypto_transaction_model.dart';

import 'add_crypto_dialog.dart';
import 'crypto_history_card.dart';
import 'edit_crypto_dialog.dart';

class CryptoDialog
    extends
        StatefulWidget {
  const CryptoDialog({
    super.key,
    required this.symbol,
  });

  final String symbol;

  @override
  State<
    CryptoDialog
  >
  createState() {
    return _CryptoDialogState();
  }
}

class _CryptoDialogState
    extends
        State<
          CryptoDialog
        > {
  // ============================================================
  // STATE
  // ============================================================

  List<
    CryptoTransactionModel
  >
  transactions = [];

  bool isLoading = true;

  String? errorMessage;

  bool _controllerListenerAttached = false;

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

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _attachControllerListener();

        load();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _detachControllerListener();

    super.dispose();
  }

  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  void _attachControllerListener() {
    if (_controllerListenerAttached) {
      return;
    }

    cryptoController.addListener(
      _onCryptoControllerChanged,
    );

    _controllerListenerAttached = true;
  }

  void _detachControllerListener() {
    if (!_controllerListenerAttached) {
      return;
    }

    cryptoController.removeListener(
      _onCryptoControllerChanged,
    );

    _controllerListenerAttached = false;
  }

  void _onCryptoControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load() async {
    if (!mounted) {
      return;
    }

    setState(
      () {
        isLoading = true;
        errorMessage = null;
      },
    );

    try {
      final result = await cryptoController.getBySymbol(
        normalizedSymbol,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          transactions =
              List<
                CryptoTransactionModel
              >.from(
                result,
              );
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][LOAD] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          errorMessage =
              'Não foi possível carregar '
              '$normalizedSymbol.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isLoading = false;
          },
        );
      }
    }
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  double get totalQuantity {
    final controllerValue = cryptoController.quantityFor(
      normalizedSymbol,
    );

    if (controllerValue.isFinite &&
        controllerValue >=
            0) {
      return controllerValue;
    }

    return transactions.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.quantity;
      },
    );
  }

  // ============================================================
  // TOTAL INVESTED
  // ============================================================

  double get totalInvested {
    final controllerValue = cryptoController.investedFor(
      normalizedSymbol,
    );

    if (controllerValue.isFinite &&
        controllerValue >=
            0) {
      return controllerValue;
    }

    return transactions.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.invested;
      },
    );
  }

  // ============================================================
  // CURRENT PRICE
  // ============================================================

  double get currentPrice {
    final value = cryptoController.priceFor(
      normalizedSymbol,
    );

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // CURRENT VALUE
  // ============================================================

  double get currentValue {
    final value = cryptoController.currentValueFor(
      normalizedSymbol,
    );

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // PROFIT / LOSS
  // ============================================================

  double get profitLoss {
    final value = cryptoController.profitLossFor(
      normalizedSymbol,
    );

    if (!value.isFinite) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // PROFIT / LOSS %
  // ============================================================

  double get profitLossPercent {
    final value = cryptoController.profitLossPercentFor(
      normalizedSymbol,
    );

    if (!value.isFinite) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get cryptoTitle {
    switch (normalizedSymbol) {
      case 'BTC':
        return 'Bitcoin';

      case 'ETH':
        return 'Ethereum';

      case 'SOL':
        return 'Solana';

      case 'USDT':
        return 'Tether';

      default:
        return normalizedSymbol;
    }
  }

  // ============================================================
  // DECIMALS
  // ============================================================

  int get quantityDecimals {
    switch (normalizedSymbol) {
      case 'BTC':
        return 8;

      case 'ETH':
        return 8;

      case 'SOL':
        return 8;

      case 'USDT':
        return 8;

      default:
        return 8;
    }
  }

  // ============================================================
  // FORMAT QUANTITY
  // ============================================================

  String _formatQuantity(
    double value,
  ) {
    final safeValue =
        value.isFinite &&
            value >=
                0
        ? value
        : 0.0;

    return safeValue.toStringAsFixed(
      quantityDecimals,
    );
  }

  // ============================================================
  // FORMAT CURRENCY
  // ============================================================

  String _formatCurrency(
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
  // FORMAT SIGNED CURRENCY
  // ============================================================

  String _formatSignedCurrency(
    double value,
  ) {
    if (!value.isFinite) {
      return 'R\$ 0,00';
    }

    if (value >
        0) {
      return '+ ${_formatCurrency(value)}';
    }

    if (value <
        0) {
      return '- ${_formatCurrency(value.abs())}';
    }

    return _formatCurrency(
      0,
    );
  }

  // ============================================================
  // FORMAT PERCENT
  // ============================================================

  String _formatPercent(
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
  // ADD
  // ============================================================

  Future<
    void
  >
  add() async {
    try {
      await showDialog<
        void
      >(
        context: context,
        builder:
            (
              dialogContext,
            ) {
              return AddCryptoDialog(
                symbol: normalizedSymbol,
                onSave:
                    (
                      transaction,
                    ) {
                      return cryptoController.add(
                        transaction,
                      );
                    },
              );
            },
      );

      if (!mounted) {
        return;
      }

      await load();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][ADD] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível adicionar a compra.',
        );
      }
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<
    void
  >
  edit(
    CryptoTransactionModel transaction,
  ) async {
    try {
      await showDialog<
        void
      >(
        context: context,
        builder:
            (
              dialogContext,
            ) {
              return EditCryptoDialog(
                transaction: transaction,
                onSave:
                    (
                      updated,
                    ) {
                      return cryptoController.update(
                        updated,
                      );
                    },
              );
            },
      );

      if (!mounted) {
        return;
      }

      await load();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][EDIT] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível atualizar a compra.',
        );
      }
    }
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<
    void
  >
  remove(
    CryptoTransactionModel transaction,
  ) async {
    try {
      await cryptoController.delete(
        transaction.id,
      );

      if (!mounted) {
        return;
      }

      await load();

      if (mounted) {
        _showMessage(
          'Compra excluída.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][DELETE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível excluir a compra.',
        );
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cryptoTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                normalizedSymbol,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // LIVE INDICATOR
        // ======================================================
        if (currentPrice >
            0)
          Container(
            margin: const EdgeInsets.only(
              right: 6,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                999,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: Colors.green,
                ),
                SizedBox(
                  width: 5,
                ),
                Text(
                  'Atualizado',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final positive =
        profitLoss >
        0;

    final negative =
        profitLoss <
        0;

    final resultColor = positive
        ? Colors.green
        : negative
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // SALDO
            // ==================================================
            const Text(
              'Saldo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              '${_formatQuantity(totalQuantity)} '
              '$normalizedSymbol',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            const Divider(),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // COTAÇÃO ATUAL
            // ==================================================
            const Text(
              'Cotação atual',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            _AnimatedMarketText(
              value: currentPrice,
              text:
                  currentPrice >
                      0
                  ? '${_formatCurrency(currentPrice)} / '
                        '$normalizedSymbol'
                  : 'Cotação indisponível',
              normalColor: colorScheme.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // VALOR ATUAL
            // ==================================================
            const Text(
              'Valor atual',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            _AnimatedMarketText(
              value: currentValue,
              text: _formatCurrency(
                currentValue,
              ),
              normalColor: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),

            const SizedBox(
              height: 16,
            ),

            // ==================================================
            // INVESTIDO
            // ==================================================
            const Text(
              'Investido',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              _formatCurrency(
                totalInvested,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Divider(),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // RESULTADO
            // ==================================================
            const Text(
              'Resultado',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 7,
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: _AnimatedMarketText(
                    value: profitLoss,
                    text: _formatSignedCurrency(
                      profitLoss,
                    ),
                    normalColor: resultColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                _AnimatedMarketText(
                  value: profitLossPercent,
                  text: _formatPercent(
                    profitLossPercent,
                  ),
                  normalColor: resultColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            Row(
              children: [
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : negative
                      ? Icons.trending_down_rounded
                      : Icons.trending_flat_rounded,
                  size: 17,
                  color: resultColor,
                ),

                const SizedBox(
                  width: 5,
                ),

                Text(
                  positive
                      ? 'Acima do valor investido'
                      : negative
                      ? 'Abaixo do valor investido'
                      : 'Sem variação',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: resultColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : add,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Adicionar compra',
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _buildHistory() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 32,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage !=
        null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 36,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 12,
              ),

              OutlinedButton.icon(
                onPressed: load,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CryptoHistoryCard(
      transactions: transactions,
      onDelete: remove,
      onEdit: edit,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 20,
                ),

                _buildSummary(),

                const SizedBox(
                  height: 20,
                ),

                _buildAddButton(),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  'Histórico',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ANIMATED MARKET TEXT
// ============================================================
//
// Sempre que o valor recebido mudar:
//
// valor normal
//      ↓
// novo valor fica verde
//      ↓
// permanece verde por 900 ms
//      ↓
// retorna para sua cor original
//
// Isso funciona para:
//
// - cotação atual
// - valor atual
// - resultado em R$
// - resultado em %
//
// ============================================================

class _AnimatedMarketText
    extends
        StatefulWidget {
  const _AnimatedMarketText({
    required this.value,
    required this.text,
    required this.normalColor,
    required this.fontSize,
    required this.fontWeight,
  });

  final double value;

  final String text;

  final Color normalColor;

  final double fontSize;

  final FontWeight fontWeight;

  @override
  State<
    _AnimatedMarketText
  >
  createState() {
    return _AnimatedMarketTextState();
  }
}

class _AnimatedMarketTextState
    extends
        State<
          _AnimatedMarketText
        > {
  bool _highlight = false;

  Timer? _timer;

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant _AnimatedMarketText oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.value ==
        widget.value) {
      return;
    }

    _timer?.cancel();

    setState(
      () {
        _highlight = true;
      },
    );

    _timer = Timer(
      const Duration(
        milliseconds: 900,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _highlight = false;
          },
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _timer?.cancel();

    _timer = null;

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedDefaultTextStyle(
      duration: const Duration(
        milliseconds: 220,
      ),
      curve: Curves.easeOut,
      style: TextStyle(
        fontSize: widget.fontSize,
        fontWeight: widget.fontWeight,
        color: _highlight
            ? Colors.green
            : widget.normalColor,
      ),
      child: Text(
        widget.text,
      ),
    );
  }
}
