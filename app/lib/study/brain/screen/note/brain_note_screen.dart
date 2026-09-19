import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../controllers/brain_controller.dart';
import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';
import '../../sections/brain_editor_section.dart';
import '../../source/widgets/brain_sources_section.dart';

// ============================================================
// BRAIN NOTE SCREEN
// ============================================================
//
// Página dedicada para ABRIR uma anotação já existente.
//
// Fluxo:
//
// BrainScreen
//      ↓
// BrainNoteScreen
//      ↓
// BrainController global
//      ↓
// BrainRepository
//      ↓
// local + SyncQueue + Supabase
//
// Esta página NÃO cria BrainController próprio.
// Também NÃO faz dispose() no controller global.
//
// FASE 09 — CAPTURA SEM TEMA:
//
// - Tema não é mais exibido no viewer;
// - Tema não é mais enviado ao editor visual;
// - anotações antigas continuam compatíveis internamente por meio
//   do BrainFile / BrainController / BrainStorage legado.
//
// FASE 13 — FONTES DO CONHECIMENTO:
//
// - fontes aparecem na visualização da anotação;
// - adicionar/editar/remover usa BrainSourcesSection;
// - persistência continua no Vault criptografado;
// - BrainStorage Markdown não recebe metadados sensíveis da fonte.
//
// ============================================================

class BrainNoteScreen
    extends
        StatefulWidget {
  const BrainNoteScreen({
    super.key,
    required this.note,
    this.initialSearchTerms =
        const <
          String
        >[],
  });

  final BrainFile note;

  // Termos vindos da busca do Brain. Quando presentes, a página abre
  // diretamente na região do conteúdo que contém a melhor ocorrência.
  final List<
    String
  >
  initialSearchTerms;

  @override
  State<
    BrainNoteScreen
  >
  createState() {
    return _BrainNoteScreenState();
  }
}

