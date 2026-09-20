import 'package:flutter/material.dart';

import 'training_history_filter.dart';
import 'training_history_pie_chart.dart';
import 'training_history_records.dart';
import 'training_history_summary.dart';

// ============================================================
// VIEW
// ============================================================

enum TrainingHistoryView {
  distribution,
  records,
}

// ============================================================
// DIALOG
// ============================================================

class TrainingHistoryDialog
    extends
        StatefulWidget {
  const TrainingHistoryDialog({
    super.key,
    required this.entries,
    this.onEdit,
    this.onDelete,
    this.initialPeriod = TrainingHistoryPeriod.last30Days,
  });

  final List<
    TrainingHistoryEntry
  >
  entries;

  final Future<
    void
  >
  Function(
    TrainingHistoryEntry entry,
  )?
  onEdit;

  final Future<
    void
  >
  Function(
    TrainingHistoryEntry entry,
  )?
  onDelete;

  final TrainingHistoryPeriod initialPeriod;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required List<
      TrainingHistoryEntry
    >
    entries,
    Future<
      void
    >
    Function(
      TrainingHistoryEntry entry,
    )?
    onEdit,
    Future<
      void
    >
    Function(
      TrainingHistoryEntry entry,
    )?
    onDelete,
    TrainingHistoryPeriod initialPeriod = TrainingHistoryPeriod.last30Days,
  }) {
    return showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            _,
          ) {
            return TrainingHistoryDialog(
              entries: entries,
              onEdit: onEdit,
              onDelete: onDelete,
              initialPeriod: initialPeriod,
            );
          },
    );
  }

  @override
  State<
    TrainingHistoryDialog
  >
  createState() {
    return _TrainingHistoryDialogState();
  }
}

// ============================================================
// STATE
// ============================================================

