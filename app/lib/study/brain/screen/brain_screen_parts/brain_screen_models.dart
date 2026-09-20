part of '../brain_screen.dart';

// ============================================================
// SEARCH VISUAL TARGET
// ============================================================
//
// Representa um alvo encontrado pela busca dentro do cérebro
// visual.
//
// O alvo pode apontar para:
// - uma ramificação;
// - uma conexão;
// - ambos, dependendo do resultado da busca.
//
// Atualmente a busca visual resolve o alvo através da conexão.
// Mantemos branchIndex no modelo por compatibilidade com o fluxo
// visual existente, mas ele permanece nulo enquanto não houver
// resolução explícita de ramificação.
//
// ============================================================

class _BrainSearchVisualTarget {
  const _BrainSearchVisualTarget({
    this.connectionIndex,
  }) : branchIndex = null;

  final int? branchIndex;

  final int? connectionIndex;

  bool get hasBranch =>
      branchIndex !=
      null;

  bool get hasConnection =>
      connectionIndex !=
      null;

  bool get isEmpty =>
      !hasBranch &&
      !hasConnection;
}

// ============================================================
// RASCUNHO DE PERGUNTA
// ============================================================
//
// Usado exclusivamente durante o fluxo de criação de perguntas.
//
// Cada pergunta possui seus próprios controllers para permitir
// que várias perguntas sejam preenchidas simultaneamente antes
// de serem enviadas individualmente ao BrainController.
//
// Perguntas não dependem mais de Tema.
//
// Cada rascunho contém:
// - pergunta;
// - resposta;
// - fontes;
// - configuração da primeira revisão.
//
// ============================================================

class _QuestionDraft {
  _QuestionDraft({
    _QuestionReviewDelay? delay,
  }) : delay =
           delay ??
           _QuestionReviewDelay.oneDay;

  final TextEditingController questionController = TextEditingController();

  final TextEditingController answerController = TextEditingController();

  final List<
    BrainSource
  >
  sources =
      <
        BrainSource
      >[];

  _QuestionReviewDelay delay;

  String get question => questionController.text.trim();

  String get answer => answerController.text.trim();

  bool get hasQuestion => question.isNotEmpty;

  bool get hasAnswer => answer.isNotEmpty;

  bool get isValid => hasQuestion;

  void dispose() {
    questionController.dispose();

    answerController.dispose();

    // BrainSource atualmente não possui controllers nem recursos
    // descartáveis associados ao ciclo de vida deste draft.
    //
    // Portanto, não devemos limpar `sources` aqui apenas por
    // conveniência, pois o conteúdo pode ainda estar sendo usado
    // durante a conclusão assíncrona do salvamento.
  }
}

// ============================================================
// PRIMEIRA REVISÃO DA PERGUNTA
// ============================================================
//
// Define quando a primeira revisão de uma pergunta deverá
// acontecer.
//
// Essa configuração é usada somente para a primeira revisão.
// Depois disso, o ReviewController continua responsável pelo
// agendamento das próximas revisões.
//
// ============================================================

enum _QuestionReviewDelay {
  now,
  fifteenMinutes,
  oneHour,
  oneDay,
  threeDays,
  sevenDays,
  thirtyDays;

  String get label {
    return switch (this) {
      _QuestionReviewDelay.now => 'Agora',
      _QuestionReviewDelay.fifteenMinutes => '15 minutos',
      _QuestionReviewDelay.oneHour => '1 hora',
      _QuestionReviewDelay.oneDay => '1 dia',
      _QuestionReviewDelay.threeDays => '3 dias',
      _QuestionReviewDelay.sevenDays => '7 dias',
      _QuestionReviewDelay.thirtyDays => '30 dias',
    };
  }

  Duration get duration {
    return switch (this) {
      _QuestionReviewDelay.now => Duration.zero,
      _QuestionReviewDelay.fifteenMinutes => const Duration(
        minutes: 15,
      ),
      _QuestionReviewDelay.oneHour => const Duration(
        hours: 1,
      ),
      _QuestionReviewDelay.oneDay => const Duration(
        days: 1,
      ),
      _QuestionReviewDelay.threeDays => const Duration(
        days: 3,
      ),
      _QuestionReviewDelay.sevenDays => const Duration(
        days: 7,
      ),
      _QuestionReviewDelay.thirtyDays => const Duration(
        days: 30,
      ),
    };
  }

  DateTime scheduledAt({
    DateTime? from,
  }) {
    final DateTime base =
        from ??
        DateTime.now();

    return base.add(
      duration,
    );
  }
}
