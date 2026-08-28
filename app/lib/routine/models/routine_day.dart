import 'block_type.dart';
import 'board_block.dart';
import 'check_item.dart';

class RoutineDay {
  RoutineDay({
    required DateTime date,
    this.id,
    String focus = '',
    List<
      BoardBlock
    >?
    blocks,
  }) : date = _dateOnly(
         date,
       ),
       focus = focus.trim(),
       blocks =
           blocks ??
           [];

  // ============================================================
  // FIELDS
  // ============================================================

  final String? id;

  final DateTime date;

  String focus;

  final List<
    BoardBlock
  >
  blocks;

  // ============================================================
  // DATE
  // ============================================================

  DateTime get normalizedDate {
    return _dateOnly(
      date,
    );
  }

  // ============================================================
  // TASKS
  // ============================================================

  Iterable<
    CheckItem
  >
  get tasks {
    return blocks
        .where(
          (
            block,
          ) =>
              block.type ==
              BlockType.tasks,
        )
        .expand(
          (
            block,
          ) => block.items,
        );
  }

  // ============================================================
  // TASK STATS
  // ============================================================

  int get totalTasks {
    return tasks.length;
  }

  int get completedTasks {
    return tasks
        .where(
          (
            item,
          ) => item.done,
        )
        .length;
  }

  int get pendingTasks {
    return totalTasks -
        completedTasks;
  }

  double get progress {
    if (totalTasks ==
        0) {
      return 0;
    }

    return completedTasks /
        totalTasks;
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get hasBlocks {
    return blocks.isNotEmpty;
  }

  bool get hasTasks {
    return totalTasks >
        0;
  }

  bool get hasFocus {
    return focus.trim().isNotEmpty;
  }

  bool get isCompleted {
    return totalTasks >
            0 &&
        completedTasks ==
            totalTasks;
  }

  bool get isEmpty {
    return !hasFocus &&
        !hasBlocks;
  }

  // ============================================================
  // FOCUS
  // ============================================================

  void updateFocus(
    String value,
  ) {
    focus = value.trim();
  }

  void clearFocus() {
    focus = '';
  }

  // ============================================================
  // BLOCKS
  // ============================================================

  void addBlock(
    BoardBlock block,
  ) {
    blocks.add(
      block,
    );
  }

  void addBlocks(
    Iterable<
      BoardBlock
    >
    newBlocks,
  ) {
    blocks.addAll(
      newBlocks,
    );
  }

  bool removeBlock(
    BoardBlock block,
  ) {
    return blocks.remove(
      block,
    );
  }

  bool removeBlockById(
    String blockId,
  ) {
    final originalLength = blocks.length;

    blocks.removeWhere(
      (
        block,
      ) =>
          block.id ==
          blockId,
    );

    return blocks.length !=
        originalLength;
  }

  void clearBlocks() {
    blocks.clear();
  }

  // ============================================================
  // FIND BLOCK
  // ============================================================

  BoardBlock? findBlockById(
    String blockId,
  ) {
    for (final block in blocks) {
      if (block.id ==
          blockId) {
        return block;
      }
    }

    return null;
  }

  // ============================================================
  // BLOCK INDEX
  // ============================================================

  int indexOfBlock(
    String blockId,
  ) {
    return blocks.indexWhere(
      (
        block,
      ) =>
          block.id ==
          blockId,
    );
  }

  // ============================================================
  // REPLACE BLOCK
  // ============================================================

  bool replaceBlock(
    BoardBlock block,
  ) {
    final index = indexOfBlock(
      block.id,
    );

    if (index <
        0) {
      return false;
    }

    blocks[index] = block;

    return true;
  }

  // ============================================================
  // BLOCKS BY TYPE
  // ============================================================

  List<
    BoardBlock
  >
  blocksByType(
    BlockType type,
  ) {
    return blocks
        .where(
          (
            block,
          ) =>
              block.type ==
              type,
        )
        .toList();
  }

  // ============================================================
  // BLOCK COUNT BY TYPE
  // ============================================================

  int countBlocksByType(
    BlockType type,
  ) {
    return blocks
        .where(
          (
            block,
          ) =>
              block.type ==
              type,
        )
        .length;
  }

  // ============================================================
  // DATE MATCH
  // ============================================================

  bool containsDate(
    DateTime value,
  ) {
    return normalizedDate ==
        _dateOnly(
          value,
        );
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RoutineDay copyWith({
    String? id,
    bool removeId = false,
    DateTime? date,
    String? focus,
    List<
      BoardBlock
    >?
    blocks,
  }) {
    return RoutineDay(
      id: removeId
          ? null
          : id ??
                this.id,
      date:
          date ??
          this.date,
      focus:
          focus ??
          this.focus,
      blocks:
          blocks ??
          List<
            BoardBlock
          >.from(
            this.blocks,
          ),
    );
  }

  // ============================================================
  // COPY
  // ============================================================
  //
  // Essa cópia cria um NOVO dia lógico.
  //
  // Por isso o ID do Supabase não é reutilizado.
  //
  // Os blocos também recebem novos IDs através de block.copy().
  //
  // ============================================================

  RoutineDay copy({
    DateTime? date,
  }) {
    return RoutineDay(
      id: null,
      date:
          date ??
          normalizedDate,
      focus: focus,
      blocks: blocks
          .map(
            (
              block,
            ) => block.copy(),
          )
          .toList(),
    );
  }

  // ============================================================
  // SNAPSHOT
  // ============================================================
  //
  // Diferente de copy(), mantém os IDs.
  //
  // Pode ser útil para estado temporário, undo/redo ou comparação.
  //
  // ============================================================

  RoutineDay snapshot() {
    return RoutineDay(
      id: id,
      date: normalizedDate,
      focus: focus,
      blocks:
          List<
            BoardBlock
          >.from(
            blocks,
          ),
    );
  }

  // ============================================================
  // NORMALIZE DATE
  // ============================================================

  static DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    if (other
        is! RoutineDay) {
      return false;
    }

    // ----------------------------------------------------------
    // Se ambos possuem ID do banco, compara pelo ID.
    // ----------------------------------------------------------

    if (id !=
            null &&
        other.id !=
            null) {
      return id ==
          other.id;
    }

    // ----------------------------------------------------------
    // Caso ainda não tenham sido salvos, compara pela data.
    // ----------------------------------------------------------

    return normalizedDate ==
        other.normalizedDate;
  }

  // ============================================================
  // HASH CODE
  // ============================================================

  @override
  int get hashCode {
    if (id !=
        null) {
      return id.hashCode;
    }

    return normalizedDate.hashCode;
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'RoutineDay('
        'id: $id, '
        'date: $normalizedDate, '
        'focus: $focus, '
        'blocks: ${blocks.length}, '
        'tasks: $totalTasks, '
        'completedTasks: $completedTasks, '
        'progress: $progress'
        ')';
  }
}
