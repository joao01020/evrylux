import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';

class CryptoBalanceDialog
    extends
        StatefulWidget {
  const CryptoBalanceDialog({
    super.key,

    // ==========================================================
    // SALDOS
    // ==========================================================
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,

    // ==========================================================
    // VALORES ATUAIS
    // ==========================================================
    required this.bitcoinCurrentValue,
    required this.ethereumCurrentValue,
    required this.solanaCurrentValue,
    required this.usdtCurrentValue,

    // ==========================================================
    // RESULTADO %
    // ==========================================================
    required this.bitcoinProfitPercent,
    required this.ethereumProfitPercent,
    required this.solanaProfitPercent,
    required this.usdtProfitPercent,

    // ==========================================================
    // AÇÕES
    // ==========================================================
    required this.onEditBitcoin,
    required this.onEditEthereum,
    required this.onEditSolana,
    required this.onEditUsdt,
  });

  // ============================================================
  // SALDOS
  // ============================================================

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  // ============================================================
  // VALORES ATUAIS
  // ============================================================

  final double bitcoinCurrentValue;

  final double ethereumCurrentValue;

  final double solanaCurrentValue;

  final double usdtCurrentValue;

  // ============================================================
  // RESULTADO %
  // ============================================================

  final double bitcoinProfitPercent;

  final double ethereumProfitPercent;

  final double solanaProfitPercent;

  final double usdtProfitPercent;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onEditBitcoin;

  final VoidCallback onEditEthereum;

  final VoidCallback onEditSolana;

  final VoidCallback onEditUsdt;

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    CryptoBalanceDialog
  >
  createState() {
    return _CryptoBalanceDialogState();
  }
}

