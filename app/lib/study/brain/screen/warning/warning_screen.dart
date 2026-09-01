import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';
import '../../repositories/brain_repository.dart';

class WarningScreen
    extends
        StatefulWidget {
  const WarningScreen({
    super.key,
  });

  @override
  State<
    WarningScreen
  >
  createState() {
    return _WarningScreenState();
  }
}

class _WarningScreenState
    extends
        State<
          WarningScreen
        > {
  final BrainRepository _repository = BrainRepository();

  bool _isLoading = true;

  bool _isDeleting = false;

  String? _errorMessage;

  List<
    BrainConcept
  >
  _items =
      <
        BrainConcept
      >[];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _load();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  _load() async {
    setState(
      () {
        _isLoading = true;

        _errorMessage = null;
      },
    );

    try {
      final items = await _repository.loadConceptsByType(
        BrainConceptType.warning,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _items = items;

          _isLoading = false;
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = error.toString();

          _isLoading = false;
        },
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _deleteWarning(
    BrainConcept item,
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
                    'Excluir atenção?',
                  ),
                  content: Text(
                    'Deseja excluir "${item.title}"?\n\n'
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
        _isDeleting = true;
      },
    );

    try {
      await _repository.deleteConceptAndSourceNote(
        item.id,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _items.removeWhere(
            (
              current,
            ) {
              return current.id ==
                  item.id;
            },
          );
        },
      );

      _showMessage(
        'Atenção e anotação de origem excluídas.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível excluir a atenção e a anotação de origem.',
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
    final type = BrainConceptType.warning;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              type.icon,
              color: type.color,
            ),
            const SizedBox(
              width: 10,
            ),
            const Text(
              'Atenções',
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _isDeleting
                ? null
                : _load,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 6,
          ),
        ],
      ),
      body: _buildBody(
        context,
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage !=
        null) {
      return _buildError(
        context,
      );
    }

    if (_items.isEmpty) {
      return _buildEmpty(
        context,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(
          18,
        ),
        itemCount: _items.length,
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
              return _buildCard(
                context,
                _items[index],
              );
            },
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildCard(
    BuildContext context,
    BrainConcept item,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: item.color.withValues(
                  alpha: 0.10,
                ),
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: item.color.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: Icon(
                item.icon,
                color: item.color,
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.emoji,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Expanded(
                        child: Text(
                          item.title,
                          style:
                              Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),

                      IconButton(
                        tooltip: 'Excluir atenção',
                        onPressed: _isDeleting
                            ? null
                            : () {
                                _deleteWarning(
                                  item,
                                );
                              },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  SelectableText(
                    item.description,
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _buildTag(
                    item,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TAG
  // ============================================================

  Widget _buildTag(
    BrainConcept item,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: item.color.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          8,
        ),
        border: Border.all(
          color: item.color.withValues(
            alpha: 0.16,
          ),
        ),
      ),
      child: Text(
        item.label,
        style: TextStyle(
          color: item.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty(
    BuildContext context,
  ) {
    final type = BrainConceptType.warning;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(
            height: 140,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: 54,
                  color: type.color,
                ),

                const SizedBox(
                  height: 14,
                ),

                const Text(
                  'Nenhuma atenção salva.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Text(
                    'Erros comuns, cuidados e detalhes importantes aparecerão aqui.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 46,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Não foi possível carregar as atenções.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              _errorMessage ??
                  'Erro desconhecido.',
              textAlign: TextAlign.center,
            ),

            const SizedBox(
              height: 14,
            ),

            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh,
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
}
