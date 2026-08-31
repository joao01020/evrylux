import 'package:flutter/material.dart';

import '../../models/training_activity_type.dart';
import '../models/body_region_schedule.dart';

// ============================================================
// BODY REGION CARD
// ============================================================
//
// Card usado na lista de atividades configuradas.
//
// O nome da classe foi mantido como BodyRegionCard para evitar
// quebrar imports antigos do módulo.
//
// Agora a fonte de verdade é:
//
// TrainingActivityType
//
// Isso permite exibir:
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
// sem depender de schedule.region.
//
// ============================================================

class BodyRegionCard
    extends
        StatelessWidget {
  const BodyRegionCard({
    super.key,
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  // ============================================================
  // DATA
  // ============================================================

  final BodyRegionSchedule schedule;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

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

  static const Color _danger = Color(
    0xFFB3261E,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final TrainingActivityType activity = schedule.activity;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(
          15,
        ),
        child: Container(
          padding: const EdgeInsets.all(
            12,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(
              15,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // ICON
              // ==================================================
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
                width: 11,
              ),

              // ==================================================
              // CONTENT
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
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
                            '${schedule.daysPerWeek}x',
                            style: const TextStyle(
                              color: _primaryDark,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      schedule.compactDaysLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _primaryDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      schedule.frequencyLabel,
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

              const SizedBox(
                width: 6,
              ),

              // ==================================================
              // MENU
              // ==================================================
              PopupMenuButton<
                String
              >(
                tooltip: 'Opções',
                color: _surface,
                surfaceTintColor: Colors.transparent,
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: _muted,
                  size: 19,
                ),
                onSelected:
                    (
                      value,
                    ) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;

                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                itemBuilder:
                    (
                      context,
                    ) {
                      return const [
                        PopupMenuItem<
                          String
                        >(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 17,
                                color: _primaryDark,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Editar dias',
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem<
                          String
                        >(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 17,
                                color: _danger,
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Remover',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
