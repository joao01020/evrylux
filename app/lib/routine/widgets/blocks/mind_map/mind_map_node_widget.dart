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
          ) => onHoverChanged(
            true,
          ),
      onExit:
          (
            _,
          ) => onHoverChanged(
            false,
          ),
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
        onDoubleTap: () => controller.startEditing(
          node,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: _nodeBody(
                context,
              ),
            ),
            for (final port in NodePort.values)
              MindMapPortWidget(
                port: port,
                color: block.color,
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

  Widget _nodeBody(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: node.isRoot
            ? block.color
            : const Color(
                0xFF171A22,
              ),
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: node.isRoot
              ? block.color
              : block.color.withValues(
                  alpha: .75,
                ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x55000000,
            ),
            blurRadius: 12,
            offset: Offset(
              0,
              5,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: node.isEditing
                ? _editor()
                : _label(),
          ),
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
                  color: Color(
                    0xFF9298A6,
                  ),
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
          ) => node.label = value,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      cursorColor: Colors.white,
      decoration: const InputDecoration(
        isDense: true,
        hintText: 'Digite...',
        hintStyle: TextStyle(
          color: Colors.white54,
          fontSize: 11,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _label() {
    return Text(
      node.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
