import 'dart:math';

import 'package:flutter/material.dart';

import 'block_type.dart' as block_model;
import 'check_item.dart' as check_model;
import 'content_status.dart' as content_model;
import 'mind_map_node.dart' as mind_map_model;

class BoardBlock {
  BoardBlock({
    required this.id,
    required this.type,
    required this.title,
    this.content = '',
    this.status = content_model.ContentStatus.idea,
    this.position,
    List<
      check_model.CheckItem
    >?
    items,
    List<
      mind_map_model.MindMapNode
    >?
    mindNodes,
  }) : items =
           items ??
           [],
       mindNodes =
           mindNodes ??
           [];

  // ============================================================
  // FACTORY - TASK
  // ============================================================

  factory BoardBlock.task({
    required String title,
    required List<
      check_model.CheckItem
    >
    items,
  }) {
    return BoardBlock(
      id: createId(),
      type: block_model.BlockType.tasks,
      title: title,
      items: items,
    );
  }

  // ============================================================
  // FACTORY - NOTE
  // ============================================================

  factory BoardBlock.note({
    required String title,
    required String content,
  }) {
    return BoardBlock(
      id: createId(),
      type: block_model.BlockType.note,
      title: title,
      content: content,
    );
  }

  // ============================================================
  // FACTORY - CONTENT
  // ============================================================

  factory BoardBlock.content({
    required String title,
    required String content,
    content_model.ContentStatus status = content_model.ContentStatus.idea,
  }) {
    return BoardBlock(
      id: createId(),
      type: block_model.BlockType.content,
      title: title,
      content: content,
      status: status,
    );
  }

  // ============================================================
  // FACTORY - PHOTO
  // ============================================================

  factory BoardBlock.photo({
    required String title,
    required String reference,
  }) {
    return BoardBlock(
      id: createId(),
      type: block_model.BlockType.photo,
      title: title,
      content: reference,
    );
  }

  // ============================================================
  // FACTORY - MIND MAP
  // ============================================================

  factory BoardBlock.mindMap({
    required String title,
    List<
      mind_map_model.MindMapNode
    >?
    nodes,
  }) {
    return BoardBlock(
      id: createId(),
      type: block_model.BlockType.mindMap,
      title: title,
      mindNodes: nodes,
    );
  }

  // ============================================================
  // FIELDS
  // ============================================================

  final String id;

  final block_model.BlockType type;

  String title;

  String content;

  content_model.ContentStatus status;

  Offset? position;

  final List<
    check_model.CheckItem
  >
  items;

  final List<
    mind_map_model.MindMapNode
  >
  mindNodes;

  // ============================================================
  // UI
  // ============================================================

  IconData get icon => type.icon;

  Color get color => type.color;

  // ============================================================
  // TYPE HELPERS
  // ============================================================

  bool get isTask =>
      type ==
      block_model.BlockType.tasks;

  bool get isNote =>
      type ==
      block_model.BlockType.note;

  bool get isContent =>
      type ==
      block_model.BlockType.content;

  bool get isPhoto =>
      type ==
      block_model.BlockType.photo;

  bool get isMindMap =>
      type ==
      block_model.BlockType.mindMap;

  bool get hasPosition =>
      position !=
      null;

  // ============================================================
  // TASK STATS
  // ============================================================

  int get totalTasks => items.length;

  int get completedTasks {
    return items
        .where(
          (
            item,
          ) => item.done,
        )
        .length;
  }

  double get taskProgress {
    if (items.isEmpty) {
      return 0;
    }

    return completedTasks /
        items.length;
  }

  // ============================================================
  // TASK ACTIONS
  // ============================================================

  void addTask(
    check_model.CheckItem item,
  ) {
    items.add(
      item,
    );
  }

  bool removeTask(
    check_model.CheckItem item,
  ) {
    return items.remove(
      item,
    );
  }

  void clearTasks() {
    items.clear();
  }

  // ============================================================
  // MIND MAP ACTIONS
  // ============================================================

  void addMindMapNode(
    mind_map_model.MindMapNode node,
  ) {
    mindNodes.add(
      node,
    );
  }

  bool removeMindMapNode(
    String nodeId,
  ) {
    final originalLength = mindNodes.length;

    mindNodes.removeWhere(
      (
        node,
      ) =>
          node.id ==
          nodeId,
    );

    return mindNodes.length !=
        originalLength;
  }

  void clearMindMapNodes() {
    mindNodes.clear();
  }

  // ============================================================
  // UPDATE
  // ============================================================

