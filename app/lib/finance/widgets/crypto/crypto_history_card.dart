import 'package:flutter/material.dart';

import '../../models/crypto/crypto_transaction_model.dart';
import 'crypto_transaction_tile.dart';

class CryptoHistoryCard
    extends
        StatelessWidget {
  const CryptoHistoryCard({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final List<
    CryptoTransactionModel
  >
  transactions;

  // ============================================================
  // AÇÕES
  // ============================================================

  final ValueChanged<
    CryptoTransactionModel
  >
  onDelete;

  final ValueChanged<
    CryptoTransactionModel
  >
  onEdit;

  // ============================================================
  // TRANSAÇÕES ORDENADAS
  // ============================================================

  List<
    CryptoTransactionModel
  >
  get sortedTransactions {
    final items =
        List<
          CryptoTransactionModel
        >.from(
          transactions,
        );

    items.sort(
      (
        a,
        b,
      ) {
        return b.date.compareTo(
          a.date,
        );
      },
    );

    return items;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState(
        context,
      );
    }

    final items = sortedTransactions;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // LISTA
          // ====================================================
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder:
                (
                  context,
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
                  final transaction = items[index];

                  return CryptoTransactionTile(
                    transaction: transaction,

                    onEdit: () {
                      onEdit(
                        transaction,
                      );
                    },

                    onDelete: () {
                      onDelete(
                        transaction,
                      );
                    },
                  );
                },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_bitcoin_rounded,
              size: 42,
              color: colorScheme.onSurfaceVariant,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Nenhuma compra registrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              'As compras adicionadas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
