import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart';

import '../../models/crypto/crypto_transaction_model.dart';

import 'crypto_history_card.dart';
import 'add_crypto_dialog.dart';
import 'edit_crypto_dialog.dart';

class CryptoDialog
    extends
        StatefulWidget {
  final String symbol;

  const CryptoDialog({
    super.key,
    required this.symbol,
  });

  @override
  State<
    CryptoDialog
  >
  createState() => _CryptoDialogState();
}

class _CryptoDialogState
    extends
        State<
          CryptoDialog
        > {
  List<
    CryptoTransactionModel
  >
  transactions = [];

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<
    void
  >
  load() async {
    final result = await cryptoController.getBySymbol(
      widget.symbol,
    );

    if (!mounted) return;

    setState(
      () {
        transactions = result;
      },
    );
  }

  double get totalQuantity {
    return transactions.fold(
      0.0,
      (
        total,
        item,
      ) {
        return total +
            item.quantity;
      },
    );
  }

  double get totalInvested {
    return transactions.fold(
      0.0,
      (
        total,
        item,
      ) {
        return total +
            item.invested;
      },
    );
  }

  String title() {
    switch (widget.symbol) {
      case "BTC":
        return "Bitcoin";

      case "ETH":
        return "Ethereum";

      case "SOL":
        return "Solana";

      case "USDT":
        return "USDT";

      default:
        return widget.symbol;
    }
  }

  Future<
    void
  >
  add() async {
    await showDialog(
      context: context,

      builder:
          (
            context,
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

    load();
  }

  Future<
    void
  >
  edit(
    CryptoTransactionModel transaction,
  ) async {
    await showDialog(
      context: context,

      builder:
          (
            context,
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

    load();
  }

  Future<
    void
  >
  remove(
    CryptoTransactionModel transaction,
  ) async {
    await cryptoController.delete(
      transaction.id,
    );

    load();
  }

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

      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Text(
                    title(),

                    style: const TextStyle(
                      fontSize: 26,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(
                    16,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        "Saldo",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "${totalQuantity.toStringAsFixed(8)} ${widget.symbol}",

                        style: const TextStyle(
                          fontSize: 24,

                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Divider(),

                      const Text(
                        "Investido",

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        "R\$ ${totalInvested.toStringAsFixed(2)}",

                        style: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: add,

                  icon: const Icon(
                    Icons.add,
                  ),

                  label: const Text(
                    "Adicionar compra",
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Histórico",

                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              CryptoHistoryCard(
                transactions: transactions,

                onDelete: remove,

                onEdit: edit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
