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
    required this.projection,
    required this.history,
    required this.patrimony,
    required this.invested,
    required this.investmentGoal,
    required this.minimumGoal,
    required this.mediumGoal,
    required this.maximumGoal,
    required this.bitcoin,
    required this.ethereum,
    required this.solana,
    required this.usdt,
    required this.onBalance,
    required this.onCrypto,
    required this.onVault,
    required this.onPlanning,
    required this.onContribution,
    required this.onEditPatrimony,
    required this.onEditGoal,
    required this.onDeleteContribution,
    required this.onHistoryItemTap,
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

  final double investmentGoal;

  final double minimumGoal;

  final double mediumGoal;

  final double maximumGoal;

  final double bitcoin;

  final double ethereum;

  final double solana;

  final double usdt;

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
            patrimony: patrimony,

            invested: invested,

            bitcoin: bitcoin,

            ethereum: ethereum,

            solana: solana,

            usdt: usdt,

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

            showBalances: showBalances,
          ),

          const SizedBox(
            height: 20,
          ),

          // ====================================================
          // RESUMO FINANCEIRO
          //
          // Agora contém apenas:
          // - Objetivo
          // - Ritmos
          //
          // Patrimônio foi removido do FinanceSummarySection.
          // ====================================================
          FinanceSummarySection(
            investmentGoal: investmentGoal,

            minimumGoal: minimumGoal,

            mediumGoal: mediumGoal,

            maximumGoal: maximumGoal,

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
