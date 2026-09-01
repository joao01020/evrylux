import 'brain_concept.dart';

// ============================================================
// BRAIN FILE
// ============================================================
//
// Representa uma anotação salva no Cérebro.
//
// createdAt:
// - data original de criação;
// - usada para posicionar a anotação no calendário.
//
// updatedAt:
// - última edição da anotação.
//
// Compatibilidade:
//
// createdAt é opcional no construtor.
// Se não for informado, usamos updatedAt.
//
// ============================================================

class BrainFile {
  const BrainFile({
    required this.topic,
    required this.title,
    required this.path,
    required this.content,
    required this.concepts,
    DateTime? createdAt,
    required this.updatedAt,
  }) : createdAt =
           createdAt ??
           updatedAt;

  // ============================================================
  // DATA
  // ============================================================

  final String topic;

  final String title;

  final String path;

  final String content;

  /// Conhecimentos extraídos desta anotação.
  final List<
    BrainConcept
  >
  concepts;

  /// Data original de criação.
  ///
  /// Essa é a data usada pelo calendário.
  final DateTime createdAt;

  /// Última atualização da anotação.
  final DateTime updatedAt;

  // ============================================================
  // COPY
  // ============================================================

  BrainFile copyWith({
    String? topic,
    String? title,
    String? path,
    String? content,
    List<
      BrainConcept
    >?
    concepts,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrainFile(
      topic:
          topic ??
          this.topic,
      title:
          title ??
          this.title,
      path:
          path ??
          this.path,
      content:
          content ??
          this.content,
      concepts:
          concepts ??
          this.concepts,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // BASIC INFO
  // ============================================================

  bool get hasConcepts {
    return concepts.isNotEmpty;
  }

  int get conceptsCount {
    return concepts.length;
  }

  bool get hasTopic {
    return topic.trim().isNotEmpty;
  }

  bool get hasTitle {
    return title.trim().isNotEmpty;
  }

  bool get hasContent {
    return content.trim().isNotEmpty;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  bool wasCreatedOn(
    DateTime date,
  ) {
    final created = createdAt.toLocal();

    final target = date.toLocal();

    return created.year ==
            target.year &&
        created.month ==
            target.month &&
        created.day ==
            target.day;
  }

  bool wasUpdatedOn(
    DateTime date,
  ) {
    final updated = updatedAt.toLocal();

    final target = date.toLocal();

    return updated.year ==
            target.year &&
        updated.month ==
            target.month &&
        updated.day ==
            target.day;
  }

  // ============================================================
  // CONCEITOS
  // ============================================================

  List<
    BrainConcept
  >
  get conceptItems {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            BrainConceptType.concept;
      },
    ).toList();
  }

  int get conceptCount {
    return conceptItems.length;
  }

  // ============================================================
  // PERGUNTAS
  // ============================================================

  List<
    BrainConcept
  >
  get questionItems {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            BrainConceptType.question;
      },
    ).toList();
  }

  int get questionCount {
    return questionItems.length;
  }

  // ============================================================
  // EXEMPLOS
  // ============================================================

  List<
    BrainConcept
  >
  get exampleItems {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            BrainConceptType.example;
      },
    ).toList();
  }

  int get exampleCount {
    return exampleItems.length;
  }

  // ============================================================
  // ATENÇÕES
  // ============================================================

  List<
    BrainConcept
  >
  get warningItems {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            BrainConceptType.warning;
      },
    ).toList();
  }

  int get warningCount {
    return warningItems.length;
  }

  // ============================================================
  // FILTER BY TYPE
  // ============================================================

  List<
    BrainConcept
  >
  conceptsByType(
    BrainConceptType type,
  ) {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            type;
      },
    ).toList();
  }

  // ============================================================
  // HAS TYPE
  // ============================================================

  bool hasConceptType(
    BrainConceptType type,
  ) {
    return concepts.any(
      (
        concept,
      ) {
        return concept.type ==
            type;
      },
    );
  }

  // ============================================================
  // TOTAL BY TYPE
  // ============================================================

  int countByType(
    BrainConceptType type,
  ) {
    return concepts.where(
      (
        concept,
      ) {
        return concept.type ==
            type;
      },
    ).length;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainFile('
        'topic: $topic, '
        'title: $title, '
        'path: $path, '
        'concepts: ${concepts.length}, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
