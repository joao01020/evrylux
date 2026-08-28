import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/board_block.dart';
import '../models/mind_map_node.dart';
import '../models/node_port.dart';

class MindMapController
    extends
        ChangeNotifier {
  MindMapController({
    this.onChanged,
  });

  static const double nodeWidth = 132;
  static const double nodeHeight = 46;

  final VoidCallback? onChanged;

  MindMapNode ensureRoot(
    BoardBlock block,
  ) {
    for (final node in block.mindNodes) {
      if (node.isRoot) {
        return node;
      }
    }

    final root = MindMapNode(
      id: _createId(
        block.id,
      ),
      label: block.title,
      position: const Offset(
        20,
        105,
      ),
      isRoot: true,
    );

    block.mindNodes.insert(
      0,
      root,
    );
    _notifyChange();
    return root;
  }

  MindMapNode createConnectedNode({
    required BoardBlock block,
    required MindMapNode parent,
    required NodePort sourcePort,
    required double canvasWidth,
    required double canvasHeight,
    String label = '',
  }) {
    final siblingCount = block.mindNodes.where(
      (
        node,
      ) {
        return node.parentId ==
                parent.id &&
            node.sourcePort ==
                sourcePort;
      },
    ).length;

    final desired = _childPosition(
      parent: parent,
      port: sourcePort,
      siblingIndex: siblingCount,
    );

    final node = MindMapNode(
      id: _createId(
        block.id,
      ),
      parentId: parent.id,
      label: label,
      position: Offset(
        desired.dx
            .clamp(
              0.0,
              canvasWidth -
                  nodeWidth,
            )
            .toDouble(),
        desired.dy
            .clamp(
              0.0,
              canvasHeight -
                  nodeHeight,
            )
            .toDouble(),
      ),
      sourcePort: sourcePort,
      targetPort: sourcePort.opposite,
      isEditing: true,
    );

    block.addMindMapNode(
      node,
    );
    _syncContent(
      block,
    );
    _notifyChange();
    return node;
  }

  void moveNode({
    required MindMapNode node,
    required Offset delta,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    if (node.isEditing) {
      return;
    }

    node.position = Offset(
      (node.position.dx +
              delta.dx)
          .clamp(
            0.0,
            canvasWidth -
                nodeWidth,
          )
          .toDouble(),
      (node.position.dy +
              delta.dy)
          .clamp(
            0.0,
            canvasHeight -
                nodeHeight,
          )
          .toDouble(),
    );

    _notifyChange();
  }

  void startEditing(
    MindMapNode node,
  ) {
    node.isEditing = true;
    notifyListeners();
  }

  void finishEditing({
    required BoardBlock block,
    required MindMapNode node,
    required String value,
  }) {
    node.label = value.trim().isEmpty
        ? 'Nova ideia'
        : value.trim();
    node.isEditing = false;

    if (node.isRoot) {
      block.title = node.label;
    }

    _syncContent(
      block,
    );
    _notifyChange();
  }

  bool deleteNode({
    required BoardBlock block,
    required String nodeId,
  }) {
    final target = _findNode(
      block,
      nodeId,
    );
    if (target ==
            null ||
        target.isRoot) {
      return false;
    }

    final ids =
        <
          String
        >{
          nodeId,
        };
    var addedChild = true;

    while (addedChild) {
      addedChild = false;
      for (final node in block.mindNodes) {
        if (node.parentId !=
                null &&
            ids.contains(
              node.parentId,
            ) &&
            ids.add(
              node.id,
            )) {
          addedChild = true;
        }
      }
    }

    block.mindNodes.removeWhere(
      (
        node,
      ) => ids.contains(
        node.id,
      ),
    );
    _syncContent(
      block,
    );
    _notifyChange();
    return true;
  }

  MindMapNode? _findNode(
    BoardBlock block,
    String nodeId,
  ) {
    for (final node in block.mindNodes) {
      if (node.id ==
          nodeId) {
        return node;
      }
    }
    return null;
  }

  Offset _childPosition({
    required MindMapNode parent,
    required NodePort port,
    required int siblingIndex,
  }) {
    final spread =
        siblingIndex *
        56.0;

    return switch (port) {
      NodePort.top => Offset(
        parent.position.dx +
            spread,
        parent.position.dy -
            nodeHeight -
            58,
      ),
      NodePort.right => Offset(
        parent.position.dx +
            nodeWidth +
            58,
        parent.position.dy +
            spread,
      ),
      NodePort.bottom => Offset(
        parent.position.dx +
            spread,
        parent.position.dy +
            nodeHeight +
            58,
      ),
      NodePort.left => Offset(
        parent.position.dx -
            nodeWidth -
            58,
        parent.position.dy +
            spread,
      ),
    };
  }

  void _syncContent(
    BoardBlock block,
  ) {
    block.content = block.mindNodes
        .where(
          (
            node,
          ) => !node.isRoot,
        )
        .map(
          (
            node,
          ) => node.label,
        )
        .join(
          '\n',
        );
  }

  void _notifyChange() {
    notifyListeners();
    onChanged?.call();
  }

  String _createId(
    String prefix,
  ) {
    return '$prefix-node-${DateTime.now().microsecondsSinceEpoch}';
  }
}
