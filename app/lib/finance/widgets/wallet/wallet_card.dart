import 'package:flutter/material.dart';

class WalletCard
    extends
        StatelessWidget {
  const WalletCard({
    super.key,
    required this.patrimony,
    required this.invested,
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,
    required this.onBalance,
    required this.onBitcoin,
    required this.onEthereum,
    required this.onSolana,
    required this.onUsdt,
    required this.onVault,
    this.showBalances = true,
  });

  final double patrimony;
  final double invested;

  final double bitcoin;
  final double ethereum;
  final double solana;
  final double usdt;

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
                  value: _valueText(
                    patrimony,
                  ),
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: _FinanceValueCard(
                  icon: Icons.trending_up_rounded,
                  title: 'Investido',
                  value: _valueText(
                    invested,
                  ),
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
          // CRIPTO
          // ====================================================
          if (bitcoin >
              0)
            _cryptoLine(
              symbol: '₿',
              value: bitcoin,
              suffix: 'BTC',
            ),

          if (ethereum >
              0)
            _cryptoLine(
              symbol: 'Ξ',
              value: ethereum,
              suffix: 'ETH',
            ),

          if (solana >
              0)
            _cryptoLine(
              symbol: '◎',
              value: solana,
              suffix: 'SOL',
            ),

          if (usdt >
              0)
            _cryptoLine(
              symbol: '₮',
              value: usdt,
              suffix: 'USDT',
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

  // ============================================================
  // CRYPTO
  // ============================================================

  Widget _cryptoLine({
    required String symbol,
    required double value,
    required String suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              symbol,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            _cryptoValueText(
              value,
              suffix,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VALOR CRIPTO
  // ============================================================

  String _cryptoValueText(
    double value,
    String suffix,
  ) {
    if (!showBalances) {
      return '•••••• $suffix';
    }

    return '${_formatCrypto(value)} $suffix';
  }

  // ============================================================
  // VALOR MONETÁRIO
  // ============================================================

  String _valueText(
    double value,
  ) {
    if (!showBalances) {
      return 'R\$ ••••••';
    }

    return _currency(
      value,
    );
  }

  // ============================================================
  // FORMATAR CRIPTO
  // ============================================================

  String _formatCrypto(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    return safeValue.toStringAsFixed(
      8,
    );
  }

  // ============================================================
  // FORMATAR MOEDA
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
// FINANCE VALUE CARD
// ============================================================

class _FinanceValueCard
    extends
        StatelessWidget {
  const _FinanceValueCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;

  final String title;

  final String value;

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

          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
