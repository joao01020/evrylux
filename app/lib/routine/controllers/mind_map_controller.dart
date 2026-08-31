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
  // CALLBACK DE PERSISTÊNCIA
  // ============================================================
  //
  // IMPORTANTE:
  //
  // onChanged NÃO é chamado durante cada pixel do drag.
  //
  // Durante o movimento usamos apenas notifyListeners(), mantendo
  // a posição local fluida e evitando vários saves concorrentes.
  //
  // O save real deve acontecer quando o usuário SOLTAR o nó,
  // chamando commitNodePosition().
  //
  // Isso reduz o problema de "snap back", no qual uma resposta
  // antiga do Supabase sobrescreve uma posição mais recente.
  //
  // ============================================================

  final VoidCallback? onChanged;

  // ============================================================
  // DRAFTS DE EDIÇÃO
  // ============================================================

  final Map<
    String,
    String
  >
  _editingDrafts = {};

  // ============================================================
  // TAMANHO DOS NÓS
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

    _commitChange();

    return root;
  }

  // ============================================================
  // TAMANHO DO NÓ
  // ============================================================

  Size nodeSize(
    MindMapNode node,
  ) {
    final text = node.isEditing
        ? _editingDrafts[node.id] ??
              node.label
        : node.label;

    return calculateNodeSize(
      text,
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
        ? ' '
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

    // ==========================================================
    // POSIÇÃO LIVRE
    // ==========================================================
    //
    // Não limitamos mais o nó ao canvasWidth/canvasHeight.
    //
    // O bloco/lousa pode crescer de forma adaptativa e os nós
    // continuam livres para ocupar toda a área disponível.
    //
    // ==========================================================

    provisionalNode.position = desired;

    block.addMindMapNode(
      provisionalNode,
    );

    _editingDrafts[provisionalNode.id] = label;

    // ==========================================================
    // NÃO PERSISTIR ANTES DE TERMINAR O TEXTO
    // ==========================================================
    //
    // Ao criar um nó novo, ele entra imediatamente em edição.
    //
    // Se chamarmos onChanged aqui, o Supabase pode salvar o nó
    // vazio e devolver essa versão enquanto o usuário ainda está
    // digitando. Isso faz o texto recém-digitado desaparecer e
    // voltar para o valor anterior.
    //
    // Portanto, neste momento atualizamos apenas a interface.
    //
    // O save real acontece em finishEditing().
    //
    // ==========================================================

    notifyListeners();

    return provisionalNode;
  }

  // ============================================================
  // MOVER NÓ - SOMENTE ESTADO LOCAL
  // ============================================================
  //
  // Aqui NÃO chamamos onChanged.
  //
  // Isso é proposital:
  //
  // onPanUpdate pode acontecer dezenas ou centenas de vezes em
  // um único arraste. Salvar a cada pixel cria vários requests
  // concorrentes e pode fazer uma resposta antiga devolver o nó
  // para uma posição anterior.
  //
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

    // ==========================================================
    // MOVIMENTO LIVRE
    // ==========================================================
    //
    // Não usamos clamp.
    //
    // Assim o nó não fica preso ao tamanho antigo da lousa.
    //
    // O canvasWidth/canvasHeight continuam no método apenas para
    // manter compatibilidade com o widget atual.
    //
    // ==========================================================

    node.position = Offset(
      node.position.dx +
          delta.dx,
      node.position.dy +
          delta.dy,
    );

    // Apenas redesenha localmente.
    notifyListeners();
  }

  // ============================================================
  // COMMIT DA POSIÇÃO
  // ============================================================
  //
  // Chame este método no onPanEnd do MindMapNodeWidget.
  //
  // Exemplo:
  //
  // onPanEnd: (_) {
  //   controller.commitNodePosition(
  //     block: block,
  //     node: node,
  //   );
  // },
  //
  // ============================================================

  void commitNodePosition({
    required BoardBlock block,
    required MindMapNode node,
  }) {
    if (node.isEditing) {
      return;
    }

    _syncContent(
      block,
    );

    _commitChange();
  }

  // ============================================================
  // CANCELAMENTO DO DRAG
  // ============================================================
  //
  // Mesmo se o GestureDetector cancelar o gesto, persistimos a
  // última posição local já alcançada.
  //
  // ============================================================

  void commitNodePositionAfterCancel({
    required BoardBlock block,
    required MindMapNode node,
  }) {
    commitNodePosition(
      block: block,
      node: node,
    );
  }

  // ============================================================
  // EDITAR
  // ============================================================

  void startEditing(
    MindMapNode node,
  ) {
    node.isEditing = true;

    _editingDrafts[node.id] = node.label;

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

    _editingDrafts.remove(
      node.id,
    );

    if (!node.isRoot &&
        normalized.isEmpty) {
      block.mindNodes.removeWhere(
        (
          item,
        ) =>
            item.id ==
            node.id,
      );

      _syncContent(
        block,
      );

      _commitChange();

      return;
    }

    if (node.isRoot &&
        normalized.isEmpty) {
      node.isEditing = false;

      notifyListeners();

      return;
    }

    node.label = normalized;

    node.isEditing = false;

    if (node.isRoot) {
      block.title = node.label;
    }

    _syncContent(
      block,
    );

    _commitChange();
  }

  // ============================================================
  // ATUALIZAR TEXTO DURANTE DIGITAÇÃO
  // ============================================================
  //
  // Mantém o texto e o tamanho atualizados na interface, mas
  // NÃO dispara persistência em cada tecla.
  //
  // ============================================================

  void updateNodeLabel({
    required BoardBlock block,
    required MindMapNode node,
    required String value,
  }) {
    _editingDrafts[node.id] = value;

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

    for (final id in ids) {
      _editingDrafts.remove(
        id,
      );
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

    _commitChange();

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
  // COMMIT / PERSISTÊNCIA
  // ============================================================

  void _commitChange() {
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
