import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/board_controller.dart';
import '../controllers/mind_map_controller.dart';
import '../controllers/routine_controller.dart';
import '../controllers/routine_state.dart';
import '../data/datasources/routine_memory_datasource.dart';
import '../data/datasources/routine_remote_data_source.dart';
import '../data/repositories/routine_repository_impl.dart';
import '../models/block_type.dart';
import '../models/board_block.dart';
import '../models/check_item.dart';
import '../models/routine_day.dart';
import '../widgets/blocks/content_block.dart';
import '../widgets/blocks/mind_map/mind_map_block.dart';
import '../widgets/blocks/note_block.dart';
import '../widgets/blocks/photo_block.dart';
import '../widgets/blocks/task_block.dart';
import '../widgets/calendar/routine_calendar_panel.dart';
import '../widgets/dialogs/add_block_sheet.dart';
import '../widgets/dialogs/routine_text_editor.dart';

class RoutineScreen
    extends
        StatefulWidget {
  const RoutineScreen({
    super.key,
    this.controller,
    this.userId,
  });

  /// Permite injetar um controller já configurado.
  ///
  /// Quando nenhum controller é informado, a tela cria automaticamente:
  ///
  /// Supabase Auth
  ///      ↓
  /// RoutineController
  ///      ↓
  /// RoutineRepositoryImpl
  ///      ↓
  /// RoutineRemoteDataSource
  ///
  /// O [userId] foi mantido apenas por compatibilidade com chamadas antigas.
  /// Para persistência no Supabase, o ID usado é sempre o usuário autenticado.
  final RoutineController? controller;
  final String? userId;

  @override
  State<
    RoutineScreen
  >
  createState() => _RoutineScreenState();
}

