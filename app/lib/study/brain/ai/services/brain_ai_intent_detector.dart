import '../models/brain_ai_intent.dart';

class BrainAiIntentDetector {
  const BrainAiIntentDetector();

  BrainAiIntent detect(String rawQuery) {
    final original = rawQuery.trim();

    if (original.isEmpty) {
      return const BrainAiIntent(
        type: BrainAiIntentType.normalSearch,
        rawQuery: '',
      );
    }

    final normalized = _normalize(original);

    final type = _detectType(normalized);

    if (type == BrainAiIntentType.normalSearch) {
      return BrainAiIntent(type: type, rawQuery: original);
    }

    return BrainAiIntent(
      type: type,
      rawQuery: original,
      topic: _extractTopic(original: original, normalized: normalized),
    );
  }

  // ============================================================
  // DETECÇÃO DA INTENÇÃO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // As frases exibidas no modal precisam estar representadas aqui.
  //
  // Atualmente suportamos:
  //
  // - o que eu já aprendi sobre ...
  // - o que eu sei sobre ...
  // - o que falta eu aprender sobre ...
  // - o que eu deveria revisar sobre ...
  // - quais conhecimentos estão relacionados a ...
  // - quais perguntas eu ainda tenho sobre ...
  //
  // ============================================================

  BrainAiIntentType _detectType(String query) {
    final rules = <BrainAiIntentType, List<RegExp>>{
      BrainAiIntentType.studyGaps: [
        RegExp(r'\bo que (?:ainda )?falta (?:eu )?aprender\b'),
        RegExp(r'\bo que (?:eu )?devo aprender\b'),
        RegExp(r'\bo que (?:eu )?posso aprender\b'),
        RegExp(r'\bproximos? passos?\b'),
      ],

      BrainAiIntentType.knowledgeSummary: [
        RegExp(r'\bo que (?:eu )?ja aprendi\b'),
        RegExp(r'\bo que (?:eu )?sei sobre\b'),
        RegExp(r'\bmeu conhecimento sobre\b'),
      ],

      BrainAiIntentType.relatedKnowledge: [
        RegExp(
          r'\bquais conhecimentos? (?:estao )?relacionad[oa]s? (?:a|com)\b',
        ),
        RegExp(r'\bconhecimentos? relacionad[oa]s? (?:a|com)\b'),
        RegExp(r'\bo que (?:tem|esta) relacao com\b'),
        RegExp(r'\bo que esta relacionado (?:a|com)\b'),
      ],

      BrainAiIntentType.reviewSuggestions: [
        RegExp(r'\bo que (?:eu )?devo revisar\b'),
        RegExp(r'\bo que (?:eu )?deveria revisar\b'),
        RegExp(r'\bo que revisar\b'),
      ],

      BrainAiIntentType.openQuestions: [
        RegExp(r'\bquais perguntas? (?:eu )?ainda tenho sobre\b'),
        RegExp(r'\bque perguntas? (?:eu )?ainda tenho sobre\b'),
        RegExp(r'\bquais duvidas? (?:eu )?ainda tenho sobre\b'),
        RegExp(r'\bo que (?:eu )?nao entendi\b'),
        RegExp(r'\bperguntas? (?:em aberto|sem resposta)\b'),
      ],
    };

    for (final entry in rules.entries) {
      if (entry.value.any((pattern) => pattern.hasMatch(query))) {
        return entry.key;
      }
    }

    return BrainAiIntentType.normalSearch;
  }

  // ============================================================
  // EXTRAÇÃO DO ASSUNTO
  // ============================================================
  //
  // O detector identifica a intenção usando texto normalizado, mas
  // preserva o texto ORIGINAL do assunto para não perder:
  //
  // - maiúsculas;
  // - acentos;
  // - símbolos como C++;
  // - nomes técnicos.
  //
  // Exemplo:
  //
  // "o que eu deveria revisar sobre ESP32"
  //
  // topic = "ESP32"
  //
  // ============================================================

  String? _extractTopic({
    required String original,
    required String normalized,
  }) {
    final prefixes = <String>[
      // Conhecimento acumulado.
      'o que eu já aprendi sobre',
      'o que já aprendi sobre',
      'o que eu sei sobre',
      'o que sei sobre',
      'meu conhecimento sobre',

      // Lacunas.
      'o que ainda falta eu aprender sobre',
      'o que ainda falta aprender sobre',
      'o que falta eu aprender sobre',
      'o que falta aprender sobre',
      'o que eu devo aprender sobre',
      'o que devo aprender sobre',
      'o que eu posso aprender sobre',
      'o que posso aprender sobre',
      'próximos passos sobre',
      'proximo passo sobre',

      // Revisão.
      'o que eu deveria revisar sobre',
      'o que deveria revisar sobre',
      'o que eu devo revisar sobre',
      'o que devo revisar sobre',
      'o que revisar sobre',

      // Conhecimentos relacionados.
      'quais conhecimentos estão relacionados a',
      'quais conhecimentos estão relacionados com',
      'quais conhecimentos relacionados a',
      'quais conhecimentos relacionados com',
      'conhecimentos relacionados a',
      'conhecimentos relacionados com',
      'o que está relacionado a',
      'o que está relacionado com',
      'o que tem relação com',

      // Perguntas em aberto.
      'quais perguntas eu ainda tenho sobre',
      'quais perguntas ainda tenho sobre',
      'que perguntas eu ainda tenho sobre',
      'que perguntas ainda tenho sobre',
      'quais dúvidas eu ainda tenho sobre',
      'quais dúvidas ainda tenho sobre',
      'o que eu não entendi sobre',
      'o que não entendi sobre',
      'perguntas em aberto sobre',
      'perguntas sem resposta sobre',
    ];

    final ordered = <String>[...prefixes]
      ..sort(
        (first, second) =>
            _normalize(second).length.compareTo(_normalize(first).length),
      );

    for (final prefix in ordered) {
      final normalizedPrefix = _normalize(prefix);

      if (normalized == normalizedPrefix) {
        return null;
      }

      final prefixWithSpace = '$normalizedPrefix ';

      if (!normalized.startsWith(prefixWithSpace)) {
        continue;
      }

      final prefixWordCount = normalizedPrefix
          .split(' ')
          .where((value) => value.trim().isNotEmpty)
          .length;

      final originalWords = original
          .split(RegExp(r'\s+'))
          .where((value) => value.trim().isNotEmpty)
          .toList();

      if (originalWords.length <= prefixWordCount) {
        return null;
      }

      final topic = originalWords
          .skip(prefixWordCount)
          .join(' ')
          .replaceFirst(RegExp(r'[?!.]+$'), '')
          .trim();

      return topic.isEmpty ? null : topic;
    }

    // Fallback para variações não cadastradas explicitamente,
    // mas que ainda possuam "sobre".
    final fallback = RegExp(
      r'\bsobre\s+(.+?)\s*[?!.]*$',
    ).firstMatch(normalized);

    final value = fallback?.group(1)?.trim();

    return value == null || value.isEmpty ? null : value;
  }

  // ============================================================
  // NORMALIZAÇÃO
  // ============================================================

  String _normalize(String value) {
    var result = value.toLowerCase();

    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'õ': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    replacements.forEach((source, target) {
      result = result.replaceAll(source, target);
    });

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
