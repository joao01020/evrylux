import 'package:flutter/material.dart';

import '../services/history/investment_history.dart';
import '../widgets/timeline/investment_timeline.dart';

import '../utils/finance_screen_formatter.dart';

class FinanceHistoryScreen
    extends
        StatefulWidget {
  final List<
    InvestmentHistory
  >
  history;

  final Future<
    void
  >
  Function(
    InvestmentHistory item,
  )
  onDelete;

  const FinanceHistoryScreen({
    super.key,
    required this.history,
    required this.onDelete,
  });

  @override
  State<
    FinanceHistoryScreen
  >
  createState() {
    return _FinanceHistoryScreenState();
  }
}

class _FinanceHistoryScreenState
    extends
        State<
          FinanceHistoryScreen
        > {
  Future<
    void
  >
  _deleteItem(
    InvestmentHistory item,
  ) async {
    await widget.onDelete(
      item,
    );

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  void _showHistoryItem(
    InvestmentHistory item,
  ) {
    final value = FinanceScreenFormatter.currency(
      item.safeValue,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          '$value • ${item.normalizedRhythm}',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Histórico de aportes',
        ),
      ),
      body: widget.history.isEmpty
          ? const _EmptyHistory()
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                20,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.history.length} '
                    '${widget.history.length == 1 ? 'aporte' : 'aportes'}',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium,
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    'Aqui estão todos os aportes registrados.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium,
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  InvestmentTimeline(
                    history: widget.history.reversed.toList(),
                    showHeader: false,
                    onDelete: _deleteItem,
                    onTap: _showHistoryItem,
                  ),
                ],
              ),
            ),
    );
  }
}

class _EmptyHistory
    extends
        StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              'Nenhum aporte registrado',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleLarge,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Seus aportes aparecerão aqui depois que você '
              'registrar o primeiro.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
