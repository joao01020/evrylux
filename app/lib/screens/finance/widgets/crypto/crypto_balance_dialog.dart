import 'package:flutter/material.dart';

class CryptoBalanceDialog extends StatelessWidget {
  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  const CryptoBalanceDialog({
    super.key,

    required this.bitcoin,

    required this.ethereum,

    required this.solana,

    required this.usdt,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      title: const Row(
        children: [
          Icon(Icons.account_balance_wallet),

          SizedBox(width: 10),

          Text("Saldo da carteira"),
        ],
      ),

      content: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          crypto("₿", "Bitcoin", bitcoin.toStringAsFixed(8)),

          crypto("Ξ", "Ethereum", ethereum.toStringAsFixed(6)),

          crypto("◎", "Solana", solana.toStringAsFixed(4)),

          crypto("₮", "USDT", usdt.toStringAsFixed(2)),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },

          child: const Text("Fechar"),
        ),
      ],
    );
  }

  Widget crypto(String icon, String name, String value) {
    return Card(
      child: ListTile(
        leading: Text(
          icon,

          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),

        title: Text(name),

        trailing: Text(
          value,

          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
