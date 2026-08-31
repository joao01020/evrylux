import 'package:flutter/material.dart';

import '../../models/training_activity_type.dart';
import '../controllers/body_map_controller.dart';
import '../models/body_region.dart';
import 'body_weekday_selector.dart';

// ============================================================
// BODY REGION DAY DIALOG
// ============================================================
//
// Modal responsável por configurar os dias de treino de uma
// atividade.
//
// A fonte de verdade agora é:
//
// TrainingActivityType
//
// Isso permite configurar:
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
// BodyRegion continua aceito apenas por compatibilidade com
// chamadas antigas do mapa corporal.
//
// ============================================================

class BodyRegionDayDialog
    extends
        StatelessWidget {
  const BodyRegionDayDialog({
    super.key,
    required this.controller,
    required this.onSave,
    this.activity,
    this.region,
  }) : assert(
         activity !=
                 null ||
             region !=
                 null,
         'Informe activity ou region.',
       );

  // ============================================================
  // DATA
  // ============================================================

  final BodyMapController controller;

  final TrainingActivityType? activity;

  final BodyRegion? region;

  final Future<
    void
  >
  Function()
  onSave;

  // ============================================================
  // COLORS
  // ============================================================

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

  // ============================================================
  // RESOLVED ACTIVITY
  // ============================================================

  TrainingActivityType get _resolvedActivity {
    final directActivity = activity;

    if (directActivity !=
        null) {
      return directActivity;
    }

    final bodyRegion = region;

    if (bodyRegion !=
        null) {
      return bodyRegion.activity;
    }

    throw StateError(
      'BodyRegionDayDialog sem atividade.',
    );
  }

  // ============================================================
  // SHOW - ACTIVITY
  // ============================================================

  static Future<
    void
  >
  show(
    BuildContext context, {
    required BodyMapController controller,
    required TrainingActivityType activity,
    required Future<
      void
    >
    Function()
    onSave,
  }) {
    controller.selectActivity(
      activity,
    );

    return showDialog<
      void
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) {
            return BodyRegionDayDialog(
              controller: controller,
              activity: activity,
              onSave: onSave,
            );
          },
    );
  }

  // ============================================================
  // SHOW - REGION COMPATIBILITY
  // ============================================================
  //
  // Mantido para chamadas antigas:
  //
  // BodyRegionDayDialog.showForRegion(
  //   ...
  //   region: BodyRegion.chest,
  // )
  //
  // ============================================================

  static Future<
    void
  >
  showForRegion(
    BuildContext context, {
    required BodyMapController controller,
    required BodyRegion region,
    required Future<
      void
    >
    Function()
    onSave,
  }) {
    controller.selectRegion(
      region,
    );

    return showDialog<
      void
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) {
            return BodyRegionDayDialog(
              controller: controller,
              region: region,
              onSave: onSave,
            );
          },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentActivity = _resolvedActivity;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
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
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x1E000000,
                ),
                blurRadius: 24,
                offset: Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: controller,
            builder:
                (
                  context,
                  _,
                ) {
                  final selectedDays = controller.draftWeekdays;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(
                                13,
                              ),
                            ),
                            child: Icon(
                              currentActivity.icon,
                              color: _primaryDark,
                              size: 22,
                            ),
                          ),

                          const SizedBox(
                            width: 11,
                          ),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentActivity.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: _text,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                const Text(
                                  'Selecione os dias de treino',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
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

                      // ==================================================
                      // WEEKDAYS
                      // ==================================================
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(
                          12,
                        ),
                        decoration: BoxDecoration(
                          color: _surfaceSoft,
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                          border: Border.all(
                            color: _border,
                          ),
                        ),
                        child: BodyWeekdaySelector(
                          selectedWeekdays: selectedDays,
                          onToggle:
                              (
                                weekday,
                              ) {
                                controller.toggleWeekday(
                                  weekday,
                                );
                              },
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==================================================
                      // SUMMARY + ACTIONS
                      // ==================================================
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDays.isEmpty
                                  ? 'Nenhum dia selecionado'
                                  : '${selectedDays.length} '
                                        'dia${selectedDays.length == 1 ? '' : 's'} '
                                        'por semana',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

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

                          ElevatedButton.icon(
                            onPressed: () async {
                              await onSave();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _primary,
                              foregroundColor: _primaryDark,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  11,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.check_rounded,
                              size: 17,
                            ),
                            label: const Text(
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
