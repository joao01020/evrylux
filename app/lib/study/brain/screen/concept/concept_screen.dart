import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../models/brain_concept.dart';
import '../../repositories/brain_repository.dart';

class ConceptScreen
    extends
        StatefulWidget {
  const ConceptScreen({
    super.key,
  });

  @override
  State<
    ConceptScreen
  >
  createState() {
    return _ConceptScreenState();
  }
}

class _ConceptScreenState
    extends
        State<
          ConceptScreen
        > {
  final BrainRepository _repository = dependencies.brainRepository;

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;

  bool _isDeleting = false;

  String? _errorMessage;

  String _query = '';

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  _load() async {
    if (_isLoading &&
        _items.isNotEmpty) {
      return;
    }

    setState(
      () {
        _isLoading = true;

        _errorMessage = null;
      },
    );

    try {
      final items = await _repository.loadConceptsByType(
        BrainConceptType.concept,
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
  // FILTER
  // ============================================================

  List<
    BrainConcept
  >
  get _filteredItems {
    final query = _query.trim().toLowerCase();

    if (query.isEmpty) {
      return _items;
    }

    return _items.where(
      (
        item,
      ) {
        final title = item.title.toLowerCase();

        final description = item.description.toLowerCase();

        return title.contains(
              query,
            ) ||
            description.contains(
              query,
            );
      },
    ).toList();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _deleteConcept(
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
                    'Excluir conceito?',
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
        'Conceito e anotação de origem excluídos.',
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível excluir o conceito e a anotação de origem.',
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
    final type = BrainConceptType.concept;

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
              'Conceitos',
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
      body: Column(
        children: [
          _buildSearch(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        16,
        18,
        4,
      ),
      child: TextField(
        controller: _searchController,
        onChanged:
            (
              value,
            ) {
              setState(
                () {
                  _query = value;
                },
              );
            },
        decoration: InputDecoration(
          hintText: 'Pesquisar conceitos...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(
                      () {
                        _query = '';
                      },
                    );
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
          border: const OutlineInputBorder(),
        ),
      ),
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

    final items = _filteredItems;

    if (items.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(
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
              return _buildConceptCard(
                context,
                items[index],
              );
            },
      ),
    );
  }

  // ============================================================
  // CARD
  // ============================================================

  Widget _buildConceptCard(
    BuildContext context,
    BrainConcept item,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: item.color.withValues(
              alpha: 0.10,
            ),
            borderRadius: BorderRadius.circular(
              11,
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
        title: Row(
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
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(
            top: 7,
          ),
          child: Text(
            item.description,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: IconButton(
          tooltip: 'Excluir conceito',
          onPressed: _isDeleting
              ? null
              : () {
                  _deleteConcept(
                    item,
                  );
                },
          icon: const Icon(
            Icons.delete_outline_rounded,
          ),
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
                  Icons.lightbulb_outline_rounded,
                  size: 54,
                ),
                SizedBox(
                  height: 14,
                ),
                Text(
                  'Nenhum conceito encontrado.',
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
                    'Os conhecimentos salvos como Conceito aparecerão aqui.',
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
              'Não foi possível carregar os conceitos.',
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