class _BrainNoteScreenState
    extends
        State<
          BrainNoteScreen
        > {
  late final BrainController _controller;

  final ScrollController _viewerScrollController = ScrollController();

  late final TextEditingController _searchNavigatorController;
  final FocusNode _searchNavigatorFocusNode = FocusNode();
  late List<
    String
  >
  _activeSearchTerms;

  final List<
    GlobalKey
  >
  _searchMatchKeys =
      <
        GlobalKey
      >[];

  int _activeSearchMatchIndex = 0;

  bool _showSearchNavigator = true;

  bool _isSearchNavigatorHovered = false;

  bool _isOpening = true;

  bool _didPositionInitialSearch = false;

  bool _isEditing = false;

  bool _isDeleting = false;

  String? _openError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = dependencies.brainController;

    _controller.addListener(
      _onControllerChanged,
    );

    _activeSearchTerms = widget.initialSearchTerms
        .map(
          (
            term,
          ) => term.trim(),
        )
        .where(
          (
            term,
          ) => term.isNotEmpty,
        )
        .toList();

    _searchNavigatorController = TextEditingController(
      text: _activeSearchTerms.join(
        ' ',
      ),
    );

    _openNote();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _viewerScrollController.dispose();
    _searchNavigatorController.dispose();
    _searchNavigatorFocusNode.dispose();

    // Controller global:
    // não fazer _controller.dispose() aqui.

    super.dispose();
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // OPEN
  // ============================================================

  Future<
    void
  >
  _openNote() async {
    setState(
      () {
        _isOpening = true;
        _openError = null;
      },
    );

    final opened = await _controller.openNote(
      widget.note,
    );

    if (!mounted) {
      return;
    }

    if (!opened) {
      setState(
        () {
          _isOpening = false;
          _openError =
              _controller.errorMessage ??
              'Não foi possível abrir a anotação.';
        },
      );

      _controller.clearMessages();

      return;
    }

    setState(
      () {
        _isOpening = false;
      },
    );

    _scheduleInitialSearchPosition();
  }

  // ============================================================
  // POSICIONAMENTO INICIAL DA BUSCA
  // ============================================================

  void _scheduleInitialSearchPosition() {
    if (_didPositionInitialSearch ||
        _activeSearchTerms.isEmpty) {
      return;
    }

    _didPositionInitialSearch = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        WidgetsBinding.instance.addPostFrameCallback(
          (
            _,
          ) {
            if (!mounted ||
                _searchMatchKeys.isEmpty) {
              return;
            }

            _goToSearchMatch(
              0,
              animate: false,
            );
          },
        );
      },
    );
  }

  void _syncSearchMatchKeys(
    int matchCount,
  ) {
    while (_searchMatchKeys.length <
        matchCount) {
      _searchMatchKeys.add(
        GlobalKey(),
      );
    }

    if (_searchMatchKeys.length >
        matchCount) {
      _searchMatchKeys.removeRange(
        matchCount,
        _searchMatchKeys.length,
      );
    }

    if (matchCount ==
        0) {
      _activeSearchMatchIndex = 0;
      return;
    }

    if (_activeSearchMatchIndex >=
        matchCount) {
      _activeSearchMatchIndex =
          matchCount -
          1;
    }
  }

  Future<
    void
  >
  _goToSearchMatch(
    int index, {
    bool animate = true,
  }) async {
    if (_searchMatchKeys.isEmpty) {
      return;
    }

    final count = _searchMatchKeys.length;

    final normalizedIndex =
        ((index %
                count) +
            count) %
        count;

    if (mounted &&
        _activeSearchMatchIndex !=
            normalizedIndex) {
      setState(
        () {
          _activeSearchMatchIndex = normalizedIndex;
        },
      );

      // A troca do destaque ativo altera o widget. Esperamos o frame
      // antes de procurar o BuildContext da ocorrência.
      await WidgetsBinding.instance.endOfFrame;
    }

    if (!mounted) {
      return;
    }

    final targetContext = _searchMatchKeys[normalizedIndex].currentContext;

    if (targetContext ==
            null ||
        !targetContext.mounted) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.28,
      duration: animate
          ? const Duration(
              milliseconds: 360,
            )
          : Duration.zero,
      curve: Curves.easeOutCubic,
    );
  }

  void _goToPreviousSearchMatch() {
    _goToSearchMatch(
      _activeSearchMatchIndex -
          1,
    );
  }

  void _goToNextSearchMatch() {
    _goToSearchMatch(
      _activeSearchMatchIndex +
          1,
    );
  }

  void _closeSearchNavigator() {
    if (!_showSearchNavigator) {
      return;
    }

    setState(
      () {
        _showSearchNavigator = false;
      },
    );
  }

  void _submitSearchNavigator(
    String value,
  ) {
    final clean = value.trim();

    setState(
      () {
        _activeSearchTerms = clean.isEmpty
            ? <
                String
              >[]
            : <
                String
              >[
                clean,
              ];
        _activeSearchMatchIndex = 0;
        _showSearchNavigator = true;
      },
    );

    if (clean.isEmpty) {
      _searchNavigatorFocusNode.requestFocus();
      return;
    }

    _searchNavigatorFocusNode.unfocus();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted ||
            _searchMatchKeys.isEmpty) {
          return;
        }

        _goToSearchMatch(
          0,
        );
      },
    );
  }

  void _openSearchNavigator() {
    setState(
      () {
        _showSearchNavigator = true;
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _searchNavigatorFocusNode.requestFocus();
        _searchNavigatorController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchNavigatorController.text.length,
        );
      },
    );
  }

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

    return normalized;
  }

  List<
    _BrainNoteSearchMatch
  >
  _searchMatches(
    String text,
  ) {
    final normalizedText = _normalizeSearchText(
      text,
    );

    final matches =
        <
          _BrainNoteSearchMatch
        >[];

    for (final rawTerm in _activeSearchTerms) {
      final term = rawTerm.trim();

      if (term.isEmpty) {
        continue;
      }

      final normalizedTerm = _normalizeSearchText(
        term,
      );

      if (normalizedTerm.isEmpty) {
        continue;
      }

      var start = 0;

      while (start <
          normalizedText.length) {
        final index = normalizedText.indexOf(
          normalizedTerm,
          start,
        );

        if (index <
            0) {
          break;
        }

        final end =
            index +
            normalizedTerm.length;

        if (index <=
                text.length &&
            end <=
                text.length) {
          matches.add(
            _BrainNoteSearchMatch(
              start: index,
              end: end,
            ),
          );
        }

        start =
            end >
                start
            ? end
            : start +
                  1;
      }
    }

    matches.sort(
      (
        a,
        b,
      ) {
        final byStart = a.start.compareTo(
          b.start,
        );

        if (byStart !=
            0) {
          return byStart;
        }

        return b.end.compareTo(
          a.end,
        );
      },
    );

    final merged =
        <
          _BrainNoteSearchMatch
        >[];

    for (final match in matches) {
      if (merged.isEmpty) {
        merged.add(
          match,
        );
        continue;
      }

      final previous = merged.last;

      if (match.start <
          previous.end) {
        if (match.end >
            previous.end) {
          merged[merged.length -
              1] = _BrainNoteSearchMatch(
            start: previous.start,
            end: match.end,
          );
        }

        continue;
      }

      merged.add(
        match,
      );
    }

    return merged;
  }

  Widget _buildSearchAwareContent(
    BuildContext context,
    BrainFile note,
  ) {
    final style =
        Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.65,
        );

    if (_activeSearchTerms.isEmpty) {
      _syncSearchMatchKeys(
        0,
      );

      return SelectableText(
        note.content,
        style: style,
      );
    }

    final matches = _searchMatches(
      note.content,
    );

    _syncSearchMatchKeys(
      matches.length,
    );

    if (matches.isEmpty) {
      return SelectableText(
        note.content,
        style: style,
      );
    }

    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final normalHighlightStyle =
        style?.copyWith(
          backgroundColor: colorScheme.primaryContainer.withValues(
            alpha: 0.62,
          ),
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ) ??
        TextStyle(
          backgroundColor: colorScheme.primaryContainer.withValues(
            alpha: 0.62,
          ),
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        );

    final activeHighlightStyle =
        style?.copyWith(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
        ) ??
        TextStyle(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w800,
          decoration: TextDecoration.underline,
          decorationThickness: 2,
        );

    final children =
        <
          Widget
        >[];
    var cursor = 0;

    for (
      var index = 0;
      index <
          matches.length;
      index++
    ) {
      final match = matches[index];

      if (match.start >
          cursor) {
        children.add(
          SelectableText(
            note.content.substring(
              cursor,
              match.start,
            ),
            style: style,
          ),
        );
      }

      final matchedText = note.content.substring(
        match.start,
        match.end,
      );

      final isActive =
          index ==
          _activeSearchMatchIndex;

      children.add(
        Container(
          key: _searchMatchKeys[index],
          alignment: Alignment.centerLeft,
          child: SelectableText(
            matchedText,
            style: isActive
                ? activeHighlightStyle
                : normalHighlightStyle,
          ),
        ),
      );

      cursor = match.end;
    }

    if (cursor <
        note.content.length) {
      children.add(
        SelectableText(
          note.content.substring(
            cursor,
          ),
          style: style,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildSearchNavigator(
    BuildContext context,
  ) {
    if (!_showSearchNavigator) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final hasMatches = _searchMatchKeys.isNotEmpty;
    final isFocused = _searchNavigatorFocusNode.hasFocus;
    final isActive =
        _isSearchNavigatorHovered ||
        isFocused;

    // Em repouso o localizador interfere menos na leitura.
    // Ao passar o mouse ou editar a busca, ele volta a ficar
    // praticamente opaco para manter ótima legibilidade.
    final panelOpacity = isActive
        ? 0.96
        : 0.68;

    final borderOpacity = isActive
        ? 0.62
        : 0.30;

    final elevation = isActive
        ? 2.0
        : 0.7;

    return MouseRegion(
      onEnter:
          (
            _,
          ) {
            if (!mounted ||
                _isSearchNavigatorHovered) {
              return;
            }

            setState(
              () {
                _isSearchNavigatorHovered = true;
              },
            );
          },
      onExit:
          (
            _,
          ) {
            if (!mounted ||
                !_isSearchNavigatorHovered) {
              return;
            }

            setState(
              () {
                _isSearchNavigatorHovered = false;
              },
            );
          },
      child: AnimatedOpacity(
        opacity: isActive
            ? 1.0
            : 0.88,
        duration: const Duration(
          milliseconds: 160,
        ),
        curve: Curves.easeOut,
        child: Material(
          elevation: elevation,
          borderRadius: BorderRadius.circular(
            12,
          ),
          color: colorScheme.surfaceContainerHighest.withValues(
            alpha: panelOpacity,
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ),
            padding: const EdgeInsets.only(
              left: 10,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(
                  alpha: borderOpacity,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 170,
                  child: TextField(
                    controller: _searchNavigatorController,
                    focusNode: _searchNavigatorFocusNode,
                    textInputAction: TextInputAction.search,
                    onTap: () {
                      if (!mounted) {
                        return;
                      }

                      // O FocusNode muda antes do próximo frame.
                      // Este setState garante que o painel reaja
                      // imediatamente ao clique.
                      setState(
                        () {},
                      );
                    },
                    onSubmitted: _submitSearchNavigator,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Pesquisar...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: 28,
                      ),
                    ),
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  hasMatches
                      ? '${_activeSearchMatchIndex + 1} de ${_searchMatchKeys.length}'
                      : '0 de 0',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                IconButton(
                  tooltip: 'Ocorrência anterior',
                  visualDensity: VisualDensity.compact,
                  onPressed: hasMatches
                      ? _goToPreviousSearchMatch
                      : null,
                  icon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Próxima ocorrência',
                  visualDensity: VisualDensity.compact,
                  onPressed: hasMatches
                      ? _goToNextSearchMatch
                      : null,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar navegação da busca',
                  visualDensity: VisualDensity.compact,
                  onPressed: _closeSearchNavigator,
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 19,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CURRENT NOTE
  // ============================================================

  BrainFile get _currentNote {
    return _controller.selectedNote ??
        widget.note;
  }

  // ============================================================
  // EDIT
  // ============================================================

  void _startEditing() {
    if (_controller.isSaving ||
        _isDeleting) {
      return;
    }

    setState(
      () {
        _isEditing = true;
      },
    );
  }

  void _cancelEditing() {
    if (_controller.isSaving) {
      return;
    }

    setState(
      () {
        _isEditing = false;
      },
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _save() async {
    final title = _controller.titleController.text.trim();

    final content = _controller.contentController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Digite um título antes de salvar.',
      );

      return;
    }

    if (content.isEmpty) {
      _showMessage(
        'Digite o conteúdo antes de salvar.',
      );

      return;
    }

    final saved = await _controller.saveNote();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showControllerMessage();

      return;
    }

    setState(
      () {
        _isEditing = false;
      },
    );

    _showControllerMessage();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _delete(
    BrainFile note,
  ) async {
    if (_isDeleting ||
        _controller.isSaving) {
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
                    'Excluir anotação?',
                  ),
                  content: Text(
                    'Deseja excluir permanentemente "${note.title}"?',
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

    final deleted = await _controller.deleteNote(
      note,
    );

    if (!mounted) {
      return;
    }

    if (!deleted) {
      setState(
        () {
          _isDeleting = false;
        },
      );

      _showControllerMessage();

      return;
    }

    Navigator.of(
      context,
    ).pop(
      true,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showControllerMessage() {
    final error = _controller.errorMessage;

    final success = _controller.successMessage;

    if (error !=
        null) {
      _showMessage(
        error,
      );

      _controller.clearMessages();

      return;
    }

    if (success !=
        null) {
      _showMessage(
        success,
      );

      _controller.clearMessages();
    }
  }

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
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    String two(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar anotação'
              : 'Anotação',
        ),
        actions: [
          if (!_isOpening &&
              _openError ==
                  null &&
              !_isEditing)
            IconButton(
              tooltip: 'Editar',
              onPressed:
                  _controller.isSaving ||
                      _isDeleting
                  ? null
                  : _startEditing,
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),

          if (_isEditing)
            TextButton(
              onPressed: _controller.isSaving
                  ? null
                  : _cancelEditing,
              child: const Text(
                'Cancelar',
              ),
            ),

          if (!_isEditing &&
              !_isOpening &&
              _openError ==
                  null)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _isDeleting
                  ? null
                  : () {
                      _delete(
                        _currentNote,
                      );
                    },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),

          const SizedBox(
            width: 8,
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
    if (_isOpening) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_openError !=
        null) {
      return _buildError();
    }

    if (_isEditing) {
      return _buildEditor();
    }

    return _buildViewer(
      context,
    );
  }

  // ============================================================
  // VIEWER
  // ============================================================

  Widget _buildViewer(
    BuildContext context,
  ) {
    final note = _currentNote;

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _viewerScrollController,
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 900,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // TITLE
                  // ==================================================
                  SelectableText(
                    note.title,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // ==================================================
                  // DATES
                  // ==================================================
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _meta(
                        context: context,
                        icon: Icons.calendar_today_outlined,
                        text: 'Criado em ${_formatDate(note.createdAt)}',
                      ),
                      _meta(
                        context: context,
                        icon: Icons.update_rounded,
                        text: 'Atualizado em ${_formatDate(note.updatedAt)}',
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  Divider(
                    color:
                        Theme.of(
                          context,
                        ).dividerColor.withValues(
                          alpha: 0.55,
                        ),
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // ==================================================
                  // CONTENT
                  // ==================================================
                  _buildSearchAwareContent(
                    context,
                    note,
                  ),

                  // ==================================================
                  // FONTES DO CONHECIMENTO
                  // ==================================================
                  const SizedBox(
                    height: 30,
                  ),

                  Divider(
                    color:
                        Theme.of(
                          context,
                        ).dividerColor.withValues(
                          alpha: 0.55,
                        ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  BrainSourcesSection(
                    controller: _controller,
                  ),

                  if (note.concepts.isNotEmpty) ...[
                    const SizedBox(
                      height: 30,
                    ),

                    Divider(
                      color:
                          Theme.of(
                            context,
                          ).dividerColor.withValues(
                            alpha: 0.55,
                          ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    Text(
                      'Classificações',
                      style:
                          Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final concept in note.concepts)
                          Chip(
                            avatar: Icon(
                              _conceptIcon(
                                concept.type,
                              ),
                              size: 16,
                              color: _conceptColor(
                                concept.type,
                              ),
                            ),
                            label: Text(
                              _conceptLabel(
                                concept.type,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 18,
          child: _showSearchNavigator
              ? _buildSearchNavigator(
                  context,
                )
              : Material(
                  elevation: 2,
                  shape: const CircleBorder(),
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  child: IconButton(
                    tooltip: 'Pesquisar nesta anotação',
                    onPressed: _openSearchNavigator,
                    icon: const Icon(
                      Icons.search_rounded,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: BrainEditorSection(
            selectedNote: _controller.selectedNote,
            titleController: _controller.titleController,
            contentController: _controller.contentController,
            contentFocusNode: _controller.contentFocusNode,
            isSaving: _controller.isSaving,
            onSave: _save,
            onDelete: _delete,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CLASSIFICAÇÃO
  // ============================================================
  //
  // BrainConceptType é um enum de domínio e não possui getters
  // visuais como icon, color ou label.
  //
  // Por isso esta tela resolve a apresentação localmente.
  //
  // ============================================================

  IconData _conceptIcon(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return Icons.lightbulb_outline_rounded;

      case BrainConceptType.question:
        return Icons.help_outline_rounded;

      case BrainConceptType.example:
        return Icons.code_rounded;

      case BrainConceptType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  Color _conceptColor(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return const Color(
          0xFF3B6939,
        );

      case BrainConceptType.question:
        return const Color(
          0xFF3859FF,
        );

      case BrainConceptType.example:
        return const Color(
          0xFF6D4AFF,
        );

      case BrainConceptType.warning:
        return const Color(
          0xFFB26A00,
        );
    }
  }

  String _conceptLabel(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return 'Conceito';

      case BrainConceptType.question:
        return 'Pergunta';

      case BrainConceptType.example:
        return 'Exemplo';

      case BrainConceptType.warning:
        return 'Atenção';
    }
  }

  // ============================================================
  // META
  // ============================================================

  Widget _meta({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall,
        ),
      ],
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
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              _openError ??
                  'Não foi possível abrir a anotação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed: _openNote,
              icon: const Icon(
                Icons.refresh_rounded,
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

// ============================================================
// MATCH DE BUSCA DENTRO DA ANOTAÇÃO
// ============================================================

class _BrainNoteSearchMatch {
  const _BrainNoteSearchMatch({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}
