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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (transactions.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
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
              final transaction = transactions[index];

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
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_bitcoin_rounded,
              size: 42,
              color: Colors.grey,
            ),

            SizedBox(
              height: 12,
            ),

            Text(
              'Nenhuma compra registrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(
              height: 4,
            ),

            Text(
              'As compras adicionadas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
