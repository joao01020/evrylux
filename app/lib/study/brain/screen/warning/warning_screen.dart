import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

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
  final BrainRepository _repository = dependencies.brainRepository;

  // ============================================================
  // CACHE DE SESSÃO
  // ============================================================
  //
  // A versão anterior sempre bloqueava a tela esperando
  // loadConceptsByType(BrainConceptType.warning).
  //
  // Agora:
  //
  // cache disponível
  //      ↓
  // mostra imediatamente
  //      ↓
  // atualiza silenciosamente
  //
  // sem cache
  //      ↓
  // tenta reaproveitar BrainController.notes
  //      ↓
  // se ainda não houver dados, consulta o repositório
  //
  // O Vault/repositório continua sendo a fonte persistente.
  //
  // ============================================================

  static List<
    BrainConcept
  >?
  _sessionWarningCache;

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;

  bool _isRefreshing = false;

  bool _isDeleting = false;

  String? _errorMessage;

  List<
    BrainConcept
  >
  _items =
      <
        BrainConcept
      >[];

  // Evita chamadas simultâneas ao mesmo carregamento.
  Future<
    void
  >?
  _loadFuture;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _bootstrap();
  }

  // ============================================================
  // BOOTSTRAP RÁPIDO
  // ============================================================

  void _bootstrap() {
    // ==========================================================
    // 1. CACHE DA TELA
    // ==========================================================

    final cached = _sessionWarningCache;

    if (cached !=
        null) {
      _items =
          List<
            BrainConcept
          >.of(
            cached,
            growable: false,
          );

      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          unawaited(
            _load(
              showBlockingLoader: false,
            ),
          );
        },
      );

      return;
    }

    // ==========================================================
    // 2. APROVEITAR O CÉREBRO JÁ CARREGADO
    // ==========================================================

    final warmItems = _warningsFromLoadedBrain();

    if (warmItems.isNotEmpty) {
      _items = warmItems;

      _sessionWarningCache =
          List<
            BrainConcept
          >.of(
            warmItems,
            growable: false,
          );

      _isLoading = false;

      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          unawaited(
            _load(
              showBlockingLoader: false,
            ),
          );
        },
      );

      return;
    }

    // ==========================================================
    // 3. PRIMEIRA ABERTURA SEM CACHE
    // ==========================================================

    unawaited(
      _load(
        showBlockingLoader: true,
      ),
    );
  }

  // ============================================================
  // ATENÇÕES JÁ CARREGADAS NO BRAIN CONTROLLER
  // ============================================================

  List<
    BrainConcept
  >
  _warningsFromLoadedBrain() {
    final notes = dependencies.brainController.notes;

    if (notes.isEmpty) {
      return const <
        BrainConcept
      >[];
    }

    final seen =
        <
          String
        >{};

    final result =
        <
          BrainConcept
        >[];

    for (final note in notes) {
      for (final concept in note.concepts) {
        if (concept.type !=
            BrainConceptType.warning) {
          continue;
        }

        final id = concept.id.trim();

        if (id.isNotEmpty &&
            !seen.add(
              id,
            )) {
          continue;
        }

        result.add(
          concept,
        );
      }
    }

    return List<
      BrainConcept
    >.of(
      result,
      growable: false,
    );
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  _load({
    bool showBlockingLoader = false,
  }) {
    final running = _loadFuture;

    if (running !=
        null) {
      return running;
    }

    final future = _performLoad(
      showBlockingLoader: showBlockingLoader,
    );

    _loadFuture = future;

    return future.whenComplete(
      () {
        if (identical(
          _loadFuture,
          future,
        )) {
          _loadFuture = null;
        }
      },
    );
  }

  Future<
    void
  >
  _performLoad({
    required bool showBlockingLoader,
  }) async {
    if (mounted) {
      setState(
        () {
          if (showBlockingLoader &&
              _items.isEmpty) {
            _isLoading = true;
          } else {
            _isRefreshing = true;
          }

          _errorMessage = null;
        },
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final items = await _repository.loadConceptsByType(
        BrainConceptType.warning,
      );

      stopwatch.stop();

      debugPrint(
        '[WARNING SCREEN] '
        'loadConceptsByType=${stopwatch.elapsedMilliseconds}ms '
        'itens=${items.length}',
      );

      if (!mounted) {
        return;
      }

      final immutableItems =
          List<
            BrainConcept
          >.of(
            items,
            growable: false,
          );

      _sessionWarningCache = immutableItems;

      setState(
        () {
          _items = immutableItems;

          _isLoading = false;

          _isRefreshing = false;

          _errorMessage = null;
        },
      );
    } catch (
      error
    ) {
      stopwatch.stop();

      debugPrint(
        '[WARNING SCREEN] '
        'falha após ${stopwatch.elapsedMilliseconds}ms: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;

          _isRefreshing = false;

          if (_items.isEmpty) {
            _errorMessage = error.toString();
          }
        },
      );

      if (_items.isNotEmpty) {
        _showMessage(
          'Não foi possível atualizar as atenções agora.',
        );
      }
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

      final updated = _items
          .where(
            (
              current,
            ) =>
                current.id !=
                item.id,
          )
          .toList(
            growable: false,
          );

      _sessionWarningCache = updated;

      setState(
        () {
          _items = updated;

          _isDeleting = false;
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

      setState(
        () {
          _isDeleting = false;
        },
      );

      _showMessage(
        'Não foi possível excluir a atenção e a anotação de origem.',
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
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.only(
                right: 4,
              ),
              child: Center(
                child: SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed:
                _isDeleting ||
                    _isRefreshing
                ? null
                : () {
                    _load(
                      showBlockingLoader: false,
                    );
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
    if (_isLoading &&
        _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage !=
            null &&
        _items.isEmpty) {
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
      onRefresh: () {
        return _load(
          showBlockingLoader: false,
        );
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.all(
          18,
        ),
        itemCount: _items.length,
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
    return RepaintBoundary(
      child: Card(
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
      onRefresh: () {
        return _load(
          showBlockingLoader: false,
        );
      },
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
              onPressed: () {
                _load(
                  showBlockingLoader: true,
                );
              },
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
