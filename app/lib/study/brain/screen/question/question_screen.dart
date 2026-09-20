import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../controllers/review_controller.dart';
import '../../models/brain_review_item.dart';
import '../../services/brain_review_deletion_service.dart';

import 'review_screen.dart';

// ============================================================
// QUESTION SCREEN
// ============================================================
//
// FASE 10 — REVISÃO CONSOLIDADA
//
// Esta tela passa a ser o hub único das revisões:
//
// - Atrasadas;
// - Hoje;
// - Próximas;
// - Aprendendo;
// - Arquivadas.
//
// Também inicia uma sessão contínua com todas as revisões que já
// estão disponíveis agora, sem obrigar o usuário a voltar para a
// lista depois de responder cada pergunta.
//
// ============================================================

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

  late final BrainReviewDeletionService _deletionService;

  int _selectedTab = 1;

  bool _isDeleting = false;

  bool _selectionMode = false;

  final Set<
    String
  >
  _selectedReviewIds =
      <
        String
      >{};

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = dependencies.reviewController;

    _deletionService = BrainReviewDeletionService(
      brainRepository: dependencies.brainRepository,
      reviewController: _controller,
    );

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

    // Controller global: não fazer dispose() aqui.
    super.dispose();
  }

  // ============================================================
  // INITIALIZE
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

    // O dado local já está disponível. A atualização remota é
    // complementar e não bloqueia o modo offline.
    try {
      await _controller.refreshFromRemote();
    } catch (
      _
    ) {
      // O controller mantém a mensagem de erro.
    }

    if (!mounted) {
      return;
    }

    _showMessages();
  }

  // ============================================================
  // AGRUPAMENTOS
  // ============================================================
  //
  // A regra de datas pertence ao ReviewController.
  //
  // A tela apenas consome os agrupamentos consolidados.
  //
  // ============================================================

  List<
    BrainReviewItem
  >
  get _overdueReviews {
    return _controller.overdueReviews;
  }

  List<
    BrainReviewItem
  >
  get _todayReviews {
    return _controller.todayReviews;
  }

  List<
    BrainReviewItem
  >
  get _futureReviews {
    return _controller.futureReviews;
  }

  List<
    BrainReviewItem
  >
  get _dueNowReviews {
    return _controller.dueReviews;
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
        return _overdueReviews;

      case 1:
        return _todayReviews;

      case 2:
        return _futureReviews;

      case 3:
        return _controller.activeReviews;

      case 4:
        return _controller.archivedReviews;

      default:
        return const <
          BrainReviewItem
        >[];
    }
  }

  // ============================================================
  // REVIEW — ITEM ÚNICO
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
  // REVIEW — SESSÃO CONSOLIDADA
  // ============================================================

  Future<
    void
  >
  _openReviewSession() async {
    final queue = _dueNowReviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();

    if (queue.isEmpty) {
      _showSnackBar(
        'Nenhuma revisão está disponível agora.',
      );

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
                review: queue.first,
                controller: _controller,
                sessionReviews: queue,
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
                    'Deseja excluir "${review.question}" das revisões?\n\n'
                    'O conhecimento de origem será preservado.',
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
      await _deletionService.deleteReviewOnly(
        review,
      );

      await _controller.loadReviews();

      if (!mounted) {
        return;
      }

      _controller.clearMessages();

      _showSnackBar(
        'Pergunta excluída. O conhecimento de origem foi preservado.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        'Não foi possível excluir a pergunta.',
      );
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
  // MULTI-SELEÇÃO
  // ============================================================

  void _enterSelectionMode(
    BrainReviewItem review,
  ) {
    if (_isDeleting) {
      return;
    }

    setState(
      () {
        _selectionMode = true;
        _selectedReviewIds.add(
          review.id,
        );
      },
    );
  }

  void _toggleReviewSelection(
    BrainReviewItem review,
  ) {
    if (_isDeleting) {
      return;
    }

    setState(
      () {
        _selectionMode = true;

        if (_selectedReviewIds.contains(
          review.id,
        )) {
          _selectedReviewIds.remove(
            review.id,
          );
        } else {
          _selectedReviewIds.add(
            review.id,
          );
        }

        if (_selectedReviewIds.isEmpty) {
          _selectionMode = false;
        }
      },
    );
  }

  void _cancelSelection() {
    if (_isDeleting) {
      return;
    }

    setState(
      () {
        _selectionMode = false;
        _selectedReviewIds.clear();
      },
    );
  }

  void _selectAllVisible() {
    if (_isDeleting) {
      return;
    }

    final visibleIds = _currentItems
        .map(
          (
            review,
          ) => review.id,
        )
        .toSet();

    if (visibleIds.isEmpty) {
      return;
    }

    final allVisibleSelected = visibleIds.every(
      _selectedReviewIds.contains,
    );

    setState(
      () {
        _selectionMode = true;

        if (allVisibleSelected) {
          _selectedReviewIds.removeAll(
            visibleIds,
          );

          if (_selectedReviewIds.isEmpty) {
            _selectionMode = false;
          }
        } else {
          _selectedReviewIds.addAll(
            visibleIds,
          );
        }
      },
    );
  }

  Future<
    void
  >
  _deleteSelectedReviews() async {
    if (_isDeleting ||
        _selectedReviewIds.isEmpty) {
      return;
    }

    final selected = _controller.reviews.where(
      (
        review,
      ) {
        return _selectedReviewIds.contains(
          review.id,
        );
      },
    ).toList();

    if (selected.isEmpty) {
      _cancelSelection();
      return;
    }

    final count = selected.length;

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
                  title: Text(
                    count ==
                            1
                        ? 'Excluir pergunta?'
                        : 'Excluir $count perguntas?',
                  ),
                  content: Text(
                    count ==
                            1
                        ? 'A pergunta selecionada será removida da revisão. '
                              'O conhecimento de origem será preservado.'
                        : 'As $count perguntas selecionadas serão removidas da revisão. '
                              'Os conhecimentos de origem serão preservados.',
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
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                      ),
                      label: Text(
                        count ==
                                1
                            ? 'Excluir'
                            : 'Excluir $count',
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

    var deleted = 0;

    try {
      // Exclusão em lote remove SOMENTE os BrainReviewItem.
      // Isso é intencional: uma única anotação pode originar várias
      // perguntas automáticas e nunca deve ser apagada por uma seleção
      // de perguntas na tela de revisão.
      for (final review in selected) {
        await _deletionService.deleteReviewOnly(
          review,
        );

        if (_controller.errorMessage !=
            null) {
          break;
        }

        deleted++;
      }

      await _controller.loadReviews();

      if (!mounted) {
        return;
      }

      final error = _controller.errorMessage;

      _controller.clearMessages();

      setState(
        () {
          _selectionMode = false;
          _selectedReviewIds.clear();
        },
      );

      if (error !=
          null) {
        _showSnackBar(
          deleted ==
                  0
              ? error
              : '$deleted de $count perguntas foram excluídas. $error',
        );
      } else {
        _showSnackBar(
          deleted ==
                  1
              ? '1 pergunta excluída. O conhecimento de origem foi preservado.'
              : '$deleted perguntas excluídas. Os conhecimentos de origem foram preservados.',
        );
      }
    } catch (
      _
    ) {
      if (!mounted) {
        return;
      }

      _showSnackBar(
        deleted ==
                0
            ? 'Não foi possível excluir as perguntas selecionadas.'
            : '$deleted de $count perguntas foram excluídas antes de ocorrer um erro.',
      );
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
  // MESSAGES
  // ============================================================

  void _showMessages() {
    final error = _controller.errorMessage;
    final success = _controller.successMessage;

    if (error !=
        null) {
      _showSnackBar(
        error,
      );

      _controller.clearMessages();

      return;
    }

    if (success !=
        null) {
      _showSnackBar(
        success,
      );

      _controller.clearMessages();
    }
  }

  void _showSnackBar(
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
        leading: _selectionMode
            ? IconButton(
                tooltip: 'Cancelar seleção',
                onPressed: _isDeleting
                    ? null
                    : _cancelSelection,
                icon: const Icon(
                  Icons.close_rounded,
                ),
              )
            : null,
        title: _selectionMode
            ? Text(
                '${_selectedReviewIds.length} '
                '${_selectedReviewIds.length == 1 ? 'selecionada' : 'selecionadas'}',
              )
            : const Text(
                'Revisar',
              ),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              tooltip: 'Selecionar todas desta lista',
              onPressed: _isDeleting
                  ? null
                  : _selectAllVisible,
              icon: const Icon(
                Icons.select_all_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Excluir selecionadas',
              onPressed:
                  _isDeleting ||
                      _selectedReviewIds.isEmpty
                  ? null
                  : _deleteSelectedReviews,
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),
          ] else
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
    if (_controller.isLoading &&
        _controller.reviews.isEmpty) {
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
        if (!_selectionMode) ...[
          _buildReviewNowCard(),
          _buildSummary(),
        ],
        _buildTabs(),
        Expanded(
          child: _buildList(),
        ),
      ],
    );
  }

  // ============================================================
  // REVISAR AGORA
  // ============================================================

  Widget _buildReviewNowCard() {
    final dueNow = _dueNowReviews.length;
    final overdue = _overdueReviews.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        4,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color:
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(
                alpha: 0.55,
              ),
          borderRadius: BorderRadius.circular(
            18,
          ),
          border: Border.all(
            color:
                Theme.of(
                  context,
                ).colorScheme.primary.withValues(
                  alpha: 0.18,
                ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(
                      alpha: 0.10,
                    ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
              child: Icon(
                dueNow >
                        0
                    ? Icons.play_arrow_rounded
                    : Icons.check_rounded,
                color: Theme.of(
                  context,
                ).colorScheme.primary,
                size: 24,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dueNow >
                            0
                        ? '$dueNow ${dueNow == 1 ? 'revisão disponível' : 'revisões disponíveis'}'
                        : 'Tudo em dia',
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    dueNow >
                            0
                        ? overdue >
                                  0
                              ? '$overdue ${overdue == 1 ? 'atrasada' : 'atrasadas'} • revise em uma única sessão'
                              : 'Revise tudo em uma única sessão'
                        : 'Nenhuma pergunta precisa ser revisada agora.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            FilledButton.icon(
              onPressed:
                  dueNow ==
                          0 ||
                      _isDeleting
                  ? null
                  : _openReviewSession,
              icon: const Icon(
                Icons.psychology_alt_outlined,
              ),
              label: const Text(
                'Revisar agora',
              ),
            ),
          ],
        ),
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
        4,
        18,
        2,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color:
                Theme.of(
                  context,
                ).dividerColor.withValues(
                  alpha: 0.55,
                ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _metric(
                label: 'Atrasadas',
                value: _overdueReviews.length,
                icon: Icons.notification_important_outlined,
              ),
            ),
            _summaryDivider(),
            Expanded(
              child: _metric(
                label: 'Hoje',
                value: _todayReviews.length,
                icon: Icons.today_outlined,
              ),
            ),
            _summaryDivider(),
            Expanded(
              child: _metric(
                label: 'Próximas',
                value: _futureReviews.length,
                icon: Icons.schedule_outlined,
              ),
            ),
            _summaryDivider(),
            Expanded(
              child: _metric(
                label: 'Ativas',
                value: _controller.activeCount,
                icon: Icons.psychology_alt_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryDivider() {
    return Container(
      width: 1,
      height: 26,
      color:
          Theme.of(
            context,
          ).dividerColor.withValues(
            alpha: 0.55,
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
    final theme = Theme.of(
      context,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 3,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
          ),

          const SizedBox(
            width: 6,
          ),

          Flexible(
            child: Text(
              '$value $label',
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
  // TABS
  // ============================================================

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),
      child:
          SegmentedButton<
            int
          >(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(
                  Icons.notification_important_outlined,
                ),
                label: Text(
                  'Atrasadas',
                ),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(
                  Icons.today_outlined,
                ),
                label: Text(
                  'Hoje',
                ),
              ),
              ButtonSegment(
                value: 2,
                icon: Icon(
                  Icons.schedule_outlined,
                ),
                label: Text(
                  'Próximas',
                ),
              ),
              ButtonSegment(
                value: 3,
                icon: Icon(
                  Icons.psychology_outlined,
                ),
                label: Text(
                  'Aprendendo',
                ),
              ),
              ButtonSegment(
                value: 4,
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
                _selectionMode ||
                    _isDeleting
                ? null
                : (
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
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18,
        ),
        itemCount: items.length,
        separatorBuilder:
            (
              _,
              _,
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
    final now = DateTime.now();

    final due =
        !review.archived &&
        !review.nextReviewAt.isAfter(
          now,
        );

    final overdue =
        !review.archived &&
        _controller.overdueReviews.any(
          (
            item,
          ) {
            return item.id ==
                review.id;
          },
        );

    final selected = _selectedReviewIds.contains(
      review.id,
    );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onLongPress: _isDeleting
            ? null
            : () {
                _enterSelectionMode(
                  review,
                );
              },
        onTap: _isDeleting
            ? null
            : () {
                if (_selectionMode) {
                  _toggleReviewSelection(
                    review,
                  );
                  return;
                }

                if (!review.archived) {
                  _openReview(
                    review,
                  );
                }
              },
        child: ListTile(
          selected: selected,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          leading: _selectionMode
              ? Checkbox(
                  value: selected,
                  onChanged: _isDeleting
                      ? null
                      : (
                          _,
                        ) {
                          _toggleReviewSelection(
                            review,
                          );
                        },
                )
              : CircleAvatar(
                  child: Icon(
                    review.archived
                        ? Icons.archive_outlined
                        : overdue
                        ? Icons.notification_important_outlined
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
                    : overdue
                    ? 'Revisão atrasada desde ${_formatDate(review.nextReviewAt)}'
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
          trailing: _selectionMode
              ? null
              : PopupMenuButton<
                  String
                >(
                  tooltip: 'Opções',
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

                          case 'select':
                            _enterSelectionMode(
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
                              value: 'select',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_box_outlined,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    'Selecionar',
                                  ),
                                ],
                              ),
                            ),
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
                            value: 'select',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_box_outlined,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Selecionar',
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
        message = 'Nenhuma revisão atrasada.';
        description = 'Ótimo: não há perguntas pendentes de dias anteriores.';
        break;

      case 1:
        message = 'Nenhuma pergunta programada para hoje.';
        description = 'As revisões de hoje aparecerão aqui.';
        break;

      case 2:
        message = 'Nenhuma revisão futura.';
        description = 'Perguntas dos próximos dias aparecerão aqui.';
        break;

      case 3:
        message = 'Nenhuma pergunta em aprendizado.';
        description = 'Marque um conhecimento para revisão para gerar perguntas automaticamente.';
        break;

      case 4:
        message = 'Nenhuma pergunta arquivada.';
        description = 'Perguntas arquivadas aparecerão aqui.';
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
              Icons.psychology_alt_outlined,
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
              'Não foi possível carregar as revisões.',
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
    final local = date.toLocal();

    String two(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }
}
