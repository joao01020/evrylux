import 'package:flutter/material.dart';

import '../../projections/finance_projection.dart';
import '../../services/history/investment_history.dart';

import '../progress/investment_progress.dart';
import '../timeline/investment_timeline.dart';
import '../wallet/wallet_card.dart';

import '../sections/finance_intro.dart';
import '../sections/finance_section_header.dart';
import '../sections/finance_summary_section.dart';

class FinanceBody
    extends
        StatelessWidget {
  const FinanceBody({
    super.key,

    // ==========================================================
    // PROJEÇÃO / HISTÓRICO
    // ==========================================================
    required this.projection,
    required this.history,

    // ==========================================================
    // FINANCEIRO
    // ==========================================================
    required this.patrimony,
    required this.invested,

    // ==========================================================
    // OBJETIVO
    // ==========================================================
    required this.objectiveName,
    required this.investmentGoal,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,

    // ==========================================================
    // QUANTIDADES CRYPTO
    // ==========================================================
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,

    // ==========================================================
    // VALORES ATUAIS CRYPTO
    // ==========================================================
    required this.bitcoinCurrentValue,
    required this.ethereumCurrentValue,
    required this.solanaCurrentValue,
    required this.usdtCurrentValue,

    // ==========================================================
    // LUCRO / PREJUÍZO %
    // ==========================================================
    required this.bitcoinProfitPercent,
    required this.ethereumProfitPercent,
    required this.solanaProfitPercent,
    required this.usdtProfitPercent,

    // ==========================================================
    // AÇÕES
    // ==========================================================
    required this.onBalance,
    required this.onCrypto,
    required this.onVault,
    required this.onPlanning,
    required this.onContribution,
    required this.onEditPatrimony,
    required this.onEditGoal,
    required this.onDeleteContribution,
    required this.onHistoryItemTap,

    // ==========================================================
    // VISIBILIDADE
    // ==========================================================
    this.showBalances = true,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final FinanceProjection projection;

  final List<
    InvestmentHistory
  >
  history;

  final double patrimony;

  final double invested;

  // ============================================================
  // OBJETIVO
  // ============================================================

  final String objectiveName;

  final double investmentGoal;

  final double minimumGoal;

  final double mediumGoal;

  final double maximumGoal;

  // ============================================================
  // CRYPTO - QUANTIDADES
  // ============================================================

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

  // ============================================================
  // CRYPTO - VALORES ATUAIS
  // ============================================================

  final double bitcoinCurrentValue;

  final double ethereumCurrentValue;

  final double solanaCurrentValue;

  final double usdtCurrentValue;

  // ============================================================
  // CRYPTO - LUCRO / PREJUÍZO %
  // ============================================================

  final double bitcoinProfitPercent;

  final double ethereumProfitPercent;

  final double solanaProfitPercent;

  final double usdtProfitPercent;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onBalance;

  final ValueChanged<
    String
  >
  onCrypto;

  final VoidCallback onVault;

  final VoidCallback onPlanning;

  final VoidCallback onContribution;

  final VoidCallback onEditPatrimony;

  final VoidCallback onEditGoal;

  final ValueChanged<
    InvestmentHistory
  >
  onDeleteContribution;

  final ValueChanged<
    InvestmentHistory
  >
  onHistoryItemTap;

  // ============================================================
  // VISIBILIDADE DOS SALDOS
  // ============================================================

  final bool showBalances;

  // ============================================================
  // VALORES SEGUROS
  // ============================================================

  double _safeMoney(
    double value,
  ) {
    if (!value.isFinite ||
        value <
            0) {
      return 0;
    }

    return value;
  }

  double _safePercent(
    double value,
  ) {
    if (!value.isFinite) {
      return 0;
    }

    return value;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        110,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // INTRO
          // ====================================================
          const FinanceIntro(),

          const SizedBox(
            height: 28,
          ),

          // ====================================================
          // CARTEIRA
          // ====================================================
          WalletCard(
            // ==================================================
            // FINANCEIRO
            // ==================================================
            patrimony: _safeMoney(
              patrimony,
            ),

            invested: _safeMoney(
              invested,
            ),

            // ==================================================
            // QUANTIDADES
            // ==================================================
            bitcoin: _safeMoney(
              bitcoin,
            ),

            ethereum: _safeMoney(
              ethereum,
            ),

            solana: _safeMoney(
              solana,
            ),

            usdt: _safeMoney(
              usdt,
            ),

            // ==================================================
            // BTC
            // ==================================================
            bitcoinCurrentValue: _safeMoney(
              bitcoinCurrentValue,
            ),

            bitcoinProfitPercent: _safePercent(
              bitcoinProfitPercent,
            ),

            // ==================================================
            // ETH
            // ==================================================
            ethereumCurrentValue: _safeMoney(
              ethereumCurrentValue,
            ),

            ethereumProfitPercent: _safePercent(
              ethereumProfitPercent,
            ),

            // ==================================================
            // SOL
            // ==================================================
            solanaCurrentValue: _safeMoney(
              solanaCurrentValue,
            ),

            solanaProfitPercent: _safePercent(
              solanaProfitPercent,
            ),

            // ==================================================
            // USDT
            // ==================================================
            usdtCurrentValue: _safeMoney(
              usdtCurrentValue,
            ),

            usdtProfitPercent: _safePercent(
              usdtProfitPercent,
            ),

            // ==================================================
            // AÇÕES
            // ==================================================
            onBalance: onBalance,

            onBitcoin: () {
              onCrypto(
                'BTC',
              );
            },

            onEthereum: () {
              onCrypto(
                'ETH',
              );
            },

            onSolana: () {
              onCrypto(
                'SOL',
              );
            },

            onUsdt: () {
              onCrypto(
                'USDT',
              );
            },

            onVault: onVault,

            // ==================================================
            // VISIBILIDADE
            // ==================================================
            showBalances: showBalances,
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // RESUMO FINANCEIRO
          // ====================================================
          FinanceSummarySection(
            objectiveName: objectiveName,

            investmentGoal: _safeMoney(
              investmentGoal,
            ),

            minimumGoal: _safeMoney(
              minimumGoal,
            ),

            mediumGoal: _safeMoney(
              mediumGoal,
            ),

            maximumGoal: _safeMoney(
              maximumGoal,
            ),

            onObjectiveTap: onEditGoal,

            onRhythmsTap: onPlanning,

            showBalances: showBalances,
          ),

          const SizedBox(
            height: 32,
          ),

          // ====================================================
          // SUA EVOLUÇÃO
          // ====================================================
          const FinanceSectionHeader(
            title: 'Sua evolução',
            subtitle: 'O objetivo cresce enquanto o tempo restante diminui.',
          ),

          const SizedBox(
            height: 14,
          ),

          InvestmentProgress(
            projection: projection,

            showPatrimony: true,

            showAverageContribution: true,

            showEstimatedTime: true,

            showBalances: showBalances,
          ),

          const SizedBox(
            height: 32,
          ),

          // ====================================================
          // HISTÓRICO
          // ====================================================
          FinanceSectionHeader(
            title: 'Histórico',
            subtitle: 'Cada aporte representa um avanço no seu caminho.',
            trailing: FilledButton.icon(
              onPressed: onContribution,
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Aporte',
              ),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // TIMELINE
          // ====================================================
          InvestmentTimeline(
            history: history,

            showHeader: false,

            onDelete: onDeleteContribution,

            onTap: onHistoryItemTap,

            showBalances: showBalances,
          ),
        ],
      ),
    );
  }
}
