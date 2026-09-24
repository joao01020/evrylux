import 'brain_ai_context_item.dart';
import 'brain_ai_intent.dart';

class BrainAiRequest {
  const BrainAiRequest({
    required this.intent,
    required this.knowledge,
  });

  final BrainAiIntent intent;
  final List<BrainAiContextItem> knowledge;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'intent': intent.wireName,
    'query': intent.rawQuery,
    if (intent.topic != null && intent.topic!.trim().isNotEmpty)
      'topic': intent.topic,
    'knowledge': knowledge.map((item) => item.toJson()).toList(),
  };
}
