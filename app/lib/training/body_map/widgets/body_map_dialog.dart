import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';

import '../../models/training_activity_type.dart';
import '../controllers/body_map_controller.dart';
import '../models/body_region.dart';
import '../models/body_region_schedule.dart';
import '../services/body_map_service.dart';
import 'body_map_front.dart';
import 'body_map_legend.dart';

// ============================================================
// BODY MAP DIALOG
// ============================================================
//
// Modal principal do planejamento corporal.
//
// Agora trabalha com TrainingActivityType como fonte de verdade.
//
// Permite configurar:
//
// - Peito
// - Pernas
// - Braço
// - Costas
// - Ombro
// - Core
// - Corrida
// - Caminhada
//
// O boneco frontal continua usando BodyRegion apenas para
// interação visual.
//
// ============================================================

class BodyMapDialog
    extends
        StatefulWidget {
  const BodyMapDialog({
    super.key,
    this.controller,
    this.service,
  });

  final BodyMapController? controller;

  final BodyMapService? service;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    List<
      BodyRegionSchedule
    >?
  >
  show(
    BuildContext context, {
    BodyMapController? controller,
    BodyMapService? service,
  }) {
    return showDialog<
      List<
        BodyRegionSchedule
      >
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) {
            return BodyMapDialog(
              controller: controller,
              service: service,
            );
          },
    );
  }

  @override
  State<
    BodyMapDialog
  >
  createState() => _BodyMapDialogState();
}

