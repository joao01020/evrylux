import 'brain_concept.dart';

class BrainFile {
  final String topic;

  final String title;

  final String path;

  final String content;

  /// Conhecimentos extraídos desta anotação.
  final List<
    BrainConcept
  >
  concepts;

  final DateTime updatedAt;

  const BrainFile({
    required this.topic,
    required this.title,
    required this.path,
    required this.content,
    required this.concepts,
    required this.updatedAt,
  });

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
        'updatedAt: $updatedAt'
        ')';
  }
}
