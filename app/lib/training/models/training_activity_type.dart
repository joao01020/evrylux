import 'package:flutter/material.dart';

// ============================================================
// TRAINING ACTIVITY TYPE
// ============================================================
//
// Define todos os tipos de atividade que podem ser:
//
// - configurados no mapa corporal;
// - exibidos no "Registrar treino";
// - salvos no planejamento semanal;
// - persistidos no SQLite;
// - sincronizados com Supabase.
//
// IMPORTANTE:
//
// Usamos IDs estáveis em inglês para persistência.
//
// Exemplo:
//
// chest
// legs
// arms
//
// enquanto a interface continua mostrando:
//
// Peito
// Pernas
// Braço
//
// ============================================================

enum TrainingActivityType {
  chest,
  legs,
  arms,
  back,
  shoulders,
  core,
  running,
  walking,
}

// ============================================================
// TRAINING ACTIVITY TYPE EXTENSION
// ============================================================

extension TrainingActivityTypeExtension
    on
        TrainingActivityType {
  // ==========================================================
  // ID
  // ==========================================================
  //
  // Valor usado no banco de dados.
  //
  // Não alterar depois que já existirem dados persistidos.
  //
  // ==========================================================

  String get id {
    switch (this) {
      case TrainingActivityType.chest:
        return 'chest';

      case TrainingActivityType.legs:
        return 'legs';

      case TrainingActivityType.arms:
        return 'arms';

      case TrainingActivityType.back:
        return 'back';

      case TrainingActivityType.shoulders:
        return 'shoulders';

      case TrainingActivityType.core:
        return 'core';

      case TrainingActivityType.running:
        return 'running';

      case TrainingActivityType.walking:
        return 'walking';
    }
  }

  // ==========================================================
  // LABEL
  // ==========================================================

  String get label {
    switch (this) {
      case TrainingActivityType.chest:
        return 'Peito';

      case TrainingActivityType.legs:
        return 'Pernas';

      case TrainingActivityType.arms:
        return 'Braço';

      case TrainingActivityType.back:
        return 'Costas';

      case TrainingActivityType.shoulders:
        return 'Ombro';

      case TrainingActivityType.core:
        return 'Core';

      case TrainingActivityType.running:
        return 'Corrida';

      case TrainingActivityType.walking:
        return 'Caminhada';
    }
  }

  // ==========================================================
  // SHORT LABEL
  // ==========================================================
  //
  // Útil futuramente em chips pequenos.
  //
  // ==========================================================

  String get shortLabel {
    switch (this) {
      case TrainingActivityType.chest:
        return 'Peito';

      case TrainingActivityType.legs:
        return 'Pernas';

      case TrainingActivityType.arms:
        return 'Braço';

      case TrainingActivityType.back:
        return 'Costas';

      case TrainingActivityType.shoulders:
        return 'Ombro';

      case TrainingActivityType.core:
        return 'Core';

      case TrainingActivityType.running:
        return 'Corrida';

      case TrainingActivityType.walking:
        return 'Caminhada';
    }
  }

  // ==========================================================
  // DESCRIPTION
  // ==========================================================

  String get description {
    switch (this) {
      case TrainingActivityType.chest:
        return 'Treino de peito';

      case TrainingActivityType.legs:
        return 'Treino de pernas';

      case TrainingActivityType.arms:
        return 'Treino de braços';

      case TrainingActivityType.back:
        return 'Treino de costas';

      case TrainingActivityType.shoulders:
        return 'Treino de ombros';

      case TrainingActivityType.core:
        return 'Treino de abdômen e core';

      case TrainingActivityType.running:
        return 'Treino de corrida';

      case TrainingActivityType.walking:
        return 'Caminhada';
    }
  }

  // ==========================================================
  // ICON
  // ==========================================================
  //
  // Mantém uma representação visual consistente dentro do app.
  //
  // ==========================================================

  IconData get icon {
    switch (this) {
      case TrainingActivityType.chest:
        return Icons.fitness_center_rounded;

      case TrainingActivityType.legs:
        return Icons.directions_walk_rounded;

      case TrainingActivityType.arms:
        return Icons.sports_gymnastics_rounded;

      case TrainingActivityType.back:
        return Icons.view_agenda_rounded;

      case TrainingActivityType.shoulders:
        return Icons.adjust_rounded;

      case TrainingActivityType.core:
        return Icons.local_fire_department_rounded;

      case TrainingActivityType.running:
        return Icons.directions_run_rounded;

      case TrainingActivityType.walking:
        return Icons.directions_walk_rounded;
    }
  }

  // ==========================================================
  // EMOJI
  // ==========================================================
  //
  // Mantém compatibilidade visual com os cards que você já usa
  // no modal "Registrar treino".
  //
  // ==========================================================

  String get emoji {
    switch (this) {
      case TrainingActivityType.chest:
        return '🏋️';

      case TrainingActivityType.legs:
        return '🦵';

      case TrainingActivityType.arms:
        return '💪';

      case TrainingActivityType.back:
        return '🧱';

      case TrainingActivityType.shoulders:
        return '🎯';

      case TrainingActivityType.core:
        return '🔥';

      case TrainingActivityType.running:
        return '🏃';

      case TrainingActivityType.walking:
        return '🚶';
    }
  }

  // ==========================================================
  // BODY REGION
  // ==========================================================
  //
  // true:
  // pode ser representado como parte do corpo.
  //
  // false:
  // é uma atividade geral.
  //
  // ==========================================================

  bool get isBodyRegion {
    switch (this) {
      case TrainingActivityType.chest:
      case TrainingActivityType.legs:
      case TrainingActivityType.arms:
      case TrainingActivityType.back:
      case TrainingActivityType.shoulders:
      case TrainingActivityType.core:
        return true;

      case TrainingActivityType.running:
      case TrainingActivityType.walking:
        return false;
    }
  }

  // ==========================================================
  // CARDIO
  // ==========================================================

  bool get isCardio {
    switch (this) {
      case TrainingActivityType.running:
      case TrainingActivityType.walking:
        return true;

      case TrainingActivityType.chest:
      case TrainingActivityType.legs:
      case TrainingActivityType.arms:
      case TrainingActivityType.back:
      case TrainingActivityType.shoulders:
      case TrainingActivityType.core:
        return false;
    }
  }

  // ==========================================================
  // STRENGTH
  // ==========================================================

  bool get isStrength => isBodyRegion;

  // ==========================================================
  // ORDER
  // ==========================================================
  //
  // Mantém exatamente a ordem visual que você já usa:
  //
  // Peito
  // Pernas
  // Braço
  // Costas
  // Ombro
  // Core
  // Corrida
  // Caminhada
  //
  // ==========================================================

  int get order {
    switch (this) {
      case TrainingActivityType.chest:
        return 0;

      case TrainingActivityType.legs:
        return 1;

      case TrainingActivityType.arms:
        return 2;

      case TrainingActivityType.back:
        return 3;

      case TrainingActivityType.shoulders:
        return 4;

      case TrainingActivityType.core:
        return 5;

      case TrainingActivityType.running:
        return 6;

      case TrainingActivityType.walking:
        return 7;
    }
  }

  // ==========================================================
  // FROM ID
  // ==========================================================
  //
  // Converte o valor salvo no banco para enum.
  //
  // ==========================================================

  static TrainingActivityType? fromId(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();

    for (final activity in TrainingActivityType.values) {
      if (activity.id ==
          normalized) {
        return activity;
      }
    }

    return null;
  }

  // ==========================================================
  // FROM LABEL
  // ==========================================================
  //
  // Útil para migrar seus dados antigos que podem estar salvos
  // como:
  //
  // "Peito"
  // "Pernas"
  // "Braço"
  //
  // ==========================================================

  static TrainingActivityType? fromLabel(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim().toLowerCase();

    for (final activity in TrainingActivityType.values) {
      if (activity.label.toLowerCase() ==
          normalized) {
        return activity;
      }
    }

    // ========================================================
    // COMPATIBILIDADE
    // ========================================================

    switch (normalized) {
      case 'bracos':
      case 'braços':
      case 'braco':
      case 'braço':
        return TrainingActivityType.arms;

      case 'ombros':
      case 'ombro':
        return TrainingActivityType.shoulders;

      case 'perna':
      case 'pernas':
        return TrainingActivityType.legs;

      case 'costas':
      case 'costa':
        return TrainingActivityType.back;

      case 'abdomen':
      case 'abdômen':
      case 'abdominal':
      case 'core':
        return TrainingActivityType.core;

      case 'correr':
      case 'corrida':
        return TrainingActivityType.running;

      case 'caminhar':
      case 'caminhada':
        return TrainingActivityType.walking;

      case 'peitoral':
      case 'peito':
        return TrainingActivityType.chest;
    }

    return null;
  }

  // ==========================================================
  // FROM ANY
  // ==========================================================
  //
  // Tenta:
  //
  // 1. ID
  // 2. label
  //
  // ==========================================================

  static TrainingActivityType? fromAny(
    String? value,
  ) {
    return fromId(
          value,
        ) ??
        fromLabel(
          value,
        );
  }
}

