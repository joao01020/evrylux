import 'package:flutter/material.dart';

import '../../services/history/investment_history.dart';

import 'components/investment_month_group.dart';
import 'components/investment_timeline_empty.dart';
import 'components/investment_timeline_header.dart';
import 'components/investment_timeline_summary.dart';

class InvestmentTimeline
    extends
        StatelessWidget {
  final List<
    InvestmentHistory
  >
  history;

  /// Exibe o cabeçalho interno do histórico.
  final bool showHeader;

  /// Quantidade máxima de registros mostrados.
  ///
  /// Quando for nulo, todos os registros serão exibidos.
  final int? maxItems;

  /// Função chamada ao tocar em um aporte.
  final ValueChanged<
    InvestmentHistory
  >?
  onTap;

  /// Função chamada ao excluir um aporte.
  final ValueChanged<
    InvestmentHistory
  >?
  onDelete;

  const InvestmentTimeline({
    super.key,
    required this.history,
    this.showHeader = true,
    this.maxItems,
    this.onTap,
    this.onDelete,
  });

  // =========================================================
  // DADOS ORGANIZADOS
  // =========================================================

  List<
    InvestmentHistory
  >
  get _orderedHistory {
    final items =
        List<
          InvestmentHistory
        >.from(
          history,
        );

    items.sort(
      (
        first,
        second,
      ) {
        return second.date.compareTo(
          first.date,
        );
      },
    );

    if (maxItems ==
            null ||
        maxItems! <=
            0 ||
        maxItems! >=
            items.length) {
      return items;
    }

    return items
        .take(
          maxItems!,
        )
        .toList();
  }

  Map<
    String,
    List<
      InvestmentHistory
    >
  >
  _groupByMonth(
    List<
      InvestmentHistory
    >
    items,
  ) {
    final groups =
        <
          String,
          List<
            InvestmentHistory
          >
        >{};

    for (final item in items) {
      final month = item.date.month.toString().padLeft(
        2,
        '0',
      );

      final key = '${item.date.year}-$month';

      groups.putIfAbsent(
        key,
        () =>
            <
              InvestmentHistory
            >[],
      );

      groups[key]!.add(
        item,
      );
    }

    return groups;
  }

  // =========================================================
  // ESTATÍSTICAS
  // =========================================================

  double get _totalInvested {
    return history.fold<
      double
    >(
      0,
      (
        total,
        item,
      ) {
        return total +
            item.value;
      },
    );
  }

  double get _averageContribution {
    if (history.isEmpty) {
      return 0;
    }

    return _totalInvested /
        history.length;
  }

  int get _hiddenItemsCount {
    if (maxItems ==
            null ||
        maxItems! <=
            0) {
      return 0;
    }

    final hidden =
        history.length -
        maxItems!;

    return hidden >
            0
        ? hidden
        : 0;
  }

  // =========================================================
  // TELA
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final items = _orderedHistory;

    final groups = _groupByMonth(
      items,
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
        side: BorderSide(
          color: Theme.of(
            context,
          ).dividerColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              InvestmentTimelineHeader(
                contributionCount: history.length,
              ),

              const SizedBox(
                height: 20,
              ),
            ],

            if (history.isNotEmpty) ...[
              InvestmentTimelineSummary(
                totalInvested: _totalInvested,
                averageContribution: _averageContribution,
                contributionCount: history.length,
              ),

              const SizedBox(
                height: 24,
              ),
            ],

            if (items.isEmpty)
              const InvestmentTimelineEmpty()
            else
              for (final group in groups.values)
                InvestmentMonthGroup(
                  items: group,
                  onTap: onTap,
                  onDelete: onDelete,
                ),

            if (_hiddenItemsCount >
                0) ...[
              const SizedBox(
                height: 4,
              ),

              Center(
                child: Text(
                  '$_hiddenItemsCount '
                  '${_hiddenItemsCount == 1 ? 'aporte anterior não exibido' : 'aportes anteriores não exibidos'}.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
