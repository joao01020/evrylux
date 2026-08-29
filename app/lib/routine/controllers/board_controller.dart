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

      block.position = _initialPosition(
        index: index,
        boardWidth: boardWidth,
        blockWidth: width,
      );
    }
  }

  // ============================================================
  // MOVE BLOCK
  // ============================================================
  //
  // Movimento livre.
  //
  // Não existe:
  //
  // - snap
  // - alinhamento automático
  // - reposicionamento por coluna
  // - grade magnética
  //
  // Existe apenas uma proteção mínima para impedir que o bloco
  // desapareça completamente para fora da lousa.
  //
  // ============================================================

  void moveBlock({
    required BoardBlock block,
    required Offset delta,
    required double boardWidth,
    required double boardHeight,
    required double blockWidth,
  }) {
    final current =
        block.position ??
        Offset.zero;

    final nextX =
        current.dx +
        delta.dx;

    final nextY =
        current.dy +
        delta.dy;

    // ==========================================================
    // LIMITES LEVES
    // ==========================================================
    //
    // Permite que o usuário arraste parcialmente para fora,
    // mas mantém uma pequena parte do card visível.
    //
    // Exemplo:
    //
    // cardWidth = 390
    //
    // ele pode ir até:
    //
    // x = -346
    //
    // sobrando aproximadamente 44 px visíveis.
    //
    // ==========================================================

    final minimumX =
        -blockWidth +
        _minimumVisibleArea;

    final maximumX =
        boardWidth -
        _minimumVisibleArea;

    final minimumY = -40.0;

    // ==========================================================
    // Y
    // ==========================================================
    //
    // Não limitamos rigidamente o movimento para baixo.
    //
    // Isso permite que o canvas cresça através de canvasHeight().
    //
    // ==========================================================

    final freeY =
        nextY <
            minimumY
        ? minimumY
        : nextY;

    final freeX = nextX.clamp(
      minimumX,
      maximumX,
    );

    block.position = Offset(
      freeX.toDouble(),
      freeY.toDouble(),
    );

    _notifyChange();
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
    BoardBlock block,
  ) {
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

    // ==========================================================
    // POSIÇÃO DA CÓPIA
    // ==========================================================
    //
    // Em vez de deixar o bloco duplicado exatamente em cima do
    // original, deslocamos levemente.
    //
    // ==========================================================

    duplicate.position = Offset(
      current.dx +
          28,
      current.dy +
          28,
    );

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
