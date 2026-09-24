import '../models/brain_ai_request.dart';
import '../models/brain_ai_response.dart';

abstract class BrainAiClient {
  Future<BrainAiResponse> ask(BrainAiRequest request);
}

class BrainAiDisabledClient implements BrainAiClient {
  @override
  Future<BrainAiResponse> ask(BrainAiRequest request) {
    throw StateError(
      'BrainAiClient ainda não foi conectado ao backend.',
    );
  }
}
