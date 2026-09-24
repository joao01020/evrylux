import '../models/brain_ai_intent.dart';

class BrainAiIntentDetector {
  const BrainAiIntentDetector();

  BrainAiIntent detect(String rawQuery) {
    final original = rawQuery.trim();
    final query = _normalize(original);

    final rules = <BrainAiIntentType, List<RegExp>>{
      BrainAiIntentType.studyGaps: [
        RegExp(r'\bo que (?:ainda )?falta (?:eu )?aprender\b'),
        RegExp(r'\bo que devo aprender\b'),
        RegExp(r'\bo que posso aprender\b'),
        RegExp(r'\bproximos? passos?\b'),
      ],
      BrainAiIntentType.knowledgeSummary: [
        RegExp(r'\bo que (?:eu )?ja aprendi\b'),
        RegExp(r'\bo que (?:eu )?sei sobre\b'),
        RegExp(r'\bmeu conhecimento sobre\b'),
      ],
      BrainAiIntentType.relatedKnowledge: [
        RegExp(r'\bo que (?:tem|esta) rela(?:cao|cionado)\b'),
        RegExp(r'\brelacionad[oa]s? (?:a|com)\b'),
      ],
      BrainAiIntentType.reviewSuggestions: [
        RegExp(r'\bo que (?:eu )?devo revisar\b'),
        RegExp(r'\bo que revisar\b'),
      ],
      BrainAiIntentType.openQuestions: [
        RegExp(r'\bo que (?:eu )?nao entendi\b'),
        RegExp(r'\bperguntas? (?:em aberto|sem resposta)\b'),
      ],
    };

    for (final entry in rules.entries) {
      if (entry.value.any((pattern) => pattern.hasMatch(query))) {
        return BrainAiIntent(
          type: entry.key,
          rawQuery: original,
          topic: _extractTopic(query),
        );
      }
    }

    return BrainAiIntent(
      type: BrainAiIntentType.normalSearch,
      rawQuery: original,
    );
  }

  String? _extractTopic(String query) {
    final match =
        RegExp(r'\b(?:sobre|de|do|da)\s+(.+?)\s*[?!.]*$').firstMatch(query);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const map = {
      'á':'a','à':'a','â':'a','ã':'a','ä':'a',
      'é':'e','è':'e','ê':'e','ë':'e',
      'í':'i','ì':'i','î':'i','ï':'i',
      'ó':'o','ò':'o','ô':'o','õ':'o','ö':'o',
      'ú':'u','ù':'u','û':'u','ü':'u','ç':'c',
    };
    map.forEach((a,b) => result = result.replaceAll(a,b));
    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