class _BodyMapDialogState
    extends
        State<
          BodyMapDialog
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _errorColor = Color(
    0xFFB3261E,
  );

  // ============================================================
  // CONTROLLER / SERVICE
  // ============================================================

  late final BodyMapController _controller;

  late final BodyMapService _service;

  late final bool _ownsController;

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = true;

  bool _saving = false;

  String? _error;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _ownsController =
        widget.controller ==
        null;

    _controller =
        widget.controller ??
        BodyMapController();

    _service =
        widget.service ??
        bodyMapService;

    _controller.addListener(
      _onControllerChanged,
    );

    _initialize();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    try {
      final schedules = await _service.loadAll();

      _controller.loadSchedules(
        schedules,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;
          _error = null;
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;
          _error = error.toString();
        },
      );
    }
  }

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // SELECT ACTIVITY
  // ============================================================

  Future<
    void
  >
  _selectAndEditActivity(
    TrainingActivityType activity,
  ) async {
    _controller.selectActivity(
      activity,
    );

    await _showActivityEditor(
      activity,
    );
  }

  // ============================================================
  // CONFIGURE CURRENT BODY REGION
  // ============================================================

  Future<
    void
  >
  _configureSelectedBodyRegion() async {
    final activity = _controller.selectedActivity;

    if (activity ==
        null) {
      return;
    }

    await _showActivityEditor(
      activity,
    );
  }

  // ============================================================
  // ACTIVITY EDITOR
  // ============================================================

  Future<
    void
  >
  _showActivityEditor(
    TrainingActivityType activity,
  ) async {
    _controller.selectActivity(
      activity,
    );

    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            dialogContext,
          ) {
            return _ActivityDaysDialog(
              controller: _controller,
              activity: activity,
              onSave: () async {
                final schedule = _controller.saveCurrentActivity();

                if (schedule ==
                    null) {
                  await _service.removeActivity(
                    activity,
                  );
                } else {
                  await _service.saveSchedule(
                    schedule,
                  );
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(
                  dialogContext,
                ).pop();
              },
            );
          },
    );
  }

  // ============================================================
  // REMOVE ACTIVITY
  // ============================================================

  Future<
    void
  >
  _removeActivity(
    TrainingActivityType activity,
  ) async {
    try {
      await _service.removeActivity(
        activity,
      );

      _controller.removeActivity(
        activity,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _error = null;
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _error = error.toString();
        },
      );
    }
  }

  // ============================================================
  // SAVE PLAN
  // ============================================================

  Future<
    void
  >
  _savePlan() async {
    if (_saving) {
      return;
    }

    setState(
      () {
        _saving = true;
        _error = null;
      },
    );

    try {
      final schedules = await _service.replacePlan(
        _controller.schedules,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pop(
        schedules,
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _saving = false;
          _error = error.toString();
        },
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        22,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1120,
          maxHeight: 780,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x20000000,
                ),
                blurRadius: 34,
                offset: Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),

              const Divider(
                height: 1,
                color: _border,
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: _primaryDark,
                        ),
                      )
                    : _buildContent(),
              ),

              const Divider(
                height: 1,
                color: _border,
              ),

              _buildFooter(),
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
        22,
        18,
        16,
        16,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(
                14,
              ),
            ),
            child: const Icon(
              Icons.accessibility_new_rounded,
              color: _primaryDark,
              size: 24,
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
                  'Mapa corporal de treino',
                  style: TextStyle(
                    color: _text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Configure várias regiões e atividades para cada dia da semana.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: _saving
                ? null
                : () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final narrow =
                constraints.maxWidth <
                850;

            if (narrow) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(
                  18,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 650,
                      child: _buildBodyPanel(),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    SizedBox(
                      height: 560,
                      child: _buildSchedulePanel(),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(
                18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 5,
                    child: _buildBodyPanel(),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    flex: 4,
                    child: _buildSchedulePanel(),
                  ),
                ],
              ),
            );
          },
    );
  }

  // ============================================================
  // BODY PANEL
  // ============================================================

  Widget _buildBodyPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              8,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecione no corpo',
                        style: TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        'Você pode configurar várias regiões no mesmo plano.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_controller.selectedActivity !=
                    null)
                  TextButton.icon(
                    onPressed: _configureSelectedBodyRegion,
                    icon: const Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                    ),
                    label: const Text(
                      'Configurar dias',
                    ),
                  ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: BodyMapLegend(),
          ),

          const SizedBox(
            height: 8,
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                8,
              ),
              child: BodyMapFront(
                controller: _controller,
              ),
            ),
          ),

          const Divider(
            height: 1,
            color: _border,
          ),

          _buildActivityPicker(),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVITY PICKER
  // ============================================================

  Widget _buildActivityPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todas as opções de treino',
            style: TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TrainingActivityTypes.all
                .map(
                  _buildActivityChip,
                )
                .toList(
                  growable: false,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChip(
    TrainingActivityType activity,
  ) {
    final configured = _controller.isActivityConfigured(
      activity,
    );

    final selected =
        _controller.selectedActivity ==
        activity;

    return InkWell(
      onTap: () {
        _selectAndEditActivity(
          activity,
        );
      },
      borderRadius: BorderRadius.circular(
        12,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 160,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _primary
              : configured
              ? const Color(
                  0xFFE5F6E1,
                )
              : _surfaceSoft,
          borderRadius: BorderRadius.circular(
            12,
          ),
          border: Border.all(
            color:
                selected ||
                    configured
                ? _primaryDark
                : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activity.icon,
              size: 15,
              color:
                  configured ||
                      selected
                  ? _primaryDark
                  : _muted,
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              activity.label,
              style: TextStyle(
                color:
                    configured ||
                        selected
                    ? _primaryDark
                    : _text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (configured) ...[
              const SizedBox(
                width: 5,
              ),
              const Icon(
                Icons.check_circle_rounded,
                size: 13,
                color: _primaryDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SCHEDULE PANEL
  // ============================================================

  Widget _buildSchedulePanel() {
    final schedules = _controller.schedules;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              15,
              16,
              12,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atividades configuradas',
                        style: TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                        'Seu plano semanal completo.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                    border: Border.all(
                      color: _border,
                    ),
                  ),
                  child: Text(
                    '${schedules.length}',
                    style: const TextStyle(
                      color: _primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(
            height: 1,
            color: _border,
          ),

          Expanded(
            child: schedules.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    itemCount: schedules.length,
                    separatorBuilder:
                        (
                          context,
                          index,
                        ) {
                          return const SizedBox(
                            height: 8,
                          );
                        },
                    itemBuilder:
                        (
                          context,
                          index,
                        ) {
                          final schedule = schedules[index];

                          return _ActivityScheduleCard(
                            schedule: schedule,
                            onEdit: () {
                              _selectAndEditActivity(
                                schedule.activity,
                              );
                            },
                            onDelete: () {
                              _removeActivity(
                                schedule.activity,
                              );
                            },
                          );
                        },
                  ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(
                  13,
                ),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: _primaryDark,
                    size: 17,
                  ),
                  SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      'Configure quantas atividades quiser. O mesmo dia pode ter Peito + Braço + Ombro, por exemplo.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(
                  18,
                ),
              ),
              child: const Icon(
                Icons.add_rounded,
                color: _primaryDark,
                size: 26,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Nenhuma atividade configurada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _text,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 5,
            ),
            const Text(
              'Clique no corpo ou em uma das opções abaixo dele.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(
        16,
      ),
      child: Row(
        children: [
          if (_error !=
              null)
            Expanded(
              child: Text(
                _error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _errorColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            const Spacer(),

          TextButton(
            onPressed: _saving
                ? null
                : () {
                    Navigator.of(
                      context,
                    ).pop();
                  },
            child: const Text(
              'Fechar',
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          ElevatedButton.icon(
            onPressed: _saving
                ? null
                : _savePlan,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _primary,
              foregroundColor: _primaryDark,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 13,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _primaryDark,
                    ),
                  )
                : const Icon(
                    Icons.check_rounded,
                    size: 18,
                  ),
            label: Text(
              _saving
                  ? 'Salvando'
                  : 'Salvar plano',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVITY SCHEDULE CARD
// ============================================================

class _ActivityScheduleCard
    extends
        StatelessWidget {
  const _ActivityScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  final BodyRegionSchedule schedule;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    final activity = schedule.activity;

    return Container(
      padding: const EdgeInsets.all(
        11,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(
                0xFFE5F6E1,
              ),
              borderRadius: BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              activity.icon,
              size: 19,
              color: _primaryDark,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  schedule.compactDaysLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 17,
              color: _primaryDark,
            ),
          ),

          IconButton(
            tooltip: 'Remover',
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 17,
              color: Color(
                0xFFB3261E,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTIVITY DAYS DIALOG
// ============================================================

class _ActivityDaysDialog
    extends
        StatelessWidget {
  const _ActivityDaysDialog({
    required this.controller,
    required this.activity,
    required this.onSave,
  });

  final BodyMapController controller;

  final TrainingActivityType activity;

  final Future<
    void
  >
  Function()
  onSave;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 390,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            18,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder:
                (
                  context,
                  _,
                ) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Icon(
                              activity.icon,
                              color: _primaryDark,
                              size: 21,
                            ),
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity.label,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'Selecione os dias de treino',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            tooltip: 'Fechar',
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop();
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      for (
                        var weekday = DateTime.monday;
                        weekday <=
                            DateTime.sunday;
                        weekday++
                      )
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 6,
                          ),
                          child: InkWell(
                            onTap: () {
                              controller.toggleWeekday(
                                weekday,
                              );
                            },
                            borderRadius: BorderRadius.circular(
                              11,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    controller.draftWeekdays.contains(
                                      weekday,
                                    )
                                    ? _surfaceSoft
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                                border: Border.all(
                                  color:
                                      controller.draftWeekdays.contains(
                                        weekday,
                                      )
                                      ? _primaryDark
                                      : _border,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: controller.draftWeekdays.contains(
                                      weekday,
                                    ),
                                    onChanged:
                                        (
                                          _,
                                        ) {
                                          controller.toggleWeekday(
                                            weekday,
                                          );
                                        },
                                    activeColor: _primaryDark,
                                  ),

                                  const SizedBox(
                                    width: 4,
                                  ),

                                  Text(
                                    BodyRegionSchedule.weekdayName(
                                      weekday,
                                    ),
                                    style: const TextStyle(
                                      color: _text,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(
                        height: 8,
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).pop();
                            },
                            child: const Text(
                              'Cancelar',
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          ElevatedButton(
                            onPressed: () async {
                              await onSave();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _primary,
                              foregroundColor: _primaryDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Salvar dias',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
          ),
        ),
      ),
    );
  }
}