// ============================================================
// TRAINING ACTIVITY HELPERS
// ============================================================

class TrainingActivityTypes {
  TrainingActivityTypes._();

  // ==========================================================
  // ALL
  // ==========================================================

  static List<
    TrainingActivityType
  >
  get all {
    final values = TrainingActivityType.values.toList();

    values.sort(
      (
        first,
        second,
      ) {
        return first.order.compareTo(
          second.order,
        );
      },
    );

    return List<
      TrainingActivityType
    >.unmodifiable(
      values,
    );
  }

  // ==========================================================
  // BODY REGIONS
  // ==========================================================

  static List<
    TrainingActivityType
  >
  get bodyRegions {
    return List<
      TrainingActivityType
    >.unmodifiable(
      all.where(
        (
          activity,
        ) {
          return activity.isBodyRegion;
        },
      ),
    );
  }

  // ==========================================================
  // CARDIO
  // ==========================================================

  static List<
    TrainingActivityType
  >
  get cardio {
    return List<
      TrainingActivityType
    >.unmodifiable(
      all.where(
        (
          activity,
        ) {
          return activity.isCardio;
        },
      ),
    );
  }

  // ==========================================================
  // SORT
  // ==========================================================

  static List<
    TrainingActivityType
  >
  sort(
    Iterable<
      TrainingActivityType
    >
    values,
  ) {
    final result = values.toSet().toList();

    result.sort(
      (
        first,
        second,
      ) {
        return first.order.compareTo(
          second.order,
        );
      },
    );

    return result;
  }

  // ==========================================================
  // TO IDS
  // ==========================================================

  static List<
    String
  >
  toIds(
    Iterable<
      TrainingActivityType
    >
    values,
  ) {
    return sort(
          values,
        )
        .map(
          (
            activity,
          ) {
            return activity.id;
          },
        )
        .toList(
          growable: false,
        );
  }

  // ==========================================================
  // FROM IDS
  // ==========================================================

  static Set<
    TrainingActivityType
  >
  fromIds(
    Iterable<
      dynamic
    >?
    values,
  ) {
    final result =
        <
          TrainingActivityType
        >{};

    if (values ==
        null) {
      return result;
    }

    for (final value in values) {
      final activity = TrainingActivityTypeExtension.fromAny(
        value?.toString(),
      );

      if (activity !=
          null) {
        result.add(
          activity,
        );
      }
    }

    return result;
  }
}
