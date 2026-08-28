import 'package:flutter/material.dart';

import '../../controllers/review_controller.dart';
import '../../models/brain_review_item.dart';
import 'review_screen.dart';

class QuestionScreen
    extends
        StatefulWidget {
  const QuestionScreen({
    super.key,
  });

  @override
  State<
    QuestionScreen
  >
  createState() {
    return _QuestionScreenState();
  }
}

class _QuestionScreenState
    extends
        State<
          QuestionScreen
        > {
  late final ReviewController _controller;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _controller = ReviewController();

    _controller.addListener(
      _onControllerChanged,
    );

    _initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // INIT
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    _showMessages();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<
    void
  >
  _openReview(
    BrainReviewItem review,
  ) async {
    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return ReviewScreen(
                review: review,
                controller: _controller,
              );
            },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // ARCHIVE
  // ============================================================

  Future<
    void
  >
  _archive(
    BrainReviewItem review,
  ) async {
    await _controller.archiveReview(
      review,
    );

    if (!mounted) {
      return;
    }

    _showMessages();
  }

  Future<
    void
  >
  _restore(
    BrainReviewItem review,
  ) async {
    await _controller.restoreReview(
      review,
    );

    if (!mounted) {
      return;
    }

    _showMessages();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessages() {
    final error = _controller.errorMessage;

    final success = _controller.successMessage;

    if (error !=
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            error,
          ),
        ),
      );

      _controller.clearMessages();

      return;
    }

    if (success !=
        null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            success,
          ),
        ),
      );

      _controller.clearMessages();
    }
  }

  // ============================================================
  // CURRENT LIST
  // ============================================================

  List<
    BrainReviewItem
  >
  get _currentItems {
    switch (_selectedTab) {
      case 0:
        return _controller.dueReviews;

      case 1:
        return _controller.upcomingReviews;

      case 2:
        return _controller.activeReviews;

      case 3:
        return _controller.archivedReviews;

      default:
        return [];
    }
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
              Icons.help_outline_rounded,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              'Perguntas',
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _controller.isLoading
                ? null
                : () async {
                    await _controller.loadReviews();

                    if (!mounted) {
                      return;
                    }

                    _showMessages();
                  },
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                _buildSummary(),
                _buildTabs(),
                Expanded(
                  child: _buildList(),
                ),
              ],
            ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        10,
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric(
              label: 'Hoje',
              value: _controller.dueCount,
              icon: Icons.today_outlined,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: _metric(
              label: 'Próximas',
              value: _controller.upcomingCount,
              icon: Icons.schedule_outlined,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: _metric(
              label: 'Ativas',
              value: _controller.activeCount,
              icon: Icons.psychology_alt_outlined,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: _metric(
              label: 'Arquivadas',
              value: _controller.archivedCount,
              icon: Icons.archive_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required int value,
    required IconData icon,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 21,
            ),
            const SizedBox(
              height: 7,
            ),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(
              height: 3,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),
      child:
          SegmentedButton<
            int
          >(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(
                  Icons.today_outlined,
                ),
                label: Text(
                  'Hoje',
                ),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(
                  Icons.schedule_outlined,
                ),
                label: Text(
                  'Próximas',
                ),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(
                  Icons.psychology_outlined,
                ),
                label: Text(
                  'Aprendendo',
                ),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(
                  Icons.archive_outlined,
                ),
                label: Text(
                  'Arquivadas',
                ),
              ),
            ],
            selected: {
              _selectedTab,
            },
            onSelectionChanged:
                (
                  values,
                ) {
                  setState(
                    () {
                      _selectedTab = values.first;
                    },
                  );
                },
          ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _buildList() {
    final items = _currentItems;

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(
        18,
      ),
      itemCount: items.length,
      separatorBuilder:
          (
            _,
            __,
          ) {
            return const SizedBox(
              height: 10,
            );
          },
      itemBuilder:
          (
            context,
            index,
          ) {
            final review = items[index];

            return _buildReviewCard(
              review,
            );
          },
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  Widget _buildReviewCard(
    BrainReviewItem review,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: const CircleAvatar(
          child: Icon(
            Icons.help_outline_rounded,
          ),
        ),
        title: Text(
          review.question,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 6,
            ),
            Text(
              review.archived
                  ? 'Arquivada'
                  : 'Próxima revisão: ${_formatDate(review.nextReviewAt)}',
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              'Revisões: ${review.reviewCount} • '
              'Acertos: ${review.correctCount} • '
              'Erros: ${review.wrongCount}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: review.archived
            ? null
            : () {
                _openReview(
                  review,
                );
              },
        trailing:
            PopupMenuButton<
              String
            >(
              onSelected:
                  (
                    value,
                  ) async {
                    switch (value) {
                      case 'review':
                        await _openReview(
                          review,
                        );
                        break;

                      case 'archive':
                        await _archive(
                          review,
                        );
                        break;

                      case 'restore':
                        await _restore(
                          review,
                        );
                        break;
                    }
                  },
              itemBuilder:
                  (
                    _,
                  ) {
                    if (review.archived) {
                      return const [
                        PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              Icon(
                                Icons.unarchive_outlined,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Restaurar',
                              ),
                            ],
                          ),
                        ),
                      ];
                    }

                    return const [
                      PopupMenuItem(
                        value: 'review',
                        child: Row(
                          children: [
                            Icon(
                              Icons.psychology_alt_outlined,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Revisar',
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_outlined,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Arquivar',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
            ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    String message;

    switch (_selectedTab) {
      case 0:
        message = 'Nenhuma pergunta para revisar agora.';
        break;

      case 1:
        message = 'Nenhuma revisão futura.';
        break;

      case 2:
        message = 'Nenhuma pergunta em aprendizado.';
        break;

      case 3:
        message = 'Nenhuma pergunta arquivada.';
        break;

      default:
        message = 'Nenhuma pergunta.';
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.help_outline_rounded,
            size: 54,
          ),
          const SizedBox(
            height: 14,
          ),
          Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    String two(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${two(date.day)}/'
        '${two(date.month)}/'
        '${date.year} '
        '${two(date.hour)}:'
        '${two(date.minute)}';
  }
}