class _CryptoBalanceDialogState
    extends
        State<
          CryptoBalanceDialog
        > {
  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  bool _listenerAttached = false;

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

        _attachListener();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _detachListener();

    super.dispose();
  }

  // ============================================================
  // LISTENER
  // ============================================================

  void _attachListener() {
    if (_listenerAttached) {
      return;
    }

    cryptoController.addListener(
      _onCryptoChanged,
    );

    _listenerAttached = true;
  }

  void _detachListener() {
    if (!_listenerAttached) {
      return;
    }

    cryptoController.removeListener(
      _onCryptoChanged,
    );

    _listenerAttached = false;
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
          ),

          SizedBox(
            width: 10,
          ),

          Text(
            'Saldo da carteira',
          ),
        ],
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // BTC
            // ==================================================
            _crypto(
              context: context,
              icon: '₿',
              name: 'Bitcoin',
              symbol: 'BTC',
              quantity: widget.bitcoin,
              quantityDecimals: 8,
              fallbackCurrentValue: widget.bitcoinCurrentValue,
              fallbackProfitPercent: widget.bitcoinProfitPercent,
              onEdit: widget.onEditBitcoin,
            ),

            // ==================================================
            // ETH
            // ==================================================
            _crypto(
              context: context,
              icon: 'Ξ',
              name: 'Ethereum',
              symbol: 'ETH',
              quantity: widget.ethereum,
              quantityDecimals: 8,
              fallbackCurrentValue: widget.ethereumCurrentValue,
              fallbackProfitPercent: widget.ethereumProfitPercent,
              onEdit: widget.onEditEthereum,
            ),

            // ==================================================
            // SOL
            // ==================================================
            _crypto(
              context: context,
              icon: '◎',
              name: 'Solana',
              symbol: 'SOL',
              quantity: widget.solana,
              quantityDecimals: 8,
              fallbackCurrentValue: widget.solanaCurrentValue,
              fallbackProfitPercent: widget.solanaProfitPercent,
              onEdit: widget.onEditSolana,
            ),

            // ==================================================
            // USDT
            // ==================================================
            _crypto(
              context: context,
              icon: '₮',
              name: 'Tether',
              symbol: 'USDT',
              quantity: widget.usdt,
              quantityDecimals: 8,
              fallbackCurrentValue: widget.usdtCurrentValue,
              fallbackProfitPercent: widget.usdtProfitPercent,
              onEdit: widget.onEditUsdt,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          child: const Text(
            'Fechar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CRYPTO CARD
  // ============================================================

  Widget _crypto({
    required BuildContext context,
    required String icon,
    required String name,
    required String symbol,
    required double quantity,
    required int quantityDecimals,
    required double fallbackCurrentValue,
    required double fallbackProfitPercent,
    required VoidCallback onEdit,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final safeQuantity = _safeQuantity(
      quantity,
    );

    // ==========================================================
    // COTAÇÃO ATUAL
    // ==========================================================

    final currentPrice = _priceFor(
      symbol,
    );

    // ==========================================================
    // VALOR ATUAL
    // ==========================================================

    final currentValue = _currentValueFor(
      symbol: symbol,
      quantity: safeQuantity,
      fallback: fallbackCurrentValue,
    );

    // ==========================================================
    // RESULTADO %
    // ==========================================================

    final profitPercent = _profitPercentFor(
      symbol: symbol,
      currentValue: currentValue,
      fallback: fallbackProfitPercent,
    );

    final isPositive =
        profitPercent >
        0;

    final isNegative =
        profitPercent <
        0;

    final resultColor = isPositive
        ? Colors.green
        : isNegative
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // =================================================
              // ÍCONE
              // =================================================
              SizedBox(
                width: 42,
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              // =================================================
              // NOME / QUANTIDADE
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      '${safeQuantity.toStringAsFixed(quantityDecimals)} '
                      '$symbol',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // ============================================
                    // COTAÇÃO
                    // ============================================
                    if (currentPrice >
                        0)
                      _AnimatedMarketText(
                        value: currentPrice,
                        text: '${_currency(currentPrice)} / $symbol',
                        normalColor: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                  ],
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              // =================================================
              // VALOR ATUAL / RESULTADO
              // =================================================
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedMarketText(
                    value: currentValue,
                    text: _currency(
                      currentValue,
                    ),
                    normalColor: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),

                  const SizedBox(
                    height: 4,
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPositive)
                        Icon(
                          Icons.arrow_drop_up_rounded,
                          size: 18,
                          color: resultColor,
                        )
                      else if (isNegative)
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 18,
                          color: resultColor,
                        ),

                      _AnimatedMarketText(
                        value: profitPercent,
                        text: _formatPercent(
                          profitPercent,
                        ),
                        normalColor: resultColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(
                width: 12,
              ),

              // =================================================
              // EDIT
              // =================================================
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAFE QUANTITY
  // ============================================================

  double _safeQuantity(
    double value,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // PRICE
  // ============================================================

  double _priceFor(
    String symbol,
  ) {
    try {
      final value = cryptoController.priceFor(
        symbol,
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
        '[CRYPTO BALANCE]'
        '[PRICE]'
        '[$symbol] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 0;
    }
  }

  // ============================================================
  // CURRENT VALUE
  // ============================================================

  double _currentValueFor({
    required String symbol,
    required double quantity,
    required double fallback,
  }) {
    final price = _priceFor(
      symbol,
    );

    if (quantity >
            0 &&
        price >
            0) {
      final result =
          quantity *
          price;

      if (result.isFinite &&
          result >=
              0) {
        return result;
      }
    }

    if (fallback.isFinite &&
        fallback >=
            0) {
      return fallback;
    }

    return 0;
  }

  // ============================================================
  // PROFIT %
  // ============================================================

  double _profitPercentFor({
    required String symbol,
    required double currentValue,
    required double fallback,
  }) {
    try {
      final invested = cryptoController.investedFor(
        symbol,
      );

      if (invested.isFinite &&
          invested >
              0) {
        final result =
            ((currentValue -
                    invested) /
                invested) *
            100;

        if (result.isFinite) {
          return result;
        }
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO BALANCE]'
        '[PROFIT]'
        '[$symbol] $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }

    if (fallback.isFinite) {
      return fallback;
    }

    return 0;
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
        ? parts.last
        : '00';

    final reversed = integer
        .split(
          '',
        )
        .reversed
        .toList();

    final buffer = StringBuffer();

    for (
      int index = 0;
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
}

// ============================================================
// ANIMATED MARKET TEXT
// ============================================================
//
// Quando o valor muda:
//
// valor antigo
//     ↓
// atualização
//     ↓
// novo valor verde
//     ↓
// 900 ms
//     ↓
// cor normal
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

    // ==========================================================
    // COMPARAÇÃO
    // ==========================================================
    //
    // Para valores monetários, pequenas casas que não aparecem
    // na tela não precisam disparar a animação.
    //
    // ==========================================================

    final oldRounded =
        (oldWidget.value *
                100)
            .round();

    final newRounded =
        (widget.value *
                100)
            .round();

    if (oldRounded ==
        newRounded) {
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
