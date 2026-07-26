import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

import '../../widgets/finance/wallet_card.dart';
import '../../widgets/finance/crypto_dialog.dart';
import '../../widgets/finance/crypto_balance_dialog.dart';

import 'vault/vault_screen.dart';

class FinanceScreen
    extends
        StatefulWidget {
  const FinanceScreen({
    super.key,
  });

  @override
  State<
    FinanceScreen
  >
  createState() => _FinanceScreenState();
}

class _FinanceScreenState
    extends
        State<
          FinanceScreen
        > {
  final _controller = financeController;

  double bitcoin = 0;

  double ethereum = 0;

  double solana = 0;

  double usdt = 0;

  @override
  void initState() {
    super.initState();

    loadFinance();

    loadCryptoBalances();
  }

  Future<
    void
  >
  loadFinance() async {
    await _controller.loadData();

    if (mounted) {
      setState(
        () {},
      );
    }
  }

  Future<
    void
  >
  loadCryptoBalances() async {
    await cryptoController.load(
      "BTC",
    );

    bitcoin = cryptoController.quantity;

    await cryptoController.load(
      "ETH",
    );

    ethereum = cryptoController.quantity;

    await cryptoController.load(
      "SOL",
    );

    solana = cryptoController.quantity;

    await cryptoController.load(
      "USDT",
    );

    usdt = cryptoController.quantity;

    if (mounted) {
      setState(
        () {},
      );
    }
  }

  void openVault() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder:
            (
              _,
            ) => const VaultScreen(),
      ),
    );
  }

  void openCryptoDialog(
    String symbol,
  ) {
    showDialog(
      context: context,

      builder:
          (
            _,
          ) {
            return CryptoDialog(
              symbol: symbol,
            );
          },
    ).then(
      (
        _,
      ) {
        loadCryptoBalances();
      },
    );
  }

  void openBalance() {
    showDialog(
      context: context,

      builder:
          (
            _,
          ) {
            return CryptoBalanceDialog(
              bitcoin: bitcoin,

              ethereum: ethereum,

              solana: solana,

              usdt: usdt,
            );
          },
    );
  }

  void editValue({
    required String title,

    required double currentValue,

    required Function(
      double,
    )
    onSave,
  }) {
    final controller = TextEditingController(
      text: currentValue.toString(),
    );

    showDialog(
      context: context,

      builder:
          (
            _,
          ) {
            return AlertDialog(
              title: Text(
                title,
              ),

              content: TextField(
                controller: controller,

                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),

                decoration: const InputDecoration(
                  labelText: "Valor",
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Cancelar",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    final value =
                        double.tryParse(
                          controller.text.replaceAll(
                            ",",
                            ".",
                          ),
                        ) ??
                        currentValue;

                    setState(
                      () {
                        onSave(
                          value,
                        );

                        _controller.saveData();
                      },
                    );

                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Salvar",
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget financeMiniCard({
    required String icon,

    required String title,

    required String value,

    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,

        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(
              10,
            ),

            child: Column(
              children: [
                Text(
                  icon,

                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  title,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 11,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  value,

                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final model = _controller.model;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Financeiro 💰",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Sua liberdade financeira começa aqui.",

              style: TextStyle(
                fontSize: 28,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              "Construa patrimônio investindo um pouco toda semana.",

              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            WalletCard(
              patrimony: model.patrimony,

              invested: model.invested,

              bitcoin: bitcoin,

              ethereum: ethereum,

              solana: solana,

              usdt: usdt,

              onBalance: openBalance,

              onBitcoin: () {
                openCryptoDialog(
                  "BTC",
                );
              },

              onEthereum: () {
                openCryptoDialog(
                  "ETH",
                );
              },

              onSolana: () {
                openCryptoDialog(
                  "SOL",
                );
              },

              onUsdt: () {
                openCryptoDialog(
                  "USDT",
                );
              },

              onVault: openVault,
            ),

            const SizedBox(
              height: 24,
            ),

            Row(
              children: [
                financeMiniCard(
                  icon: "💼",

                  title: "Patrimônio",

                  value: "R\$ ${model.patrimony.toStringAsFixed(2)}",

                  onTap: () {
                    editValue(
                      title: "Editar patrimônio",

                      currentValue: model.patrimony,

                      onSave:
                          (
                            value,
                          ) {
                            model.patrimony = value;
                          },
                    );
                  },
                ),

                financeMiniCard(
                  icon: "💰",

                  title: "Investido",

                  value: "R\$ ${model.invested.toStringAsFixed(2)}",

                  onTap: () {
                    editValue(
                      title: "Editar investimento",

                      currentValue: model.invested,

                      onSave:
                          (
                            value,
                          ) {
                            model.invested = value;
                          },
                    );
                  },
                ),

                financeMiniCard(
                  icon: "🎯",

                  title: "Meta mensal",

                  value: "R\$ ${model.monthlyGoal.toStringAsFixed(2)}",

                  onTap: () {
                    editValue(
                      title: "Editar meta mensal",

                      currentValue: model.monthlyGoal,

                      onSave:
                          (
                            value,
                          ) {
                            model.monthlyGoal = value;
                          },
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
