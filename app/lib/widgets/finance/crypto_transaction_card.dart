import 'package:flutter/material.dart';

import '../../models/finance/crypto_transaction_model.dart';

class CryptoTransactionCard
    extends
        StatelessWidget {
  final CryptoTransactionModel transaction;

  final VoidCallback onDelete;

  final VoidCallback onEdit;

  const CryptoTransactionCard({
    super.key,

    required this.transaction,

    required this.onDelete,

    required this.onEdit,
  });

  String formatDate(
    DateTime date,
  ) {
    final day = date.day.toString().padLeft(
      2,
      "0",
    );

    final month = date.month.toString().padLeft(
      2,
      "0",
    );

    return "$day/$month/${date.year}";
  }

  int decimalPlaces(
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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dismissible(
      key: ValueKey(
        transaction.id,
      ),

      direction: DismissDirection.endToStart,

      background: Container(
        alignment: Alignment.centerRight,

        padding: const EdgeInsets.only(
          right: 24,
        ),

        color: Colors.red,

        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),

      confirmDismiss:
          (
            direction,
          ) async {
            return await showDialog<
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
                            "Essa operação será removida do histórico.",
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
                ) ??
                false;
          },

      onDismissed:
          (
            direction,
          ) {
            onDelete();
          },

      child: GestureDetector(
        onLongPress: onEdit,

        child: Card(
          margin: const EdgeInsets.symmetric(
            vertical: 6,
          ),

          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),

            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    transaction.symbol,

                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 14,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        formatDate(
                          transaction.date,
                        ),

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        "${transaction.quantity.toStringAsFixed(decimalPlaces(transaction.symbol))} ${transaction.symbol}",
                      ),

                      Text(
                        "R\$ ${transaction.invested.toStringAsFixed(2)}",

                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.more_vert,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
