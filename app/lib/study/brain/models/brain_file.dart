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

  bool get hasConcepts => concepts.isNotEmpty;

  int get conceptsCount => concepts.length;

  List<
    BrainConcept
  >
  get keepConcepts => concepts
      .where(
        (
          concept,
        ) =>
            concept.type ==
            BrainConceptType.keep,
      )
      .toList();

  List<
    BrainConcept
  >
  get memorizeConcepts => concepts
      .where(
        (
          concept,
        ) =>
            concept.type ==
            BrainConceptType.memorize,
      )
      .toList();
}
