import 'package:flutter/material.dart';

// ============================================================
// BRAIN CONCEPT TYPE
// ============================================================

enum BrainConceptType {
  concept,
  question,
  example,
  warning,
}

// ============================================================
// BRAIN CONCEPT TYPE EXTENSION
// ============================================================

extension BrainConceptTypeExtension
    on
        BrainConceptType {
  // ============================================================
  // LABEL
  // ============================================================

  String get label {
    switch (this) {
      case BrainConceptType.concept:
        return 'Conceito';

      case BrainConceptType.question:
        return 'Pergunta';

      case BrainConceptType.example:
        return 'Exemplo';

      case BrainConceptType.warning:
        return 'Atenção';
    }
  }

  // ============================================================
  // EMOJI
  // ============================================================

  String get emoji {
    switch (this) {
      case BrainConceptType.concept:
        return '💡';

      case BrainConceptType.question:
        return '❓';

      case BrainConceptType.example:
        return '🧩';

      case BrainConceptType.warning:
        return '⚠️';
    }
  }

  // ============================================================
  // ICON
  // ============================================================

  IconData get icon {
    switch (this) {
      case BrainConceptType.concept:
        return Icons.lightbulb_outline_rounded;

      case BrainConceptType.question:
        return Icons.help_outline_rounded;

      case BrainConceptType.example:
        return Icons.code_rounded;

      case BrainConceptType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  // ============================================================
  // COLOR
  // ============================================================

  Color get color {
    switch (this) {
      case BrainConceptType.concept:
        return const Color(
          0xFF74C97B,
        );

      case BrainConceptType.question:
        return const Color(
          0xFF6FA8FF,
        );

      case BrainConceptType.example:
        return const Color(
          0xFFB48CFF,
        );

      case BrainConceptType.warning:
        return const Color(
          0xFFFFB866,
        );
    }
  }

  // ============================================================
  // FOLDER
  // ============================================================

  String get folderName {
    switch (this) {
      case BrainConceptType.concept:
        return 'concepts';

      case BrainConceptType.question:
        return 'questions';

      case BrainConceptType.example:
        return 'examples';

      case BrainConceptType.warning:
        return 'warnings';
    }
  }

  // ============================================================
  // DESCRIPTION
  // ============================================================

  String get description {
    switch (this) {
      case BrainConceptType.concept:
        return 'Uma ideia principal do conteúdo.';

      case BrainConceptType.question:
        return 'Uma pergunta para revisar depois.';

      case BrainConceptType.example:
        return 'Um exemplo prático do conteúdo.';

      case BrainConceptType.warning:
        return 'Um detalhe importante ou erro comum.';
    }
  }

  // ============================================================
  // FROM STRING
  // ============================================================

  static BrainConceptType fromString(
    String? value,
  ) {
    final normalized =
        value?.trim().toLowerCase() ??
        '';

    switch (normalized) {
      case 'concept':
      case 'conceito':
        return BrainConceptType.concept;

      case 'question':
      case 'pergunta':
        return BrainConceptType.question;

      case 'example':
      case 'exemplo':
        return BrainConceptType.example;

      case 'warning':
      case 'attention':
      case 'atenção':
      case 'atencao':
        return BrainConceptType.warning;

      // ========================================================
      // COMPATIBILIDADE COM DADOS ANTIGOS
      // ========================================================

      case 'keep':
      case 'memorize':
        return BrainConceptType.concept;

      default:
        return BrainConceptType.concept;
    }
  }
}

// ============================================================
// BRAIN CONCEPT
// ============================================================

class BrainConcept {
  final String id;

  final String title;

  final String description;

  final BrainConceptType type;

  const BrainConcept({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
  });

  // ============================================================
  // HELPERS
  // ============================================================

  String get label {
    return type.label;
  }

  String get emoji {
    return type.emoji;
  }

  IconData get icon {
    return type.icon;
  }

  Color get color {
    return type.color;
  }

  String get folderName {
    return type.folderName;
  }

  String get typeDescription {
    return type.description;
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'id': id,

      'title': title,

      'description': description,

      'type': type.name,
    };
  }

  factory BrainConcept.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return BrainConcept(
      id:
          json['id']?.toString().trim() ??
          '',

      title:
          json['title']?.toString().trim() ??
          '',

      description:
          json['description']?.toString().trim() ??
          '',

      type: BrainConceptTypeExtension.fromString(
        json['type']?.toString(),
      ),
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainConcept copyWith({
    String? id,
    String? title,
    String? description,
    BrainConceptType? type,
  }) {
    return BrainConcept(
      id:
          id ??
          this.id,

      title:
          title ??
          this.title,

      description:
          description ??
          this.description,

      type:
          type ??
          this.type,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is BrainConcept &&
        other.id ==
            id &&
        other.title ==
            title &&
        other.description ==
            description &&
        other.type ==
            type;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      type,
    );
  }

  // ============================================================
  // TO STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainConcept('
        'id: $id, '
        'title: $title, '
        'description: $description, '
        'type: ${type.name}'
        ')';
  }
}
