import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/crypto/crypto_transaction_model.dart';

class CryptoTransactionTile
    extends
        StatelessWidget {
  const CryptoTransactionTile({
    super.key,
    required this.transaction,
    required this.onDelete,
    required this.onEdit,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final CryptoTransactionModel transaction;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onDelete;

  final VoidCallback onEdit;

  // ============================================================
  // FORMATAR DATA
  // ============================================================

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

    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  // ============================================================
  // CASAS DECIMAIS
  // ============================================================

  int _decimals(
    String symbol,
  ) {
    switch (symbol.toUpperCase()) {
      case 'BTC':
        return 8;

      case 'ETH':
        return 6;

      case 'SOL':
        return 4;

      case 'USDT':
        return 8;

      default:
        return 6;
    }
  }

  // ============================================================
  // FORMATAR VALOR
  // ============================================================

  String _formatCurrency(
    double value,
  ) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // CONFIRMAR EXCLUSÃO
  // ============================================================

  Future<
    bool
  >
  _confirmDelete(
    BuildContext context,
  ) async {
    final result =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir compra?',
                  ),
                  content: Text(
                    'Deseja realmente excluir esta compra de '
                    '${transaction.symbol}?\n\n'
                    'Esta operação não poderá ser desfeita.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      child: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    return result ??
        false;
  }

  // ============================================================
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  _handleDelete(
    BuildContext context,
  ) async {
    final confirmed = await _confirmDelete(
      context,
    );

    if (!confirmed) {
      return;
    }

    onDelete();
  }

  // ============================================================
  // MENU DOS TRÊS PONTOS
  // ============================================================

  Widget _buildOptionsMenu(
    BuildContext context,
  ) {
    return PopupMenuButton<
      _CryptoTransactionAction
    >(
      tooltip: 'Opções',
      icon: const Icon(
        Icons.more_horiz,
      ),
      onSelected:
          (
            action,
          ) async {
            switch (action) {
              case _CryptoTransactionAction.edit:
                HapticFeedback.selectionClick();

                onEdit();

                break;

              case _CryptoTransactionAction.delete:
                HapticFeedback.mediumImpact();

                await _handleDelete(
                  context,
                );

                break;
            }
          },
      itemBuilder:
          (
            context,
          ) {
            return const [
              PopupMenuItem<
                _CryptoTransactionAction
              >(
                value: _CryptoTransactionAction.edit,
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      size: 20,
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(
                      'Editar',
                    ),
                  ],
                ),
              ),

              PopupMenuDivider(),

              PopupMenuItem<
                _CryptoTransactionAction
              >(
                value: _CryptoTransactionAction.delete,
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                    ),

                    SizedBox(
                      width: 12,
                    ),

                    Text(
                      'Excluir',
                    ),
                  ],
                ),
              ),
            ];
          },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dismissible(
      key: ValueKey(
        transaction.id,
      ),

      // ========================================================
      // ARRASTAR PARA EXCLUIR
      // ========================================================
      direction: DismissDirection.endToStart,

      confirmDismiss:
          (
            direction,
          ) async {
            return _confirmDelete(
              context,
            );
          },

      onDismissed:
          (
            direction,
          ) {
            onDelete();
          },

      // ========================================================
      // FUNDO DA EXCLUSÃO
      // ========================================================
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(
          right: 24,
        ),
        color: Theme.of(
          context,
        ).colorScheme.error,
        child: Icon(
          Icons.delete_outline_rounded,
          color: Theme.of(
            context,
          ).colorScheme.onError,
          size: 30,
        ),
      ),

      // ========================================================
      // ITEM
      // ========================================================
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ======================================================
        // SEGURAR PARA EDITAR
        // ======================================================
        onLongPress: () {
          HapticFeedback.mediumImpact();

          onEdit();
        },

        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),

          // ====================================================
          // ÍCONE
          // ====================================================
          leading: CircleAvatar(
            radius: 22,
            child: Text(
              transaction.symbol.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),

          // ====================================================
          // DATA
          // ====================================================
          title: Text(
            _formatDate(
              transaction.date,
            ),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          // ====================================================
          // QUANTIDADE + INVESTIDO
          // ====================================================
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 5,
              ),

              Text(
                '${transaction.quantity.toStringAsFixed(_decimals(transaction.symbol))} ${transaction.symbol.toUpperCase()}',
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                _formatCurrency(
                  transaction.invested,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // ====================================================
          // MENU
          // ====================================================
          trailing: _buildOptionsMenu(
            context,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// AÇÕES DO MENU
// ============================================================

enum _CryptoTransactionAction {
  edit,
  delete,
}
