import 'dart:async';

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

  // ============================================================
  // CACHE DE SESSÃO
  // ============================================================
  //
  // A tela de Conceitos era obrigada a consultar o Vault toda vez
  // que era aberta.
  //
  // Como loadConceptsByType() pode passar pelo ConceptVaultStore,
  // isso pode envolver leitura/decriptação de objetos mesmo quando os
  // mesmos conceitos acabaram de ser carregados.
  //
  // Mantemos uma cópia somente em memória durante a sessão do app.
  // Ela NÃO substitui o repositório e NÃO é persistência.
  //
  // Fluxo:
  //
  // cache disponível
  //      ↓
  // mostra imediatamente
  //      ↓
  // atualiza silenciosamente em background
  //
  // sem cache
  //      ↓
  // tenta aproveitar BrainController.notes já carregadas
  //      ↓
  // se ainda estiver vazio, mostra loading e consulta o repositório
  //
  // ============================================================

  static List<
    BrainConcept
  >?
  _sessionConceptCache;

  // ============================================================
  // SEARCH DEBOUNCE
  // ============================================================

  Timer? _searchDebounceTimer;

  static const Duration _searchDebounceDuration = Duration(
    milliseconds: 140,
  );

  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isDeleting = false;

  String? _errorMessage;
  String _query = '';

  List<
    BrainConcept
  >
  _items =
      <
        BrainConcept
      >[];
  List<
    BrainConcept
  >
  _filteredItems =
      <
        BrainConcept
      >[];

  // Índice pré-normalizado da pesquisa.
  //
  // Evita lowerCase/normalização para todos os conceitos a cada rebuild.
  final Map<
    String,
    String
  >
  _searchIndex =
      <
        String,
        String
      >{};

  // Evita duas cargas do Vault ao mesmo tempo.
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // BOOTSTRAP RÁPIDO
  // ============================================================

  void _bootstrap() {
    final cached = _sessionConceptCache;

    if (cached !=
        null) {
      _replaceItems(
        cached,
        notify: false,
      );

      _isLoading = false;

      // Primeira pintura usa cache. A atualização real acontece sem
      // bloquear a tela.
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
    // APROVEITAR O CÉREBRO JÁ CARREGADO
    // ==========================================================
    //
    // Na navegação normal, BrainController já possui as notas
    // descriptografadas em memória. Extraímos os conceitos delas
    // para evitar reler o Vault apenas para a primeira pintura.
    //
    // ==========================================================

    final warmItems = _conceptsFromLoadedBrain();

    if (warmItems.isNotEmpty) {
      _replaceItems(
        warmItems,
        notify: false,
      );

      _sessionConceptCache =
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

    // Primeira abertura sem dados aquecidos.
    unawaited(
      _load(
        showBlockingLoader: true,
      ),
    );
  }

  // ============================================================
  // CONCEITOS JÁ CARREGADOS PELO CONTROLLER
  // ============================================================

  List<
    BrainConcept
  >
  _conceptsFromLoadedBrain() {
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
            BrainConceptType.concept) {
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

    return result;
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
        BrainConceptType.concept,
      );

      stopwatch.stop();

      debugPrint(
        '[CONCEPT SCREEN] '
        'loadConceptsByType=${stopwatch.elapsedMilliseconds}ms '
        'itens=${items.length}',
      );

      if (!mounted) {
        return;
      }

      _sessionConceptCache =
          List<
            BrainConcept
          >.of(
            items,
            growable: false,
          );

      _replaceItems(
        items,
        notify: false,
      );

      setState(
        () {
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
        '[CONCEPT SCREEN] '
        'falha após ${stopwatch.elapsedMilliseconds}ms: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _isLoading = false;
          _isRefreshing = false;

          // Com dados já disponíveis, uma falha de refresh não deve
          // apagar a tela inteira e mostrar erro.
          if (_items.isEmpty) {
            _errorMessage = error.toString();
          }
        },
      );

      if (_items.isNotEmpty) {
        _showMessage(
          'Não foi possível atualizar os conceitos agora.',
        );
      }
    }
  }

  // ============================================================
  // ATUALIZAR ITENS + ÍNDICE DE BUSCA
  // ============================================================

  void _replaceItems(
    List<
      BrainConcept
    >
    items, {
    required bool notify,
  }) {
    _items =
        List<
          BrainConcept
        >.of(
          items,
        );

    _rebuildSearchIndex();

    _applySearch(
      _query,
      notify: notify,
    );
  }

  void _rebuildSearchIndex() {
    _searchIndex.clear();

    for (final item in _items) {
      _searchIndex[item.id] = _normalizeSearchText(
        '${item.title}\n${item.description}',
      );
    }
  }

  // ============================================================
  // SEARCH
  // ============================================================

  String _normalizeSearchText(
    String value,
  ) {
    var normalized = value.toLowerCase();

    const replacements =
        <
          String,
          String
        >{
          'á': 'a',
          'à': 'a',
          'â': 'a',
          'ã': 'a',
          'ä': 'a',
          'é': 'e',
          'è': 'e',
          'ê': 'e',
          'ë': 'e',
          'í': 'i',
          'ì': 'i',
          'î': 'i',
          'ï': 'i',
          'ó': 'o',
          'ò': 'o',
          'ô': 'o',
          'õ': 'o',
          'ö': 'o',
          'ú': 'u',
          'ù': 'u',
          'û': 'u',
          'ü': 'u',
          'ç': 'c',
        };

    replacements.forEach(
      (
        source,
        target,
      ) {
        normalized = normalized.replaceAll(
          source,
          target,
        );
      },
    );

    return normalized
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();
  }

  void _scheduleSearch(
    String value,
  ) {
    _searchDebounceTimer?.cancel();

    _query = value;

    // Atualiza o botão de limpar imediatamente sem refiltrar a lista.
    if (mounted) {
      setState(
        () {},
      );
    }

    if (value.trim().isEmpty) {
      _applySearch(
        '',
        notify: true,
      );

      return;
    }

    _searchDebounceTimer = Timer(
      _searchDebounceDuration,
      () {
        if (!mounted) {
          return;
        }

        _applySearch(
          value,
          notify: true,
        );
      },
    );
  }

  void _applySearch(
    String rawQuery, {
    required bool notify,
  }) {
    final query = _normalizeSearchText(
      rawQuery,
    );

    if (query.isEmpty) {
      _filteredItems =
          List<
            BrainConcept
          >.of(
            _items,
            growable: false,
          );
    } else {
      _filteredItems = _items
          .where(
            (
              item,
            ) {
              final indexed =
                  _searchIndex[item.id] ??
                  _normalizeSearchText(
                    '${item.title}\n${item.description}',
                  );

              return indexed.contains(
                query,
              );
            },
          )
          .toList(
            growable: false,
          );
    }

    if (notify &&
        mounted) {
      setState(
        () {},
      );
    }
  }

  void _clearSearch() {
    _searchDebounceTimer?.cancel();
    _searchController.clear();
    _query = '';

    _applySearch(
      '',
      notify: true,
    );
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

      _sessionConceptCache = updated;

      _replaceItems(
        updated,
        notify: false,
      );

      setState(
        () {
          _isDeleting = false;
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

      setState(
        () {
          _isDeleting = false;
        },
      );

      _showMessage(
        'Não foi possível excluir o conceito e a anotação de origem.',
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
        onChanged: _scheduleSearch,
        decoration: InputDecoration(
          hintText: 'Pesquisar conceitos...',
          prefixIcon: const Icon(
            Icons.search,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  onPressed: _clearSearch,
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

    final items = _filteredItems;

    if (items.isEmpty) {
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
    return RepaintBoundary(
      child: Card(
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
