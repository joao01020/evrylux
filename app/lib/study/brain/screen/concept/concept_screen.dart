import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';
import '../../services/brain_storage.dart';

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
  final BrainStorage _storage = const BrainStorage();

  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;

  String? _errorMessage;

  String _query = '';

  List<
    BrainConcept
  >
  _items = [];

  @override
  void initState() {
    super.initState();

    _load();
  }

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
    setState(
      () {
        _isLoading = true;
        _errorMessage = null;
      },
    );

    try {
      final items = await _storage.loadConceptsByType(
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
        return item.title.toLowerCase().contains(
              query,
            ) ||
            item.description.toLowerCase().contains(
              query,
            );
      },
    ).toList();
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
            onPressed: _load,
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
            return _buildConceptCard(
              context,
              items[index],
            );
          },
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
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return const Center(
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
          Text(
            'Os conceitos salvos nas suas anotações aparecerão aqui.',
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
          Text(
            _errorMessage ??
                'Erro desconhecido.',
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
    );
  }
}
