import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../models/brain_concept.dart';
import '../../repositories/brain_repository.dart';

class ExampleScreen
    extends
        StatefulWidget {
  const ExampleScreen({
    super.key,
  });

  @override
  State<
    ExampleScreen
  >
  createState() {
    return _ExampleScreenState();
  }
}

class _ExampleScreenState
    extends
        State<
          ExampleScreen
        > {
  final BrainRepository _repository = dependencies.brainRepository;

  bool _isLoading = true;

  bool _isDeleting = false;

  String? _errorMessage;

  List<
    BrainConcept
  >
  _items = [];

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
        BrainConceptType.example,
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
  _deleteExample(
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
                    'Excluir exemplo?',
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
        'Exemplo e anotação de origem excluídos.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível excluir o exemplo e a anotação de origem.',
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
    final type = BrainConceptType.example;

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
              'Exemplos',
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
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage !=
        null) {
      return _buildError();
    }

    if (_items.isEmpty) {
      return _buildEmpty();
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
              return _buildExampleCard(
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

  Widget _buildExampleCard(
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
                    alpha: 0.20,
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
                      ),

                      const SizedBox(
                        width: 7,
                      ),

                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      IconButton(
                        tooltip: 'Excluir exemplo',
                        onPressed: _isDeleting
                            ? null
                            : () {
                                _deleteExample(
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
                    height: 10,
                  ),

                  SelectableText(
                    item.description,
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
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(
            height: 140,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.code_rounded,
                  size: 54,
                ),
                SizedBox(
                  height: 14,
                ),
                Text(
                  'Nenhum exemplo salvo.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                  ),
                  child: Text(
                    'Os conhecimentos salvos como Exemplo aparecerão aqui.',
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
              Icons.error_outline,
              size: 46,
            ),

            const SizedBox(
              height: 12,
            ),

            const Text(
              'Não foi possível carregar os exemplos.',
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
