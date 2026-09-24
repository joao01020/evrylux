class BrainAiContextItem {
  const BrainAiContextItem({
    required this.id,
    required this.title,
    required this.summary,
    this.type,
  });

  final String id;
  final String title;
  final String summary;
  final String? type;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'summary': summary,
    if (type != null) 'type': type,
  };
}
