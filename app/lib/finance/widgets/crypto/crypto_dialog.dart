import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';

import '../../models/crypto/crypto_transaction_model.dart';

import 'add_crypto_dialog.dart';
import 'crypto_history_card.dart';
import 'edit_crypto_dialog.dart';

class CryptoDialog
    extends
        StatefulWidget {
  const CryptoDialog({
    super.key,
    required this.symbol,
  });

  final String symbol;

  @override
  State<
    CryptoDialog
  >
  createState() {
    return _CryptoDialogState();
  }
}

class _CryptoDialogState
    extends
        State<
          CryptoDialog
        > {
  // ============================================================
  // STATE
  // ============================================================

  List<
    CryptoTransactionModel
  >
  transactions = [];

  bool isLoading = true;

  String? errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load() async {
    if (!mounted) {
      return;
    }

    setState(
      () {
        isLoading = true;
        errorMessage = null;
      },
    );

    try {
      final result = await cryptoController.getBySymbol(
        widget.symbol,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          transactions =
              List<
                CryptoTransactionModel
              >.from(
                result,
              );
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][LOAD] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          errorMessage = 'Não foi possível carregar ${widget.symbol}.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            isLoading = false;
          },
        );
      }
    }
  }

  // ============================================================
  // TOTAL QUANTITY
  // ============================================================

  double get totalQuantity {
    return transactions.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.quantity;
      },
    );
  }

  // ============================================================
  // TOTAL INVESTED
  // ============================================================

  double get totalInvested {
    return transactions.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.invested;
      },
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  String get cryptoTitle {
    switch (widget.symbol.trim().toUpperCase()) {
      case 'BTC':
        return 'Bitcoin';

      case 'ETH':
        return 'Ethereum';

      case 'SOL':
        return 'Solana';

      case 'USDT':
        return 'USDT';

      default:
        return widget.symbol.toUpperCase();
    }
  }

  // ============================================================
  // DECIMALS
  // ============================================================

  int get quantityDecimals {
    switch (widget.symbol.trim().toUpperCase()) {
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
  // FORMAT CURRENCY
  // ============================================================

  String _formatCurrency(
    double value,
  ) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  // ============================================================
  // ADD
  // ============================================================

  Future<
    void
  >
  add() async {
    try {
      await showDialog<
        void
      >(
        context: context,
        builder:
            (
              dialogContext,
            ) {
              return AddCryptoDialog(
                symbol: widget.symbol,
                onSave:
                    (
                      transaction,
                    ) {
                      return cryptoController.add(
                        transaction,
                      );
                    },
              );
            },
      );

      if (!mounted) {
        return;
      }

      await load();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][ADD] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível adicionar a compra.',
        );
      }
    }
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<
    void
  >
  edit(
    CryptoTransactionModel transaction,
  ) async {
    try {
      await showDialog<
        void
      >(
        context: context,
        builder:
            (
              dialogContext,
            ) {
              return EditCryptoDialog(
                transaction: transaction,
                onSave:
                    (
                      updated,
                    ) {
                      return cryptoController.update(
                        updated,
                      );
                    },
              );
            },
      );

      if (!mounted) {
        return;
      }

      await load();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][EDIT] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível atualizar a compra.',
        );
      }
    }
  }

  // ============================================================
  // REMOVE
  // ============================================================

  Future<
    void
  >
  remove(
    CryptoTransactionModel transaction,
  ) async {
    try {
      await cryptoController.delete(
        transaction.id,
      );

      if (!mounted) {
        return;
      }

      await load();

      if (mounted) {
        _showMessage(
          'Compra excluída.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[CRYPTO DIALOG][DELETE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (mounted) {
        _showMessage(
          'Não foi possível excluir a compra.',
        );
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cryptoTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                widget.symbol.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: () {
            Navigator.of(
              context,
            ).pop();
          },
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saldo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              '${totalQuantity.toStringAsFixed(quantityDecimals)} '
              '${widget.symbol.toUpperCase()}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Divider(),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Investido',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              _formatCurrency(
                totalInvested,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ADD BUTTON
  // ============================================================

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading
            ? null
            : add,
        icon: const Icon(
          Icons.add_rounded,
        ),
        label: const Text(
          'Adicionar compra',
        ),
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Widget _buildHistory() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(
          vertical: 32,
        ),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (errorMessage !=
        null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 36,
              ),

              const SizedBox(
                height: 10,
              ),

              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 12,
              ),

              OutlinedButton.icon(
                onPressed: load,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Tentar novamente',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CryptoHistoryCard(
      transactions: transactions,
      onDelete: remove,
      onEdit: edit,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 560,
        ),
        child: Padding(
          padding: const EdgeInsets.all(
            20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),

                const SizedBox(
                  height: 20,
                ),

                _buildSummary(),

                const SizedBox(
                  height: 20,
                ),

                _buildAddButton(),

                const SizedBox(
                  height: 24,
                ),

                const Text(
                  'Histórico',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
