import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../controllers/review_controller.dart';
import '../../models/brain_review_item.dart';
import '../../repositories/brain_repository.dart';

class ReviewScreen
    extends
        StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.review,
    required this.controller,
  });

  final BrainReviewItem review;

  final ReviewController controller;

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

  final BrainRepository _brainRepository = dependencies.brainRepository;

  // ============================================================
  // CURRENT REVIEW
  // ============================================================

  BrainReviewItem get _review {
    final current = widget.controller.findById(
      widget.review.id,
    );

    return current ??
        widget.review;
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

    Navigator.pop(
      context,
      true,
    );
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
  //
  // Exclui:
  //
  // 1. a revisão/pergunta;
  // 2. o BrainConcept relacionado;
  // 3. a anotação Markdown de origem;
  // 4. as demais classificações ligadas à mesma anotação;
  // 5. a presença da anotação no calendário;
  // 6. registra os DELETEs remotos pela SyncQueue.
  //
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
      // ========================================================
      // 1. NOTA DE ORIGEM + CONCEITOS
      // ========================================================
      //
      // Revisões novas guardam o caminho exato da nota.
      //
      // Portanto usamos primeiro sourceNotePath, porque ele
      // identifica diretamente o arquivo .md associado.
      //
      // Para revisões antigas sem sourceNotePath, mantemos
      // compatibilidade com a exclusão pelo conceptId.
      //
      // ========================================================

      final sourceNotePath = review.sourceNotePath.trim();

      final conceptId = review.conceptId.trim();

      if (sourceNotePath.isNotEmpty) {
        await _brainRepository.deleteConceptsByNoteId(
          sourceNotePath,
        );

        await _brainRepository.deleteNote(
          sourceNotePath,
        );
      } else if (conceptId.isNotEmpty) {
        await _brainRepository.deleteConceptAndSourceNote(
          conceptId,
        );
      }

      // ========================================================
      // 2. REVISÃO
      // ========================================================

      await widget.controller.deleteReview(
        review,
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

      widget.controller.clearMessages();

      Navigator.pop(
        context,
        true,
      );
    } catch (
      error
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
        title: const Row(
          children: [
            Icon(
              Icons.psychology_alt_outlined,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Revisão',
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
          else ...[
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
            ),
            child: Column(
              children: [
                _buildProgressInfo(),

                const SizedBox(
                  height: 18,
                ),

                _buildQuestionCard(),

                const SizedBox(
                  height: 18,
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
      ),
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

  // ============================================================
  // SMALL INFO
  // ============================================================

  Widget _smallInfo({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 19,
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 2,
            ),

            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
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
  // BUTTONS
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

  // ============================================================
  // REVIEW BUTTON
  // ============================================================

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
}
