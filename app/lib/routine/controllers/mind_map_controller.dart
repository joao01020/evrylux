import 'package:flutter/material.dart';

import '../models/board_block.dart';
import '../models/mind_map_node.dart';
import '../models/node_port.dart';

class MindMapController
    extends
        ChangeNotifier {
  MindMapController({
    this.onChanged,
  });

  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onChanged;

  // ============================================================
  // TAMANHO DOS NÓS
  // ============================================================
  //
  // O nó não possui mais altura fixa.
  //
  // A largura cresce até maxNodeWidth e, depois disso, o texto
  // quebra em várias linhas e a altura aumenta automaticamente.
  //
  // ============================================================

  static const double minNodeWidth = 132;

  static const double maxNodeWidth = 260;

  static const double minNodeHeight = 46;

  static const double nodeHorizontalPadding = 42;

  static const double nodeVerticalPadding = 20;

  static const double nodeFontSize = 13;

  static const double nodeLineHeight = 1.25;

  // ============================================================
  // COMPATIBILIDADE
  // ============================================================
  //
  // Mantemos estes nomes para não quebrar outros arquivos antigos
  // que ainda possam utilizar MindMapController.nodeWidth/Height.
  //
  // O canvas atualizado deve preferir nodeSize(node).
  //
  // ============================================================

  static const double nodeWidth = minNodeWidth;

  static const double nodeHeight = minNodeHeight;

  // ============================================================
  // ESPAÇAMENTO
  // ============================================================

  static const double nodeSpacing = 58;

  static const double siblingSpacing = 22;

  // ============================================================
  // ROOT
  // ============================================================

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

    _syncContent(
      block,
    );

    _notifyChange();

    return root;
  }

  // ============================================================
  // TAMANHO DO NÓ
  // ============================================================

  Size nodeSize(
    MindMapNode node,
  ) {
    return calculateNodeSize(
      node.label,
      hasDeleteButton: !node.isRoot,
    );
  }

  // ============================================================
  // CALCULAR TAMANHO
  // ============================================================

  Size calculateNodeSize(
    String text, {
    bool hasDeleteButton = false,
  }) {
    final normalized = text.trim().isEmpty
        ? 'Nova ideia'
        : text.trim();

    final extraDeleteWidth = hasDeleteButton
        ? 24.0
        : 0.0;

    final availableTextWidth =
        maxNodeWidth -
        nodeHorizontalPadding -
        extraDeleteWidth;

    final painter = TextPainter(
      text: TextSpan(
        text: normalized,
        style: const TextStyle(
          fontSize: nodeFontSize,
          fontWeight: FontWeight.w600,
          height: nodeLineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    // Primeiro calculamos quanto o texto desejaria ocupar em uma linha.
    painter.layout(
      minWidth: 0,
      maxWidth: availableTextWidth,
    );

    final desiredWidth =
        painter.width +
        nodeHorizontalPadding +
        extraDeleteWidth;

    final width = desiredWidth
        .clamp(
          minNodeWidth,
          maxNodeWidth,
        )
        .toDouble();

    // Recalculamos com a largura final para descobrir a altura real.
    final finalTextWidth =
        width -
        nodeHorizontalPadding -
        extraDeleteWidth;

    painter.layout(
      minWidth: 0,
      maxWidth:
          finalTextWidth <=
              0
          ? 1
          : finalTextWidth,
    );

    final height =
        (painter.height +
                nodeVerticalPadding)
            .clamp(
              minNodeHeight,
              double.infinity,
            )
            .toDouble();

    return Size(
      width,
      height,
    );
  }

  // ============================================================
  // POSIÇÃO DE UMA PORTA
  // ============================================================
  //
  // Usa o tamanho real do nó.
  //
  // Isso mantém as linhas/setas presas na borda correta mesmo
  // quando o nó cresce por causa do texto.
  //
  // ============================================================

  Offset portPosition(
    MindMapNode node,
    NodePort port,
  ) {
    final size = nodeSize(
      node,
    );

    return switch (port) {
      NodePort.top => Offset(
        node.position.dx +
            size.width /
                2,
        node.position.dy,
      ),
      NodePort.right => Offset(
        node.position.dx +
            size.width,
        node.position.dy +
            size.height /
                2,
      ),
      NodePort.bottom => Offset(
        node.position.dx +
            size.width /
                2,
        node.position.dy +
            size.height,
      ),
      NodePort.left => Offset(
        node.position.dx,
        node.position.dy +
            size.height /
                2,
      ),
    };
  }

  // ============================================================
  // CRIAR NÓ CONECTADO
  // ============================================================

  MindMapNode createConnectedNode({
    required BoardBlock block,
    required MindMapNode parent,
    required NodePort sourcePort,
    required double canvasWidth,
    required double canvasHeight,
    String label = '',
  }) {
    final siblings = block.mindNodes.where(
      (
        node,
      ) {
        return node.parentId ==
                parent.id &&
            node.sourcePort ==
                sourcePort;
      },
    ).toList();

    final desired = _childPosition(
      parent: parent,
      port: sourcePort,
      siblingIndex: siblings.length,
      childLabel: label,
    );

    final provisionalNode = MindMapNode(
      id: _createId(
        block.id,
      ),
      parentId: parent.id,
      label: label,
      position: desired,
      sourcePort: sourcePort,
      targetPort: sourcePort.opposite,
      isEditing: true,
    );

    final size = nodeSize(
      provisionalNode,
    );

    provisionalNode.position = Offset(
      desired.dx
          .clamp(
            0.0,
            _maxX(
              canvasWidth,
              size.width,
            ),
          )
          .toDouble(),
      desired.dy
          .clamp(
            0.0,
            _maxY(
              canvasHeight,
              size.height,
            ),
          )
          .toDouble(),
    );

    block.addMindMapNode(
      provisionalNode,
    );

    _syncContent(
      block,
    );

    _notifyChange();

    return provisionalNode;
  }

  // ============================================================
  // MOVER NÓ
  // ============================================================

  void moveNode({
    required MindMapNode node,
    required Offset delta,
    required double canvasWidth,
    required double canvasHeight,
  }) {
    if (node.isEditing) {
      return;
    }

    final size = nodeSize(
      node,
    );

    node.position = Offset(
      (node.position.dx +
              delta.dx)
          .clamp(
            0.0,
            _maxX(
              canvasWidth,
              size.width,
            ),
          )
          .toDouble(),
      (node.position.dy +
              delta.dy)
          .clamp(
            0.0,
            _maxY(
              canvasHeight,
              size.height,
            ),
          )
          .toDouble(),
    );

    _notifyChange();
  }

  // ============================================================
  // EDITAR
  // ============================================================

  void startEditing(
    MindMapNode node,
  ) {
    node.isEditing = true;

    // Precisamos redesenhar imediatamente porque o tamanho pode
    // mudar enquanto o usuário digita.
    notifyListeners();
  }

  // ============================================================
  // FINALIZAR EDIÇÃO
  // ============================================================

  void finishEditing({
    required BoardBlock block,
    required MindMapNode node,
    required String value,
  }) {
    final normalized = value.trim();

    node.label = normalized.isEmpty
        ? 'Nova ideia'
        : normalized;

    node.isEditing = false;

    if (node.isRoot) {
      block.title = node.label;
    }

    _syncContent(
      block,
    );

    _notifyChange();
  }

  // ============================================================
  // ATUALIZAR TEXTO DURANTE DIGITAÇÃO
  // ============================================================
  //
  // Pode ser usado pelo widget no onChanged para recalcular o
  // tamanho do nó em tempo real.
  //
  // ============================================================

  void updateNodeLabel({
    required BoardBlock block,
    required MindMapNode node,
    required String value,
  }) {
    node.label = value;

    if (node.isRoot) {
      block.title = value;
    }

    _syncContent(
      block,
    );

    notifyListeners();
  }

  // ============================================================
  // DELETAR NÓ
  // ============================================================

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

  // ============================================================
  // BUSCAR NÓ
  // ============================================================

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

  // ============================================================
  // POSIÇÃO DO FILHO
  // ============================================================

  Offset _childPosition({
    required MindMapNode parent,
    required NodePort port,
    required int siblingIndex,
    required String childLabel,
  }) {
    final parentSize = nodeSize(
      parent,
    );

    final childSize = calculateNodeSize(
      childLabel,
      hasDeleteButton: true,
    );

    final spread =
        siblingIndex *
        (minNodeHeight +
            siblingSpacing);

    return switch (port) {
      NodePort.top => Offset(
        parent.position.dx +
            (parentSize.width -
                    childSize.width) /
                2 +
            spread,
        parent.position.dy -
            childSize.height -
            nodeSpacing,
      ),
      NodePort.right => Offset(
        parent.position.dx +
            parentSize.width +
            nodeSpacing,
        parent.position.dy +
            (parentSize.height -
                    childSize.height) /
                2 +
            spread,
      ),
      NodePort.bottom => Offset(
        parent.position.dx +
            (parentSize.width -
                    childSize.width) /
                2 +
            spread,
        parent.position.dy +
            parentSize.height +
            nodeSpacing,
      ),
      NodePort.left => Offset(
        parent.position.dx -
            childSize.width -
            nodeSpacing,
        parent.position.dy +
            (parentSize.height -
                    childSize.height) /
                2 +
            spread,
      ),
    };
  }

  // ============================================================
  // LIMITE X
  // ============================================================

  double _maxX(
    double canvasWidth,
    double width,
  ) {
    return (canvasWidth -
            width)
        .clamp(
          0.0,
          double.infinity,
        )
        .toDouble();
  }

  // ============================================================
  // LIMITE Y
  // ============================================================

  double _maxY(
    double canvasHeight,
    double height,
  ) {
    return (canvasHeight -
            height)
        .clamp(
          0.0,
          double.infinity,
        )
        .toDouble();
  }

  // ============================================================
  // SINCRONIZAR CONTEÚDO
  // ============================================================

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

  // ============================================================
  // NOTIFICAR ALTERAÇÃO
  // ============================================================

  void _notifyChange() {
    notifyListeners();

    onChanged?.call();
  }

  // ============================================================
  // ID
  // ============================================================

  String _createId(
    String prefix,
  ) {
    return '$prefix-node-${DateTime.now().microsecondsSinceEpoch}';
  }
}
