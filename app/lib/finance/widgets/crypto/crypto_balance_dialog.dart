import 'package:flutter/material.dart';

class CryptoBalanceDialog
    extends
        StatelessWidget {
  const CryptoBalanceDialog({
    super.key,
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,
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
  // AÇÕES
  // ============================================================

  final VoidCallback onEditBitcoin;
  final VoidCallback onEditEthereum;
  final VoidCallback onEditSolana;
  final VoidCallback onEditUsdt;

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
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _crypto(
              context: context,
              icon: '₿',
              name: 'Bitcoin',
              symbol: 'BTC',
              value: bitcoin.toStringAsFixed(
                8,
              ),
              onEdit: onEditBitcoin,
            ),

            _crypto(
              context: context,
              icon: 'Ξ',
              name: 'Ethereum',
              symbol: 'ETH',
              value: ethereum.toStringAsFixed(
                6,
              ),
              onEdit: onEditEthereum,
            ),

            _crypto(
              context: context,
              icon: '◎',
              name: 'Solana',
              symbol: 'SOL',
              value: solana.toStringAsFixed(
                4,
              ),
              onEdit: onEditSolana,
            ),

            _crypto(
              context: context,
              icon: '₮',
              name: 'USDT',
              symbol: 'USDT',
              value: usdt.toStringAsFixed(
                8,
              ),
              onEdit: onEditUsdt,
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
  // CRYPTO
  // ============================================================

  Widget _crypto({
    required BuildContext context,
    required String icon,
    required String name,
    required String symbol,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      child: ListTile(
        onTap: onEdit,
        leading: SizedBox(
          width: 40,
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
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          symbol,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Icon(
              Icons.edit_outlined,
              size: 18,
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
