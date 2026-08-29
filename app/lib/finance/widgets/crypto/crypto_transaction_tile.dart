import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/dependencies/app_dependencies.dart';

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
  // SYMBOL
  // ============================================================

  String get symbol {
    return transaction.symbol.trim().toUpperCase();
  }

  // ============================================================
  // QUANTITY
  // ============================================================

  double get quantity {
    final value = transaction.quantity;

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // INVESTED
  // ============================================================

  double get invested {
    final value = transaction.invested;

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // PREÇO DA COMPRA
  // ============================================================

  double get purchasePrice {
    if (quantity <=
            0 ||
        invested <=
            0) {
      return 0;
    }

    final value =
        invested /
        quantity;

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // COTAÇÃO ATUAL
  // ============================================================

  double get currentPrice {
    try {
      final value = cryptoController.priceFor(
        symbol,
      );

      if (!value.isFinite ||
          value <=
              0) {
        return 0;
      }

      return value;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO TRANSACTION TILE]'
        '[PRICE]'
        '[$symbol] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 0;
    }
  }

  // ============================================================
  // VALOR ATUAL
  // ============================================================

  double get currentValue {
    if (quantity <=
            0 ||
        currentPrice <=
            0) {
      return 0;
    }

    final value =
        quantity *
        currentPrice;

    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // RESULTADO
  // ============================================================

  double get result {
    if (invested <=
            0 ||
        currentPrice <=
            0) {
      return 0;
    }

    final value =
        currentValue -
        invested;

    if (!value.isFinite) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // RESULTADO %
  // ============================================================

  double get resultPercent {
    if (invested <=
            0 ||
        currentPrice <=
            0) {
      return 0;
    }

    final value =
        (result /
            invested) *
        100;

    if (!value.isFinite) {
      return 0;
    }

    return value;
  }

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

    return '${two(date.day)}/'
        '${two(date.month)}/'
        '${date.year}';
  }

  // ============================================================
  // CASAS DECIMAIS
  // ============================================================

  int _decimals(
    String symbol,
  ) {
    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
        return 8;

      case 'ETH':
        return 8;

      case 'SOL':
        return 8;

      case 'USDT':
        return 8;

      default:
        return 8;
    }
  }

  // ============================================================
  // FORMATAR QUANTIDADE
  // ============================================================

  String _formatQuantity(
    double value,
  ) {
    final safeValue =
        value.isFinite &&
            value >=
                0
        ? value
        : 0.0;

    return safeValue.toStringAsFixed(
      _decimals(
        symbol,
      ),
    );
  }

  // ============================================================
  // FORMATAR MOEDA
  // ============================================================

  String _formatCurrency(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final negative =
        safeValue <
        0;

    final absolute = safeValue.abs();

    final parts = absolute
        .toStringAsFixed(
          2,
        )
        .split(
          '.',
        );

    final integer = parts.first;

    final decimal =
        parts.length >
            1
        ? parts[1]
        : '00';

    final reversed = integer
        .split(
          '',
        )
        .reversed
        .toList();

    final buffer = StringBuffer();

    for (
      var index = 0;
      index <
          reversed.length;
      index++
    ) {
      if (index >
              0 &&
          index %
                  3 ==
              0) {
        buffer.write(
          '.',
        );
      }

      buffer.write(
        reversed[index],
      );
    }

    final formattedInteger = buffer
        .toString()
        .split(
          '',
        )
        .reversed
        .join();

    return '${negative ? '-' : ''}'
        'R\$ $formattedInteger,$decimal';
  }

  // ============================================================
  // FORMATAR MOEDA COM SINAL
  // ============================================================

  String _formatSignedCurrency(
    double value,
  ) {
    if (!value.isFinite) {
      return 'R\$ 0,00';
    }

    if (value >
        0) {
      return '+ ${_formatCurrency(value)}';
    }

    if (value <
        0) {
      return '- ${_formatCurrency(value.abs())}';
    }

    return _formatCurrency(
      0,
    );
  }

  // ============================================================
  // FORMATAR %
  // ============================================================

  String _formatPercent(
    double value,
  ) {
    final safeValue = value.isFinite
        ? value
        : 0.0;

    final sign =
        safeValue >
            0
        ? '+'
        : '';

    return '$sign'
        '${safeValue.toStringAsFixed(2).replaceAll('.', ',')}%';
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
                    '$symbol?\n\n'
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
  // MENU
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
  // LINHA DE INFORMAÇÃO
  // ============================================================

  Widget _infoRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(
        top: 4,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: bold
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final hasPrice =
        currentPrice >
        0;

    final positive =
        result >
        0;

    final negative =
        result <
        0;

    final resultColor = positive
        ? Colors.green
        : negative
        ? colorScheme.error
        : colorScheme.onSurfaceVariant;

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
        color: colorScheme.error,
        child: Icon(
          Icons.delete_outline_rounded,
          color: colorScheme.onError,
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

        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =================================================
              // ÍCONE
              // =================================================
              CircleAvatar(
                radius: 22,
                child: Text(
                  symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              // =================================================
              // INFORMAÇÕES
              // =================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===========================================
                    // DATA
                    // ===========================================
                    Text(
                      _formatDate(
                        transaction.date,
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // ===========================================
                    // QUANTIDADE
                    // ===========================================
                    Text(
                      '${_formatQuantity(quantity)} '
                      '$symbol',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 7,
                    ),

                    // ===========================================
                    // INVESTIDO
                    // ===========================================
                    _infoRow(
                      context: context,
                      label: 'Investido',
                      value: _formatCurrency(
                        invested,
                      ),
                      bold: true,
                    ),

                    // ===========================================
                    // PREÇO DA COMPRA
                    // ===========================================
                    if (purchasePrice >
                        0)
                      _infoRow(
                        context: context,
                        label: 'Preço da compra',
                        value:
                            '${_formatCurrency(purchasePrice)} / '
                            '$symbol',
                      ),

                    // ===========================================
                    // VALOR ATUAL
                    // ===========================================
                    if (hasPrice)
                      _infoRow(
                        context: context,
                        label: 'Valor atual',
                        value: _formatCurrency(
                          currentValue,
                        ),
                        bold: true,
                      ),

                    // ===========================================
                    // RESULTADO
                    // ===========================================
                    if (hasPrice)
                      _infoRow(
                        context: context,
                        label: 'Resultado',
                        value:
                            '${_formatSignedCurrency(result)}  '
                            '${_formatPercent(resultPercent)}',
                        valueColor: resultColor,
                        bold: true,
                      ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              // =================================================
              // MENU
              // =================================================
              _buildOptionsMenu(
                context,
              ),
            ],
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
