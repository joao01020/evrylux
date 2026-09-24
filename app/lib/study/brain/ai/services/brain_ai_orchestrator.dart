import '../../models/brain_file.dart';
import '../../search/models/brain_search_response.dart';
import '../models/brain_ai_request.dart';
import '../models/brain_ai_response.dart';
import 'brain_ai_client.dart';
import 'brain_ai_context_builder.dart';
import 'brain_ai_intent_detector.dart';

class BrainAiOrchestrator {
  const BrainAiOrchestrator({
    required this.intentDetector,
    required this.contextBuilder,
    required this.client,
  });

  final BrainAiIntentDetector intentDetector;
  final BrainAiContextBuilder contextBuilder;
  final BrainAiClient client;

  Future<BrainAiResponse> run({
    required String rawQuery,
    required List<BrainFile> notes,
    required BrainSearchResponse searchResponse,
  }) async {
    final intent = intentDetector.detect(rawQuery);

    if (!intent.usesAi) {
      throw StateError('A consulta não exige IA.');
    }

    final context = contextBuilder.build(
      allNotes: notes,
      searchResponse: searchResponse,
    );

    return client.ask(
      BrainAiRequest(
        intent: intent,
        knowledge: context,
      ),
    );
  }
}
