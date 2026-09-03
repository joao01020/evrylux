import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/mind_map_controller.dart';
import '../data/dtos/board_block_dto.dart';
import '../data/mappers/board_block_mapper.dart';
import '../models/board_block.dart';
import '../widgets/blocks/mind_map/mind_map_canvas.dart';

// ============================================================
// CHANNEL
// ============================================================
//
// A janela principal continua sendo a fonte da verdade.
//
// A janela secundária:
// - recebe um snapshot do BoardBlock;
// - trabalha somente em memória;
// - devolve mudanças pelo channel;
// - NÃO acessa Supabase;
// - NÃO acessa SQLite;
// - NÃO processa SyncQueue.
//
// ============================================================

const WindowMethodChannel
_mindMapWindowChannel = WindowMethodChannel(
  'routine_mind_map_window',
  mode: ChannelMode.bidirectional,
);

// ============================================================
// APP
// ============================================================

class MindMapWindowApp
    extends
        StatelessWidget {
  const MindMapWindowApp({
    super.key,
    required this.arguments,
  });

  final String arguments;

  @override
  Widget build(
    BuildContext context,
  ) {
    final data = MindMapWindowArguments.fromRaw(
      arguments,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: data.title,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(
          0xFF090A0E,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(
            0xFF7BE495,
          ),
          brightness: Brightness.dark,
        ),
      ),
      home: MindMapWindow(
        arguments: data,
      ),
    );
  }
}

// ============================================================
// ARGUMENTS
// ============================================================

class MindMapWindowArguments {
  const MindMapWindowArguments({
    required this.window,
    required this.blockId,
    required this.title,
    required this.block,
  });

  final String window;

  final String blockId;

  final String title;

  final Map<
    String,
    dynamic
  >
  block;

  factory MindMapWindowArguments.fromRaw(
    String raw,
  ) {
    final value = raw.trim();

    if (value.isEmpty) {
      throw const FormatException(
        'Argumentos da janela do mapa mental estão vazios.',
      );
    }

    final decoded = jsonDecode(
      value,
    );

    if (decoded
        is! Map) {
      throw const FormatException(
        'Argumentos inválidos para a janela do mapa mental.',
      );
    }

    final map =
        Map<
          String,
          dynamic
        >.from(
          decoded,
        );

    final window =
        map['window']?.toString().trim() ??
        '';

    final blockId =
        map['block_id']?.toString().trim() ??
        '';

    final title =
        map['title']?.toString().trim() ??
        '';

    final rawBlock = map['block'];

    if (window !=
        'mind_map') {
      throw const FormatException(
        'Tipo de janela inválido.',
      );
    }

    if (blockId.isEmpty) {
      throw const FormatException(
        'block_id não foi informado.',
      );
    }

    if (rawBlock
        is! Map) {
      throw const FormatException(
        'Snapshot do BoardBlock não foi informado.',
      );
    }

    return MindMapWindowArguments(
      window: window,
      blockId: blockId,
      title: title.isEmpty
          ? 'Lousa'
          : title,
      block:
          Map<
            String,
            dynamic
          >.from(
            rawBlock,
          ),
    );
  }
}

// ============================================================
// WINDOW
// ============================================================

class MindMapWindow
    extends
        StatefulWidget {
  const MindMapWindow({
    super.key,
    required this.arguments,
  });

  final MindMapWindowArguments arguments;

  @override
  State<
    MindMapWindow
  >
  createState() {
    return _MindMapWindowState();
  }
}

// ============================================================
// STATE
// ============================================================

