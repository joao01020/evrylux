part of '../brain_screen.dart';

// Visual lifecycle + local/Vault-first search experience.
extension _BrainScreenVisualSearch on _BrainScreenState {
  // ============================================================
  // CÉREBRO VISUAL — CONTAGEM
  // ============================================================

  int _currentBrainKnowledgeCount() {
    // ========================================================
    // FONTE REAL DO PROGRESSO VISUAL
    // ========================================================
    //
    // Cada captura de conhecimento criada pela BrainScreen gera
    // uma BrainFile persistida localmente.
    //
    // Usar notes.length é mais confiável do que somar concepts,
    // pois o carregamento/migração de conceitos pode acontecer em
    // uma etapa diferente do carregamento da nota.
    //
    // Resultado:
    //
    // 0 notas salvas = cérebro vazio
    // 1 nota salva   = 1 ramificação
    // 2 notas salvas = 2 ramificações
    // ...
    //
    // ========================================================

    return _controller.notes.length;
  }

  // ============================================================
  // CÉREBRO VISUAL — NASCIMENTO
  // ============================================================

  Future<void> _onBrainBirthCompleted() async {
    // O callback visual não persiste estado diretamente.
    //
    // Ele apenas comunica o evento real ao ExperienceController.
    // A persistência de introSeen pertence ao
    // BrainInitializationService.
    await _completeBrainBirth();
  }

  // ============================================================
  // CÉREBRO VISUAL — SINCRONIZAR CONHECIMENTO
  // ============================================================

  Future<bool> _syncBrainVisualKnowledge({
    required bool animateGrowth,
    bool reloadLocal = false,
  }) async {
    final visualController = _brainVisualController;

    if (visualController == null) {
      return false;
    }

    // ========================================================
    // RECARREGAR A FONTE REAL
    // ========================================================
    //
    // O crescimento só deve acontecer a partir do conteúdo que
    // realmente foi persistido no armazenamento local.
    //
    // ========================================================

    if (reloadLocal) {
      await _controller.loadNotes();

      if (!mounted) {
        return false;
      }
    }

    final currentCount = _currentBrainKnowledgeCount();

    final previousVisualCount = visualController.knowledgeCount;

    debugPrint(
      '[BRAIN VISUAL] '
      'salvos=$currentCount '
      'visual=$previousVisualCount '
      'animar=$animateGrowth',
    );

    _brainVisualKnowledgeCount = currentCount;

    // ========================================================
    // NOVO CONHECIMENTO
    // ========================================================

    if (animateGrowth && currentCount > previousVisualCount) {
      visualController.animateKnowledgeTarget(currentCount);

      return true;
    }

    // ========================================================
    // RECONCILIAÇÃO NORMAL
    // ========================================================

    visualController.setKnowledgeCount(currentCount);

    return false;
  }

  // ============================================================
  // CÉREBRO VISUAL — ATIVIDADE DE PESQUISA
  // ============================================================

  void _setBrainSearchActivity(
    String rawQuery, {
    Duration hold = const Duration(milliseconds: 900),
  }) {
    final visualController = _brainVisualController;

    _brainSearchPulseStopTimer?.cancel();

    if (visualController == null) {
      return;
    }

    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      visualController.setSearching(false);

      visualController.clearSearchMatch();

      return;
    }

    // Limpa qualquer brilho anterior antes de uma nova pesquisa.
    visualController.clearSearchMatch();

    // Mantém os pulsos distribuídos enquanto o usuário digita.
    visualController.setSearching(true);

