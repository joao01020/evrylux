import 'brain_ai_context_item.dart';
import 'brain_ai_intent.dart';

class BrainAiRequest {
  const BrainAiRequest({
    required this.intent,
    required this.knowledge,
    this.avoidSuggestions = const <String>[],
  });

  final BrainAiIntent intent;
  final List<BrainAiContextItem> knowledge;

  /// Sugestões exibidas recentemente para o mesmo assunto.
  ///
  /// O backend usa essa lista somente para evitar repetição de próximos
  /// caminhos. Ela não altera o conhecimento real do usuário.
  final List<String> avoidSuggestions;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'intent': intent.wireName,
    'query': intent.rawQuery,
    if (intent.topic != null && intent.topic!.trim().isNotEmpty)
      'topic': intent.topic,
    'knowledge': knowledge.map((item) => item.toJson()).toList(),
    if (avoidSuggestions.isNotEmpty) 'avoidSuggestions': avoidSuggestions,
  };
}
