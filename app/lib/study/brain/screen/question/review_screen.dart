import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../controllers/review_controller.dart';
import '../../models/brain_review_item.dart';
import '../../services/brain_review_deletion_service.dart';

// ============================================================
// REVIEW SCREEN
// ============================================================
//
// FASE 10 — REVISÃO CONSOLIDADA
//
// Continua aceitando uma única revisão, mas também pode receber
// [sessionReviews] para executar uma sessão contínua:
//
// pergunta -> mostrar resposta -> avaliar -> próxima pergunta.
//
// Ao terminar a fila, a própria tela mostra um resumo da sessão.
//
// ============================================================

class ReviewScreen
    extends
        StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.review,
    required this.controller,
    this.sessionReviews,
  });

  final BrainReviewItem review;

  final ReviewController controller;

  final List<
    BrainReviewItem
  >?
  sessionReviews;

  @override
  State<
    ReviewScreen
  >
  createState() {
    return _ReviewScreenState();
  }
}

class _ReviewScreenState
    extends
        State<
          ReviewScreen
        > {
  bool _showAnswer = false;

  bool _isSubmitting = false;

  bool _sessionCompleted = false;

  int _currentIndex = 0;

  int _sessionAnswered = 0;

  int _sessionCorrect = 0;

  int _sessionWrong = 0;

  late final BrainReviewDeletionService _deletionService;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _deletionService = BrainReviewDeletionService(
      brainRepository: dependencies.brainRepository,
      reviewController: widget.controller,
    );
  }

  // ============================================================
  // SESSION
  // ============================================================

  bool get _isSession {
    return widget.sessionReviews !=
            null &&
        widget.sessionReviews!.isNotEmpty;
  }

  List<
    BrainReviewItem
  >
  get _sessionItems {
    final items = widget.sessionReviews;

    if (items ==
            null ||
        items.isEmpty) {
      return [
        widget.review,
      ];
    }

    return items;
  }

  BrainReviewItem get _seedReview {
    if (!_isSession) {
      return widget.review;
    }

    final items = _sessionItems;

    final safeIndex = _currentIndex.clamp(
      0,
      items.length -
          1,
    );

    return items[safeIndex];
  }

  // ============================================================
  // CURRENT REVIEW
  // ============================================================

  BrainReviewItem get _review {
    final seed = _seedReview;

    final current = widget.controller.findById(
      seed.id,
    );

    return current ??
        seed;
  }

  // ============================================================
  // ANSWER
  // ============================================================

  Future<
    void
  >
  _answer(
    ReviewAnswer answer,
  ) async {
    if (_isSubmitting) {
      return;
    }

    setState(
      () {
        _isSubmitting = true;
      },
    );

    await widget.controller.answerReview(
      review: _review,
      answer: answer,
    );

    if (!mounted) {
      return;
    }

    final error = widget.controller.errorMessage;

    if (error !=
        null) {
      setState(
        () {
          _isSubmitting = false;
        },
      );

      _showMessage(
        error,
      );

      widget.controller.clearMessages();

      return;
    }

    if (!_isSession) {
      Navigator.pop(
        context,
        true,
      );

      return;
    }

    _registerSessionAnswer(
      answer,
    );

    final hasNext =
        _currentIndex <
        _sessionItems.length -
            1;

    if (hasNext) {
      setState(
        () {
          _currentIndex++;
          _showAnswer = false;
          _isSubmitting = false;
        },
      );

      return;
    }

    setState(
      () {
        _sessionCompleted = true;
        _showAnswer = false;
        _isSubmitting = false;
      },
    );
  }

  void _registerSessionAnswer(
    ReviewAnswer answer,
  ) {
    _sessionAnswered++;

    if (answer ==
            ReviewAnswer.good ||
        answer ==
            ReviewAnswer.easy) {
      _sessionCorrect++;
    }

    if (answer ==
        ReviewAnswer.again) {
      _sessionWrong++;
    }
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<
    void
  >
  _archive() async {
    if (_isSubmitting) {
      return;
    }

    setState(
      () {
        _isSubmitting = true;
      },
    );

    await widget.controller.archiveReview(
      _review,
    );

    if (!mounted) {
      return;
    }

    final error = widget.controller.errorMessage;

    if (error !=
        null) {
      setState(
        () {
          _isSubmitting = false;
        },
      );

      _showMessage(
        error,
      );

      widget.controller.clearMessages();

      return;
    }

    Navigator.pop(
      context,
      true,
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _delete() async {
    if (_isSubmitting) {
      return;
    }

    final review = _review;

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir pergunta?',
                  ),
                  content: Text(
                    'Deseja excluir permanentemente "${review.question}"?\n\n'
                    'A anotação de origem também será apagada do Cérebro e do calendário.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      child: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted ||
        confirmed !=
            true) {
      return;
    }

    setState(
      () {
        _isSubmitting = true;
      },
    );

    try {
      await _deletionService.deleteReviewAndSource(
        review,
      );

      if (!mounted) {
        return;
      }

      widget.controller.clearMessages();

      Navigator.pop(
        context,
        true,
      );
    } catch (
      _
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSubmitting = false;
        },
      );

      _showMessage(
        'Não foi possível excluir a pergunta e a anotação de origem.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    final messenger = ScaffoldMessenger.of(
      context,
    );

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.psychology_alt_outlined,
            ),
            const SizedBox(
              width: 10,
            ),
            Text(
              _isSession
                  ? 'Sessão de revisão'
                  : 'Revisão',
            ),
          ],
        ),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
              ),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          else if (!_isSession &&
              !_sessionCompleted) ...[
            IconButton(
              tooltip: 'Excluir pergunta',
              onPressed: _delete,
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Arquivar pergunta',
              onPressed: _archive,
              icon: const Icon(
                Icons.archive_outlined,
              ),
            ),
          ],
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: _sessionCompleted
          ? _buildSessionCompleted()
          : _buildReviewBody(),
    );
  }

  // ============================================================
  // REVIEW BODY
  // ============================================================

  Widget _buildReviewBody() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 760,
          ),
          child: Column(
            children: [
              if (_isSession) ...[
                _buildSessionProgress(),
                const SizedBox(
                  height: 18,
                ),
              ],

              _buildProgressInfo(),

              const SizedBox(
                height: 12,
              ),

              _buildQuestionCard(),

              const SizedBox(
                height: 14,
              ),

              if (!_showAnswer)
                _buildShowAnswerButton()
              else ...[
                _buildAnswerCard(),

                const SizedBox(
                  height: 22,
                ),

                _buildAnswerButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SESSION PROGRESS
  // ============================================================

  Widget _buildSessionProgress() {
    final total = _sessionItems.length;
    final current =
        (_currentIndex +
                1)
            .clamp(
              1,
              total,
            );

    final progress =
        total <=
            0
        ? 0.0
        : current /
              total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Pergunta $current de $total',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ),

        const SizedBox(
          height: 8,
        ),

        LinearProgressIndicator(
          value: progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(
            999,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildProgressInfo() {
    final review = _review;

    return Row(
      children: [
        Expanded(
          child: _smallInfo(
            icon: Icons.repeat,
            title: '${review.reviewCount}',
            subtitle: 'Revisões',
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _smallInfo(
            icon: Icons.check_circle_outline,
            title: '${review.correctCount}',
            subtitle: 'Acertos',
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _smallInfo(
            icon: Icons.cancel_outlined,
            title: '${review.wrongCount}',
            subtitle: 'Erros',
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: _smallInfo(
            icon: Icons.local_fire_department_outlined,
            title: '${review.streak}',
            subtitle: 'Sequência',
          ),
        ),
      ],
    );
  }

  Widget _smallInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(
      context,
    );

    return Container(
      constraints: const BoxConstraints(
        minHeight: 44,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
          ),

          const SizedBox(
            width: 7,
          ),

          Flexible(
            child: Text(
              '$title $subtitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION
  // ============================================================

  Widget _buildQuestionCard() {
    final review = _review;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        28,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: Theme.of(
            context,
          ).dividerColor,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 38,
          ),

          const SizedBox(
            height: 18,
          ),

          Text(
            review.question,
            textAlign: TextAlign.center,
            style:
                Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SHOW ANSWER
  // ============================================================

  Widget _buildShowAnswerButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        onPressed: _isSubmitting
            ? null
            : () {
                setState(
                  () {
                    _showAnswer = true;
                  },
                );
              },
        icon: const Icon(
          Icons.visibility_outlined,
        ),
        label: const Text(
          'Mostrar resposta',
        ),
      ),
    );
  }

  // ============================================================
  // ANSWER CARD
  // ============================================================

  Widget _buildAnswerCard() {
    final review = _review;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(
          16,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
              ),
              SizedBox(
                width: 8,
              ),
              Text(
                'Resposta',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          SelectableText(
            review.answer,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),

          if (review.sourceNoteTitle.trim().isNotEmpty) ...[
            const SizedBox(
              height: 18,
            ),

            const Divider(),

            const SizedBox(
              height: 6,
            ),

            Text(
              'Origem: ${review.sourceNoteTitle}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ANSWER BUTTONS
  // ============================================================

  Widget _buildAnswerButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Como foi sua lembrança?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _reviewButton(
              label: 'Errei',
              subtitle: '15 min',
              icon: Icons.replay,
              answer: ReviewAnswer.again,
            ),
            _reviewButton(
              label: 'Difícil',
              subtitle: '1 dia',
              icon: Icons.sentiment_dissatisfied_outlined,
              answer: ReviewAnswer.hard,
            ),
            _reviewButton(
              label: 'Acertei',
              subtitle: '3+ dias',
              icon: Icons.check_circle_outline,
              answer: ReviewAnswer.good,
            ),
            _reviewButton(
              label: 'Fácil',
              subtitle: '7+ dias',
              icon: Icons.auto_awesome_outlined,
              answer: ReviewAnswer.easy,
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required ReviewAnswer answer,
  }) {
    return SizedBox(
      width: 160,
      height: 66,
      child: OutlinedButton(
        onPressed: _isSubmitting
            ? null
            : () {
                _answer(
                  answer,
                );
              },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
            ),

            const SizedBox(
              width: 8,
            ),

            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SESSION COMPLETED
  // ============================================================

  Widget _buildSessionCompleted() {
    final neutral =
        _sessionAnswered -
        _sessionCorrect -
        _sessionWrong;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 620,
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.done_all_rounded,
                  size: 38,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Text(
                'Sessão concluída',
                style:
                    Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Você revisou $_sessionAnswered '
                '${_sessionAnswered == 1 ? 'pergunta' : 'perguntas'} nesta sessão.',
                textAlign: TextAlign.center,
              ),

              const SizedBox(
                height: 24,
              ),

              Row(
                children: [
                  Expanded(
                    child: _sessionMetric(
                      icon: Icons.check_circle_outline,
                      value: _sessionCorrect,
                      label: 'Acertei/Fácil',
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: _sessionMetric(
                      icon: Icons.sentiment_dissatisfied_outlined,
                      value: neutral,
                      label: 'Difícil',
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: _sessionMetric(
                      icon: Icons.replay,
                      value: _sessionWrong,
                      label: 'Errei',
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 26,
              ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      true,
                    );
                  },
                  icon: const Icon(
                    Icons.check_rounded,
                  ),
                  label: const Text(
                    'Concluir',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionMetric({
    required IconData icon,
    required int value,
    required String label,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        child: Column(
          children: [
            Icon(
              icon,
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
