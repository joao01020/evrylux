import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';
import '../../services/brain_storage.dart';

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
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage !=
        null) {
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
              _errorMessage!,
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

    if (_items.isEmpty) {
      return const Center(
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
            Text(
              'Exemplos práticos aparecerão aqui.',
            ),
          ],
        ),
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
            final item = _items[index];

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
          },
    );
  }
}