class _MindMapWindowState
    extends
        State<
          MindMapWindow
        >
    with
        WindowListener {
  BoardBlock? _block;

  MindMapController? _controller;

  bool _loading = true;

  bool _docking = false;

  String? _error;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    windowManager.addListener(
      this,
    );

    _mindMapWindowChannel.setMethodCallHandler(
      _handleChannelCall,
    );

    _initializeWindow();

    _loadSnapshot(
      widget.arguments.block,
    );
  }

  // ==========================================================
  // INITIALIZE WINDOW
  // ==========================================================

  Future<
    void
  >
  _initializeWindow() async {
    try {
      await windowManager.setPreventClose(
        true,
      );

      await windowManager.setTitle(
        widget.arguments.title,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MIND MAP WINDOW][INIT WINDOW] $error',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ==========================================================
  // NATIVE CLOSE BUTTON
  // ==========================================================

  @override
  void onWindowClose() {
    _dockAndHide();
  }

  // ==========================================================
  // CHANNEL FROM MAIN WINDOW
  // ==========================================================

  Future<
    dynamic
  >
  _handleChannelCall(
    MethodCall call,
  ) async {
    switch (call.method) {
      case 'mind_map_replace':
        final arguments = call.arguments;

        if (arguments
            is! Map) {
          return false;
        }

        final data =
            Map<
              String,
              dynamic
            >.from(
              arguments,
            );

        final blockId =
            data['block_id']?.toString().trim() ??
            '';

        if (blockId !=
            widget.arguments.blockId) {
          return false;
        }

        final rawBlock = data['block'];

        if (rawBlock
            is! Map) {
          return false;
        }

        await _loadSnapshot(
          Map<
            String,
            dynamic
          >.from(
            rawBlock,
          ),
        );

        return true;

      default:
        return null;
    }
  }

  // ==========================================================
  // LOAD SNAPSHOT
  // ==========================================================

  Future<
    void
  >
  _loadSnapshot(
    Map<
      String,
      dynamic
    >
    map,
  ) async {
    try {
      if (mounted) {
        setState(
          () {
            _loading = true;
            _error = null;
          },
        );
      }

      final dto = BoardBlockDto.fromMap(
        map,
      );

      final block = BoardBlockMapper.toModel(
        dto,
      );

      if (block.id !=
          widget.arguments.blockId) {
        throw StateError(
          'Snapshot pertence a outro bloco.',
        );
      }

      final controller = MindMapController(
        onChanged: _publishCurrentBlock,
      );

      // Garante root apenas localmente.
      //
      // Se for necessário criar um root, a alteração também será
      // enviada à janela principal pelo callback do controller.
      _block = block;
      _controller = controller;

      controller.ensureRoot(
        block,
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(
        () {
          _loading = false;
          _error = null;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MIND MAP WINDOW][LOAD SNAPSHOT] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;
          _error = error.toString();
        },
      );
    }
  }

  // ==========================================================
  // SERIALIZE CURRENT BLOCK
  // ==========================================================

  Map<
    String,
    dynamic
  >?
  _currentBlockMap() {
    final block = _block;

    if (block ==
        null) {
      return null;
    }

    return BoardBlockMapper.toDto(
      model: block,
    ).toMap();
  }

  // ==========================================================
  // PUBLISH CHANGE
  // ==========================================================

  void _publishCurrentBlock() {
    final blockMap = _currentBlockMap();

    if (blockMap ==
        null) {
      return;
    }

    _mindMapWindowChannel.invokeMethod(
      'mind_map_changed',
      {
        'block_id': widget.arguments.blockId,
        'block': blockMap,
      },
    );
  }

  // ==========================================================
  // DOCK
  // ==========================================================

  Future<
    void
  >
  _dockAndHide() async {
    if (_docking) {
      return;
    }

    _docking = true;

    try {
      final blockMap = _currentBlockMap();

      await _mindMapWindowChannel.invokeMethod(
        'mind_map_dock',
        {
          'block_id': widget.arguments.blockId,
          if (blockMap !=
              null)
            'block': blockMap,
        },
      );

      // Não destruímos a engine.
      //
      // Em Linux isso evita o crash que já ocorreu com
      // FlutterEngineRemoveView / EGL.
      await windowManager.hide();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MIND MAP WINDOW][DOCK] $error',
      );

      debugPrint(
        '$stackTrace',
      );

      try {
        await windowManager.hide();
      } catch (
        _
      ) {}
    } finally {
      _docking = false;
    }
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    windowManager.removeListener(
      this,
    );

    _mindMapWindowChannel.setMethodCallHandler(
      null,
    );

    _controller?.dispose();

    super.dispose();
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF090A0E,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: const BoxDecoration(
        color: Color(
          0xFF0D0F15,
        ),
        border: Border(
          bottom: BorderSide(
            color: Color(
              0xFF292D38,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_tree_rounded,
            color: Color(
              0xFF7BE495,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              _block?.title ??
                  widget.arguments.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(
                  0xFFF5F7FA,
                ),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Encaixar lousa',
            onPressed: _dockAndHide,
            icon: const Icon(
              Icons.call_merge_rounded,
              color: Color(
                0xFF7BE495,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error !=
        null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(
                0xFFFF8DAA,
              ),
            ),
          ),
        ),
      );
    }

    final block = _block;
    final controller = _controller;

    if (block ==
            null ||
        controller ==
            null) {
      return const Center(
        child: Text(
          'Lousa indisponível.',
        ),
      );
    }

    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            return Padding(
              padding: const EdgeInsets.all(
                14,
              ),
              child: MindMapCanvas(
                block: block,
                controller: controller,
                height: constraints.maxHeight,
              ),
            );
          },
    );
  }
}
