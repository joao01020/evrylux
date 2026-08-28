import 'package:flutter/material.dart';

import '../../models/mind_map_node.dart';
import '../../models/node_port.dart';
import '../dtos/mind_map_node_dto.dart';

abstract final class MindMapNodeMapper {
  static MindMapNode toModel(
    MindMapNodeDto dto,
  ) {
    return MindMapNode(
      id: dto.id,
      parentId: dto.parentId,
      label: dto.label,
      position: Offset(
        dto.positionX,
        dto.positionY,
      ),
      isRoot: dto.isRoot,
      sourcePort: NodePort.fromDatabase(
        dto.sourcePort,
      ),
      targetPort: NodePort.fromDatabase(
        dto.targetPort,
      ),
    );
  }

  static MindMapNodeDto toDto({
    required MindMapNode model,
    required String blockId,
  }) {
    return MindMapNodeDto(
      id: model.id,
      blockId: blockId,
      parentId: model.parentId,
      label: model.label,
      positionX: model.position.dx,
      positionY: model.position.dy,
      isRoot: model.isRoot,
      sourcePort: model.sourcePort.databaseValue,
      targetPort: model.targetPort.databaseValue,
    );
  }

  static List<
    MindMapNode
  >
  toModelList(
    Iterable<
      MindMapNodeDto
    >
    dtos,
  ) {
    return dtos
        .map(
          toModel,
        )
        .toList();
  }

  static List<
    MindMapNodeDto
  >
  toDtoList({
    required Iterable<
      MindMapNode
    >
    models,
    required String blockId,
  }) {
    return models
        .map(
          (
            model,
          ) => toDto(
            model: model,
            blockId: blockId,
          ),
        )
        .toList();
  }
}
