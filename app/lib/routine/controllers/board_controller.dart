import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../models/block_type.dart';
import '../models/board_block.dart';
import '../models/routine_day.dart';

class BoardController
    extends
        ChangeNotifier {
  BoardController({
    this.onChanged,
  });

  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onChanged;

  // ============================================================
  // CONFIGURAÇÕES
  // ============================================================

  /// Quantos pixels do bloco devem continuar visíveis
  /// mesmo quando o usuário arrastar parcialmente para fora.
  static const double _minimumVisibleArea = 44;

  /// Espaçamento inicial entre os blocos.
  static const double _initialGap = 14;

  /// Distância vertical usada apenas para posicionamento inicial.
  static const double _initialRowHeight = 230;

  /// Espaço mínimo entre dois blocos.
  static const double _collisionGap = 12;

  /// Alturas estimadas para colisão por tipo de bloco.
  ///
  /// Essas alturas representam melhor o tamanho visual real de
  /// cada card e evitam "áreas invisíveis" grandes demais.
  ///
  /// O mapa mental continua usando a altura persistida no próprio
  /// BoardBlock.
  static const double _taskBlockHeight = 210;

  static const double _noteBlockHeight = 136;

  static const double _contentBlockHeight = 190;

  static const double _photoBlockHeight = 260;

  static const double _documentBlockHeight = 154;

  // ============================================================
  // BLOCK WIDTH
  // ============================================================

  double blockWidth({
    required BoardBlock block,
    required double boardWidth,
    double normalWidth = 390,
  }) {
    if (boardWidth <=
        0) {
      return 1;
    }

    if (block.type ==
        BlockType.mindMap) {
      if (boardWidth >=
          620) {
        return 620;
      }

      return boardWidth;
    }

    if (boardWidth <
        normalWidth) {
      return boardWidth;
    }

    return normalWidth;
  }

  // ============================================================
  // INITIALIZE POSITIONS
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Este método NÃO reposiciona blocos que já possuem posição.
  //
  // Ele serve apenas para dar uma posição inicial a blocos que
  // ainda nunca foram posicionados.
  //
  // Dessa forma:
  //
  // usuário arrasta
  //      ↓
  // posição é salva
  //      ↓
  // rebuild
  //      ↓
  // initializePositions()
  //      ↓
  // posição existente é preservada
  //
  // ============================================================

  void initializePositions({
    required RoutineDay day,
    required double boardWidth,
    double normalWidth = 390,
  }) {
    for (
      var index = 0;
      index <
          day.blocks.length;
      index++
    ) {
      final block = day.blocks[index];

      // ========================================================
      // JÁ POSSUI POSIÇÃO
      // ========================================================
      //
      // Não altera absolutamente nada.
      //
      // Esse é o ponto principal para impedir que o bloco
      // "volte" depois de um rebuild.
      //
      // ========================================================

      if (block.position !=
          null) {
        continue;
      }

      final width = blockWidth(
        block: block,
        boardWidth: boardWidth,
        normalWidth: normalWidth,
      );

      block.position = findFreePosition(
        day: day,
        block: block,
        boardWidth: boardWidth,
        blockWidth: width,
      );
    }
  }

  // ============================================================
  // FIND FREE POSITION
  // ============================================================
  //
  // Procura automaticamente uma área vazia da lousa para um bloco
  // que ainda não possui posição.
  //
  // A busca acontece da esquerda para a direita e depois desce para
  // a próxima faixa vertical.
  //
  // Regras:
  //
  // - nunca posiciona em cima de outro bloco;
  // - respeita o _collisionGap;
  // - usa a largura real do bloco;
  // - usa a altura de colisão específica do tipo;
  // - funciona também quando a lousa possui apenas uma coluna;
  // - se não houver espaço na área visível, continua procurando
  //   para baixo, permitindo que o canvas cresça.
  //
  // ============================================================

  Offset findFreePosition({
    required RoutineDay day,
    required BoardBlock block,
    required double boardWidth,
    double? blockWidth,
    double startX = 0,
    double startY = 0,
    double horizontalGap = 18,
    double verticalGap = 18,
    int maxRows = 500,
  }) {
    final resolvedWidth =
        blockWidth ??
        this.blockWidth(
          block: block,
          boardWidth: boardWidth,
        );

    final resolvedHeight = _blockHeight(
      block,
    );

    final safeBoardWidth =
        boardWidth <=
            0
        ? resolvedWidth
        : boardWidth;

    final usableStartX =
        startX <
            0
        ? 0.0
        : startX;

    final usableStartY =
        startY <
            0
        ? 0.0
        : startY;

    // ==========================================================
    // QUANTAS COLUNAS CABEM
    // ==========================================================

    final availableWidth =
        safeBoardWidth -
        usableStartX;

    final stepX =
        resolvedWidth +
        horizontalGap;

    final columns =
        availableWidth <=
            resolvedWidth
        ? 1
        : ((availableWidth +
                      horizontalGap) /
                  stepX)
              .floor()
              .clamp(
                1,
                1000,
              );

    final stepY =
        resolvedHeight +
        verticalGap;

    // ==========================================================
    // BUSCA POR ÁREA LIVRE
    // ==========================================================

    for (
      var row = 0;
      row <
          maxRows;
      row++
    ) {
      final y =
          usableStartY +
          (row *
              stepY);

      for (
        var column = 0;
        column <
            columns;
        column++
      ) {
        var x =
            usableStartX +
            (column *
                stepX);

        // Mantém o bloco inteiro dentro da largura quando possível.
        final maxX =
            safeBoardWidth >
                resolvedWidth
            ? safeBoardWidth -
                  resolvedWidth
            : 0.0;

        if (x >
            maxX) {
          x = maxX;
        }

        final candidate = Offset(
          x,
          y,
        );

        if (canPlaceBlock(
          day: day,
          movingBlock: block,
          position: candidate,
          blockWidth: resolvedWidth,
          blockHeight: resolvedHeight,
        )) {
          return candidate;
        }
      }
    }

    // ==========================================================
    // FALLBACK
    // ==========================================================
    //
    // Em uma lousa extremamente cheia, posicionamos abaixo de
    // todos os blocos existentes.
    //
    // ==========================================================

    var lowestBottom = usableStartY;

    for (final other in day.blocks) {
      if (identical(
            other,
            block,
          ) ||
          other.id ==
              block.id) {
        continue;
      }

      final otherPosition = other.position;

      if (otherPosition ==
          null) {
        continue;
      }

      final bottom =
          otherPosition.dy +
          _blockHeight(
            other,
          );

      if (bottom >
          lowestBottom) {
        lowestBottom = bottom;
      }
    }

    return Offset(
      usableStartX,
      lowestBottom +
          verticalGap,
    );
  }

  // ============================================================
  // MOVE BLOCK
  // ============================================================
  //
  // Movimento livre, porém SEM sobreposição.
  //
  // Estratégia:
  //
  // 1. calcula a posição desejada;
  // 2. tenta mover nos dois eixos;
  // 3. se houver colisão, tenta somente X;
  // 4. se ainda houver colisão, tenta somente Y;
  // 5. se os dois eixos estiverem bloqueados, mantém a posição.
  //
  // Isso faz o bloco "deslizar" ao redor dos outros em vez de
  // simplesmente atravessá-los.
  //
  // ============================================================

  void moveBlock({
    required RoutineDay day,
    required BoardBlock block,
    required Offset delta,
    required double boardWidth,
    required double boardHeight,
    required double blockWidth,
    double? blockHeight,
  }) {
    final current =
        block.position ??
        Offset.zero;

    final resolvedHeight =
        blockHeight ??
        _blockHeight(
          block,
        );

    final desired = _clampPosition(
      position: Offset(
        current.dx +
            delta.dx,
        current.dy +
            delta.dy,
      ),
      boardWidth: boardWidth,
      blockWidth: blockWidth,
    );

    // ==========================================================
    // DESENCALHAR BLOCO QUE JÁ ESTÁ SOBREPOSTO
    // ==========================================================
    //
    // Problema anterior:
    //
    // Se um bloco já estivesse sobre outro, qualquer pequeno
    // movimento continuava tecnicamente em colisão.
    //
    // Como canPlaceBlock() retornava false para:
    //
    // - movimento completo;
    // - somente X;
    // - somente Y;
    //
    // o bloco ficava completamente "preso".
    //
    // Regra nova:
    //
    // - se a posição ATUAL já é inválida/sobreposta,
    //   permitimos movimento livre temporariamente;
    //
    // - isso deixa o usuário arrastar o bloco para fora da
    //   sobreposição;
    //
    // - assim que o bloco chega a uma posição válida, nas próximas
    //   movimentações volta a valer a proteção normal contra
    //   colisões.
    //
    // Dessa forma mantemos a regra "sem sobreposição" para blocos
    // normais, mas nunca deixamos um bloco existente encalhado.
    //
    // ==========================================================

    final currentIsValid = canPlaceBlock(
      day: day,
      movingBlock: block,
      position: current,
      blockWidth: blockWidth,
      blockHeight: resolvedHeight,
    );

    if (!currentIsValid) {
      block.position = desired;

      _notifyChange();

      return;
    }

    // ==========================================================
    // TENTATIVA COMPLETA
    // ==========================================================

    if (canPlaceBlock(
      day: day,
      movingBlock: block,
      position: desired,
      blockWidth: blockWidth,
      blockHeight: resolvedHeight,
    )) {
      block.position = desired;

      _notifyChange();

      return;
    }

    // ==========================================================
    // TENTATIVA SOMENTE NO EIXO X
    // ==========================================================

    final horizontal = _clampPosition(
      position: Offset(
        desired.dx,
        current.dy,
      ),
      boardWidth: boardWidth,
      blockWidth: blockWidth,
    );

    if (canPlaceBlock(
      day: day,
      movingBlock: block,
      position: horizontal,
      blockWidth: blockWidth,
      blockHeight: resolvedHeight,
    )) {
      block.position = horizontal;

      _notifyChange();

      return;
    }

    // ==========================================================
    // TENTATIVA SOMENTE NO EIXO Y
    // ==========================================================

    final vertical = _clampPosition(
      position: Offset(
        current.dx,
        desired.dy,
      ),
      boardWidth: boardWidth,
      blockWidth: blockWidth,
    );

    if (canPlaceBlock(
      day: day,
      movingBlock: block,
      position: vertical,
      blockWidth: blockWidth,
      blockHeight: resolvedHeight,
    )) {
      block.position = vertical;

      _notifyChange();

      return;
    }

    // Ambos os eixos estão bloqueados.
    //
    // Mantemos a posição atual.
  }

  // ============================================================
  // CAN PLACE BLOCK
  // ============================================================

  bool canPlaceBlock({
    required RoutineDay day,
    required BoardBlock movingBlock,
    required Offset position,
    required double blockWidth,
    required double blockHeight,
  }) {
    final movingRect = _collisionRect(
      position: position,
      width: blockWidth,
      height: blockHeight,
    );

    for (final other in day.blocks) {
      if (identical(
            other,
            movingBlock,
          ) ||
          other.id ==
              movingBlock.id) {
        continue;
      }

      final otherPosition = other.position;

      if (otherPosition ==
          null) {
        continue;
      }

      final otherWidth = _collisionBlockWidth(
        block: other,
      );

      final otherHeight = _blockHeight(
        other,
      );

      final otherRect = _collisionRect(
        position: otherPosition,
        width: otherWidth,
        height: otherHeight,
      );

      if (movingRect.overlaps(
        otherRect,
      )) {
        return false;
      }
    }

    return true;
  }

  // ============================================================
  // COLLISION RECT
  // ============================================================
  //
  // Inflamos metade do gap em cada lado.
  //
  // Dois blocos passam a respeitar aproximadamente 12 px entre
  // eles sem precisar alterar o tamanho visual do card.
  //
  // ============================================================

  Rect _collisionRect({
    required Offset position,
    required double width,
    required double height,
  }) {
    final halfGap =
        _collisionGap /
        2;

    return Rect.fromLTWH(
      position.dx -
          halfGap,
      position.dy -
          halfGap,
      width +
          _collisionGap,
      height +
          _collisionGap,
    );
  }

  // ============================================================
  // BLOCK HEIGHT
  // ============================================================

  double _blockHeight(
    BoardBlock block,
  ) {
    switch (block.type) {
      case BlockType.tasks:
        return _taskBlockHeight;

      case BlockType.note:
        return _noteBlockHeight;

      case BlockType.content:
        return _contentBlockHeight;

      case BlockType.photo:
        return _photoBlockHeight;

      case BlockType.mindMap:
        return block.height ??
            430;

      case BlockType.document:
        return _documentBlockHeight;
    }
  }

  // ============================================================
  // COLLISION BLOCK WIDTH
  // ============================================================
  //
  // O mapa mental possui largura personalizada persistida.
  //
  // Blocos comuns usam a largura padrão usada pela lousa.
  //
  // ============================================================

  double _collisionBlockWidth({
    required BoardBlock block,
  }) {
    if (block.type ==
        BlockType.mindMap) {
      return block.width ??
          620;
    }

    return 390;
  }

  // ============================================================
  // CLAMP POSITION
  // ============================================================

  Offset _clampPosition({
    required Offset position,
    required double boardWidth,
    required double blockWidth,
  }) {
    final minimumX =
        -blockWidth +
        _minimumVisibleArea;

    final maximumX =
        boardWidth -
        _minimumVisibleArea;

    const minimumY = -40.0;

    final x = position.dx.clamp(
      minimumX,
      maximumX,
    );

    final y =
        position.dy <
            minimumY
        ? minimumY
        : position.dy;

    return Offset(
      x.toDouble(),
      y.toDouble(),
    );
  }

  // ============================================================
  // SET POSITION
  // ============================================================
  //
  // Útil caso você queira futuramente:
  //
  // - clicar no canvas e mover diretamente;
  // - restaurar posição;
  // - importar posição do banco;
  // - implementar zoom/pan.
  //
  // ============================================================

  void setBlockPosition({
    required BoardBlock block,
    required Offset position,
  }) {
    block.position = position;

    _notifyChange();
  }

  // ============================================================
  // ADD BLOCK
  // ============================================================

  void addBlock(
    RoutineDay day,
    BoardBlock block, {
    double? boardWidth,
  }) {
    if (block.position ==
            null &&
        boardWidth !=
            null &&
        boardWidth >
            0) {
      final width = this.blockWidth(
        block: block,
        boardWidth: boardWidth,
      );

      block.position = findFreePosition(
        day: day,
        block: block,
        boardWidth: boardWidth,
        blockWidth: width,
      );
    }

    day.addBlock(
      block,
    );

    _notifyChange();
  }

  // ============================================================
  // REMOVE BLOCK
  // ============================================================

  bool removeBlock(
    RoutineDay day,
    String blockId,
  ) {
    final removed = day.removeBlockById(
      blockId,
    );

    if (removed) {
      _notifyChange();
    }

    return removed;
  }

  // ============================================================
  // DUPLICATE BLOCK
  // ============================================================

  BoardBlock duplicateBlock(
    RoutineDay day,
    BoardBlock block,
  ) {
    final duplicate = block.copy();

    final current =
        block.position ??
        Offset.zero;

    final width = _collisionBlockWidth(
      block: duplicate,
    );

    final height = _blockHeight(
      duplicate,
    );

    // ==========================================================
    // PROCURAR POSIÇÃO LIVRE
    // ==========================================================
    //
    // Evita criar a cópia exatamente em cima do original.
    //
    // Procuramos em diagonal até encontrar um espaço sem colisão.
    //
    // ==========================================================

    var candidate = Offset(
      current.dx +
          28,
      current.dy +
          28,
    );

    const step = 28.0;

    for (
      var attempt = 0;
      attempt <
          40;
      attempt++
    ) {
      if (canPlaceBlock(
        day: day,
        movingBlock: duplicate,
        position: candidate,
        blockWidth: width,
        blockHeight: height,
      )) {
        break;
      }

      candidate = Offset(
        candidate.dx +
            step,
        candidate.dy +
            step,
      );
    }

    duplicate.position = candidate;

    day.addBlock(
      duplicate,
    );

    _notifyChange();

    return duplicate;
  }

  // ============================================================
  // CANVAS HEIGHT
  // ============================================================

  double canvasHeight({
    required RoutineDay day,
    required double minimumHeight,
    double estimatedBlockHeight = 280,
    double bottomPadding = 120,
  }) {
    var greatestBottom = minimumHeight;

    for (final block in day.blocks) {
      final position = block.position;

      if (position ==
          null) {
        continue;
      }

      final bottom =
          position.dy +
          estimatedBlockHeight;

      if (bottom >
          greatestBottom) {
        greatestBottom = bottom;
      }
    }

    return greatestBottom +
        bottomPadding;
  }

  // ============================================================
  // CANVAS WIDTH REQUIRED
  // ============================================================
  //
  // Não é obrigatório usar agora, mas deixa o controller pronto
  // para um canvas horizontalmente expansível no futuro.
  //
  // ============================================================

  double canvasWidth({
    required RoutineDay day,
    required double minimumWidth,
    double estimatedBlockWidth = 390,
    double rightPadding = 120,
  }) {
    var greatestRight = minimumWidth;

    for (final block in day.blocks) {
      final position = block.position;

      if (position ==
          null) {
        continue;
      }

      final right =
          position.dx +
          estimatedBlockWidth;

      if (right >
          greatestRight) {
        greatestRight = right;
      }
    }

    return greatestRight +
        rightPadding;
  }

  // ============================================================
  // RESET POSITIONS
  // ============================================================
  //
  // Caso você queira no futuro um botão:
  //
  // "Organizar blocos"
  //
  // você pode chamar este método.
  //
  // É importante NÃO executar automaticamente.
  //
  // ============================================================

  void resetPositions({
    required RoutineDay day,
    required double boardWidth,
    double normalWidth = 390,
  }) {
    for (
      var index = 0;
      index <
          day.blocks.length;
      index++
    ) {
      final block = day.blocks[index];

      final width = blockWidth(
        block: block,
        boardWidth: boardWidth,
        normalWidth: normalWidth,
      );

      block.position = _initialPosition(
        index: index,
        boardWidth: boardWidth,
        blockWidth: width,
      );
    }

    _notifyChange();
  }

  // ============================================================
  // INITIAL POSITION
  // ============================================================

  Offset _initialPosition({
    required int index,
    required double boardWidth,
    required double blockWidth,
  }) {
    final useTwoColumns =
        boardWidth >=
        (blockWidth *
                2) +
            28;

    if (useTwoColumns) {
      final column =
          index %
          2;

      final row =
          index ~/
          2;

      return Offset(
        column *
            (blockWidth +
                _initialGap),
        row *
            _initialRowHeight,
      );
    }

    return Offset(
      0,
      index *
          _initialRowHeight,
    );
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _notifyChange() {
    notifyListeners();

    onChanged?.call();
  }
}
