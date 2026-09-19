import '../models/brain_generated_review_question.dart';
import 'brain_review_generation_queue.dart';

/// Contrato do gerador de questões de revisão.
abstract interface class BrainReviewQuestionGenerator {
  Future<List<BrainGeneratedReviewQuestion>> generate(
    BrainReviewGenerationCandidate candidate,
  );
}

/// Gerador local/offline da Fase 3.
///
/// Objetivos desta versão:
/// - trabalhar com conhecimentos grandes;
/// - separar o texto em unidades menores;
/// - ignorar comentários pessoais/intenção futura;
/// - reconhecer padrões simples de definição, função e causa/efeito;
/// - gerar perguntas abertas com resposta sustentada pelo texto original;
/// - não depender de IA nem de API externa.
class LocalBrainReviewQuestionGenerator
    implements BrainReviewQuestionGenerator {
  const LocalBrainReviewQuestionGenerator();

  static const int _maxQuestionsPerKnowledge = 8;

  @override
  Future<List<BrainGeneratedReviewQuestion>> generate(
    BrainReviewGenerationCandidate candidate,
  ) async {
    final title = candidate.title.trim();
    final knowledge = candidate.knowledge.trim();

    if (knowledge.isEmpty) {
      return const <BrainGeneratedReviewQuestion>[];
    }

    final units = _extractReviewableUnits(knowledge);
    if (units.isEmpty) {
      return const <BrainGeneratedReviewQuestion>[];
    }

    final result = <BrainGeneratedReviewQuestion>[];
    final usedQuestions = <String>{};

    for (var index = 0;
        index < units.length && result.length < _maxQuestionsPerKnowledge;
        index++) {
      final generated = _buildQuestion(
        candidate: candidate,
        title: title,
        unit: units[index],
        index: index,
      );

      if (generated == null) {
        continue;
      }

      final normalizedQuestion = generated.question.toLowerCase().trim();
      if (!usedQuestions.add(normalizedQuestion)) {
        continue;
      }

      result.add(generated);
    }

    return List<BrainGeneratedReviewQuestion>.unmodifiable(result);
  }

  List<String> _extractReviewableUnits(String text) {
    final normalized = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();

    // Mantém pontuação porque ela ajuda na classificação, mas usa também
    // quebras de linha como limite de ideia.
    final rawUnits = normalized
        .split(RegExp(r'(?<=[.!;])\s+|\n+'))
        .map(_cleanUnit)
        .where((unit) => unit.isNotEmpty)
        .toList();

    final result = <String>[];
    final seen = <String>{};

    for (final unit in rawUnits) {
      if (!_isReviewable(unit)) {
        continue;
      }

      final key = unit.toLowerCase();
      if (!seen.add(key)) {
        continue;
      }

      result.add(unit);
    }

    return result;
  }

  String _cleanUnit(String value) {
    return value
        .replaceFirst(RegExp(r'^[-•–—]\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isReviewable(String unit) {
    final clean = unit.trim();
    final lower = clean.toLowerCase();

    if (clean.length < 24 || clean.length > 520) {
      return false;
    }

    // Perguntas do próprio texto não possuem necessariamente uma resposta
    // explícita e segura para o motor local.
    if (clean.endsWith('?')) {
      return false;
    }

    const personalOrPlanningPrefixes = <String>[
      'eu acho',
      'eu achei',
      'eu gosto',
      'eu gostei',
      'achei interessante',
      'gostei de',
      'quero estudar',
      'quero pesquisar',
      'preciso estudar',
      'preciso pesquisar',
      'vou estudar',
      'vou pesquisar',
      'talvez ',
      'amanhã ',
      'hoje estudei',
      'hoje aprendi',
      'minha opinião',
    ];

    for (final prefix in personalOrPlanningPrefixes) {
      if (lower.startsWith(prefix)) {
        return false;
      }
    }

    // Para entrar na revisão a frase precisa parecer uma afirmação com uma
    // relação que o gerador saiba transformar em pergunta aberta.
    return _definitionPattern.hasMatch(clean) ||
        _purposePattern.hasMatch(clean) ||
        _behaviorPattern.hasMatch(clean) ||
        _causePattern.hasMatch(clean) ||
        _allowsPattern.hasMatch(clean) ||
        _usedForPattern.hasMatch(clean);
  }

  BrainGeneratedReviewQuestion? _buildQuestion({
    required BrainReviewGenerationCandidate candidate,
    required String title,
    required String unit,
    required int index,
  }) {
    final definition = _definitionPattern.firstMatch(unit);
    if (definition != null) {
      final subject = _cleanSubject(definition.group(1));
      final predicate = _cleanAnswer(definition.group(2));
      if (_validPair(subject, predicate)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.recall,
          question: 'O que é $subject?',
          answer: '$subject ${_definitionVerb(definition.group(0)!)} $predicate',
        );
      }
    }

    final purpose = _purposePattern.firstMatch(unit);
    if (purpose != null) {
      final subject = _cleanSubject(purpose.group(1));
      final purposeText = _cleanAnswer(purpose.group(2));
      if (_validPair(subject, purposeText)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.application,
          question: 'Para que serve $subject?',
          answer: purposeText,
        );
      }
    }

    final usedFor = _usedForPattern.firstMatch(unit);
    if (usedFor != null) {
      final subject = _cleanSubject(usedFor.group(1));
      final purposeText = _cleanAnswer(usedFor.group(2));
      if (_validPair(subject, purposeText)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.application,
          question: 'Para que $subject é utilizado?',
          answer: purposeText,
        );
      }
    }

    final cause = _causePattern.firstMatch(unit);
    if (cause != null) {
      final causeText = _cleanSubject(cause.group(1));
      final effect = _cleanAnswer(cause.group(2));
      if (_validPair(causeText, effect)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.application,
          question: 'O que pode acontecer quando $causeText?',
          answer: effect,
        );
      }
    }

    final allows = _allowsPattern.firstMatch(unit);
    if (allows != null) {
      final subject = _cleanSubject(allows.group(1));
      final effect = _cleanAnswer(allows.group(2));
      if (_validPair(subject, effect)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.explanation,
          question: 'O que $subject permite fazer?',
          answer: effect,
        );
      }
    }

    final behavior = _behaviorPattern.firstMatch(unit);
    if (behavior != null) {
      final subject = _cleanSubject(behavior.group(1));
      final action = _cleanAnswer(behavior.group(2));
      if (_validPair(subject, action)) {
        return _question(
          candidate: candidate,
          index: index,
          kind: BrainGeneratedReviewQuestionKind.explanation,
          question: 'O que $subject faz?',
          answer: action,
        );
      }
    }

    return null;
  }

  BrainGeneratedReviewQuestion _question({
    required BrainReviewGenerationCandidate candidate,
    required int index,
    required BrainGeneratedReviewQuestionKind kind,
    required String question,
    required String answer,
  }) {
    return BrainGeneratedReviewQuestion(
      id: '${candidate.conceptId}-local-$index',
      sourceConceptId: candidate.conceptId,
      kind: kind,
      question: question,
      answer: answer,
    );
  }

  bool _validPair(String subject, String answer) {
    return subject.length >= 2 &&
        subject.length <= 120 &&
        answer.length >= 3 &&
        answer.length <= 420;
  }

  String _cleanSubject(String? value) {
    var result = (value ?? '').trim();
    result = result.replaceFirst(RegExp(r'^(o|a|os|as)\s+', caseSensitive: false), '');
    return result.trim();
  }

  String _cleanAnswer(String? value) {
    var result = (value ?? '').trim();
    result = result.replaceFirst(RegExp(r'^[,:;\-–—]\s*'), '');
    result = result.replaceFirst(RegExp(r'[.;]+$'), '');
    return result.trim();
  }

  String _definitionVerb(String wholeMatch) {
    final lower = wholeMatch.toLowerCase();
    if (RegExp(r'\bsão\b').hasMatch(lower)) return 'são';
    if (RegExp(r'\bconsiste em\b').hasMatch(lower)) return 'consiste em';
    if (RegExp(r'\bsignifica\b').hasMatch(lower)) return 'significa';
    return 'é';
  }

  // "Mutex é um mecanismo..."
  static final RegExp _definitionPattern = RegExp(
    r'^(.{2,120}?)\s+(?:é|são|significa|consiste em)\s+(.{3,420})$',
    caseSensitive: false,
  );

  // "Mutex serve para proteger..."
  static final RegExp _purposePattern = RegExp(
    r'^(.{2,120}?)\s+(?:serve|servem)\s+para\s+(.{3,420})$',
    caseSensitive: false,
  );

  // "Mutex é utilizado para proteger..."
  static final RegExp _usedForPattern = RegExp(
    r'^(.{2,120}?)\s+(?:é|são)\s+(?:utilizado|utilizada|utilizados|utilizadas|usado|usada|usados|usadas)\s+para\s+(.{3,420})$',
    caseSensitive: false,
  );

  // "Acesso sem sincronização pode causar condição de corrida."
  static final RegExp _causePattern = RegExp(
    r'^(.{3,220}?)\s+(?:pode|podem)\s+(?:causar|provocar|gerar|resultar em)\s+(.{3,300})$',
    caseSensitive: false,
  );

  // "xTaskCreatePinnedToCore permite fixar..."
  static final RegExp _allowsPattern = RegExp(
    r'^(.{2,120}?)\s+(?:permite|permitem)\s+(.{3,420})$',
    caseSensitive: false,
  );

  // Verbos técnicos comuns que expressam comportamento/função.
  static final RegExp _behaviorPattern = RegExp(
    r'^(.{2,120}?)\s+(?:gerencia|gerenciam|controla|controlam|determina|determinam|define|definem|suspende|suspendem|bloqueia|bloqueiam|protege|protegem|armazena|armazenam|executa|executam|envia|enviam|recebe|recebem|converte|convertem|cria|criam|remove|removem|organiza|organizam)\s+(.{3,420})$',
    caseSensitive: false,
  );
}