  void updateTitle(
    String value,
  ) {
    title = value;
  }

  void updateContent(
    String value,
  ) {
    content = value;
  }

  void updateStatus(
    content_model.ContentStatus value,
  ) {
    status = value;
  }

  void updatePosition(
    Offset? value,
  ) {
    position = value;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BoardBlock copyWith({
    String? id,
    block_model.BlockType? type,
    String? title,
    String? content,
    content_model.ContentStatus? status,
    Offset? position,
    bool removePosition = false,
    List<
      check_model.CheckItem
    >?
    items,
    List<
      mind_map_model.MindMapNode
    >?
    mindNodes,
  }) {
    return BoardBlock(
      id:
          id ??
          this.id,
      type:
          type ??
          this.type,
      title:
          title ??
          this.title,
      content:
          content ??
          this.content,
      status:
          status ??
          this.status,
      position: removePosition
          ? null
          : position ??
                this.position,
      items:
          items ??
          List<
            check_model.CheckItem
          >.from(
            this.items,
          ),
      mindNodes:
          mindNodes ??
          List<
            mind_map_model.MindMapNode
          >.from(
            this.mindNodes,
          ),
    );
  }

  // ============================================================
  // DUPLICATE BLOCK
  // ============================================================

  BoardBlock copy() {
    final copiedBlockId = createId();

    final copiedNodeIds =
        <
          String,
          String
        >{};

    // ----------------------------------------------------------
    // NEW NODE UUIDS
    // ----------------------------------------------------------

    for (final node in mindNodes) {
      copiedNodeIds[node.id] = createId();
    }

    // ----------------------------------------------------------
    // COPY TASKS
    // ----------------------------------------------------------

    final copiedItems = items.map(
      (
        item,
      ) {
        return check_model.CheckItem(
          item.text,
          done: item.done,
        );
      },
    ).toList();

    // ----------------------------------------------------------
    // COPY MIND MAP
    // ----------------------------------------------------------

    final copiedNodes = mindNodes.map(
      (
        node,
      ) {
        final copiedParentId =
            node.parentId ==
                null
            ? null
            : copiedNodeIds[node.parentId];

        return mind_map_model.MindMapNode(
          id: copiedNodeIds[node.id]!,
          parentId: copiedParentId,
          label: node.label,
          position:
              node.position +
              const Offset(
                8,
                8,
              ),
          isRoot: node.isRoot,
          sourcePort: node.sourcePort,
          targetPort: node.targetPort,
          isEditing: false,
        );
      },
    ).toList();

    // ----------------------------------------------------------
    // NEW BLOCK
    // ----------------------------------------------------------

    return BoardBlock(
      id: copiedBlockId,
      type: type,
      title: '$title (cópia)',
      content: content,
      status: status,
      position:
          position ==
              null
          ? null
          : Offset(
              position!.dx +
                  24,
              position!.dy +
                  24,
            ),
      items: copiedItems,
      mindNodes: copiedNodes,
    );
  }

  // ============================================================
  // UUID
  // ============================================================
  //
  // Gera UUID v4 válido para PostgreSQL / Supabase.
  //
  // Exemplo:
  //
  // 550e8400-e29b-41d4-a716-446655440000
  //
  // Não depende do package uuid.
  //
  // ============================================================

  static String createId() {
    final random = Random.secure();

    final bytes =
        List<
          int
        >.generate(
          16,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    // UUID version 4.
    bytes[6] =
        (bytes[6] &
            0x0F) |
        0x40;

    // RFC 4122 variant.
    bytes[8] =
        (bytes[8] &
            0x3F) |
        0x80;

    final hex = bytes
        .map(
          (
            byte,
          ) => byte
              .toRadixString(
                16,
              )
              .padLeft(
                2,
                '0',
              ),
        )
        .join();

    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }

  // ============================================================
  // VALID UUID
  // ============================================================

  static bool isValidUuid(
    String value,
  ) {
    final normalized = value.trim();

    return RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    ).hasMatch(
      normalized,
    );
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    return identical(
          this,
          other,
        ) ||
        other
                is BoardBlock &&
            other.id ==
                id;
  }

  @override
  int get hashCode => id.hashCode;

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'BoardBlock('
        'id: $id, '
        'type: ${type.databaseValue}, '
        'title: $title, '
        'content: ${content.length} chars, '
        'items: ${items.length}, '
        'mindNodes: ${mindNodes.length}, '
        'position: $position'
        ')';
  }
}
