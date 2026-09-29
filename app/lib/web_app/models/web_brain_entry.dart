import '../../study/brain/models/brain_concept.dart';

class WebBrainEntry {
  const WebBrainEntry({
    required this.objectId,
    required this.title,
    required this.description,
    required this.type,
    required this.updatedAt,
    this.reviewEnabled = false,
  });

  final String objectId;
  final String title;
  final String description;
  final BrainConceptType type;
  final DateTime updatedAt;
  final bool reviewEnabled;
}
