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

  final VoidCallback? onChanged;

  double blockWidth({
    required BoardBlock block,
    required double boardWidth,
    double normalWidth = 390,
  }) {
    if (block.type ==
        BlockType.mindMap) {
      return boardWidth >=
              620
          ? 620
          : boardWidth;
    }

    return boardWidth <
            normalWidth
        ? boardWidth
        : normalWidth;
  }

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
      final width = blockWidth(
        block: block,
        boardWidth: boardWidth,
        normalWidth: normalWidth,
      );

      block.position ??= _initialPosition(
        index: index,
        boardWidth: boardWidth,
        blockWidth: width,
      );

      final maximumX =
          boardWidth >
              width
          ? boardWidth -
                width
          : 0.0;
      block.position = Offset(
        block.position!.dx
            .clamp(
              0.0,
              maximumX,
            )
            .toDouble(),
        block.position!.dy <
                0
            ? 0
            : block.position!.dy,
      );
    }
  }

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
    final maximumX =
        boardWidth >
            blockWidth
        ? boardWidth -
              blockWidth
        : 0.0;
    final maximumY =
        boardHeight >
            100
        ? boardHeight -
              100
        : 0.0;

    block.position = Offset(
      (current.dx +
              delta.dx)
          .clamp(
            0.0,
            maximumX,
          )
          .toDouble(),
      (current.dy +
              delta.dy)
          .clamp(
            0.0,
            maximumY,
          )
          .toDouble(),
    );

    _notifyChange();
  }

  void addBlock(
    RoutineDay day,
    BoardBlock block,
  ) {
    day.addBlock(
      block,
    );
    _notifyChange();
  }

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

  BoardBlock duplicateBlock(
    RoutineDay day,
    BoardBlock block,
  ) {
    final duplicate = block.copy();
    day.addBlock(
      duplicate,
    );
    _notifyChange();
    return duplicate;
  }

  double canvasHeight({
    required RoutineDay day,
    required double minimumHeight,
    double estimatedBlockHeight = 280,
    double bottomPadding = 120,
  }) {
    var greatestBottom = minimumHeight;

    for (final block in day.blocks) {
      final bottom =
          (block.position?.dy ??
              0) +
          estimatedBlockHeight;
      if (bottom >
          greatestBottom) {
        greatestBottom = bottom;
      }
    }

    return greatestBottom +
        bottomPadding;
  }

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
                14),
        row *
            230.0,
      );
    }

    return Offset(
      0,
      index *
          230.0,
    );
  }

  void _notifyChange() {
    notifyListeners();
    onChanged?.call();
  }
}
