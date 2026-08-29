import 'dart:async';

import 'package:flutter/material.dart';

class WalletCard
    extends
        StatelessWidget {
  const WalletCard({
    super.key,

    // ==========================================================
    // FINANCE
    // ==========================================================
    required this.patrimony,
    required this.invested,

    // ==========================================================
    // QUANTIDADES
    // ==========================================================
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,

    // ==========================================================
    // VALORES ATUAIS
    // ==========================================================
    this.bitcoinCurrentValue = 0,
    this.ethereumCurrentValue = 0,
    this.solanaCurrentValue = 0,
    this.usdtCurrentValue = 0,

    // ==========================================================
    // RESULTADO %
    // ==========================================================
    this.bitcoinProfitPercent = 0,
    this.ethereumProfitPercent = 0,
    this.solanaProfitPercent = 0,
    this.usdtProfitPercent = 0,

    // ==========================================================
    // ACTIONS
    // ==========================================================
    required this.onBalance,
    required this.onBitcoin,
    required this.onEthereum,
    required this.onSolana,
    required this.onUsdt,
    required this.onVault,

    // ==========================================================
    // VISIBILIDADE
    // ==========================================================
    this.showBalances = true,
  });

  // ============================================================
  // FINANCE
  // ============================================================

  final double patrimony;

  final double invested;

  // ============================================================
  // QUANTIDADES
  // ============================================================

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  // ============================================================
  // VALORES ATUAIS EM BRL
  // ============================================================

  final double bitcoinCurrentValue;

  final double ethereumCurrentValue;

  final double solanaCurrentValue;

  final double usdtCurrentValue;

  // ============================================================
  // LUCRO / PREJUÍZO %
  // ============================================================

  final double bitcoinProfitPercent;

  final double ethereumProfitPercent;

  final double solanaProfitPercent;

  final double usdtProfitPercent;

  // ============================================================
  // ACTIONS
  // ============================================================

  final VoidCallback onBalance;

  final VoidCallback onBitcoin;

  final VoidCallback onEthereum;

  final VoidCallback onSolana;

  final VoidCallback onUsdt;

  final VoidCallback onVault;

  // ============================================================
  // VISIBILIDADE GLOBAL
  // ============================================================

  final bool showBalances;

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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_rounded,
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Text(
                  'Carteira',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              IconButton(
                tooltip: 'Bitcoin',
                onPressed: onBitcoin,
                icon: const Icon(
                  Icons.currency_bitcoin,
                ),
              ),

              IconButton(
                tooltip: 'Ethereum',
                onPressed: onEthereum,
                icon: const Icon(
                  Icons.view_stream_outlined,
                ),
              ),

              IconButton(
                tooltip: 'Solana',
                onPressed: onSolana,
                icon: const Icon(
                  Icons.adjust_outlined,
                ),
              ),

              IconButton(
                tooltip: 'USDT',
                onPressed: onUsdt,
                icon: const Icon(
                  Icons.currency_exchange_outlined,
                ),
              ),

              IconButton(
                tooltip: 'Cofre',
                onPressed: onVault,
                icon: const Icon(
                  Icons.key_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // PATRIMÔNIO / INVESTIDO
          // ====================================================
          Row(
            children: [
              Expanded(
                child: _FinanceValueCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Patrimônio',
                  value: patrimony,
                  showBalances: showBalances,
                  animateChanges: true,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: _FinanceValueCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Investido',
                  value: invested,
                  showBalances: showBalances,
                  animateChanges: false,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 20,
          ),

          Divider(
            color: colorScheme.outlineVariant,
          ),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // BITCOIN
          // ====================================================
          if (bitcoin >
              0)
            _CryptoLine(
              icon: Icons.currency_bitcoin,
              name: 'Bitcoin',
              quantity: bitcoin,
              suffix: 'BTC',
              currentValue: bitcoinCurrentValue,
              profitPercent: bitcoinProfitPercent,
              showBalances: showBalances,
              onTap: onBitcoin,
            ),

          // ====================================================
          // ETHEREUM
          // ====================================================
          if (ethereum >
              0)
            _CryptoLine(
              icon: Icons.view_stream_outlined,
              name: 'Ethereum',
              quantity: ethereum,
              suffix: 'ETH',
              currentValue: ethereumCurrentValue,
              profitPercent: ethereumProfitPercent,
              showBalances: showBalances,
              onTap: onEthereum,
            ),

          // ====================================================
          // SOLANA
          // ====================================================
          if (solana >
              0)
            _CryptoLine(
              icon: Icons.adjust_outlined,
              name: 'Solana',
              quantity: solana,
              suffix: 'SOL',
              currentValue: solanaCurrentValue,
              profitPercent: solanaProfitPercent,
              showBalances: showBalances,
              onTap: onSolana,
            ),

          // ====================================================
          // USDT
          // ====================================================
          if (usdt >
              0)
            _CryptoLine(
              icon: Icons.currency_exchange_outlined,
              name: 'Tether',
              quantity: usdt,
              suffix: 'USDT',
              currentValue: usdtCurrentValue,
              profitPercent: usdtProfitPercent,
              showBalances: showBalances,
              onTap: onUsdt,
            ),

          // ====================================================
          // SEM CRIPTO
          // ====================================================
          if (bitcoin <=
                  0 &&
              ethereum <=
                  0 &&
              solana <=
                  0 &&
              usdt <=
                  0)
            TextButton.icon(
              onPressed: onBalance,
              icon: const Icon(
                Icons.add_chart_rounded,
              ),
              label: const Text(
                'Adicionar saldo cripto',
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// CRYPTO LINE
// ============================================================

class _CryptoLine
    extends
        StatelessWidget {
  const _CryptoLine({
    required this.icon,
    required this.name,
    required this.quantity,
    required this.suffix,
    required this.currentValue,
    required this.profitPercent,
    required this.showBalances,
    required this.onTap,
  });

  final IconData icon;

  final String name;

  final double quantity;

  final String suffix;

  final double currentValue;

  final double profitPercent;

  final bool showBalances;

  final VoidCallback onTap;

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

    final safeCurrentValue = currentValue.isFinite
        ? currentValue
        : 0.0;

    final safeProfitPercent = profitPercent.isFinite
        ? profitPercent
        : 0.0;

    final isPositive =
        safeProfitPercent >
        0;

    final isNegative =
        safeProfitPercent <
        0;

    final resultColor = isPositive
        ? Colors.green
        : isNegative
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            12,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // =================================================
                // ÍCONE
                // =================================================
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(
                      11,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    icon,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // =================================================
                // NOME + QUANTIDADE
                // =================================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(
                        height: 3,
                      ),

                      Text(
                        showBalances
                            ? '${_formatCrypto(quantity)} $suffix'
                            : '•••••• $suffix',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                // =================================================
                // VALOR BRL + RESULTADO
                // =================================================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // =============================================
                    // VALOR ATUAL ANIMADO
                    // =============================================
                    _AnimatedMoneyValue(
                      value: safeCurrentValue,
                      showBalances: showBalances,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    // =============================================
                    // %
                    // =============================================
                    if (showBalances)
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

                          Text(
                            _formatPercent(
                              safeProfitPercent,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: resultColor,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '••••%',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT CRYPTO
  // ============================================================

  static String _formatCrypto(
    double value,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      return '0.00000000';
    }

    return value.toStringAsFixed(
      8,
    );
  }

  // ============================================================
  // FORMAT PERCENT
  // ============================================================

  static String _formatPercent(
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
}

// ============================================================
// VALOR MONETÁRIO ANIMADO
// ============================================================
//
// Quando o valor muda:
//
// normal
//   ↓
// verde
//   ↓ 900 ms
// normal
//
// ============================================================

class _AnimatedMoneyValue
    extends
        StatefulWidget {
  const _AnimatedMoneyValue({
    required this.value,
    required this.showBalances,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w800,
  });

  final double value;

  final bool showBalances;

  final double fontSize;

  final FontWeight fontWeight;

  @override
  State<
    _AnimatedMoneyValue
  >
  createState() {
    return _AnimatedMoneyValueState();
  }
}

class _AnimatedMoneyValueState
    extends
        State<
          _AnimatedMoneyValue
        > {
  // ============================================================
  // STATE
  // ============================================================

  bool _highlight = false;

  Timer? _highlightTimer;

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant _AnimatedMoneyValue oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    // ==========================================================
    // NÃO ANIMA SE APENAS MOSTRAR/OCULTAR SALDOS
    // ==========================================================

    if (oldWidget.value ==
        widget.value) {
      return;
    }

    // ==========================================================
    // VALOR MUDOU
    // ==========================================================

    _highlightTimer?.cancel();

    setState(
      () {
        _highlight = true;
      },
    );

    _highlightTimer = Timer(
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
    _highlightTimer?.cancel();

    _highlightTimer = null;

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final normalColor = Theme.of(
      context,
    ).colorScheme.onSurface;

    final text = widget.showBalances
        ? _currency(
            widget.value,
          )
        : 'R\$ ••••••';

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
            : normalColor,
      ),
      child: Text(
        text,
      ),
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  static String _currency(
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
// FINANCE VALUE CARD
// ============================================================

class _FinanceValueCard
    extends
        StatelessWidget {
  const _FinanceValueCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.showBalances,
    required this.animateChanges,
  });

  final IconData icon;

  final String title;

  final double value;

  final bool showBalances;

  final bool animateChanges;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          14,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(
            height: 5,
          ),

          if (animateChanges)
            _AnimatedMoneyValue(
              value: value,
              showBalances: showBalances,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            )
          else
            Text(
              showBalances
                  ? _currency(
                      value,
                    )
                  : 'R\$ ••••••',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CURRENCY
  // ============================================================

  static String _currency(
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
