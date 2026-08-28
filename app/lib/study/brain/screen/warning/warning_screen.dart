import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';
import '../../services/brain_storage.dart';

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
  final BrainStorage _storage = const BrainStorage();

  bool _isLoading = true;

  String? _errorMessage;

  List<
    BrainConcept
  >
  _items = [];

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
      final items = await _storage.loadConceptsByType(
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

    return ListView.separated(
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
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Text(
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

    return Center(
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
          const Text(
            'Erros comuns e detalhes importantes aparecerão aqui.',
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
