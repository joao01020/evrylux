import 'package:flutter/material.dart';

import '../../../models/finance/crypto_transaction_model.dart';
import 'crypto_transaction_tile.dart';

class CryptoHistoryCard
    extends
        StatelessWidget {
  final List<
    CryptoTransactionModel
  >
  transactions;

  final Function(
    CryptoTransactionModel,
  )
  onDelete;

  final Function(
    CryptoTransactionModel,
  )
  onEdit;

  const CryptoHistoryCard({
    super.key,

    required this.transactions,

    required this.onDelete,

    required this.onEdit,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    if (transactions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              const Icon(
                Icons.currency_bitcoin,

                size: 42,

                color: Colors.grey,
              ),

              const SizedBox(
                height: 12,
              ),

              const Text(
                "Nenhuma compra registrada.",

                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,

      child: ListView.separated(
        shrinkWrap: true,

        physics: const NeverScrollableScrollPhysics(),

        itemCount: transactions.length,

        separatorBuilder:
            (
              _,
              index,
            ) {
              return const Divider(
                height: 1,
              );
            },

        itemBuilder:
            (
              context,
              index,
            ) {
              final item = transactions[index];

              return CryptoTransactionTile(
                transaction: item,

                onDelete: () {
                  onDelete(
                    item,
                  );
                },

                onEdit: () {
                  onEdit(
                    item,
                  );
                },
              );
            },
      ),
    );
  }
}
