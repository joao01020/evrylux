import 'package:flutter/material.dart';

import '../../../controllers/mind_map_controller.dart';
import '../../../models/board_block.dart';
import '../../../models/mind_map_node.dart';
import '../../../models/node_port.dart';
import 'mind_map_port_widget.dart';

class MindMapNodeWidget
    extends
        StatefulWidget {
  const MindMapNodeWidget({
    super.key,
    required this.block,
    required this.node,
    required this.controller,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.hovered,
    required this.onHoverChanged,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final BoardBlock block;

  final MindMapNode node;

  final MindMapController controller;

  final double canvasWidth;

  final double canvasHeight;

  final bool hovered;

  final ValueChanged<
    bool
  >
  onHoverChanged;

  @override
  State<
    MindMapNodeWidget
  >
  createState() {
    return _MindMapNodeWidgetState();
  }
}

class _MindMapNodeWidgetState
    extends
        State<
          MindMapNodeWidget
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF347A3D,
  );

  static const Color _greenLight = Color(
    0xFFEAF6EC,
  );

  static const Color _greenBorder = Color(
    0xFFA9DEA5,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // TEXTO
  // ============================================================

  static const double _fontSize = 13;

  static const double _lineHeight = 1.25;

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _textController;

  late final FocusNode _focusNode;

  bool _finishingEdit = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(
      text: widget.node.label,
    );

    _focusNode = FocusNode();

    _focusNode.addListener(
      _handleFocusChange,
    );

    if (widget.node.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback(
        (
          _,
        ) {
          if (!mounted) {
            return;
          }

          _requestEditorFocus();
        },
      );
    }
  }

  // ============================================================
  // DID UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant MindMapNodeWidget oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    // ==========================================================
    // TROCA REAL DE NÓ
    // ==========================================================
    //
    // Se este State passar a representar outro nó, sincronizamos
    // o controller com o novo conteúdo.
    //
    // ==========================================================

    if (oldWidget.node.id !=
        widget.node.id) {
      _textController.value = TextEditingValue(
        text: widget.node.label,
        selection: TextSelection.collapsed(
          offset: widget.node.label.length,
        ),
      );

      if (widget.node.isEditing) {
        WidgetsBinding.instance.addPostFrameCallback(
          (
            _,
          ) {
            if (!mounted) {
              return;
            }

            _requestEditorFocus();
          },
        );
      }

      return;
    }

    // ==========================================================
    // NÃO SOBRESCREVER ENQUANTO DIGITA
    // ==========================================================
    //
    // Durante a edição, o TextEditingController é a fonte do
    // texto visível.
    //
    // O MindMapController mantém apenas um draft temporário para
    // calcular o tamanho do nó.
    //
    // Assim, notifyListeners() pode redimensionar o canvas sem
    // fazer a letra recém-digitada desaparecer.
    //
    // ==========================================================

    if (widget.node.isEditing) {
      return;
    }

    // ==========================================================
    // SINCRONIZAÇÃO FORA DA EDIÇÃO
    // ==========================================================

    if (_textController.text !=
        widget.node.label) {
      _syncControllerFromNode();
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _focusNode.removeListener(
      _handleFocusChange,
    );

    _focusNode.dispose();

    _textController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor: widget.node.isEditing
          ? SystemMouseCursors.text
          : SystemMouseCursors.move,

      onEnter:
          (
            _,
          ) {
            widget.onHoverChanged(
              true,
            );
          },

      onExit:
          (
            _,
          ) {
            widget.onHoverChanged(
              false,
            );
          },

      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ========================================================
        // MOVER NÓ
        // ========================================================
        onPanUpdate: widget.node.isEditing
            ? null
            : (
                details,
              ) {
                widget.controller.moveNode(
                  node: widget.node,
                  delta: details.delta,
                  canvasWidth: widget.canvasWidth,
                  canvasHeight: widget.canvasHeight,
                );
              },

        // ========================================================
        // FINALIZAR MOVIMENTO
        // ========================================================
        onPanEnd: widget.node.isEditing
            ? null
            : (
                _,
              ) {
                widget.controller.commitNodePosition(
                  block: widget.block,
                  node: widget.node,
                );
              },

        onPanCancel: widget.node.isEditing
            ? null
            : () {
                widget.controller.commitNodePositionAfterCancel(
                  block: widget.block,
                  node: widget.node,
                );
              },

        // ========================================================
        // EDITAR
        // ========================================================
        onDoubleTap: () {
          if (widget.node.isEditing) {
            return;
          }

          _syncControllerFromNode();

          widget.controller.startEditing(
            widget.node,
          );

          WidgetsBinding.instance.addPostFrameCallback(
            (
              _,
            ) {
              if (!mounted) {
                return;
              }

              _requestEditorFocus();
            },
          );
        },

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================================================
            // CORPO
            // ==================================================
            Positioned.fill(
              child: _nodeBody(),
            ),

            // ==================================================
            // PORTAS
            // ==================================================
            for (final port in NodePort.values)
              MindMapPortWidget(
                port: port,
                color: _green,
                visible:
                    widget.hovered &&
                    !widget.node.isEditing,
                onTap: () {
                  widget.controller.createConnectedNode(
                    block: widget.block,
                    parent: widget.node,
                    sourcePort: port,
                    canvasWidth: widget.canvasWidth,
                    canvasHeight: widget.canvasHeight,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NODE BODY
  // ============================================================

  Widget _nodeBody() {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 160,
      ),

      decoration: BoxDecoration(
        color: widget.node.isRoot
            ? _greenLight
            : _surface,

        borderRadius: BorderRadius.circular(
          13,
        ),

        border: Border.all(
          color: widget.node.isRoot
              ? _green
              : widget.hovered
              ? _green
              : _greenBorder,

          width: widget.node.isRoot
              ? 1.6
              : 1.2,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(
              0x14000000,
            ),
            blurRadius: 10,
            offset: Offset(
              0,
              4,
            ),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ====================================================
            // LABEL / EDITOR
            // ====================================================
            Expanded(
              child: widget.node.isEditing
                  ? _editor()
                  : _label(),
            ),

            // ====================================================
            // DELETE
            // ====================================================
            if (!widget.node.isRoot &&
                !widget.node.isEditing) ...[
              const SizedBox(
                width: 6,
              ),

              InkWell(
                onTap: () {
                  widget.controller.deleteNode(
                    block: widget.block,
                    nodeId: widget.node.id,
                  );
                },

                borderRadius: BorderRadius.circular(
                  8,
                ),

                child: const Padding(
                  padding: EdgeInsets.all(
                    4,
                  ),

                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _editor() {
    return TextField(
      controller: _textController,

      focusNode: _focusNode,

      // ========================================================
      // MULTILINHA
      // ========================================================
      minLines: 1,

      maxLines: null,

      // ========================================================
      // SEM SCROLL INTERNO
      // ========================================================
      //
      // O nó cresce junto com o conteúdo. O próprio TextField não
      // cria uma área rolável interna.
      //
      // ========================================================
      scrollPhysics: const NeverScrollableScrollPhysics(),

      keyboardType: TextInputType.multiline,

      textInputAction: TextInputAction.newline,

      // ========================================================
      // DRAFT RESPONSIVO
      // ========================================================
      //
      // O TextEditingController mantém texto, cursor e seleção.
      //
      // O controller recebe somente um draft temporário para
      // recalcular o tamanho do nó em tempo real.
      //
      // O texto definitivo só é salvo em finishEditing().
      //
      // ========================================================
      onChanged:
          (
            value,
          ) {
            widget.controller.updateNodeLabel(
              block: widget.block,
              node: widget.node,
              value: value,
            );
          },

      style: const TextStyle(
        color: _text,
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        height: _lineHeight,
      ),

      cursorColor: _green,

      decoration: const InputDecoration(
        isDense: true,

        hintText: 'Digite...',

        hintStyle: TextStyle(
          color: _muted,
          fontSize: _fontSize,
          fontWeight: FontWeight.w500,
          height: _lineHeight,
        ),

        border: InputBorder.none,

        enabledBorder: InputBorder.none,

        focusedBorder: InputBorder.none,

        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _label() {
    return Text(
      widget.node.label,

      softWrap: true,

      overflow: TextOverflow.visible,

      textAlign: TextAlign.left,

      style: TextStyle(
        color: widget.node.isRoot
            ? _green
            : _text,

        fontSize: _fontSize,

        fontWeight: FontWeight.w600,

        height: _lineHeight,
      ),
    );
  }

  // ============================================================
  // FOCO
  // ============================================================

  void _requestEditorFocus() {
    if (!widget.node.isEditing) {
      return;
    }

    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }

    _textController.selection = TextSelection.collapsed(
      offset: _textController.text.length,
    );
  }

  // ============================================================
  // ALTERAÇÃO DO FOCO
  // ============================================================

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      return;
    }

    if (!widget.node.isEditing) {
      return;
    }

    _finishEditing();
  }

  // ============================================================
  // FINALIZAR EDIÇÃO
  // ============================================================

  void _finishEditing() {
    if (_finishingEdit) {
      return;
    }

    if (!widget.node.isEditing) {
      return;
    }

    _finishingEdit = true;

    final value = _textController.text;

    widget.controller.finishEditing(
      block: widget.block,
      node: widget.node,
      value: value,
    );

    if (!mounted) {
      return;
    }

    if (!widget.node.isEditing) {
      _syncControllerFromNode();
    }

    _finishingEdit = false;
  }

  // ============================================================
  // SINCRONIZAR CONTROLLER
  // ============================================================

  void _syncControllerFromNode() {
    final value = widget.node.label;

    if (_textController.text ==
        value) {
      return;
    }

    _textController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(
        offset: value.length,
      ),
    );
  }
}