class _RoutineScreenState
    extends
        State<
          RoutineScreen
        > {
  static const Color _background = Color(
    0xFF090A0E,
  );
  static const Color _surface = Color(
    0xFF111319,
  );
  static const Color _surfaceLight = Color(
    0xFF171A22,
  );
  static const Color _border = Color(
    0xFF272B36,
  );
  static const Color _primary = Color(
    0xFF7C5CFF,
  );
  static const Color _text = Color(
    0xFFF5F7FA,
  );
  static const Color _muted = Color(
    0xFF9298A6,
  );

  late final RoutineController _routineController;
  late final BoardController _boardController;
  late final MindMapController _mindMapController;
  late final bool _ownsRoutineController;

  bool _routineControllerReady = false;
  bool _initializingRoutine = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();

    _ownsRoutineController =
        widget.controller ==
        null;

    _boardController = BoardController(
      onChanged: _refreshBoard,
    );

    _mindMapController = MindMapController(
      onChanged: _onMindMapChanged,
    );

    _initializeRoutine();
  }

  Future<
    void
  >
  _initializeRoutine() async {
    try {
      final injectedController = widget.controller;

      if (injectedController !=
          null) {
        _routineController = injectedController;
      } else {
        _routineController = await _createSupabaseController();
      }

      _routineController.addListener(
        _onRoutineChanged,
      );

      _routineControllerReady = true;

      await _routineController.initialize();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _initializingRoutine = false;
          _initializationError = null;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '',
      );
      debugPrint(
        '============================================================',
      );
      debugPrint(
        '[ROUTINE][INITIALIZE] ERRO',
      );
      debugPrint(
        '$error',
      );
      debugPrint(
        '$stackTrace',
      );
      debugPrint(
        '============================================================',
      );
      debugPrint(
        '',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _initializingRoutine = false;
          _initializationError = _friendlyInitializationError(
            error,
          );
        },
      );
    }
  }

  Future<
    RoutineController
  >
  _createSupabaseController() async {
    final supabase = Supabase.instance.client;

    // ==========================================================
    // AUTH
    // ==========================================================
    //
    // Nunca utilizamos mais "local-user".
    //
    // Se já houver uma sessão, reutilizamos o usuário.
    // Caso contrário, tentamos autenticação anônima.
    //
    // Para signInAnonymously funcionar, habilite no Supabase:
    //
    // Authentication
    //   -> Providers
    //   -> Anonymous
    //
    // ==========================================================

    var user = supabase.auth.currentUser;

    if (user ==
        null) {
      debugPrint(
        '[ROUTINE][AUTH] Nenhuma sessão encontrada.',
      );

      debugPrint(
        '[ROUTINE][AUTH] Tentando login anônimo...',
      );

      final response = await supabase.auth.signInAnonymously();

      user = response.user;
    }

    if (user ==
        null) {
      throw StateError(
        'Não foi possível obter um usuário autenticado no Supabase.',
      );
    }

    final legacyUserId = widget.userId?.trim();

    if (legacyUserId !=
            null &&
        legacyUserId.isNotEmpty &&
        legacyUserId !=
            'local-user' &&
        legacyUserId !=
            user.id) {
      debugPrint(
        '[ROUTINE][AUTH] userId recebido pela tela foi ignorado: '
        '$legacyUserId',
      );

      debugPrint(
        '[ROUTINE][AUTH] ID autenticado usado: ${user.id}',
      );
    }

    debugPrint(
      '[ROUTINE][AUTH] Usuário autenticado: ${user.id}',
    );

    // ==========================================================
    // REMOTE DATASOURCE
    // ==========================================================

    final remoteDataSource = RoutineRemoteDataSource(
      client: supabase,
    );

    // ==========================================================
    // REPOSITORY
    // ==========================================================

    final repository = RoutineRepositoryImpl(
      localDataSource: RoutineMemoryDataSource(),
      remoteDataSource: remoteDataSource,

      // Durante a integração não escondemos erros do Supabase.
      fallbackToLocalOnRemoteError: false,
    );

    // ==========================================================
    // CONTROLLER
    // ==========================================================

    return RoutineController(
      repository: repository,
      userId: user.id,
    );
  }

  String _friendlyInitializationError(
    Object error,
  ) {
    if (error
        is AuthException) {
      return 'Falha na autenticação do Supabase: ${error.message}\n\n'
          'Se o app ainda não possui tela de login, habilite Anonymous '
          'Sign-Ins no painel do Supabase.';
    }

    final message = error.toString().trim();

    if (message.isEmpty) {
      return 'Não foi possível inicializar a rotina.';
    }

    return message;
  }

  Future<
    void
  >
  _retryInitialization() async {
    if (_initializingRoutine) {
      return;
    }

    if (_routineControllerReady) {
      return;
    }

    setState(
      () {
        _initializingRoutine = true;
        _initializationError = null;
      },
    );

    await _initializeRoutine();
  }

  @override
  void dispose() {
    if (_routineControllerReady) {
      _routineController.removeListener(
        _onRoutineChanged,
      );

      if (_ownsRoutineController) {
        _routineController.dispose();
      }
    }

    _boardController.dispose();
    _mindMapController.dispose();

    super.dispose();
  }

  void _onRoutineChanged() {
    if (mounted) {
      setState(
        () {},
      );
    }
  }

  void _refreshBoard() {
    if (mounted) {
      setState(
        () {},
      );
    }
  }

  void _onMindMapChanged() {
    if (!_routineControllerReady) {
      _refreshBoard();
      return;
    }

    _routineController.notifyBlockChanged();
  }

  void _notifyRoutineMutation() {
    if (!_routineControllerReady) {
      return;
    }

    _routineController.notifyBlockChanged();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_initializingRoutine) {
      return const Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: _primary,
            ),
          ),
        ),
      );
    }

    final initializationError = _initializationError;

    if (initializationError !=
        null) {
      return _RoutineInitializationError(
        message: initializationError,
        onRetry: _retryInitialization,
      );
    }

    if (!_routineControllerReady) {
      return _RoutineInitializationError(
        message: 'RoutineController não foi inicializado.',
        onRetry: _retryInitialization,
      );
    }

    final state = _routineController.state;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(
              state,
            ),
            RoutineCalendarPanel(
              state: state,
              onPreviousWeek: _routineController.previousWeek,
              onNextWeek: _routineController.nextWeek,
              onSelectDay: _routineController.selectDay,
              onToggleExpanded: _routineController.toggleCalendarExpanded,
            ),
            if (state.hasError)
              _buildError(
                state.errorMessage!,
              ),
            Expanded(
              child: state.loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: _primary,
                      ),
                    )
                  : _buildSelectedDay(
                      _routineController.selectedDay,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    RoutineState state,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        8,
      ),
      child: Row(
        children: [
          _RoundIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Voltar',
            onTap: () => Navigator.maybePop(
              context,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROTINA',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.1,
                  ),
                ),
                SizedBox(
                  height: 2,
                ),
                Text(
                  'Planeje a semana. Construa sua evolução.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: state.saving
                ? null
                : _routineController.saveSelectedDay,
            style: TextButton.styleFrom(
              foregroundColor: _text,
              backgroundColor: _surfaceLight,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
                side: const BorderSide(
                  color: _border,
                ),
              ),
            ),
            icon: state.saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _text,
                    ),
                  )
                : const Icon(
                    Icons.cloud_done_outlined,
                    size: 18,
                  ),
            label: Text(
              state.saving
                  ? 'Salvando'
                  : 'Salvar',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    String message,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF3A1F29,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(
            0xFF7C3047,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(
              0xFFFF8DAA,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _text,
                fontSize: 12,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            onPressed: _routineController.clearError,
            icon: const Icon(
              Icons.close_rounded,
              color: _muted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDay(
    RoutineDay day,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            viewport,
          ) {
            final horizontalPadding =
                viewport.maxWidth <
                    700
                ? 12.0
                : 20.0;
            final boardWidth = math
                .max(
                  1.0,
                  viewport.maxWidth -
                      (horizontalPadding *
                          2),
                )
                .toDouble();
            final minimumHeight = math
                .max(
                  480.0,
                  viewport.maxHeight -
                      100,
                )
                .toDouble();

            _boardController.initializePositions(
              day: day,
              boardWidth: boardWidth,
            );

            final boardHeight = _boardController.canvasHeight(
              day: day,
              minimumHeight: minimumHeight,
              estimatedBlockHeight: 430,
              bottomPadding: 80,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                18,
                horizontalPadding,
                24,
              ),
              child: Column(
                children: [
                  _DayHeader(
                    day: day,
                    onEditFocus: _editFocus,
                    onAddBlock: _addBlock,
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Container(
                    width: boardWidth,
                    height: boardHeight,
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                      child: day.blocks.isEmpty
                          ? _EmptyBoard(
                              onAddBlock: _addBlock,
                            )
                          : Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: const _GridPainter(),
                                  ),
                                ),
                                for (final block in day.blocks)
                                  _positionedBlock(
                                    day: day,
                                    block: block,
                                    boardWidth: boardWidth,
                                    boardHeight: boardHeight,
                                  ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
    );
  }

  Widget _positionedBlock({
    required RoutineDay day,
    required BoardBlock block,
    required double boardWidth,
    required double boardHeight,
  }) {
    final width = _boardController.blockWidth(
      block: block,
      boardWidth: boardWidth,
    );
    final position =
        block.position ??
        Offset.zero;

    return Positioned(
      key: ValueKey(
        block.id,
      ),
      left: position.dx,
      top: position.dy,
      width: width,
      child: _BoardCard(
        block: block,
        onDrag:
            (
              delta,
            ) {
              _boardController.moveBlock(
                block: block,
                delta: delta,
                boardWidth: boardWidth,
                boardHeight: boardHeight,
                blockWidth: width,
              );

              _notifyRoutineMutation();
            },
        onEdit: () => _editBlock(
          block,
        ),
        onDuplicate: () {
          _boardController.duplicateBlock(
            day,
            block,
          );

          _notifyRoutineMutation();
        },
        onDelete: () => _deleteBlock(
          day,
          block,
        ),
        child: _blockContent(
          block,
        ),
      ),
    );
  }

  Widget _blockContent(
    BoardBlock block,
  ) {
    switch (block.type) {
      case BlockType.tasks:
        return TaskBlock(
          block: block,
          onToggle:
              (
                item,
              ) {
                item.done = !item.done;
                _notifyRoutineMutation();
              },
          onAddTask: () => _addTask(
            block,
          ),
        );
      case BlockType.note:
        return NoteBlock(
          block: block,
        );
      case BlockType.content:
        return ContentBlock(
          block: block,
          onStatusChanged:
              (
                status,
              ) {
                block.status = status;
                _notifyRoutineMutation();
              },
        );
      case BlockType.photo:
        return PhotoBlock(
          block: block,
          onOpen: () => _showPhotoReference(
            block,
          ),
        );
      case BlockType.mindMap:
        return MindMapBlock(
          block: block,
          controller: _mindMapController,
        );
    }
  }

  Future<
    void
  >
  _editFocus() async {
    final day = _routineController.selectedDay;
    final value = await RoutineTextEditor.show(
      context,
      title: 'Foco do dia',
      hint: 'Qual é a principal prioridade deste dia?',
      initialValue: day.focus,
      maxLines: 2,
    );

    if (!mounted ||
        value ==
            null) {
      return;
    }

    _routineController.updateFocus(
      value,
    );
  }

  Future<
    void
  >
  _addBlock() async {
    final type = await AddBlockSheet.show(
      context,
    );

    if (!mounted ||
        type ==
            null) {
      return;
    }

    if (type ==
        BlockType.mindMap) {
      final block = BoardBlock(
        id: BoardBlock.createId(),
        type: type,
        title: 'Nova ideia',
      );
      final root = _mindMapController.ensureRoot(
        block,
      );
      _mindMapController.startEditing(
        root,
      );
      _routineController.addBlock(
        block,
      );
      return;
    }

    final value = await RoutineTextEditor.show(
      context,
      title: type.dialogTitle,
      hint: type.hint,
      maxLines:
          type ==
              BlockType.tasks
          ? 1
          : 5,
    );

    if (!mounted ||
        value ==
            null ||
        value.trim().isEmpty) {
      return;
    }

    final block = BoardBlock(
      id: BoardBlock.createId(),
      type: type,
      title: type.defaultTitle,
      content:
          type ==
              BlockType.tasks
          ? ''
          : value,
      items:
          type ==
              BlockType.tasks
          ? [
              CheckItem(
                value,
                id: BoardBlock.createId(),
              ),
            ]
          : null,
    );

    _routineController.addBlock(
      block,
    );
  }

  Future<
    void
  >
  _editBlock(
    BoardBlock block,
  ) async {
    final editsTitle =
        block.type ==
            BlockType.tasks ||
        block.type ==
            BlockType.mindMap;
    final initialValue = editsTitle
        ? block.title
        : block.content;

    final value = await RoutineTextEditor.show(
      context,
      title: editsTitle
          ? 'Editar título'
          : block.type.dialogTitle,
      hint: editsTitle
          ? 'Digite o título do bloco...'
          : block.type.hint,
      initialValue: initialValue,
      maxLines: editsTitle
          ? 1
          : 5,
    );

    if (!mounted ||
        value ==
            null) {
      return;
    }

    if (editsTitle) {
      block.title = value.trim().isEmpty
          ? block.type.defaultTitle
          : value;

      if (block.type ==
          BlockType.mindMap) {
        final root = _mindMapController.ensureRoot(
          block,
        );
        root.label = block.title;
      }
    } else {
      block.content = value;
    }

    _notifyRoutineMutation();
  }

  Future<
    void
  >
  _addTask(
    BoardBlock block,
  ) async {
    final value = await RoutineTextEditor.show(
      context,
      title: 'Nova tarefa',
      hint: BlockType.tasks.hint,
      maxLines: 1,
    );

    if (!mounted ||
        value ==
            null ||
        value.trim().isEmpty) {
      return;
    }

    block.items.add(
      CheckItem(
        value,
        id: BoardBlock.createId(),
      ),
    );
    _notifyRoutineMutation();
  }

  Future<
    void
  >
  _deleteBlock(
    RoutineDay day,
    BoardBlock block,
  ) async {
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
                  backgroundColor: _surfaceLight,
                  title: const Text(
                    'Excluir bloco?',
                    style: TextStyle(
                      color: _text,
                    ),
                  ),
                  content: Text(
                    '“${block.title}” será removido da lousa.',
                    style: const TextStyle(
                      color: _muted,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        false,
                      ),
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(
                        dialogContext,
                        true,
                      ),
                      child: const Text(
                        'Excluir',
                        style: TextStyle(
                          color: Color(
                            0xFFFF7E9D,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed ==
        true) {
      _boardController.removeBlock(
        day,
        block.id,
      );

      _notifyRoutineMutation();
    }
  }

  void _showPhotoReference(
    BoardBlock block,
  ) {
    final reference = block.content.trim();

    if (reference.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: _surfaceLight,
          content: Text(
            reference,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _text,
            ),
          ),
          action: SnackBarAction(
            label: 'Editar',
            textColor: const Color(
              0xFF65C7FF,
            ),
            onPressed: () => _editBlock(
              block,
            ),
          ),
        ),
      );
  }
}

class _RoutineInitializationError
    extends
        StatelessWidget {
  const _RoutineInitializationError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _RoutineScreenState._background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 620,
            ),
            child: Container(
              margin: const EdgeInsets.all(
                24,
              ),
              padding: const EdgeInsets.all(
                22,
              ),
              decoration: BoxDecoration(
                color: _RoutineScreenState._surface,
                borderRadius: BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: const Color(
                    0xFF7C3047,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(
                      0xFFFF8DAA,
                    ),
                    size: 34,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  const Text(
                    'Não foi possível conectar a rotina',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _RoutineScreenState._text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(
                    height: 9,
                  ),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _RoutineScreenState._muted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _RoutineScreenState._primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Tentar novamente',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DayHeader
    extends
        StatelessWidget {
  const _DayHeader({
    required this.day,
    required this.onEditFocus,
    required this.onAddBlock,
  });

  final RoutineDay day;
  final VoidCallback onEditFocus;
  final VoidCallback onAddBlock;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        12,
        14,
      ),
      decoration: BoxDecoration(
        color: _RoutineScreenState._surface,
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: _RoutineScreenState._border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _completeDate(
                    day.date,
                  ),
                  style: const TextStyle(
                    color: _RoutineScreenState._text,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                InkWell(
                  onTap: onEditFocus,
                  borderRadius: BorderRadius.circular(
                    7,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 3,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flag_outlined,
                          size: 15,
                          color: _RoutineScreenState._muted,
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Flexible(
                          child: Text(
                            day.hasFocus
                                ? day.focus
                                : 'Defina o foco deste dia',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _RoutineScreenState._muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          ElevatedButton.icon(
            onPressed: onAddBlock,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: _RoutineScreenState._primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ),
              ),
            ),
            icon: const Icon(
              Icons.add_rounded,
              size: 18,
            ),
            label: const Text(
              'Bloco',
            ),
          ),
        ],
      ),
    );
  }

  String _completeDate(
    DateTime date,
  ) {
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    const months = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }
}

class _BoardCard
    extends
        StatelessWidget {
  const _BoardCard({
    required this.block,
    required this.onDrag,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    required this.child,
  });

  final BoardBlock block;
  final ValueChanged<
    Offset
  >
  onDrag;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final Widget child;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _RoutineScreenState._surfaceLight,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: _RoutineScreenState._border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x44000000,
              ),
              blurRadius: 18,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.move,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate:
                    (
                      details,
                    ) => onDrag(
                      details.delta,
                    ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    13,
                    10,
                    7,
                    8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: block.color.withOpacity(
                            .13,
                          ),
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Icon(
                          block.icon,
                          color: block.color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          block.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _RoutineScreenState._text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: _RoutineScreenState._muted,
                          size: 18,
                        ),
                      ),
                      PopupMenuButton<
                        _BlockAction
                      >(
                        tooltip: 'Opções do bloco',
                        color: const Color(
                          0xFF20232C,
                        ),
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: _RoutineScreenState._muted,
                        ),
                        onSelected:
                            (
                              action,
                            ) {
                              switch (action) {
                                case _BlockAction.duplicate:
                                  onDuplicate();
                                  break;
                                case _BlockAction.delete:
                                  onDelete();
                                  break;
                              }
                            },
                        itemBuilder:
                            (
                              _,
                            ) => const [
                              PopupMenuItem(
                                value: _BlockAction.duplicate,
                                child: _MenuLabel(
                                  icon: Icons.copy_rounded,
                                  text: 'Duplicar',
                                ),
                              ),
                              PopupMenuItem(
                                value: _BlockAction.delete,
                                child: _MenuLabel(
                                  icon: Icons.delete_outline_rounded,
                                  text: 'Excluir',
                                  color: Color(
                                    0xFFFF8DAA,
                                  ),
                                ),
                              ),
                            ],
                      ),
                      const Icon(
                        Icons.drag_indicator_rounded,
                        color: _RoutineScreenState._muted,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(
              height: 1,
              color: _RoutineScreenState._border,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 13,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

enum _BlockAction {
  duplicate,
  delete,
}

class _MenuLabel
    extends
        StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.text,
    this.color = _RoutineScreenState._text,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _EmptyBoard
    extends
        StatelessWidget {
  const _EmptyBoard({
    required this.onAddBlock,
  });

  final VoidCallback onAddBlock;

  @override
  Widget build(
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
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _RoutineScreenState._primary.withOpacity(
                  .12,
                ),
                borderRadius: BorderRadius.circular(
                  17,
                ),
              ),
              child: const Icon(
                Icons.dashboard_customize_outlined,
                color: Color(
                  0xFFA996FF,
                ),
                size: 27,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            const Text(
              'Sua lousa está vazia',
              style: TextStyle(
                color: _RoutineScreenState._text,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 6,
            ),
            const Text(
              'Adicione tarefas, notas, conteúdo, fotos ou um mapa mental.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _RoutineScreenState._muted,
                fontSize: 12,
                height: 1.45,
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            OutlinedButton.icon(
              onPressed: onAddBlock,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(
                  0xFFA996FF,
                ),
                side: const BorderSide(
                  color: Color(
                    0xFF5E4BAA,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
                size: 18,
              ),
              label: const Text(
                'Criar primeiro bloco',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton
    extends
        StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _RoutineScreenState._surface,
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: _RoutineScreenState._border,
            ),
          ),
          child: Icon(
            icon,
            color: _RoutineScreenState._text,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _GridPainter
    extends
        CustomPainter {
  const _GridPainter();

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    const spacing = 24.0;
    final paint = Paint()
      ..color =
          const Color(
            0xFF242731,
          ).withOpacity(
            .42,
          )
      ..strokeWidth = 1;

    for (
      double x = spacing;
      x <
          size.width;
      x += spacing
    ) {
      for (
        double y = spacing;
        y <
            size.height;
        y += spacing
      ) {
        canvas.drawCircle(
          Offset(
            x,
            y,
          ),
          1,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(
    covariant _GridPainter oldDelegate,
  ) => false;
}
