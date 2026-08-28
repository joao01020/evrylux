import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/crypto/crypto_transaction_model.dart';

class CryptoTransactionTile
    extends
        StatelessWidget {
  final CryptoTransactionModel transaction;

  final VoidCallback onDelete;

  final VoidCallback onEdit;

  const CryptoTransactionTile({
    super.key,

    required this.transaction,

    required this.onDelete,

    required this.onEdit,
  });

  String _formatDate(
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

    return "${two(date.day)}/${two(date.month)}/${date.year}";
  }

  int _decimals(
    String symbol,
  ) {
    switch (symbol) {
      case "BTC":
        return 8;

      case "ETH":
        return 6;

      case "SOL":
        return 4;

      case "USDT":
        return 2;

      default:
        return 6;
    }
  }

  Future<
    bool?
  >
  _confirmDelete(
    BuildContext context,
  ) {
    return showDialog<
      bool
    >(
      context: context,

      builder:
          (
            context,
          ) {
            return AlertDialog(
              title: const Text(
                "Excluir compra?",
              ),

              content: const Text(
                "Esta operação não poderá ser desfeita.",
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      false,
                    );
                  },

                  child: const Text(
                    "Cancelar",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },

                  child: const Text(
                    "Excluir",
                  ),
                ),
              ],
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dismissible(
      key: ValueKey(
        transaction.id,
      ),

      direction: DismissDirection.endToStart,

      confirmDismiss:
          (
            direction,
          ) async {
            final result = await _confirmDelete(
              context,
            );

            return result ??
                false;
          },

      onDismissed:
          (
            direction,
          ) {
            onDelete();
          },

      background: Container(
        alignment: Alignment.centerRight,

        padding: const EdgeInsets.only(
          right: 24,
        ),

        color: Colors.red,

        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 30,
        ),
      ),

      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.mediumImpact();

          onEdit();
        },

        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,

            vertical: 10,
          ),

          leading: CircleAvatar(
            radius: 22,

            child: Text(
              transaction.symbol,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),

          title: Text(
            _formatDate(
              transaction.date,
            ),

            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(
                height: 5,
              ),

              Text(
                "${transaction.quantity.toStringAsFixed(_decimals(transaction.symbol))} ${transaction.symbol}",
              ),

              Text(
                "R\$ ${transaction.invested.toStringAsFixed(2)}",

                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          trailing: const Icon(
            Icons.more_horiz,
          ),
        ),
      ),
    );
  }
}
