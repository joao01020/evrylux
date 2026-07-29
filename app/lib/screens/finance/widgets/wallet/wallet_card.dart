import 'package:flutter/material.dart';

class WalletCard extends StatelessWidget {
  final double patrimony;

  final double invested;

  // Saldos vindos do CryptoController
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
  });

  @override
  Widget build(BuildContext context) {
    final hasCrypto = bitcoin > 0 || ethereum > 0 || solana > 0 || usdt > 0;

    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: onBalance,

                  child: Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: const Icon(Icons.account_balance_wallet, size: 28),
                  ),
                ),

                const SizedBox(width: 10),

                const Expanded(
                  child: Text(
                    "Carteira",

                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                crypto("₿", onBitcoin),

                crypto("Ξ", onEthereum),

                crypto("◎", onSolana),

                crypto("₮", onUsdt),

                const SizedBox(width: 10),

                GestureDetector(
                  onTap: onVault,

                  child: const Icon(
                    Icons.key_outlined,

                    size: 18,

                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _valueCard(
                    icon: Icons.account_balance,

                    title: "Patrimônio",

                    value: patrimony,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _valueCard(
                    icon: Icons.trending_up,

                    title: "Investido",

                    value: invested,
                  ),
                ),
              ],
            ),

            if (hasCrypto) ...[
              const SizedBox(height: 18),

              const Divider(),

              const SizedBox(height: 10),

              if (bitcoin > 0) _cryptoBalance("₿", bitcoin, "BTC", 8),

              if (ethereum > 0) _cryptoBalance("Ξ", ethereum, "ETH", 6),

              if (solana > 0) _cryptoBalance("◎", solana, "SOL", 4),

              if (usdt > 0) _cryptoBalance("₮", usdt, "USDT", 2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _cryptoBalance(
    String icon,

    double value,

    String symbol,

    int decimals,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),

      child: Row(
        children: [
          Text(
            icon,

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(width: 8),

          Text(
            "${value.toStringAsFixed(decimals)} $symbol",

            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _valueCard({
    required IconData icon,

    required String title,

    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.grey.shade100,

        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        children: [
          Icon(icon),

          const SizedBox(height: 8),

          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

          const SizedBox(height: 4),

          Text(
            "R\$ ${value.toStringAsFixed(2)}",

            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget crypto(String icon, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,

      child: Padding(
        padding: const EdgeInsets.only(left: 8),

        child: Text(
          icon,

          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
