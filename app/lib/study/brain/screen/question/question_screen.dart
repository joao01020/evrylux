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

  bool _isDeleting = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = ReviewController();

    _controller.addListener(
      _onControllerChanged,
    );

    _initialize();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

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

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  _refresh() async {
    await _controller.loadReviews();

    if (!mounted) {
      return;
    }

    _showMessages();
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
    if (review.archived) {
      return;
    }

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

    await _controller.loadReviews();

    if (!mounted) {
      return;
    }

    _showMessages();
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

  // ============================================================
  // RESTORE
  // ============================================================

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
  // POSTPONE
  // ============================================================

  Future<
    void
  >
  _postpone(
    BrainReviewItem review,
  ) async {
    await _controller.postponeReview(
      review,
      duration: const Duration(
        days: 1,
      ),
    );

    if (!mounted) {
      return;
    }

    _showMessages();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _deleteReview(
    BrainReviewItem review,
  ) async {
    if (_isDeleting) {
      return;
    }

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
                    'Deseja excluir permanentemente "${review.question}"?',
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
        _isDeleting = true;
      },
    );

    try {
      await _controller.deleteReview(
        review,
      );

      if (!mounted) {
        return;
      }

      _showMessages();
    } finally {
      if (mounted) {
        setState(
          () {
            _isDeleting = false;
          },
        );
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessages() {
    final error = _controller.errorMessage;

    final success = _controller.successMessage;

    final messenger = ScaffoldMessenger.of(
      context,
    );

    if (error !=
        null) {
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
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
      messenger.hideCurrentSnackBar();

      messenger.showSnackBar(
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
            onPressed:
                _controller.isLoading ||
                    _isDeleting
                ? null
                : _refresh,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.errorMessage !=
            null &&
        _controller.reviews.isEmpty) {
      return _buildError();
    }

    return Column(
      children: [
        _buildSummary(),

        _buildTabs(),

        Expanded(
          child: _buildList(),
        ),
      ],
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

  // ============================================================
  // METRIC
  // ============================================================

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
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height:
                  MediaQuery.sizeOf(
                    context,
                  ).height *
                  0.18,
            ),
            _buildEmpty(),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
              return _buildReviewCard(
                items[index],
              );
            },
      ),
    );
  }

  // ============================================================
  // REVIEW CARD
  // ============================================================

  Widget _buildReviewCard(
    BrainReviewItem review,
  ) {
    final due =
        !review.archived &&
        !review.nextReviewAt.isAfter(
          DateTime.now(),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          child: Icon(
            review.archived
                ? Icons.archive_outlined
                : due
                ? Icons.notifications_active_outlined
                : Icons.help_outline_rounded,
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
                  : due
                  ? 'Disponível para revisar agora'
                  : 'Próxima revisão: ${_formatDate(review.nextReviewAt)}',
            ),

            if (review.sourceNoteTitle.trim().isNotEmpty) ...[
              const SizedBox(
                height: 4,
              ),
              Text(
                'Origem: ${review.sourceNoteTitle}',
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(
              height: 4,
            ),

            Text(
              'Revisões: ${review.reviewCount} • '
              'Acertos: ${review.correctCount} • '
              'Erros: ${review.wrongCount} • '
              'Sequência: ${review.streak}',
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap:
            review.archived ||
                _isDeleting
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
              enabled: !_isDeleting,
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

                      case 'postpone':
                        await _postpone(
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

                      case 'delete':
                        await _deleteReview(
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
                        PopupMenuDivider(),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Excluir',
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
                        value: 'postpone',
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_outlined,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Adiar 1 dia',
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
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text(
                              'Excluir',
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

    String description;

    switch (_selectedTab) {
      case 0:
        message = 'Nenhuma pergunta para revisar agora.';
        description = 'Quando uma revisão estiver disponível, ela aparecerá aqui.';
        break;

      case 1:
        message = 'Nenhuma revisão futura.';
        description = 'Perguntas programadas para os próximos dias aparecerão aqui.';
        break;

      case 2:
        message = 'Nenhuma pergunta em aprendizado.';
        description = 'Salve uma anotação como Pergunta para iniciar uma revisão.';
        break;

      case 3:
        message = 'Nenhuma pergunta arquivada.';
        description = 'Perguntas concluídas ou arquivadas aparecerão aqui.';
        break;

      default:
        message = 'Nenhuma pergunta.';
        description = '';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
        ),
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
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            if (description.isNotEmpty) ...[
              const SizedBox(
                height: 6,
              ),
              Text(
                description,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Não foi possível carregar as perguntas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _controller.errorMessage ??
                  'Erro desconhecido.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 16,
            ),

            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
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
