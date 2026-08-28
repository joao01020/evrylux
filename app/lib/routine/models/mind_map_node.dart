import 'package:flutter/material.dart';

import 'node_port.dart';

class MindMapNode {
  MindMapNode({
    required this.id,
    required this.label,
    required this.position,
    this.parentId,
    this.isRoot = false,
    this.sourcePort = NodePort.right,
    this.targetPort = NodePort.left,
    this.isEditing = false,
  });

  final String id;
  final String? parentId;
  final bool isRoot;
  final NodePort sourcePort;
  final NodePort targetPort;

  String label;
  Offset position;
  bool isEditing;

  double get positionX => position.dx;
  double get positionY => position.dy;

  MindMapNode copyWith({
    String? id,
    String? parentId,
    bool removeParent = false,
    String? label,
    Offset? position,
    bool? isRoot,
    NodePort? sourcePort,
    NodePort? targetPort,
    bool? isEditing,
  }) {
    return MindMapNode(
      id:
          id ??
          this.id,
      parentId: removeParent
          ? null
          : parentId ??
                this.parentId,
      label:
          label ??
          this.label,
      position:
          position ??
          this.position,
      isRoot:
          isRoot ??
          this.isRoot,
      sourcePort:
          sourcePort ??
          this.sourcePort,
      targetPort:
          targetPort ??
          this.targetPort,
      isEditing:
          isEditing ??
          this.isEditing,
    );
  }

  Map<
    String,
    Object?
  >
  toMap({
    required String blockId,
  }) {
    return {
      'id': id,
      'block_id': blockId,
      'parent_id': parentId,
      'label': label,
      'position_x': position.dx,
      'position_y': position.dy,
      'is_root': isRoot,
      'source_port': sourcePort.databaseValue,
      'target_port': targetPort.databaseValue,
    };
  }

  factory MindMapNode.fromMap(
    Map<
      String,
      Object?
    >
    map,
  ) {
    return MindMapNode(
      id:
          map['id']
              as String,
      parentId:
          map['parent_id']
              as String?,
      label:
          map['label']
              as String? ??
          '',
      position: Offset(
        (map['position_x']
                    as num?)
                ?.toDouble() ??
            0,
        (map['position_y']
                    as num?)
                ?.toDouble() ??
            0,
      ),
      isRoot:
          map['is_root']
              as bool? ??
          false,
      sourcePort: NodePort.fromDatabase(
        map['source_port']
                as String? ??
            'right',
      ),
      targetPort: NodePort.fromDatabase(
        map['target_port']
                as String? ??
            'left',
      ),
    );
  }

  @override
  bool operator ==(
    Object other,
  ) {
    return identical(
          this,
          other,
        ) ||
        other
                is MindMapNode &&
            other.id ==
                id;
  }

  @override
  int get hashCode => id.hashCode;
}
