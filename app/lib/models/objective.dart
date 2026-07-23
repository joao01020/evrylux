class Objective {
  final String name;
  final String emoji;
  final String description;

  const Objective({
    required this.name,
    required this.emoji,
    required this.description,
  });

  String get title => "$emoji $name";
}
