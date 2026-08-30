import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/dependencies/app_dependencies.dart';
import '../../reminders/widgets/reminder_dialog.dart';

import '../controllers/board_controller.dart';
import '../controllers/comments/board_comment_controller.dart';
import '../controllers/mind_map_controller.dart';
import '../controllers/routine_controller.dart';
import '../controllers/routine_state.dart';
import '../data/datasources/comments/board_comment_remote_data_source.dart';
import '../data/datasources/routine_memory_datasource.dart';
import '../data/datasources/routine_remote_data_source.dart';
import '../data/repositories/comments/board_comment_repository.dart';
import '../data/repositories/routine_repository_impl.dart';
import '../models/block_type.dart';
import '../models/board_block.dart';
import '../models/check_item.dart';
import '../models/comments/board_comment.dart';
import '../models/routine_day.dart';
import '../widgets/blocks/content_block.dart';
import '../widgets/blocks/mind_map/mind_map_block.dart';
import '../widgets/blocks/note_block.dart';
import '../widgets/blocks/photo_block.dart';
import '../widgets/blocks/task_block.dart';
import '../widgets/calendar/routine_calendar_panel.dart';
import '../widgets/comments/board_comment_card.dart';
import '../widgets/comments/board_comment_editor.dart';
import '../widgets/comments/board_comment_pin.dart';
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
  // ============================================================
  // TEMA CLARO — BRANCO + VERDE
  // ============================================================
  //
  // Fundo claro, superfícies brancas, contraste alto para textos
  // e verde como cor principal. Os tons foram escolhidos para
  // manter boa leitura em botões, cards, menus, erros e lousa.
  //
  // ============================================================

  static const Color _background = Color(
    0xFFF7FAF7,
  );
  static const Color _surface = Color(
    0xFFFFFFFF,
  );
  static const Color _surfaceLight = Color(
    0xFFF1F7F2,
  );

  // ============================================================
  // CARDS DA LOUSA
  // ============================================================
  //
  // Cinza exclusivo dos cards arrastáveis.
  //
  // Mantemos _surfaceLight para os demais componentes da tela,
  // evitando alterar botões, diálogos e outras superfícies.
  //
  // ============================================================

  static const Color _cardBackground = Color(
    0xFFE5E7EB,
  );

  static const Color _cardBorder = Color(
    0xFFC7CBD1,
  );

  static const Color _border = Color(
    0xFFD7E3D9,
  );
  static const Color _primary = Color(
    0xFF198754,
  );
  static const Color _text = Color(
    0xFF172019,
  );
  static const Color _muted = Color(
    0xFF68746B,
  );

  late final RoutineController _routineController;
  late final BoardController _boardController;
  late final MindMapController _mindMapController;
  late final BoardCommentController _commentController;
  late final bool _ownsRoutineController;

  // ============================================================
  // COMENTÁRIOS DA LOUSA
  // ============================================================

  Offset? _pendingCommentPosition;

  BoardComment? _openedComment;

  // ============================================================
  // CARREGAMENTO DOS COMENTÁRIOS
  // ============================================================
  //
  // Mantemos o dia carregado separado do estado visual da rotina.
  //
  // Isso garante que os comentários sejam recarregados sempre que
  // o selectedDay mudar, inclusive ao:
  //
  // - entrar novamente na tela;
  // - trocar o dia;
  // - navegar entre semanas;
  // - restaurar um dia vindo do Supabase.
  //
  // ============================================================

  String? _loadedCommentDayId;

  String? _loadingCommentDayId;

  bool _routineControllerReady = false;
  bool _initializingRoutine = true;
  String? _initializationError;

  // ============================================================
  // LOUSA EXPANDIDA
  // ============================================================

  /// Expande a mesma lousa dentro da tela atual.
  /// Nenhuma janela externa é criada.
  bool _boardExpanded = false;

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

    final commentRemoteDataSource = BoardCommentRemoteDataSource(
      client: Supabase.instance.client,
    );

    final commentRepository = BoardCommentRepository(
      remoteDataSource: commentRemoteDataSource,
    );

    _commentController = BoardCommentController(
      repository: commentRepository,
    );

    _commentController.addListener(
      _onCommentsChanged,
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

      await _loadCommentsForSelectedDay(
        force: true,
      );

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

    _commentController.removeListener(
      _onCommentsChanged,
    );

    _commentController.dispose();

    super.dispose();
  }

  void _onRoutineChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );

    // O RoutineController também muda selectedDay ao navegar
    // entre semanas ou ao restaurar estado.
    //
    // Não usamos await aqui porque listener precisa ser síncrono.
    // O helper possui proteção contra chamadas duplicadas.
    _loadCommentsForSelectedDay();
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

  // ============================================================
  // COMENTÁRIOS
  // ============================================================

  void _onCommentsChanged() {
    if (!mounted) {
      return;
    }

    final error = _commentController.errorMessage;

    if (error !=
            null &&
        error.trim().isNotEmpty) {
      debugPrint(
        '[COMMENT][CONTROLLER] $error',
      );
    }

    setState(
      () {},
    );
  }

  String _commentDayId(
    RoutineDay day,
  ) {
    final date = day.normalizedDate;

    final year = date.year.toString().padLeft(
      4,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    final dayNumber = date.day.toString().padLeft(
      2,
      '0',
    );

    return '$year-$month-$dayNumber';
  }

  // ============================================================
  // CARREGAR COMENTÁRIOS DO DIA SELECIONADO
  // ============================================================

  Future<
    void
  >
  _loadCommentsForSelectedDay({
    bool force = false,
  }) async {
    if (!_routineControllerReady) {
      return;
    }

    final selectedDay = _routineController.selectedDay;

    final dayId = _commentDayId(
      selectedDay,
    );

    if (dayId.isEmpty) {
      return;
    }

    // Já existe uma chamada para esse mesmo dia em andamento.
    if (_loadingCommentDayId ==
        dayId) {
      return;
    }

    // O dia já foi carregado e não houve pedido explícito
    // para atualizar novamente.
    if (!force &&
        _loadedCommentDayId ==
            dayId) {
      return;
    }

    _loadingCommentDayId = dayId;

    debugPrint(
      '',
    );

    debugPrint(
      '============================================================',
    );

    debugPrint(
      '[COMMENT][LOAD] Buscando comentários',
    );

    debugPrint(
      '[COMMENT][LOAD] dayId: $dayId',
    );

    try {
      await _commentController.loadByDay(
        dayId,
      );

      if (!mounted) {
        return;
      }

      // Só confirmamos como carregado se o usuário ainda estiver
      // no mesmo dia quando a requisição terminar.
      final currentDayId = _commentDayId(
        _routineController.selectedDay,
      );

      if (currentDayId ==
          dayId) {
        _loadedCommentDayId = dayId;
      }

      debugPrint(
        '[COMMENT][LOAD] '
        '${_commentController.countForDay(dayId)} comentário(s) carregado(s).',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[COMMENT][LOAD] ERRO: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      // Permite tentar novamente na próxima mudança/rebuild.
      if (_loadedCommentDayId ==
          dayId) {
        _loadedCommentDayId = null;
      }
    } finally {
      if (_loadingCommentDayId ==
          dayId) {
        _loadingCommentDayId = null;
      }

      debugPrint(
        '============================================================',
      );

      debugPrint(
        '',
      );
    }
  }

  // ============================================================
  // RECARREGAR COMENTÁRIOS
  // ============================================================

  Future<
    void
  >
  _reloadCommentsForSelectedDay() {
    return _loadCommentsForSelectedDay(
      force: true,
    );
  }

  void _enableCommentMode() {
    _openedComment = null;
    _pendingCommentPosition = null;

    _commentController.enableCommentMode();
  }

  void _startCommentAt(
    RoutineDay day,
    TapDownDetails details, {
    required double boardWidth,
    required double boardHeight,
  }) {
    if (!_commentController.commentMode) {
      return;
    }

    const editorWidth = 340.0;
    const editorEstimatedHeight = 130.0;
    const margin = 12.0;

    final raw = details.localPosition;

    final maxX = math.max(
      margin,
      boardWidth -
          editorWidth -
          margin,
    );

    final maxY = math.max(
      margin,
      boardHeight -
          editorEstimatedHeight -
          margin,
    );

    final position = Offset(
      raw.dx
          .clamp(
            margin,
            maxX,
          )
          .toDouble(),
      raw.dy
          .clamp(
            margin,
            maxY,
          )
          .toDouble(),
    );

    setState(
      () {
        _openedComment = null;
        _pendingCommentPosition = position;
      },
    );
  }

  void _cancelPendingComment() {
    setState(
      () {
        _pendingCommentPosition = null;
      },
    );
  }

  Future<
    void
  >
  _submitPendingComment(
    RoutineDay day,
    String message,
  ) async {
    final position = _pendingCommentPosition;

    if (position ==
        null) {
      return;
    }

    final created = await _commentController.create(
      dayId: _commentDayId(
        day,
      ),
      message: message,
      position: position,
    );

    if (!mounted ||
        created ==
            null) {
      return;
    }

    _loadedCommentDayId = created.dayId;

    debugPrint(
      '[COMMENT][CREATE] Salvo com sucesso: ${created.id}',
    );

    debugPrint(
      '[COMMENT][CREATE] dayId: ${created.dayId}',
    );

    setState(
      () {
        _pendingCommentPosition = null;
        _openedComment = null;
      },
    );
  }

  void _openComment(
    BoardComment comment,
  ) {
    setState(
      () {
        _pendingCommentPosition = null;

        _openedComment =
            _openedComment?.id ==
                comment.id
            ? null
            : comment;
      },
    );
  }

  void _closeComment() {
    setState(
      () {
        _openedComment = null;
      },
    );
  }

  Future<
    void
  >
  _toggleResolvedComment(
    BoardComment comment,
  ) async {
    await _commentController.toggleResolved(
      comment,
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        _openedComment = null;
      },
    );
  }

  Future<
    void
  >
  _deleteComment(
    BoardComment comment,
  ) async {
    await _commentController.remove(
      comment,
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        if (_openedComment?.id ==
            comment.id) {
          _openedComment = null;
        }
      },
    );
  }

  // ============================================================
  // ARRASTAR COMENTÁRIO
  // ============================================================
  //
  // onPanUpdate altera apenas a posição local.
  // onPanEnd salva uma única vez no Supabase.
  //
  // ============================================================

  void _moveCommentLocal(
    BoardComment comment,
    Offset delta, {
    required double boardWidth,
    required double boardHeight,
  }) {
    const pinWidth = 38.0;
    const pinHeight = 38.0;

    final current = comment.position;

    final nextX =
        (current.dx +
                delta.dx)
            .clamp(
              0.0,
              math.max(
                0.0,
                boardWidth -
                    pinWidth,
              ),
            )
            .toDouble();

    final nextY =
        (current.dy +
                delta.dy)
            .clamp(
              0.0,
              math.max(
                0.0,
                boardHeight -
                    pinHeight,
              ),
            )
            .toDouble();

    _commentController.moveLocal(
      comment,
      Offset(
        nextX,
        nextY,
      ),
    );

    if (_openedComment?.id ==
        comment.id) {
      _openedComment = comment;
    }
  }

  Future<
    void
  >
  _persistCommentPosition(
    BoardComment comment,
  ) async {
    await _commentController.persistPosition(
      comment,
    );
  }

  // ============================================================
  // TROCAR DIA
  // ============================================================

  Future<
    void
  >
  _selectRoutineDay(
    DateTime date,
  ) async {
    _pendingCommentPosition = null;
    _openedComment = null;

    _commentController.disableCommentMode();

    _routineController.selectDay(
      date,
    );

    // Força a atualização do Supabase ao trocar manualmente o dia.
    await _reloadCommentsForSelectedDay();
  }

  List<
    BoardComment
  >
  _commentsForDay(
    RoutineDay day,
  ) {
    return _commentController.commentsForDay(
      _commentDayId(
        day,
      ),
    );
  }

  List<
    Widget
  >
  _buildCommentLayer({
    required RoutineDay day,
    required double boardWidth,
    required double boardHeight,
  }) {
    final comments = _commentsForDay(
      day,
    );

    final widgets =
        <
          Widget
        >[];

    // Detector fica acima dos blocos SOMENTE quando o modo
    // comentário está ativo. Assim um clique escolhe a posição.
    if (_commentController.commentMode) {
      widgets.add(
        Positioned.fill(
          child: MouseRegion(
            cursor: SystemMouseCursors.precise,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown:
                  (
                    details,
                  ) {
                    _startCommentAt(
                      day,
                      details,
                      boardWidth: boardWidth,
                      boardHeight: boardHeight,
                    );
                  },
            ),
          ),
        ),
      );
    }

    // Pins salvos em memória.
    for (final comment in comments) {
      final pinX = comment.position.dx
          .clamp(
            0.0,
            math.max(
              0.0,
              boardWidth -
                  38,
            ),
          )
          .toDouble();

      final pinY = comment.position.dy
          .clamp(
            0.0,
            math.max(
              0.0,
              boardHeight -
                  38,
            ),
          )
          .toDouble();

      widgets.add(
        Positioned(
          left: pinX,
          top: pinY,
          child: BoardCommentPin(
            key: ValueKey(
              'comment-pin-${comment.id}',
            ),
            comment: comment,
            onTap: () {
              _openComment(
                comment,
              );
            },
            onDragUpdate:
                (
                  delta,
                ) {
                  _moveCommentLocal(
                    comment,
                    delta,
                    boardWidth: boardWidth,
                    boardHeight: boardHeight,
                  );
                },
            onDragEnd: () {
              _persistCommentPosition(
                comment,
              );
            },
          ),
        ),
      );
    }

    // Editor do novo comentário.
    final pending = _pendingCommentPosition;

    if (pending !=
            null &&
        _commentController.commentMode) {
      widgets.add(
        Positioned(
          left: pending.dx,
          top: pending.dy,
          child: BoardCommentEditor(
            key: ValueKey(
              'comment-editor-${_commentDayId(day)}',
            ),
            onSubmit:
                (
                  message,
                ) {
                  _submitPendingComment(
                    day,
                    message,
                  );
                },
            onCancel: _cancelPendingComment,
          ),
        ),
      );
    }

    // Card completo ao clicar no pin.
    final opened = _openedComment;

    if (opened !=
            null &&
        opened.dayId ==
            _commentDayId(
              day,
            )) {
      const cardWidth = 340.0;
      const cardEstimatedHeight = 220.0;
      const margin = 12.0;

      var cardX =
          opened.position.dx +
          46;

      if (cardX +
              cardWidth +
              margin >
          boardWidth) {
        cardX =
            opened.position.dx -
            cardWidth -
            12;
      }

      cardX = cardX
          .clamp(
            margin,
            math.max(
              margin,
              boardWidth -
                  cardWidth -
                  margin,
            ),
          )
          .toDouble();

      final cardY = opened.position.dy
          .clamp(
            margin,
            math.max(
              margin,
              boardHeight -
                  cardEstimatedHeight -
                  margin,
            ),
          )
          .toDouble();

      widgets.add(
        Positioned(
          left: cardX,
          top: cardY,
          child: BoardCommentCard(
            key: ValueKey(
              'comment-card-${opened.id}',
            ),
            comment: opened,
            onClose: _closeComment,
            onResolve: () {
              _toggleResolvedComment(
                opened,
              );
            },
            onDelete: () {
              _deleteComment(
                opened,
              );
            },
          ),
        ),
      );
    }

    return widgets;
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
        child: _boardExpanded
            ? _buildExpandedBoard()
            : Column(
                children: [
                  _buildHeader(
                    state,
                  ),
                  RoutineCalendarPanel(
                    state: state,
                    onPreviousWeek: () {
                      _loadedCommentDayId = null;

                      _routineController.previousWeek();
                    },
                    onNextWeek: () {
                      _loadedCommentDayId = null;

                      _routineController.nextWeek();
                    },
                    onSelectDay:
                        (
                          date,
                        ) {
                          _selectRoutineDay(
                            date,
                          );
                        },
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
          0xFFFFF1F3,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: const Color(
            0xFFF0B7C0,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(
              0xFFC43A52,
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
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Positioned.fill(
                            child: CustomPaint(
                              painter: _GridPainter(),
                            ),
                          ),

                          if (day.blocks.isEmpty)
                            Positioned.fill(
                              child: _EmptyBoard(
                                onAddBlock: _addBlock,
                              ),
                            ),

                          for (final block in day.blocks)
                            _positionedBlock(
                              day: day,
                              block: block,
                              boardWidth: boardWidth,
                              boardHeight: boardHeight,
                            ),

                          ..._buildCommentLayer(
                            day: day,
                            boardWidth: boardWidth,
                            boardHeight: boardHeight,
                          ),

                          // Botão exatamente no canto superior direito da lousa.
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Tooltip(
                              message: 'Expandir lousa',
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _expandBoard,
                                  borderRadius: BorderRadius.circular(
                                    12,
                                  ),
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFF1F7F2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        12,
                                      ),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFC7DFC9,
                                        ),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(
                                            0x14000000,
                                          ),
                                          blurRadius: 8,
                                          offset: Offset(
                                            0,
                                            3,
                                          ),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.open_in_full_rounded,
                                      color: _primary,
                                      size: 19,
                                    ),
                                  ),
                                ),
                              ),
                            ),
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

  // ============================================================
  // EXPANDIR / RECOLHER LOUSA
  // ============================================================

  void _expandBoard() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _boardExpanded = true;
      },
    );
  }

  void _collapseBoard() {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _boardExpanded = false;
      },
    );
  }

  // ============================================================
  // LOUSA EXPANDIDA NA MESMA TELA
  // ============================================================

  Widget _buildExpandedBoard() {
    final day = _routineController.selectedDay;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(
              bottom: BorderSide(
                color: _border,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFE8F5EC,
                  ),
                  borderRadius: BorderRadius.circular(
                    11,
                  ),
                ),
                child: const Icon(
                  Icons.dashboard_customize_outlined,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LOUSA',
                      style: TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      _expandedBoardDate(
                        day.date,
                      ),
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _routineController.state.saving
                    ? null
                    : _routineController.saveSelectedDay,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _text,
                  side: const BorderSide(
                    color: _border,
                  ),
                ),
                icon: _routineController.state.saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _primary,
                        ),
                      )
                    : const Icon(
                        Icons.cloud_done_outlined,
                        size: 18,
                      ),
                label: Text(
                  _routineController.state.saving
                      ? 'Salvando'
                      : 'Salvar',
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              FilledButton.icon(
                onPressed: _addBlock,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Bloco',
                ),
              ),
              const SizedBox(
                width: 8,
              ),
              IconButton(
                tooltip: 'Recolher lousa',
                onPressed: _collapseBoard,
                style: IconButton.styleFrom(
                  foregroundColor: _primary,
                  backgroundColor: const Color(
                    0xFFE8F5EC,
                  ),
                  side: const BorderSide(
                    color: Color(
                      0xFFC7DFC9,
                    ),
                  ),
                ),
                icon: const Icon(
                  Icons.close_fullscreen_rounded,
                  size: 19,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: LayoutBuilder(
            builder:
                (
                  context,
                  viewport,
                ) {
                  const horizontalPadding = 12.0;
                  const verticalPadding = 12.0;

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
                        620.0,
                        viewport.maxHeight -
                            (verticalPadding *
                                2),
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
                    bottomPadding: 140,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    child: Container(
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(
                              child: CustomPaint(
                                painter: _GridPainter(),
                              ),
                            ),
                            if (day.blocks.isEmpty)
                              Positioned.fill(
                                child: _EmptyBoard(
                                  onAddBlock: _addBlock,
                                ),
                              ),
                            for (final block in day.blocks)
                              _positionedBlock(
                                day: day,
                                block: block,
                                boardWidth: boardWidth,
                                boardHeight: boardHeight,
                              ),

                            ..._buildCommentLayer(
                              day: day,
                              boardWidth: boardWidth,
                              boardHeight: boardHeight,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
          ),
        ),
      ],
    );
  }

  String _expandedBoardDate(
    DateTime date,
  ) {
    String
    two(
      int value,
    ) => value.toString().padLeft(
      2,
      '0',
    );

    return '${two(date.day)}/${two(date.month)}/${date.year}';
  }

  // ============================================================
  // REDIMENSIONAR MAPA MENTAL
  // ============================================================
  //
  // Somente o bloco de mapa mental usa tamanho personalizado.
  //
  // O redimensionamento pode acontecer pelos 4 lados e pelos
  // 4 cantos, de forma parecida com ferramentas como o Miro.
  //
  // ============================================================

  void _resizeMindMapBlock(
    BoardBlock block,
    _ResizeHandle handle,
    Offset delta, {
    required double boardWidth,
    required double boardHeight,
  }) {
    if (block.type !=
        BlockType.mindMap) {
      return;
    }

    const minWidth = 420.0;
    const minHeight = 320.0;
    const margin = 8.0;

    var position =
        block.position ??
        Offset.zero;

    var width =
        block.width ??
        math
            .min(
              620.0,
              math.max(
                minWidth,
                boardWidth -
                    position.dx -
                    margin,
              ),
            )
            .toDouble();

    var height =
        block.height ??
        430.0;

    final originalRight =
        position.dx +
        width;

    final originalBottom =
        position.dy +
        height;

    final resizeLeft =
        handle ==
            _ResizeHandle.left ||
        handle ==
            _ResizeHandle.topLeft ||
        handle ==
            _ResizeHandle.bottomLeft;

    final resizeRight =
        handle ==
            _ResizeHandle.right ||
        handle ==
            _ResizeHandle.topRight ||
        handle ==
            _ResizeHandle.bottomRight;

    final resizeTop =
        handle ==
            _ResizeHandle.top ||
        handle ==
            _ResizeHandle.topLeft ||
        handle ==
            _ResizeHandle.topRight;

    final resizeBottom =
        handle ==
            _ResizeHandle.bottom ||
        handle ==
            _ResizeHandle.bottomLeft ||
        handle ==
            _ResizeHandle.bottomRight;

    // ==========================================================
    // ESQUERDA
    // ==========================================================

    if (resizeLeft) {
      final maxLeft =
          originalRight -
          minWidth;

      final nextLeft =
          (position.dx +
                  delta.dx)
              .clamp(
                margin,
                math.max(
                  margin,
                  maxLeft,
                ),
              )
              .toDouble();

      width =
          originalRight -
          nextLeft;

      position = Offset(
        nextLeft,
        position.dy,
      );
    }

    // ==========================================================
    // DIREITA
    // ==========================================================

    if (resizeRight) {
      final maxWidth = math
          .max(
            minWidth,
            boardWidth -
                position.dx -
                margin,
          )
          .toDouble();

      width =
          (width +
                  delta.dx)
              .clamp(
                minWidth,
                maxWidth,
              )
              .toDouble();
    }

    // ==========================================================
    // TOPO
    // ==========================================================

    if (resizeTop) {
      final maxTop =
          originalBottom -
          minHeight;

      final nextTop =
          (position.dy +
                  delta.dy)
              .clamp(
                margin,
                math.max(
                  margin,
                  maxTop,
                ),
              )
              .toDouble();

      height =
          originalBottom -
          nextTop;

      position = Offset(
        position.dx,
        nextTop,
      );
    }

    // ==========================================================
    // BASE
    // ==========================================================

    if (resizeBottom) {
      final maxHeight = math
          .max(
            minHeight,
            boardHeight -
                position.dy -
                margin,
          )
          .toDouble();

      height =
          (height +
                  delta.dy)
              .clamp(
                minHeight,
                maxHeight,
              )
              .toDouble();
    }

    block.position = position;

    block.width = width;

    block.height = height;

    // ==========================================================
    // APENAS ATUALIZA A INTERFACE DURANTE O RESIZE
    // ==========================================================
    //
    // Não chamamos _notifyRoutineMutation() aqui.
    //
    // Esse método é executado várias vezes por segundo enquanto
    // o mouse é arrastado. Salvar/recarregar o Supabase aqui fazia
    // o bloco receber novamente o tamanho anterior no meio do
    // redimensionamento.
    //
    // O salvamento acontece uma única vez em _finishMindMapResize().
    //
    // ==========================================================

    _refreshBoard();
  }

  // ============================================================
  // FINALIZAR REDIMENSIONAMENTO DO MAPA MENTAL
  // ============================================================

  void _finishMindMapResize() {
    if (!_routineControllerReady) {
      return;
    }

    // Persiste uma única vez depois que o usuário solta o mouse.
    _notifyRoutineMutation();
  }

  Widget _positionedBlock({
    required RoutineDay day,
    required BoardBlock block,
    required double boardWidth,
    required double boardHeight,
  }) {
    final position =
        block.position ??
        Offset.zero;

    final isMindMap =
        block.type ==
        BlockType.mindMap;

    final defaultWidth = _boardController.blockWidth(
      block: block,
      boardWidth: boardWidth,
    );

    final maxMindMapWidth = math
        .max(
          420.0,
          boardWidth -
              position.dx -
              8,
        )
        .toDouble();

    final width = isMindMap
        ? (block.width ??
                  math.min(
                    620.0,
                    maxMindMapWidth,
                  ))
              .clamp(
                math.min(
                  420.0,
                  maxMindMapWidth,
                ),
                maxMindMapWidth,
              )
              .toDouble()
        : defaultWidth;

    final maxMindMapHeight = math
        .max(
          320.0,
          boardHeight -
              position.dy -
              8,
        )
        .toDouble();

    final double? height = isMindMap
        ? (block.height ??
                  430.0)
              .clamp(
                math.min(
                  320.0,
                  maxMindMapHeight,
                ),
                maxMindMapHeight,
              )
              .toDouble()
        : null;

    // Mantém o model sincronizado com o tamanho efetivamente
    // utilizado na tela.
    if (isMindMap) {
      block.width = width;

      block.height = height;
    }

    return Positioned(
      key: ValueKey(
        block.id,
      ),
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
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
        onResize: isMindMap
            ? (
                handle,
                delta,
              ) {
                _resizeMindMapBlock(
                  block,
                  handle,
                  delta,
                  boardWidth: boardWidth,
                  boardHeight: boardHeight,
                );
              }
            : null,
        onResizeEnd: isMindMap
            ? _finishMindMapResize
            : null,
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
        onReminder: () => _createReminderForBlock(
          block,
        ),
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
      onComment: () {
        _enableCommentMode();
      },
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
        width: 620,
        height: 430,
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

  // ============================================================
  // CRIAR LEMBRETE PARA BLOCO
  // ============================================================
  //
  // Qualquer bloco da lousa pode gerar um lembrete.
  //
  // O conteúdo do bloco é enviado para o ReminderDialog e
  // o vínculo com a lousa é salvo em:
  //
  // source_type = routine_block
  // source_id   = ID do bloco
  //
  // ============================================================

  Future<
    void
  >
  _createReminderForBlock(
    BoardBlock block,
  ) async {
    final initialTitle = block.title.trim().isEmpty
        ? 'Lembrete da lousa'
        : block.title.trim();

    final initialMessage = _reminderMessageForBlock(
      block,
    );

    final created = await ReminderDialog.show(
      context,
      controller: reminderController,
      initialTitle: initialTitle,
      initialMessage: initialMessage,
      sourceType: 'routine_block',
      sourceId: block.id,
    );

    if (!mounted ||
        created !=
            true) {
      return;
    }

    ScaffoldMessenger.of(
        context,
      )
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(
            0xFF3B6939,
          ),
          content: Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(
                width: 9,
              ),
              Expanded(
                child: Text(
                  'Lembrete criado com sucesso.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ============================================================
  // TEXTO DO LEMBRETE
  // ============================================================

  String _reminderMessageForBlock(
    BoardBlock block,
  ) {
    switch (block.type) {
      case BlockType.tasks:
        final items = block.items;

        if (items.isEmpty) {
          return block.title.trim().isEmpty
              ? 'Tarefa da sua rotina.'
              : block.title.trim();
        }

        return items
            .map(
              (
                item,
              ) {
                final marker = item.done
                    ? '✓'
                    : '•';

                return '$marker ${item.text}';
              },
            )
            .join(
              '\n',
            );

      case BlockType.note:
      case BlockType.content:
      case BlockType.photo:
        final content = block.content.trim();

        if (content.isNotEmpty) {
          return content;
        }

        return block.title.trim().isEmpty
            ? 'Lembrete da sua rotina.'
            : block.title.trim();

      case BlockType.mindMap:
        return block.title.trim().isEmpty
            ? 'Revisar mapa mental.'
            : block.title.trim();
    }
  }

  // ============================================================
  // EXCLUIR BLOCO
  // ============================================================

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
                            0xFFC43A52,
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
              0xFF198754,
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
                    0xFFF0B7C0,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(
                      0xFFC43A52,
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

enum _ResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

class _BoardCard
    extends
        StatelessWidget {
  const _BoardCard({
    required this.block,
    required this.onDrag,
    required this.onEdit,
    required this.onDuplicate,
    required this.onReminder,
    required this.onDelete,
    required this.child,
    this.onResize,
    this.onResizeEnd,
  });

  final BoardBlock block;

  final ValueChanged<
    Offset
  >
  onDrag;

  final void Function(
    _ResizeHandle handle,
    Offset delta,
  )?
  onResize;

  final VoidCallback? onResizeEnd;

  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onReminder;
  final VoidCallback onDelete;
  final Widget child;

  bool get _resizable =>
      onResize !=
      null;

  @override
  Widget build(
    BuildContext context,
  ) {
    final card = Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: _RoutineScreenState._cardBackground,
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: _RoutineScreenState._cardBorder,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(
                0x14000000,
              ),
              blurRadius: 18,
              offset: Offset(
                0,
                8,
              ),
            ),
          ],
        ),
        child: _resizable
            ? Column(
                children: [
                  _buildHeader(),

                  const Divider(
                    height: 1,
                    color: _RoutineScreenState._cardBorder,
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      child: child,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),

                  const Divider(
                    height: 1,
                    color: _RoutineScreenState._cardBorder,
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

    if (!_resizable) {
      return card;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: card,
        ),

        // ======================================================
        // CANTOS
        // ======================================================
        _resizeHandle(
          handle: _ResizeHandle.topLeft,
          alignment: Alignment.topLeft,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
        ),

        _resizeHandle(
          handle: _ResizeHandle.topRight,
          alignment: Alignment.topRight,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
        ),

        _resizeHandle(
          handle: _ResizeHandle.bottomRight,
          alignment: Alignment.bottomRight,
          cursor: SystemMouseCursors.resizeUpLeftDownRight,
        ),

        _resizeHandle(
          handle: _ResizeHandle.bottomLeft,
          alignment: Alignment.bottomLeft,
          cursor: SystemMouseCursors.resizeUpRightDownLeft,
        ),

        // ======================================================
        // LADOS
        // ======================================================
        _resizeHandle(
          handle: _ResizeHandle.top,
          alignment: Alignment.topCenter,
          cursor: SystemMouseCursors.resizeUpDown,
          horizontal: true,
        ),

        _resizeHandle(
          handle: _ResizeHandle.bottom,
          alignment: Alignment.bottomCenter,
          cursor: SystemMouseCursors.resizeUpDown,
          horizontal: true,
        ),

        _resizeHandle(
          handle: _ResizeHandle.left,
          alignment: Alignment.centerLeft,
          cursor: SystemMouseCursors.resizeLeftRight,
          vertical: true,
        ),

        _resizeHandle(
          handle: _ResizeHandle.right,
          alignment: Alignment.centerRight,
          cursor: SystemMouseCursors.resizeLeftRight,
          vertical: true,
        ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return MouseRegion(
      cursor: SystemMouseCursors.move,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate:
            (
              details,
            ) {
              onDrag(
                details.delta,
              );
            },
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
                  color: block.color.withValues(
                    alpha: .13,
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

              Tooltip(
                message: 'Criar lembrete para este bloco',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onReminder,
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFBCF0B4,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFFC7DFC9,
                          ),
                        ),
                      ),
                      child: const Text(
                        '🔔 Criar lembrete',
                        style: TextStyle(
                          color: Color(
                            0xFF3B6939,
                          ),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 4,
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
                  0xFFFFFFFF,
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
                            0xFFC43A52,
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
    );
  }

  // ============================================================
  // HANDLE DE REDIMENSIONAMENTO
  // ============================================================

  Widget _resizeHandle({
    required _ResizeHandle handle,
    required Alignment alignment,
    required MouseCursor cursor,
    bool horizontal = false,
    bool vertical = false,
  }) {
    final callback = onResize;

    if (callback ==
        null) {
      return const SizedBox.shrink();
    }

    final width = vertical
        ? 12.0
        : horizontal
        ? 56.0
        : 18.0;

    final height = horizontal
        ? 12.0
        : vertical
        ? 56.0
        : 18.0;

    return Positioned.fill(
      child: Align(
        alignment: alignment,
        child: MouseRegion(
          cursor: cursor,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate:
                (
                  details,
                ) {
                  callback(
                    handle,
                    details.delta,
                  );
                },
            onPanEnd:
                (
                  _,
                ) {
                  onResizeEnd?.call();
                },
            onPanCancel: () {
              onResizeEnd?.call();
            },
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color:
                    handle ==
                        _ResizeHandle.bottomRight
                    ? const Color(
                        0xFFF5F7F5,
                      )
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  6,
                ),
                border:
                    handle ==
                        _ResizeHandle.bottomRight
                    ? Border.all(
                        color: const Color(
                          0xFF9AA59C,
                        ),
                      )
                    : null,
              ),
              child:
                  handle ==
                      _ResizeHandle.bottomRight
                  ? const Icon(
                      Icons.open_in_full_rounded,
                      size: 11,
                      color: _RoutineScreenState._muted,
                    )
                  : null,
            ),
          ),
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
                color: _RoutineScreenState._primary.withValues(
                  alpha: .12,
                ),
                borderRadius: BorderRadius.circular(
                  17,
                ),
              ),
              child: const Icon(
                Icons.dashboard_customize_outlined,
                color: Color(
                  0xFF198754,
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
                  0xFF198754,
                ),
                side: const BorderSide(
                  color: Color(
                    0xFF86B996,
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
            0xFFD7E3D9,
          ).withValues(
            alpha: .42,
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
