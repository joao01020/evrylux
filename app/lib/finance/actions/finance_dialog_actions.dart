/*
|--------------------------------------------------------------------------
| FINANCE DIALOG ACTIONS
|--------------------------------------------------------------------------
|
| Responsável por:
|
| - diálogo de criptomoeda
| - diálogo de saldo
| - edição manual dos saldos crypto
| - planejamento
| - edição de patrimônio
| - edição da meta
| - mensagem do histórico
|
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/finance_screen_controller.dart';

import '../services/history/investment_history.dart';

import '../utils/finance_screen_formatter.dart';

import '../widgets/crypto/crypto_balance_dialog.dart';
import '../widgets/crypto/crypto_dialog.dart';

import '../widgets/dialogs/edit_finance_value_dialog.dart';
import '../widgets/dialogs/finance_planning_dialog.dart';

class FinanceDialogActions {
  const FinanceDialogActions({
    required this.context,
    required this.controller,
    required this.refresh,
    required this.isMounted,
    required this.showMessage,
  });

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final BuildContext context;

  final FinanceScreenController controller;

  final VoidCallback refresh;

  final bool Function() isMounted;

  final ValueChanged<
    String
  >
  showMessage;

  // ============================================================
  // ABRIR CRIPTOMOEDA
  // ============================================================

  Future<
    void
  >
  openCrypto(
    String symbol,
  ) async {
    await showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return CryptoDialog(
              symbol: symbol,
            );
          },
    );

    if (!isMounted()) {
      return;
    }

    try {
      // ========================================================
      // ATUALIZA CRYPTO
      // ========================================================
      //
      // O CryptoDialog pode:
      //
      // - adicionar compra
      // - editar compra
      // - excluir compra
      //
      // Por isso, depois que ele fecha, recalculamos:
      //
      // - quantidades
      // - investido
      // - valor atual
      // - lucro/prejuízo
      //
      // ========================================================

      await controller.refreshCryptoBalances();

      if (!isMounted()) {
        return;
      }

      refresh();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG][CRYPTO][REFRESH] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (isMounted()) {
        showMessage(
          'Não foi possível atualizar os saldos das criptomoedas.',
        );
      }
    }
  }

  // ============================================================
  // ABRIR SALDO DAS CRIPTOMOEDAS
  // ============================================================

  Future<
    void
  >
  openCryptoBalance() async {
    final balances = controller.balances;

    // ==========================================================
    // BTC
    // ==========================================================

    final bitcoinCurrentValue = _cryptoCurrentValue(
      symbol: 'BTC',
      quantity: balances.bitcoin,
    );

    final bitcoinProfitPercent = _cryptoProfitPercent(
      symbol: 'BTC',
      currentValue: bitcoinCurrentValue,
    );

    // ==========================================================
    // ETH
    // ==========================================================

    final ethereumCurrentValue = _cryptoCurrentValue(
      symbol: 'ETH',
      quantity: balances.ethereum,
    );

    final ethereumProfitPercent = _cryptoProfitPercent(
      symbol: 'ETH',
      currentValue: ethereumCurrentValue,
    );

    // ==========================================================
    // SOL
    // ==========================================================

    final solanaCurrentValue = _cryptoCurrentValue(
      symbol: 'SOL',
      quantity: balances.solana,
    );

    final solanaProfitPercent = _cryptoProfitPercent(
      symbol: 'SOL',
      currentValue: solanaCurrentValue,
    );

    // ==========================================================
    // USDT
    // ==========================================================

    final usdtCurrentValue = _cryptoCurrentValue(
      symbol: 'USDT',
      quantity: balances.usdt,
    );

    final usdtProfitPercent = _cryptoProfitPercent(
      symbol: 'USDT',
      currentValue: usdtCurrentValue,
    );

    // ==========================================================
    // DIALOG
    // ==========================================================

    await showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return CryptoBalanceDialog(
              // ====================================================
              // SALDOS
              // ====================================================
              bitcoin: balances.bitcoin,

              ethereum: balances.ethereum,

              solana: balances.solana,

              usdt: balances.usdt,

              // ====================================================
              // VALORES ATUAIS
              // ====================================================
              bitcoinCurrentValue: bitcoinCurrentValue,

              ethereumCurrentValue: ethereumCurrentValue,

              solanaCurrentValue: solanaCurrentValue,

              usdtCurrentValue: usdtCurrentValue,

              // ====================================================
              // RESULTADO %
              // ====================================================
              bitcoinProfitPercent: bitcoinProfitPercent,

              ethereumProfitPercent: ethereumProfitPercent,

              solanaProfitPercent: solanaProfitPercent,

              usdtProfitPercent: usdtProfitPercent,

              // ====================================================
              // BTC
              // ====================================================
              onEditBitcoin: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _editCryptoBalance(
                  symbol: 'BTC',
                  currentValue: balances.bitcoin,
                );
              },

              // ====================================================
              // ETH
              // ====================================================
              onEditEthereum: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _editCryptoBalance(
                  symbol: 'ETH',
                  currentValue: balances.ethereum,
                );
              },

              // ====================================================
              // SOL
              // ====================================================
              onEditSolana: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _editCryptoBalance(
                  symbol: 'SOL',
                  currentValue: balances.solana,
                );
              },

              // ====================================================
              // USDT
              // ====================================================
              onEditUsdt: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _editCryptoBalance(
                  symbol: 'USDT',
                  currentValue: balances.usdt,
                );
              },
            );
          },
    );
  }

  // ============================================================
  // VALOR ATUAL DA CRIPTOMOEDA
  // ============================================================
  //
  // Usa:
  //
  // quantidade × cotação atual em BRL
  //
  // Exemplo:
  //
  // 0.001 BTC × R$ 400.000
  //
  // = R$ 400
  //
  // ============================================================

  double _cryptoCurrentValue({
    required String symbol,
    required double quantity,
  }) {
    if (!quantity.isFinite ||
        quantity <=
            0) {
      return 0;
    }

    try {
      final price = controller.cryptoController.priceFor(
        symbol,
      );

      final safePrice =
          price
              is num
          ? price.toDouble()
          : 0.0;

      if (!safePrice.isFinite ||
          safePrice <=
              0) {
        return 0;
      }

      final result =
          quantity *
          safePrice;

      if (!result.isFinite ||
          result <
              0) {
        return 0;
      }

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG]'
        '[CRYPTO CURRENT VALUE]'
        '[$symbol] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 0;
    }
  }

  // ============================================================
  // RESULTADO %
  // ============================================================
  //
  // Resultado:
  //
  // valor atual - investido
  //
  // Percentual:
  //
  // resultado / investido × 100
  //
  // ============================================================

  double _cryptoProfitPercent({
    required String symbol,
    required double currentValue,
  }) {
    try {
      final invested = controller.cryptoController.investedFor(
        symbol,
      );

      final safeInvested =
          invested
              is num
          ? invested.toDouble()
          : 0.0;

      if (!safeInvested.isFinite ||
          safeInvested <=
              0) {
        return 0;
      }

      if (!currentValue.isFinite ||
          currentValue <
              0) {
        return 0;
      }

      final result =
          currentValue -
          safeInvested;

      final percent =
          (result /
              safeInvested) *
          100;

      if (!percent.isFinite) {
        return 0;
      }

      return percent;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG]'
        '[CRYPTO PROFIT PERCENT]'
        '[$symbol] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      return 0;
    }
  }

  // ============================================================
  // EDITAR SALDO CRYPTO
  // ============================================================

  Future<
    void
  >
  _editCryptoBalance({
    required String symbol,
    required double currentValue,
  }) async {
    if (!isMounted()) {
      return;
    }

    final textController = TextEditingController(
      text: currentValue
          .toStringAsFixed(
            _cryptoDecimals(
              symbol,
            ),
          )
          .replaceAll(
            '.',
            ',',
          ),
    );

    final result =
        await showDialog<
          String
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child: Text(
                          'Editar $symbol',
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informe manualmente o saldo atual de $symbol.',
                          style: TextStyle(
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        TextField(
                          controller: textController,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(
                                r'[0-9.,]',
                              ),
                            ),
                          ],
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Saldo',
                            hintText: _cryptoHint(
                              symbol,
                            ),
                            suffixText: symbol,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted:
                              (
                                value,
                              ) {
                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  value,
                                );
                              },
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          'Esse valor pode ser alterado novamente a qualquer momento.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          textController.text,
                        );
                      },
                      icon: const Icon(
                        Icons.save_outlined,
                      ),
                      label: const Text(
                        'Salvar',
                      ),
                    ),
                  ],
                );
              },
        );

    textController.dispose();

    if (result ==
            null ||
        !isMounted()) {
      return;
    }

    final value = _parseCryptoValue(
      result,
    );

    if (value ==
            null ||
        value <
            0) {
      showMessage(
        'Digite um saldo válido.',
      );

      return;
    }

    try {
      // ========================================================
      // ATUALIZA MODEL
      // ========================================================

      _setCryptoBalance(
        symbol: symbol,
        value: value,
      );

      // ========================================================
      // SALVA
      // ========================================================

      await controller.saveModel();

      if (!isMounted()) {
        return;
      }

      // ========================================================
      // ATUALIZA TELA
      // ========================================================

      refresh();

      showMessage(
        'Saldo de $symbol atualizado.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG]'
        '[CRYPTO]'
        '[UPDATE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (isMounted()) {
        showMessage(
          'Não foi possível salvar o saldo de $symbol.',
        );
      }
    }
  }

  // ============================================================
  // ALTERAR SALDO NO MODEL
  // ============================================================

  void _setCryptoBalance({
    required String symbol,
    required double value,
  }) {
    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
        controller.model.bitcoin = value;

        break;

      case 'ETH':
        controller.model.ethereum = value;

        break;

      case 'SOL':
        controller.model.solana = value;

        break;

      case 'USDT':
        controller.model.usdt = value;

        break;

      default:
        throw ArgumentError(
          'Criptomoeda não suportada: $symbol',
        );
    }
  }

  // ============================================================
  // PARSE CRYPTO
  // ============================================================

  double? _parseCryptoValue(
    String raw,
  ) {
    var value = raw.trim().replaceAll(
      ' ',
      '',
    );

    if (value.isEmpty) {
      return null;
    }

    // ----------------------------------------------------------
    // Quando existe vírgula:
    //
    // 1.234,56
    //
    // vira:
    //
    // 1234.56
    // ----------------------------------------------------------

    if (value.contains(
      ',',
    )) {
      value = value
          .replaceAll(
            '.',
            '',
          )
          .replaceAll(
            ',',
            '.',
          );
    }

    final parsed = double.tryParse(
      value,
    );

    if (parsed ==
            null ||
        !parsed.isFinite) {
      return null;
    }

    return parsed;
  }

  // ============================================================
  // CASAS DECIMAIS
  // ============================================================

  int _cryptoDecimals(
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
  // HINT CRYPTO
  // ============================================================

  String _cryptoHint(
    String symbol,
  ) {
    switch (symbol.trim().toUpperCase()) {
      case 'BTC':
        return '0,00100000';

      case 'ETH':
        return '0,01000000';

      case 'SOL':
        return '1,00000000';

      case 'USDT':
        return '0,52412687';

      default:
        return '0,00000000';
    }
  }

  // ============================================================
  // PLANEJAMENTO
  // ============================================================

  Future<
    void
  >
  openPlanning() async {
    final model = controller.model;

    final result = await showFinancePlanningDialog(
      context: context,
      invested: model.invested,
      minimumGoal: model.minimumGoal,
      mediumGoal: model.mediumGoal,
      maximumGoal: model.maximumGoal,
      projectionYears: model.projectionYears,
    );

    if (result ==
            null ||
        !isMounted()) {
      return;
    }

    controller.applyPlanning(
      result,
    );

    refresh();

    try {
      await controller.saveModel();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG][PLANNING] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (isMounted()) {
        showMessage(
          'O planejamento foi alterado, mas ocorreu um erro ao salvar.',
        );
      }

      return;
    }

    if (isMounted()) {
      showMessage(
        'Planejamento salvo.',
      );
    }
  }

  // ============================================================
  // EDITAR PATRIMÔNIO
  // ============================================================

  Future<
    void
  >
  editPatrimony() {
    return _editValue(
      title: 'Editar patrimônio',
      label: 'Patrimônio atual',
      currentValue: controller.model.patrimony,
      update: controller.updatePatrimony,
    );
  }

  // ============================================================
  // EDITAR OBJETIVO FINANCEIRO
  // ============================================================

  Future<
    void
  >
  editInvestmentGoal() {
    return _editValue(
      title: 'Editar objetivo financeiro',
      label: 'Objetivo final',
      currentValue: controller.model.investmentGoal,
      update: controller.updateInvestmentGoal,
    );
  }

  // ============================================================
  // EDITAR VALOR FINANCEIRO
  // ============================================================

  Future<
    void
  >
  _editValue({
    required String title,
    required String label,
    required double currentValue,
    required ValueChanged<
      double
    >
    update,
  }) async {
    final value = await showEditFinanceValueDialog(
      context: context,
      title: title,
      label: label,
      currentValue: currentValue,
    );

    if (value ==
            null ||
        !isMounted()) {
      return;
    }

    update(
      value,
    );

    refresh();

    try {
      await controller.saveModel();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[FINANCE DIALOG][VALUE] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (isMounted()) {
        showMessage(
          'O valor foi alterado, mas ocorreu um erro ao salvar.',
        );
      }

      return;
    }

    if (isMounted()) {
      showMessage(
        'Valor atualizado.',
      );
    }
  }

  // ============================================================
  // ITEM DO HISTÓRICO
  // ============================================================

  void showHistoryItem(
    InvestmentHistory item,
  ) {
    showMessage(
      '${FinanceScreenFormatter.currency(item.safeValue)} • '
      '${item.normalizedRhythm}',
    );
  }
}
