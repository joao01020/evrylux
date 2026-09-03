// ============================================================
// BRAIN SEARCH NORMALIZER
// ============================================================
//
// Normalização determinística e offline.
//
// Objetivos:
//
// - minúsculas;
// - remover acentos;
// - preservar símbolos úteis de termos técnicos;
// - reduzir pontuação irrelevante;
// - colapsar espaços.
//
// Exemplos:
//
// "Ponteíros em C++" -> "ponteiros em c++"
// "HTTP/REST"        -> "http rest"
//
// ============================================================

class BrainSearchNormalizer {
  const BrainSearchNormalizer._();

  // ============================================================
  // NORMALIZE
  // ============================================================

  static String normalize(String value) {
    if (value.trim().isEmpty) {
      return '';
    }

    var result = value.trim().toLowerCase();

    result = _removeDiacritics(result);

    // Mantemos alguns caracteres úteis para tecnologia:
    //
    // +  => C++
    // #  => C#
    // .  => nomes/versões/domínios
    // -  => termos compostos
    //
    result = result.replaceAll(RegExp(r'[^a-z0-9+#.\-\s]'), ' ');

    result = result.replaceAll(RegExp(r'\s+'), ' ');

    return result.trim();
  }

  // ============================================================
  // TOKENIZE
  // ============================================================

  static List<String> tokenize(String value) {
    final normalized = normalize(value);

    if (normalized.isEmpty) {
      return const <String>[];
    }

    return normalized
        .split(RegExp(r'\s+'))
        .where((token) {
          return token.trim().isNotEmpty;
        })
        .toList(growable: false);
  }

  // ============================================================
  // REMOVE DIACRITICS
  // ============================================================

  static String _removeDiacritics(String value) {
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
      'ñ': 'n',
    };

    final buffer = StringBuffer();

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);

      buffer.write(replacements[char] ?? char);
    }

    return buffer.toString();
  }
}
