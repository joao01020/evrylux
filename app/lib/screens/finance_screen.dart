import 'package:flutter/material.dart';

import '../app_dependencies.dart';
import '../widgets/finance/wallet_card.dart';
import '../widgets/finance/crypto_dialog.dart';
import 'vault_screen.dart';

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

  @override
  void initState() {
    super.initState();

    _controller.loadData().then(
      (
        _,
      ) {
        if (mounted) {
          setState(
            () {},
          );
        }
      },
    );
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
                keyboardType: TextInputType.number,
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

  void openCryptoDialog(
    String name,
    String symbol,
    Function(
      double,
    )
    save,
  ) {
    showDialog(
      context: context,
      builder:
          (
            _,
          ) {
            return CryptoDialog(
              name: name,
              symbol: symbol,
              onSave:
                  (
                    value,
                  ) {
                    setState(
                      () {
                        save(
                          value,
                        );
                        _controller.saveData();
                      },
                    );
                  },
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
              invested: model.invested,
              bitcoin: model.bitcoin,
              ethereum: model.ethereum,
              solana: model.solana,
              usdt: model.usdt,
              onBitcoin: () {
                openCryptoDialog(
                  "Bitcoin",
                  "₿",
                  (
                    value,
                  ) {
                    model.bitcoin = value;
                  },
                );
              },
              onEthereum: () {
                openCryptoDialog(
                  "Ethereum",
                  "Ξ",
                  (
                    value,
                  ) {
                    model.ethereum = value;
                  },
                );
              },
              onSolana: () {
                openCryptoDialog(
                  "Solana",
                  "◎",
                  (
                    value,
                  ) {
                    model.solana = value;
                  },
                );
              },
              onUsdt: () {
                openCryptoDialog(
                  "USDT",
                  "₮",
                  (
                    value,
                  ) {
                    model.usdt = value;
                  },
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
                  icon: "💰",
                  title: "Investido",
                  value: "R\$ ${model.invested.toStringAsFixed(2)}",
                  onTap: () {
                    editValue(
                      title: "Adicionar investimento",
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
                  value: "R\$ ${model.monthlyGoal.toStringAsFixed(0)}",
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
                financeMiniCard(
                  icon: "🏦",
                  title: "Patrimônio",
                  value: "R\$ ${model.investmentGoal.toStringAsFixed(0)}",
                  onTap: () {
                    editValue(
                      title: "Editar patrimônio",
                      currentValue: model.investmentGoal,
                      onSave:
                          (
                            value,
                          ) {
                            model.investmentGoal = value;
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