class _TrainingHistoryDialogState
    extends
        State<
          TrainingHistoryDialog
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _soft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // STATE
  // ============================================================

  late TrainingHistoryPeriod _period;

  TrainingHistoryView _view = TrainingHistoryView.distribution;

  DateTime? _customStart;

  DateTime? _customEnd;

  String? _selectedActivity;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _period = widget.initialPeriod;
  }

  // ============================================================
  // ENTRADAS FILTRADAS
  // ============================================================

  List<
    TrainingHistoryEntry
  >
  get _filteredEntries {
    final DateTime now = DateTime.now();

    DateTime? start;
    DateTime? end;

    switch (_period) {
      // ========================================================
      // HOJE
      // ========================================================

      case TrainingHistoryPeriod.today:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        );

        end = start.add(
          const Duration(
            days: 1,
          ),
        );

      // ========================================================
      // ÚLTIMOS 7 DIAS
      // ========================================================

      case TrainingHistoryPeriod.last7Days:
        start =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(
              const Duration(
                days: 6,
              ),
            );

        end =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).add(
              const Duration(
                days: 1,
              ),
            );

      // ========================================================
      // ÚLTIMOS 30 DIAS
      // ========================================================

      case TrainingHistoryPeriod.last30Days:
        start =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(
              const Duration(
                days: 29,
              ),
            );

        end =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).add(
              const Duration(
                days: 1,
              ),
            );

      // ========================================================
      // ÚLTIMOS 90 DIAS
      // ========================================================

      case TrainingHistoryPeriod.last90Days:
        start =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).subtract(
              const Duration(
                days: 89,
              ),
            );

        end =
            DateTime(
              now.year,
              now.month,
              now.day,
            ).add(
              const Duration(
                days: 1,
              ),
            );

      // ========================================================
      // ÚLTIMOS 6 MESES
      // ========================================================

      case TrainingHistoryPeriod.last6Months:
        start = DateTime(
          now.year,
          now.month -
              6,
          now.day,
        );

        end = now.add(
          const Duration(
            days: 1,
          ),
        );

      // ========================================================
      // ÚLTIMO ANO
      // ========================================================

      case TrainingHistoryPeriod.lastYear:
        start = DateTime(
          now.year -
              1,
          now.month,
          now.day,
        );

        end = now.add(
          const Duration(
            days: 1,
          ),
        );

      // ========================================================
      // TODOS
      // ========================================================

      case TrainingHistoryPeriod.all:
        break;

      // ========================================================
      // PERSONALIZADO
      // ========================================================

      case TrainingHistoryPeriod.custom:
        start = _customStart;

        final DateTime? customEnd = _customEnd;

        if (customEnd !=
            null) {
          end =
              DateTime(
                customEnd.year,
                customEnd.month,
                customEnd.day,
              ).add(
                const Duration(
                  days: 1,
                ),
              );
        }
    }

    final List<
      TrainingHistoryEntry
    >
    result = widget.entries
        .where(
          (
            TrainingHistoryEntry entry,
          ) {
            if (start !=
                    null &&
                entry.date.isBefore(
                  start,
                )) {
              return false;
            }

            if (end !=
                    null &&
                !entry.date.isBefore(
                  end,
                )) {
              return false;
            }

            return true;
          },
        )
        .toList(
          growable: false,
        );

    result.sort(
      (
        TrainingHistoryEntry a,
        TrainingHistoryEntry b,
      ) {
        return b.date.compareTo(
          a.date,
        );
      },
    );

    return result;
  }

  // ============================================================
  // PERÍODO PERSONALIZADO
  // ============================================================

  Future<
    void
  >
  _pickCustomRange() async {
    final DateTime now = DateTime.now();

    final DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(
        2000,
      ),
      lastDate: DateTime(
        now.year +
            1,
      ),
      initialDateRange:
          _customStart !=
                  null &&
              _customEnd !=
                  null
          ? DateTimeRange(
              start: _customStart!,
              end: _customEnd!,
            )
          : null,
    );

    if (!mounted ||
        range ==
            null) {
      return;
    }

    setState(
      () {
        _period = TrainingHistoryPeriod.custom;
        _customStart = range.start;
        _customEnd = range.end;
        _selectedActivity = null;
      },
    );
  }

  // ============================================================
  // ALTERAR PERÍODO
  // ============================================================

  void _changePeriod(
    TrainingHistoryPeriod period,
  ) {
    if (period ==
        TrainingHistoryPeriod.custom) {
      _pickCustomRange();
      return;
    }

    setState(
      () {
        _period = period;
        _selectedActivity = null;
      },
    );
  }

  // ============================================================
  // SELECIONAR ATIVIDADE
  // ============================================================

  void _selectActivity(
    String activity,
  ) {
    setState(
      () {
        _selectedActivity =
            _selectedActivity ==
                activity
            ? null
            : activity;
      },
    );
  }

  // ============================================================
  // FECHAR
  // ============================================================

  void _close() {
    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final List<
      TrainingHistoryEntry
    >
    entries = _filteredEntries;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 940,
          maxHeight: 760,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 30,
                offset: Offset(
                  0,
                  14,
                ),
                color: Color(
                  0x1A000000,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              _buildHeader(),

              const Divider(
                height: 1,
                color: _border,
              ),

              // ==================================================
              // CONTEÚDO
              // ==================================================
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================================================
                      // RESUMO
                      // ==================================================
                      TrainingHistorySummary(
                        entries: entries,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // FILTRO
                      // ==================================================
                      TrainingHistoryFilter(
                        selectedPeriod: _period,
                        customStart: _customStart,
                        customEnd: _customEnd,
                        onChanged: _changePeriod,
                        onCustomRangeTap: _pickCustomRange,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // TABS
                      // ==================================================
                      _buildTabs(),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // VISUALIZAÇÃO
                      // ==================================================
                      AnimatedSwitcher(
                        duration: const Duration(
                          milliseconds: 180,
                        ),
                        child:
                            _view ==
                                TrainingHistoryView.distribution
                            ? TrainingHistoryPieChart(
                                key: ValueKey(
                                  'pie-${_period.name}-${entries.length}',
                                ),
                                entries: entries,
                                selectedActivity: _selectedActivity,
                                onActivitySelected: _selectActivity,
                              )
                            : TrainingHistoryRecords(
                                key: ValueKey(
                                  'records-${_period.name}-${entries.length}',
                                ),
                                entries: entries,
                                onEdit: widget.onEdit,
                                onDelete: widget.onDelete,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        16,
        14,
        16,
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _soft,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _border,
              ),
            ),
            child: const Icon(
              Icons.donut_large_rounded,
              color: _primary,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Histórico de treinos',
                  style: TextStyle(
                    color: _text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 2,
                ),

                Text(
                  'Veja a distribuição dos seus treinos por período.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: _close,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(
        4,
      ),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              value: TrainingHistoryView.distribution,
              icon: Icons.pie_chart_outline_rounded,
              label: 'Distribuição',
            ),
          ),

          const SizedBox(
            width: 6,
          ),

          Expanded(
            child: _buildTab(
              value: TrainingHistoryView.records,
              icon: Icons.receipt_long_outlined,
              label: 'Registros',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB
  // ============================================================

  Widget _buildTab({
    required TrainingHistoryView value,
    required IconData icon,
    required String label,
  }) {
    final bool selected =
        _view ==
        value;

    return InkWell(
      borderRadius: BorderRadius.circular(
        9,
      ),
      onTap: () {
        if (_view ==
            value) {
          return;
        }

        setState(
          () {
            _view = value;
          },
        );
      },
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(
            9,
          ),
          border: Border.all(
            color: selected
                ? _border
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? _primary
                  : _muted,
            ),

            const SizedBox(
              width: 7,
            ),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? _text
                    : _muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
