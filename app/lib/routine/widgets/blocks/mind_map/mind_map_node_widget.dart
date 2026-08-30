import 'package:flutter/material.dart';

import '../../../controllers/mind_map_controller.dart';
import '../../../models/board_block.dart';
import '../../../models/mind_map_node.dart';
import '../../../models/node_port.dart';
import 'mind_map_port_widget.dart';

class MindMapNodeWidget
    extends
        StatelessWidget {
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MouseRegion(
      cursor: node.isEditing
          ? SystemMouseCursors.text
          : SystemMouseCursors.move,
      onEnter:
          (
            _,
          ) {
            onHoverChanged(
              true,
            );
          },
      onExit:
          (
            _,
          ) {
            onHoverChanged(
              false,
            );
          },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ========================================================
        // MOVER NÓ
        // ========================================================
        onPanUpdate: node.isEditing
            ? null
            : (
                details,
              ) {
                controller.moveNode(
                  node: node,
                  delta: details.delta,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                );
              },

        // ========================================================
        // EDITAR
        // ========================================================
        onDoubleTap: () {
          controller.startEditing(
            node,
          );
        },

        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ==================================================
            // CORPO
            // ==================================================
            Positioned.fill(
              child: _nodeBody(
                context,
              ),
            ),

            // ==================================================
            // PORTAS
            // ==================================================
            for (final port in NodePort.values)
              MindMapPortWidget(
                port: port,
                color: _green,
                visible:
                    hovered &&
                    !node.isEditing,
                onTap: () {
                  controller.createConnectedNode(
                    block: block,
                    parent: node,
                    sourcePort: port,
                    canvasWidth: canvasWidth,
                    canvasHeight: canvasHeight,
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

  Widget _nodeBody(
    BuildContext context,
  ) {
    return AnimatedContainer(
      duration: const Duration(
        milliseconds: 160,
      ),
      decoration: BoxDecoration(
        color: node.isRoot
            ? _greenLight
            : _surface,
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: node.isRoot
              ? _green
              : hovered
              ? _green
              : _greenBorder,
          width: node.isRoot
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

      // ========================================================
      // PADDING
      // ========================================================
      //
      // Mantemos padding vertical para o texto poder crescer
      // sem encostar nas bordas do nó.
      //
      // ========================================================
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
              child: node.isEditing
                  ? _editor()
                  : _label(),
            ),

            // ====================================================
            // DELETE
            // ====================================================
            if (!node.isRoot &&
                !node.isEditing) ...[
              const SizedBox(
                width: 6,
              ),

              InkWell(
                onTap: () {
                  controller.deleteNode(
                    block: block,
                    nodeId: node.id,
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
    return TextFormField(
      key: ValueKey(
        'edit-${node.id}',
      ),

      initialValue: node.label,

      autofocus: true,

      // ========================================================
      // MULTILINHA
      // ========================================================
      //
      // Agora o editor cresce conforme o texto.
      //
      // ========================================================
      minLines: 1,

      maxLines: null,

      keyboardType: TextInputType.multiline,

      textInputAction: TextInputAction.newline,

      // ========================================================
      // FINALIZAR AO CLICAR FORA
      // ========================================================
      onTapOutside:
          (
            _,
          ) {
            controller.finishEditing(
              block: block,
              node: node,
              value: node.label,
            );
          },

      // ========================================================
      // ATUALIZAÇÃO EM TEMPO REAL
      // ========================================================
      //
      // O label é alterado enquanto o usuário digita.
      //
      // Também notificamos o controller para o canvas poder
      // recalcular o tamanho do nó conforme o texto cresce.
      //
      // ========================================================
      onChanged:
          (
            value,
          ) {
            node.label = value;

            controller.startEditing(
              node,
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
    final value = node.label.trim().isEmpty
        ? 'Nova ideia'
        : node.label;

    return Text(
      value,

      // ========================================================
      // TEXTO COMPLETO
      // ========================================================
      //
      // Não usamos:
      //
      // maxLines
      // TextOverflow.ellipsis
      //
      // Portanto o texto pode ocupar quantas linhas precisar.
      //
      // ========================================================
      softWrap: true,

      overflow: TextOverflow.visible,

      textAlign: TextAlign.left,

      style: TextStyle(
        color: node.isRoot
            ? _green
            : _text,
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
        height: _lineHeight,
      ),
    );
  }
}
