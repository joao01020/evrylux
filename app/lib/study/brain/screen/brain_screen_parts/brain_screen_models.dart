part of '../brain_screen.dart';

// ============================================================
// SEARCH VISUAL TARGET
// ============================================================

class _BrainSearchVisualTarget {
  const _BrainSearchVisualTarget({this.branchIndex, this.connectionIndex});

  final int? branchIndex;
  final int? connectionIndex;
}

// ============================================================
// RASCUNHO DE PERGUNTA
// ============================================================
//
// FASE 09:
// perguntas não dependem mais de Tema; o texto e a captura usam
// apenas pergunta, resposta e primeira revisão.
//
//
// Usado somente pelo modal de criação em lote.
//
// Cada pergunta mantém controllers próprios para permitir que
// várias perguntas sejam preenchidas simultaneamente antes de
// enviarmos uma por uma para o BrainController.
//
// ============================================================

class _QuestionDraft {
  _QuestionDraft() : delay = _QuestionReviewDelay.oneDay;

  final TextEditingController questionController = TextEditingController();

  final TextEditingController answerController = TextEditingController();

  final List<BrainSource> sources = <BrainSource>[];

  _QuestionReviewDelay delay;

  void dispose() {
    questionController.dispose();

    answerController.dispose();
  }
}

// ============================================================
// PRIMEIRA REVISÃO DA PERGUNTA
// ============================================================
//
// Configuração individual escolhida ao criar cada pergunta.
//
// O ReviewController continua responsável pelos intervalos
// seguintes após o usuário responder à revisão.
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
    switch (this) {
      case _QuestionReviewDelay.now:
        return 'Agora';

      case _QuestionReviewDelay.fifteenMinutes:
        return '15 minutos';

      case _QuestionReviewDelay.oneHour:
        return '1 hora';

      case _QuestionReviewDelay.oneDay:
        return '1 dia';

      case _QuestionReviewDelay.threeDays:
        return '3 dias';

      case _QuestionReviewDelay.sevenDays:
        return '7 dias';

      case _QuestionReviewDelay.thirtyDays:
        return '30 dias';
    }
  }

  Duration get duration {
    switch (this) {
      case _QuestionReviewDelay.now:
        return Duration.zero;

      case _QuestionReviewDelay.fifteenMinutes:
        return const Duration(minutes: 15);

      case _QuestionReviewDelay.oneHour:
        return const Duration(hours: 1);

      case _QuestionReviewDelay.oneDay:
        return const Duration(days: 1);

      case _QuestionReviewDelay.threeDays:
        return const Duration(days: 3);

      case _QuestionReviewDelay.sevenDays:
        return const Duration(days: 7);

      case _QuestionReviewDelay.thirtyDays:
        return const Duration(days: 30);
    }
  }
}
