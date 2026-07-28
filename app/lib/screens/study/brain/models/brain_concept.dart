enum BrainConceptType {
  keep,
  memorize,
}

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
}
