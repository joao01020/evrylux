import 'package:flutter/material.dart';

class WalletCard
    extends
        StatelessWidget {
  final double invested;

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  final VoidCallback onBitcoin;

  final VoidCallback onEthereum;

  final VoidCallback onSolana;

  final VoidCallback onUsdt;

  final VoidCallback onVault;

  const WalletCard({
    super.key,

    required this.invested,

    required this.bitcoin,

    required this.ethereum,

    required this.solana,

    required this.usdt,

    required this.onBitcoin,

    required this.onEthereum,

    required this.onSolana,

    required this.onUsdt,

    required this.onVault,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(
          Icons.account_balance_wallet,
        ),

        title: Row(
          children: [
            const Text(
              "Patrimônio",
            ),

            const SizedBox(
              width: 12,
            ),

            crypto(
              "₿",
              onBitcoin,
            ),

            crypto(
              "Ξ",
              onEthereum,
            ),

            crypto(
              "◎",
              onSolana,
            ),

            crypto(
              "₮",
              onUsdt,
            ),

            const SizedBox(
              width: 12,
            ),

            // Cofre discreto
            GestureDetector(
              onTap: onVault,

              child: const Icon(
                Icons.key_outlined,

                size: 16,

                color: Colors.grey,
              ),
            ),
          ],
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              "R\$ ${invested.toStringAsFixed(2)}",
            ),

            if (bitcoin >
                0)
              Text(
                "${bitcoin.toStringAsFixed(6)} BTC",
              ),

            if (ethereum >
                0)
              Text(
                "${ethereum.toStringAsFixed(4)} ETH",
              ),

            if (solana >
                0)
              Text(
                "${solana.toStringAsFixed(3)} SOL",
              ),

            if (usdt >
                0)
              Text(
                "${usdt.toStringAsFixed(2)} USDT",
              ),
          ],
        ),
      ),
    );
  }

  Widget crypto(
    String icon,

    VoidCallback tap,
  ) {
    return GestureDetector(
      onTap: tap,

      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
        ),

        child: Text(
          icon,

          style: const TextStyle(
            fontSize: 20,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
