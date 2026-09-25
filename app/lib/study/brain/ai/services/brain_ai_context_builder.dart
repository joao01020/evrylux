import '../../models/brain_file.dart';
import '../../search/models/brain_search_response.dart';
import '../models/brain_ai_context_item.dart';

class BrainAiContextBuilder {
  const BrainAiContextBuilder({this.maxItems = 8, this.maxSummaryChars = 240});

  final int maxItems;
  final int maxSummaryChars;

  List<BrainAiContextItem> build({
    required List<BrainFile> allNotes,
    required BrainSearchResponse searchResponse,
  }) {
    // ============================================================
    // CONTEXTO DA IA — SOMENTE CONHECIMENTO RELEVANTE
    // ============================================================
    //
    // OBJETIVO:
    //
    // manter a consulta:
    //
    // - econômica;
    // - rápida;
    // - privada;
    // - relevante.
    //
    // A IA NÃO recebe o Cérebro inteiro.
    //
    // Ela recebe somente os resultados que a busca local já
    // classificou como relacionados à pergunta atual.
    //
    // IMPORTANTE:
    //
    // allNotes continua no contrato por compatibilidade com o
    // BrainAiOrchestrator atual, mas NÃO é usado como fallback.
    //
    // Se a busca local não encontrar nada:
    //
    // contexto enviado = []
    //
    // Isso é melhor do que enviar notas aleatórias.
    //
    // ============================================================

    final ranked = <BrainFile>[
      ...searchResponse.topResults,
      ...searchResponse.allResults,
    ];

    // ============================================================
    // SEM RESULTADO LOCAL
    // ============================================================

    if (ranked.isEmpty) {
      return const <BrainAiContextItem>[];
    }

    // ============================================================
    // DEDUPLICAÇÃO
    // ============================================================
    //
    // topResults normalmente também fazem parte de allResults.
    //
    // Portanto uma mesma nota pode aparecer duas vezes na lista
    // combinada.
    //
    // O Set impede duplicação de contexto e desperdício de tokens.
    //
    // ============================================================

    final seen = <String>{};

    final output = <BrainAiContextItem>[];

    for (final note in ranked) {
      // ==========================================================
      // ID
      // ==========================================================
      //
      // Preferimos o path porque normalmente ele identifica a nota
      // de forma consistente.
      //
      // Para conteúdo antigo sem path usamos um fallback apenas
      // para deduplicação desta requisição.
      //
      // ==========================================================

      final trimmedPath = note.path.trim();

      final id = trimmedPath.isNotEmpty
          ? trimmedPath
          : '${note.createdAt.microsecondsSinceEpoch}:'
                '${note.title.hashCode}';

      if (!seen.add(id)) {
        continue;
      }

      // ==========================================================
      // TÍTULO
      // ==========================================================

      final trimmedTitle = note.title.trim();

      final title = trimmedTitle.isEmpty ? 'Sem título' : trimmedTitle;

      // ==========================================================
      // RESUMO COMPACTO
      // ==========================================================
      //
      // Não enviamos o conteúdo inteiro da nota.
      //
      // Isso reduz:
      //
      // - tokens;
      // - latência;
      // - exposição de dados;
      // - custo.
      //
      // ==========================================================

      final summary = _compact(note.content);

      // ==========================================================
      // TIPO
      // ==========================================================

      final type = note.concepts.isEmpty ? 'note' : 'knowledge';

      // ==========================================================
      // CONTEXTO
      // ==========================================================

      output.add(
        BrainAiContextItem(id: id, title: title, summary: summary, type: type),
      );

      // ==========================================================
      // LIMITE
      // ==========================================================
      //
      // Por padrão:
      //
      // máximo = 8 conhecimentos
      //
      // ==========================================================

      if (output.length >= maxItems) {
        break;
      }
    }

    return output;
  }

  // ==============================================================
  // COMPACTAR CONTEÚDO
  // ==============================================================
  //
  // Exemplo:
  //
  // entrada:
  //
  // "SPI permite comunicação entre dispositivos...\n\n..."
  //
  // saída:
  //
  // "SPI permite comunicação entre dispositivos..."
  //
  // ==============================================================
  String _compact(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();

    // ============================================================
    // CONTEÚDO VAZIO
    // ============================================================

    if (clean.isEmpty) {
      return '';
    }

    // ============================================================
    // JÁ CABE NO LIMITE
    // ============================================================

    if (clean.length <= maxSummaryChars) {
      return clean;
    }

    // ============================================================
    // CORTE SEGURO
    // ============================================================
    //
    // Tentamos evitar cortar no meio de uma palavra.
    //
    // ============================================================

    final rawCut = clean.substring(0, maxSummaryChars);

    final lastSpace = rawCut.lastIndexOf(' ');

    final compacted = lastSpace > 80 ? rawCut.substring(0, lastSpace) : rawCut;

    return '${compacted.trim()}…';
  }
}
