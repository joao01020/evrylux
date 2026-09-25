import 'dart:async';

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

  // ============================================================
  // CACHE DE SESSÃO
  // ============================================================
  //
  // A tela antiga sempre chamava loadConceptsByType() no initState.
  //
  // Mesmo com o Vault otimizado, não faz sentido bloquear a primeira
  // pintura da página se os mesmos dados já estão disponíveis:
  //
  // - no BrainController;
  // - ou no cache desta própria tela.
  //
  // O cache abaixo existe SOMENTE em memória.
  //
  // O repositório/Vault continua sendo a fonte persistente de verdade.
  //
  // ============================================================

  static List<
    BrainConcept
  >?
  _sessionExampleCache;

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

  // Evita mais de uma leitura simultânea do repositório.
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
  // BOOTSTRAP
  // ============================================================

  void _bootstrap() {
    // ==========================================================
    // 1. CACHE DA PRÓPRIA TELA
    // ==========================================================

    final cached = _sessionExampleCache;

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

      // Mostra imediatamente e atualiza silenciosamente depois.
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
    //
    // Na navegação normal, o BrainController frequentemente já possui
    // as notas descriptografadas em memória.
    //
    // Extraímos os exemplos dessas notas e mostramos sem reler o Vault.
    //
    // ==========================================================

    final warmItems = _examplesFromLoadedBrain();

    if (warmItems.isNotEmpty) {
      _items = warmItems;

      _sessionExampleCache =
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
    // 3. PRIMEIRA ABERTURA SEM DADOS AQUECIDOS
    // ==========================================================

    unawaited(
      _load(
        showBlockingLoader: true,
      ),
    );
  }

  // ============================================================
  // EXEMPLOS JÁ CARREGADOS NO BRAIN CONTROLLER
  // ============================================================

  List<
    BrainConcept
  >
  _examplesFromLoadedBrain() {
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
            BrainConceptType.example) {
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
        BrainConceptType.example,
      );

      stopwatch.stop();

      debugPrint(
        '[EXAMPLE SCREEN] '
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

      _sessionExampleCache = immutableItems;

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
        '[EXAMPLE SCREEN] '
        'falha após ${stopwatch.elapsedMilliseconds}ms: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;

          _isRefreshing = false;

          // Se já temos dados aquecidos, não substituímos toda a tela
          // por um erro só porque o refresh em background falhou.
          if (_items.isEmpty) {
            _errorMessage = error.toString();
          }
        },
      );

      if (_items.isNotEmpty) {
        _showMessage(
          'Não foi possível atualizar os exemplos agora.',
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

      _sessionExampleCache = updated;

      setState(
        () {
          _items = updated;

          _isDeleting = false;
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

      setState(
        () {
          _isDeleting = false;
        },
      );

      _showMessage(
        'Não foi possível excluir o exemplo e a anotação de origem.',
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
      body: _buildBody(),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_isLoading &&
        _items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage !=
            null &&
        _items.isEmpty) {
      return _buildError();
    }

    if (_items.isEmpty) {
      return _buildEmpty();
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

                    // SelectableText é mantido para preservar exatamente
                    // o comportamento atual da tela.
                    //
                    // O RepaintBoundary acima evita que a pintura de um card
                    // afete todos os outros durante atualizações da página.
                    SelectableText(
                      item.description,
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
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: () {
        return _load(
          showBlockingLoader: false,
        );
      },
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
