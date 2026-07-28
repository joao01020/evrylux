import 'package:flutter/material.dart';

import '../projections/finance_projection.dart';
import '../../../models/finance/investment_history.dart';
import '../../../widgets/finance/investment_progress.dart';
import '../../../widgets/finance/investment_timeline.dart';
import '../../../widgets/finance/wallet_card.dart';
import '../models/crypto_balances.dart';
import 'empty_last_contribution.dart';
import 'finance_intro.dart';
import 'finance_section_header.dart';
import 'finance_summary_section.dart';

class FinanceScreenContent
    extends
        StatelessWidget {
  final dynamic model;
  final FinanceProjection projection;
  final CryptoBalances balances;
  final List<
    InvestmentHistory
  >
  history;

  final VoidCallback onPlanning;
  final VoidCallback onHistory;
  final VoidCallback onBalance;
  final VoidCallback onVault;
  final VoidCallback onPatrimony;
  final VoidCallback onObjective;

  final ValueChanged<
    String
  >
  onCrypto;
  final ValueChanged<
    InvestmentHistory
  >
  onHistoryItem;
  final ValueChanged<
    InvestmentHistory
  >
  onDeleteContribution;

  const FinanceScreenContent({
    super.key,
    required this.model,
    required this.projection,
    required this.balances,
    required this.history,
    required this.onPlanning,
    required this.onHistory,
    required this.onBalance,
    required this.onVault,
    required this.onPatrimony,
    required this.onObjective,
    required this.onCrypto,
    required this.onHistoryItem,
    required this.onDeleteContribution,
  });

  List<
    InvestmentHistory
  >
  get latestContribution {
    return history.isEmpty
        ? []
        : [
            history.last,
          ];
  }

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
            patrimony: model.patrimony,
            invested: model.invested,
            bitcoin: balances.bitcoin,
            ethereum: balances.ethereum,
            solana: balances.solana,
            usdt: balances.usdt,
            onBalance: onBalance,
            onBitcoin: () => onCrypto(
              'BTC',
            ),
            onEthereum: () => onCrypto(
              'ETH',
            ),
            onSolana: () => onCrypto(
              'SOL',
            ),
            onUsdt: () => onCrypto(
              'USDT',
            ),
            onVault: onVault,
          ),
          const SizedBox(
            height: 20,
          ),
          FinanceSummarySection(
            patrimony: model.patrimony,
            investmentGoal: model.investmentGoal,
            minimumGoal: model.minimumGoal,
            mediumGoal: model.mediumGoal,
            maximumGoal: model.maximumGoal,
            onPatrimonyTap: onPatrimony,
            onObjectiveTap: onObjective,
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
            title: 'Último aporte',
            subtitle: history.isEmpty
                ? 'Nenhum aporte registrado.'
                : 'Seu aporte mais recente.',
            trailing: TextButton.icon(
              onPressed: onHistory,
              icon: const Icon(
                Icons.history,
                size: 18,
              ),
              label: const Text(
                'Ver todos',
              ),
            ),
          ),
          const SizedBox(
            height: 14,
          ),
          if (history.isEmpty)
            const EmptyLastContribution()
          else
            InvestmentTimeline(
              history: latestContribution,
              showHeader: false,
              onDelete: onDeleteContribution,
              onTap: onHistoryItem,
            ),
        ],
      ),
    );
  }
}
