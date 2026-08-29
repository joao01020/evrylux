import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../controllers/mind_map_controller.dart';
import '../data/dtos/board_block_dto.dart';
import '../data/mappers/board_block_mapper.dart';
import '../models/board_block.dart';
import '../widgets/blocks/mind_map/mind_map_canvas.dart';

// ============================================================
// CHANNEL
// ============================================================

const WindowMethodChannel
_mindMapWindowChannel = WindowMethodChannel(
  'routine_mind_map_window',
  mode: ChannelMode.unidirectional,
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
  });

  final String window;
  final String blockId;
  final String title;

  factory MindMapWindowArguments.fromRaw(
    String raw,
  ) {
    final value = raw.trim();

    if (value.isEmpty) {
      return const MindMapWindowArguments(
        window: 'mind_map',
        blockId: '',
        title: 'Lousa',
      );
    }

    try {
      final decoded = jsonDecode(
        value,
      );

      if (decoded
          is! Map) {
        return const MindMapWindowArguments(
          window: 'mind_map',
          blockId: '',
          title: 'Lousa',
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
          'mind_map';

      final blockId =
          map['block_id']?.toString().trim() ??
          '';

      final title =
          map['title']?.toString().trim() ??
          '';

      return MindMapWindowArguments(
        window: window.isEmpty
            ? 'mind_map'
            : window,
        blockId: blockId,
        title: title.isEmpty
            ? 'Lousa'
            : title,
      );
    } catch (
      _
    ) {
      return const MindMapWindowArguments(
        window: 'mind_map',
        blockId: '',
        title: 'Lousa',
      );
    }
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
  final SupabaseClient _supabase = Supabase.instance.client;

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

    _initializeWindow();

    _loadBoard();
  }

  // ==========================================================
  // INITIALIZE WINDOW
  // ==========================================================

  Future<
    void
  >
  _initializeWindow() async {
    try {
      // ======================================================
      // NÃO DEIXAR GTK DESTRUIR A JANELA
      // ======================================================

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
      // ======================================================
      // AVISA JANELA PRINCIPAL
      // ======================================================

      await _mindMapWindowChannel.invokeMethod(
        'mind_map_dock',
        {
          'block_id': widget.arguments.blockId,
        },
      );

      // ======================================================
      // ESCONDE
      // ======================================================
      //
      // NÃO chamamos:
      //
      // windowManager.close()
      // windowManager.destroy()
      //
      // porque destruir essa Flutter Engine é justamente o que
      // está causando FlutterEngineRemoveView / EGL crash.
      //
      // ======================================================

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

      // Mesmo se a comunicação falhar, esconder é mais seguro
      // do que destruir a janela.
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
  // LOAD
  // ==========================================================

  Future<
    void
  >
  _loadBoard() async {
    try {
      if (mounted) {
        setState(
          () {
            _loading = true;

            _error = null;
          },
        );
      }

      final blockId = widget.arguments.blockId.trim();

      if (blockId.isEmpty) {
        throw StateError(
          'block_id não foi informado.',
        );
      }

      // ======================================================
      // BLOCK
      // ======================================================

      final blockResponse = await _supabase
          .from(
            'routine_blocks',
          )
          .select()
          .eq(
            'id',
            blockId,
          )
          .maybeSingle();

      if (blockResponse ==
          null) {
        throw StateError(
          'Bloco não encontrado: $blockId',
        );
      }

      final blockMap =
          Map<
            String,
            dynamic
          >.from(
            blockResponse,
          );

      // ======================================================
      // NODES
      // ======================================================

      final nodesResponse = await _supabase
          .from(
            'mind_map_nodes',
          )
          .select()
          .eq(
            'mind_map_block_id',
            blockId,
          );

      final nodes =
          <
            Map<
              String,
              dynamic
            >
          >[];

      for (final raw in nodesResponse) {
        final map =
            Map<
              String,
              dynamic
            >.from(
              raw,
            );

        final metadata = _jsonMap(
          map['metadata'],
        );

        nodes.add(
          {
            ...map,
            'block_id':
                map['mind_map_block_id'] ??
                blockId,
            'label':
                map['title'] ??
                'Nova ideia',
            'position_x':
                map['x'] ??
                0,
            'position_y':
                map['y'] ??
                0,
            'is_root':
                map['is_root'] ??
                false,
            'parent_id': metadata['parent_id'],
            'source_port':
                metadata['source_port'] ??
                'right',
            'target_port':
                metadata['target_port'] ??
                'left',
          },
        );
      }

      // ======================================================
      // DTO
      // ======================================================

      final dto = BoardBlockDto.fromMap(
        {
          ...blockMap,
          'type':
              blockMap['type'] ??
              blockMap['block_type'] ??
              'mind_map',
          'title':
              blockMap['title'] ??
              widget.arguments.title,
          'content':
              blockMap['content'] ??
              '',
          'content_status':
              blockMap['content_status'] ??
              'idea',
          'items':
              <
                Map<
                  String,
                  dynamic
                >
              >[],
          'mind_map_nodes': nodes,
        },
      );

      final block = BoardBlockMapper.toModel(
        dto,
      );

      final controller = MindMapController();

      controller.ensureRoot(
        block,
      );

      if (!mounted) {
        controller.dispose();

        return;
      }

      _controller?.dispose();

      setState(
        () {
          _block = block;

          _controller = controller;

          _loading = false;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[MIND MAP WINDOW][LOAD] $error',
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
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    windowManager.removeListener(
      this,
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

  // ==========================================================
  // TOP BAR
  // ==========================================================

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

          // ==================================================
          // ENCAIXAR
          // ==================================================
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

  // ==========================================================
  // CONTENT
  // ==========================================================

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

  // ==========================================================
  // JSON MAP
  // ==========================================================

  Map<
    String,
    dynamic
  >
  _jsonMap(
    Object? value,
  ) {
    if (value
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    return <
      String,
      dynamic
    >{};
  }
}
