import 'package:flutter/material.dart';

import '../../models/training_activity_type.dart';

// ============================================================
// BODY REGION
// ============================================================
//
// Representa SOMENTE as regiões visuais do mapa corporal.
//
// O mapa corporal usa regiões anatômicas visuais:
//
// - Peito
// - Ombros
// - Braços
// - Abdômen
// - Quadríceps
// - Panturrilhas
//
// Já o restante do sistema usa:
//
// TrainingActivityType
//
// Exemplo:
//
// abdomen
//      ↓
// TrainingActivityType.core
//
// quadriceps
// calves
//      ↓
// TrainingActivityType.legs
//
// Isso permite manter o desenho detalhado sem duplicar
// a lógica de treino.
//
// ============================================================

enum BodyRegion {
  chest,
  shoulders,
  arms,
  abdomen,
  quadriceps,
  calves,
}

// ============================================================
// BODY REGION EXTENSION
// ============================================================

extension BodyRegionExtension
    on
        BodyRegion {
  // ==========================================================
  // ID
  // ==========================================================

  String get id {
    switch (this) {
      case BodyRegion.chest:
        return 'chest';

      case BodyRegion.shoulders:
        return 'shoulders';

      case BodyRegion.arms:
        return 'arms';

      case BodyRegion.abdomen:
        return 'abdomen';

      case BodyRegion.quadriceps:
        return 'quadriceps';

      case BodyRegion.calves:
        return 'calves';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case BodyRegion.chest:
        return 'Peito';

      case BodyRegion.shoulders:
        return 'Ombros';

      case BodyRegion.arms:
        return 'Braços';

      case BodyRegion.abdomen:
        return 'Abdômen';

      case BodyRegion.quadriceps:
        return 'Quadríceps';

      case BodyRegion.calves:
        return 'Panturrilhas';
    }
  }

  // ==========================================================
  // DESCRIPTION
  // ==========================================================

  String get description {
    switch (this) {
      case BodyRegion.chest:
        return 'Peitoral';

      case BodyRegion.shoulders:
        return 'Deltoides';

      case BodyRegion.arms:
        return 'Bíceps e tríceps';

      case BodyRegion.abdomen:
        return 'Core e abdômen';

      case BodyRegion.quadriceps:
        return 'Parte frontal das coxas';

      case BodyRegion.calves:
        return 'Panturrilhas';
    }
  }

  // ==========================================================
  // ICON
  // ==========================================================

  IconData get icon {
    switch (this) {
      case BodyRegion.chest:
        return Icons.fitness_center_rounded;

      case BodyRegion.shoulders:
        return Icons.accessibility_new_rounded;

      case BodyRegion.arms:
        return Icons.sports_gymnastics_rounded;

      case BodyRegion.abdomen:
        return Icons.local_fire_department_rounded;

      case BodyRegion.quadriceps:
        return Icons.directions_walk_rounded;

      case BodyRegion.calves:
        return Icons.directions_run_rounded;
    }
  }

  // ==========================================================
  // TRAINING ACTIVITY
  // ==========================================================
  //
  // Converte a região visual para a atividade usada pelo
  // restante do sistema.
  //
  // ==========================================================

  TrainingActivityType get activity {
    switch (this) {
      case BodyRegion.chest:
        return TrainingActivityType.chest;

      case BodyRegion.shoulders:
        return TrainingActivityType.shoulders;

      case BodyRegion.arms:
        return TrainingActivityType.arms;

      case BodyRegion.abdomen:
        return TrainingActivityType.core;

      case BodyRegion.quadriceps:
      case BodyRegion.calves:
        return TrainingActivityType.legs;
    }
  }

  // ==========================================================
  // IS SAME ACTIVITY
  // ==========================================================
  //
  // Exemplo:
  //
  // quadriceps.isActivity(legs)
  // -> true
  //
  // calves.isActivity(legs)
  // -> true
  //
  // ==========================================================

  bool isActivity(
    TrainingActivityType value,
  ) {
    return activity ==
        value;
  }

  // ==========================================================
  // FROM ID
  // ==========================================================

  static BodyRegion? fromId(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();

    for (final region in BodyRegion.values) {
      if (region.id ==
          normalized) {
        return region;
      }
    }

    return null;
  }

  // ==========================================================
  // FROM ACTIVITY
  // ==========================================================
  //
  // Retorna uma região principal para uma atividade.
  //
  // Para "legs", usamos quadriceps como região principal.
  //
  // Costas não existe no mapa frontal atual.
  //
  // Corrida e caminhada também não são regiões anatômicas.
  //
  // ==========================================================

  static BodyRegion? fromActivity(
    TrainingActivityType activity,
  ) {
    switch (activity) {
      case TrainingActivityType.chest:
        return BodyRegion.chest;

      case TrainingActivityType.shoulders:
        return BodyRegion.shoulders;

      case TrainingActivityType.arms:
        return BodyRegion.arms;

      case TrainingActivityType.core:
        return BodyRegion.abdomen;

      case TrainingActivityType.legs:
        return BodyRegion.quadriceps;

      case TrainingActivityType.back:
      case TrainingActivityType.running:
      case TrainingActivityType.walking:
        return null;
    }
  }

  // ==========================================================
  // ALL REGIONS FOR ACTIVITY
  // ==========================================================
  //
  // Uma mesma atividade pode corresponder a várias áreas
  // visuais.
  //
  // Exemplo:
  //
  // legs
  //
  // ->
  //
  // quadriceps
  // calves
  //
  // ==========================================================

  static Set<
    BodyRegion
  >
  regionsForActivity(
    TrainingActivityType activity,
  ) {
    switch (activity) {
      case TrainingActivityType.chest:
        return const {
          BodyRegion.chest,
        };

      case TrainingActivityType.shoulders:
        return const {
          BodyRegion.shoulders,
        };

      case TrainingActivityType.arms:
        return const {
          BodyRegion.arms,
        };

      case TrainingActivityType.core:
        return const {
          BodyRegion.abdomen,
        };

      case TrainingActivityType.legs:
        return const {
          BodyRegion.quadriceps,
          BodyRegion.calves,
        };

      case TrainingActivityType.back:
      case TrainingActivityType.running:
      case TrainingActivityType.walking:
        return const {};
    }
  }

  // ==========================================================
  // BODY REGIONS FOR ACTIVITIES
  // ==========================================================

  static Set<
    BodyRegion
  >
  regionsForActivities(
    Iterable<
      TrainingActivityType
    >
    activities,
  ) {
    final regions =
        <
          BodyRegion
        >{};

    for (final activity in activities) {
      regions.addAll(
        regionsForActivity(
          activity,
        ),
      );
    }

    return regions;
  }
}
