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
        onPanUpdate:
            (
              details,
            ) {
              controller.moveNode(
                node: node,
                delta: details.delta,
                canvasWidth: canvasWidth,
                canvasHeight: canvasHeight,
              );
            },
        onDoubleTap: () {
          controller.startEditing(
            node,
          );
        },
        child: Stack(
          children: [
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
      child: Row(
        children: [
          const SizedBox(
            width: 12,
          ),

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
              !node.isEditing)
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
                  8,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: _muted,
                ),
              ),
            ),

          const SizedBox(
            width: 8,
          ),
        ],
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
      maxLines: 1,
      textInputAction: TextInputAction.done,
      onFieldSubmitted:
          (
            value,
          ) {
            controller.finishEditing(
              block: block,
              node: node,
              value: value,
            );
          },
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
      onChanged:
          (
            value,
          ) {
            node.label = value;
          },
      style: const TextStyle(
        color: _text,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: _green,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Digite...',
        hintStyle: TextStyle(
          color: _muted,
          fontSize: 11,
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
      node.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: node.isRoot
            ? _green
            : _text,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