    // A busca local é síncrona. Consideramos que a pesquisa
    // "terminou" quando o usuário fica alguns milissegundos sem
    // alterar o texto. Nesse momento resolvemos o resultado e
    // disparamos o pulso final.
    _brainSearchPulseStopTimer = Timer(hold, () {
      if (!mounted) {
        return;
      }

      // Ignora timer de uma consulta antiga.
      if (_searchQuery.trim() != normalizedQuery) {
        return;
      }

      final response = _searchResponse;

      final results = response.allResults;

      if (results.isEmpty) {
        debugPrint(
          '[BRAIN SEARCH VISUAL] Nenhum resultado para "$normalizedQuery".',
        );

        visualController.setSearching(false);

        visualController.clearSearchMatch();

        return;
      }

      // topResults normalmente contém o primeiro resultado mais
      // relevante. O fallback para allResults garante que o efeito
      // não deixe de acontecer caso topResults esteja vazio.
      final topResult = response.topResults.isNotEmpty
          ? response.topResults.first
          : results.first;

      final target = _visualTargetForSearchResult(topResult);

      debugPrint(
        '[BRAIN SEARCH VISUAL] '
        'Encontrado="${topResult.title}" '
        'ramo=${target.branchIndex} '
        'conexao=${target.connectionIndex}.',
      );

      visualController.resolveSearch(
        branchIndex: target.branchIndex,
        connectionIndex: target.connectionIndex,
      );
    });
  }

  // ============================================================
  // ALVO VISUAL EXATO DO RESULTADO
  // ============================================================
  //
  // O BrainScreen atual ainda usa o crescimento visual legado:
  //
  //   1 BrainFile salvo
  //        ↓
  //   1 nova entrada de BrainPaths.connections
  //
  // Portanto o vínculo correto do arquivo com o desenho é a posição
  // dele em _controller.notes. Não usamos mais hash para escolher um
  // ramo durante a pesquisa.
  //
  // Se no futuro o crescimento semântico for realmente ativado e o
  // BrainFile passar a carregar uma semanticKey persistida, este método
  // poderá devolver branchIndex. Por enquanto preservamos a arquitetura
  // real que está desenhando o cérebro hoje.
  //
  // ============================================================

  _BrainSearchVisualTarget _visualTargetForSearchResult(BrainFile note) {
    final noteIndex = _indexOfBrainNote(note);

    if (noteIndex >= 0 && noteIndex < BrainPaths.connections.length) {
      return _BrainSearchVisualTarget(connectionIndex: noteIndex);
    }

    // Fail-safe: se por algum motivo o resultado não estiver mais na
    // lista local (por exemplo, exclusão/reload entre busca e animação),
    // não acendemos outro ramo aleatório.
    return const _BrainSearchVisualTarget();
  }

  int _indexOfBrainNote(BrainFile note) {
    // O crescimento legado nasce em ordem de criação: cada novo arquivo
    // aumenta knowledgeCount em 1 e revela a próxima conexão. A lista de
    // notas pode ser exibida em outra ordenação, então não usamos
    // _controller.notes.indexOf(note) como posição visual.
    final orderedNotes = <BrainFile>[..._controller.notes]
      ..sort((a, b) {
        final byCreatedAt = a.createdAt.compareTo(b.createdAt);

        if (byCreatedAt != 0) {
          return byCreatedAt;
        }

        return a.path.compareTo(b.path);
      });

    final notePath = note.path.trim();

    if (notePath.isNotEmpty) {
      final pathIndex = orderedNotes.indexWhere(
        (item) => item.path.trim() == notePath,
      );

      if (pathIndex >= 0) {
        return pathIndex;
      }
    }

    final directIndex = orderedNotes.indexOf(note);

    if (directIndex >= 0) {
      return directIndex;
    }

    // Último fallback por identidade textual. Isso apenas reencontra o
    // mesmo arquivo na lista cronológica; nunca escolhe um caminho por hash.
    return orderedNotes.indexWhere(
      (item) =>
          item.title == note.title &&
          item.content == note.content &&
          item.createdAt == note.createdAt,
    );
  }


  // ============================================================
  // PESQUISA
  // ============================================================
  //
  // FASE 12 — RESPOSTAS ESTRUTURADAS
  //
  // A BrainScreen apenas:
  //
  // - consulta o conteúdo local já carregado;
  //   // - envia para BrainSearchEngine;
  // - renderiza BrainSearchResponse.
  //
  // O parser interpreta a linguagem natural.
  // O engine filtra e ranqueia.
  // A response organiza os resultados.
  //
  // ============================================================

  BrainSearchResponse get _searchResponse {
    final parsedQuery = _BrainScreenState._searchParser.parse(_searchQuery);

    if (parsedQuery.isEmpty) {
      return BrainSearchResponse.fromResults(const <BrainFile>[]);
    }

    return _BrainScreenState._searchEngine.search(
      notes: _controller.notes,
      query: parsedQuery,
      topLimit: 3,
    );
  }

  // ============================================================
  // PESQUISA LOCAL / VAULT-FIRST
  // ============================================================
  //
  // A pesquisa não consulta o Supabase automaticamente.
  //
  // O parser e o engine trabalham somente sobre as notas que o
  // BrainController já carregou do armazenamento local/Vault.
  //
  // A nuvem permanece fora do caminho crítico e continua sendo
  // usada apenas pela sincronização E2EE.
  //
  // ============================================================

  void _scheduleRemoteSearch(String rawQuery) {
    // Mantido para preservar os callers existentes da interface.
    // A alteração de _searchQuery já dispara o rebuild e a busca
    // local. Nenhuma chamada de rede acontece aqui.
    if (rawQuery.trim().isEmpty) {
      return;
    }
  }

  // ============================================================
  // DATA BR
  // ============================================================

  String _formatSearchDate(DateTime date) {
    final local = date.toLocal();

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year}';
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  String _previewContent(String content) {
    final clean = content.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (clean.length <= 180) {
      return clean;
    }

    return '${clean.substring(0, 180)}...';
  }

  // ============================================================
  // ABRIR RESULTADO EM PÁGINA
  // ============================================================
  //
  // Qualquer anotação existente localmente,
  // é aberta exclusivamente pela BrainNoteScreen.
  //
  // NÃO reutilizar o modal de criação aqui.
  //
  // ============================================================

  Future<void> _openSearchResult(BrainFile note) async {
    if (!mounted) {
      return;
    }

    final noteToOpen = note;

    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) {
          return BrainNoteScreen(note: noteToOpen);
        },
      ),
    );

    if (!mounted) {
      return;
    }

    // ========================================================
    // RECARREGAR AO VOLTAR
    // ========================================================
    //
    // Se a página editou ou excluiu a anotação, a lista local
    // e os resultados da pesquisa refletem a mudança.
    //
    // ========================================================

    if (changed == true) {
      await _controller.loadNotes();

      if (!mounted) {
        return;
      }

      await _syncBrainVisualKnowledge(animateGrowth: false);
    }

    if (!mounted) {
      return;
    }

    _mutateState(() {});
  }

  // ============================================================
  // AJUDA DA PESQUISA
  // ============================================================

  Future<void> _showSearchHelp() async {
    await BrainSearchHelpDialog.show(
      context: context,
      onUseExample: (example) {
        if (!mounted) {
          return;
        }

        _searchController.text = example;

        _searchController.selection = TextSelection.collapsed(
          offset: example.length,
        );

        _mutateState(() {
          _searchQuery = example;

          _showAllSearchResults = false;
        });

        _scheduleRemoteSearch(example);

        _setBrainSearchActivity(
          example,
          hold: const Duration(milliseconds: 1500),
        );
      },
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget _buildSearchField(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Tooltip(
          message: 'Como pesquisar',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _showSearchHelp,
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 21,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              _mutateState(() {
                _searchQuery = value;

                _showAllSearchResults = false;
              });

              _scheduleRemoteSearch(value);

              _setBrainSearchActivity(value);
            },
            onSubmitted: (value) {
              _setBrainSearchActivity(
                value,
                hold: const Duration(milliseconds: 1600),
              );
            },
            decoration: InputDecoration(
              hintText: 'Pergunte ao que você já aprendeu...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        _searchController.clear();

                        _mutateState(() {
                          _searchQuery = '';

                          _showAllSearchResults = false;
                        });

                        _setBrainSearchActivity('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.28,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULTADOS DA PESQUISA
  // ============================================================
  //
  // FASE 12:
  //
  // Mostramos inicialmente apenas os 3 resultados mais relevantes.
  //
  // Se houver mais:
  //
  // "Ver todos os X resultados"
  //
  // Assim a pesquisa não cresce indefinidamente na tela.
  //
  // ============================================================

  Widget _buildSearchResults(BuildContext context) {
    final response = _searchResponse;

    final visibleNotes = _showAllSearchResults
        ? response.allResults
        : response.topResults;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.manage_search_rounded, size: 20),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    response.isEmpty
                        ? 'Nenhum resultado'
                        : response.resultLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // RESUMO POR TIPO
          // ==================================================
          if (response.isNotEmpty && response.groupSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response.groupSummary.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).dividerColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
          ),

          // ==================================================
          // EMPTY
          // ==================================================
          if (response.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text('Nenhuma anotação corresponde à pesquisa.'),
            )
          else ...[
            // ================================================
            // TOP RESULTS / ALL RESULTS
            // ================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 5),
              child: Text(
                _showAllSearchResults
                    ? 'Todos os resultados'
                    : 'Mais relevantes',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),

            for (var index = 0; index < visibleNotes.length; index++) ...[
              _buildSearchResultCard(context, visibleNotes[index]),

              if (index != visibleNotes.length - 1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.35),
                ),
            ],

            // ================================================
            // EXPAND / COLLAPSE
            // ================================================
            if (response.hasMoreResults)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      _mutateState(() {
                        _showAllSearchResults = !_showAllSearchResults;
                      });
                    },
                    icon: Icon(
                      _showAllSearchResults
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(
                      _showAllSearchResults
                          ? 'Mostrar apenas os principais'
                          : 'Ver todos os ${response.total} resultados',
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE RESULTADO
  // ============================================================

  Widget _buildSearchResultCard(BuildContext context, BrainFile note) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openSearchResult(note);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _buildSearchMeta(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          text:
                              'Criado em ${_formatSearchDate(note.createdAt)}',
                        ),
                        _buildSearchMeta(
                          context: context,
                          icon: Icons.update_rounded,
                          text:
                              'Atualizado em ${_formatSearchDate(note.updatedAt)}',
                        ),
                      ],
                    ),

                    if (note.content.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _previewContent(note.content),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 10),

              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // META DO RESULTADO
  // ============================================================

  Widget _buildSearchMeta({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

}
