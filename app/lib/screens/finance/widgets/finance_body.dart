import 'package:flutter/material.dart';

import '../../../core/utils/finance_projection.dart';
import '../../../models/finance/investment_history.dart';

import '../../../widgets/finance/investment_progress.dart';
import '../../../widgets/finance/investment_timeline.dart';
import '../../../widgets/finance/wallet_card.dart';

import 'finance_intro.dart';
import 'finance_section_header.dart';
import 'finance_summary_section.dart';

class FinanceBody
    extends
        StatelessWidget {
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
  });

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
          const FinanceIntro(),

          const SizedBox(
            height: 28,
          ),

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
          ),

          const SizedBox(
            height: 20,
          ),

          FinanceSummarySection(
            patrimony: patrimony,
            investmentGoal: investmentGoal,
            minimumGoal: minimumGoal,
            mediumGoal: mediumGoal,
            maximumGoal: maximumGoal,
            onPatrimonyTap: onEditPatrimony,
            onObjectiveTap: onEditGoal,
            onRhythmsTap: onPlanning,
          ),

          const SizedBox(
            height: 32,
          ),

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
          ),

          const SizedBox(
            height: 32,
          ),

          FinanceSectionHeader(
            title: 'Histórico',
            subtitle: 'Cada aporte representa um avanço no seu caminho.',
            trailing: FilledButton.icon(
              onPressed: onContribution,
              icon: const Icon(
                Icons.add,
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

          InvestmentTimeline(
            history: history,
            showHeader: false,
            onDelete: onDeleteContribution,
            onTap: onHistoryItemTap,
          ),
        ],
      ),
    );
  }
}
