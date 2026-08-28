import 'package:flutter/material.dart';

import '../../models/block_type.dart' as block_type_model;
import '../../models/board_block.dart' as board_model;
import '../../models/check_item.dart' as check_item_model;
import '../../models/content_status.dart' as content_status_model;
import '../dtos/board_block_dto.dart';
import 'mind_map_node_mapper.dart';

abstract final class BoardBlockMapper {
  static board_model.BoardBlock toModel(
    BoardBlockDto dto,
  ) {
    final hasPosition =
        dto.positionX !=
            null &&
        dto.positionY !=
            null;

    return board_model.BoardBlock(
      id: dto.id,
      type: block_type_model.BlockType.fromDatabase(
        dto.type,
      ),
      title: dto.title,
      content: dto.content,
      status: content_status_model.ContentStatus.fromDatabase(
        dto.contentStatus,
      ),
      position: hasPosition
          ? Offset(
              dto.positionX!,
              dto.positionY!,
            )
          : null,
      items: dto.items
          .map(
            _checkItemToModel,
          )
          .toList(),
      mindNodes: MindMapNodeMapper.toModelList(
        dto.mindMapNodes,
      ),
    );
  }

  static BoardBlockDto toDto({
    required board_model.BoardBlock model,
    String? routineDayId,
    double? width,
  }) {
    return BoardBlockDto(
      id: model.id,
      routineDayId: routineDayId,
      type: model.type.databaseValue,
      title: model.title,
      content: model.content,
      contentStatus: model.status.databaseValue,
      positionX: model.position?.dx,
      positionY: model.position?.dy,
      width: width,
      items: model.items
          .asMap()
          .entries
          .map(
            (
              entry,
            ) => _checkItemToDto(
              entry.value,
              blockId: model.id,
              position: entry.key,
            ),
          )
          .toList(),
      mindMapNodes: MindMapNodeMapper.toDtoList(
        models: model.mindNodes,
        blockId: model.id,
      ),
    );
  }

  static List<
    board_model.BoardBlock
  >
  toModelList(
    Iterable<
      BoardBlockDto
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
    BoardBlockDto
  >
  toDtoList({
    required Iterable<
      board_model.BoardBlock
    >
    models,
    String? routineDayId,
  }) {
    return models
        .map(
          (
            model,
          ) => toDto(
            model: model,
            routineDayId: routineDayId,
          ),
        )
        .toList();
  }

  static check_item_model.CheckItem _checkItemToModel(
    CheckItemDto dto,
  ) {
    return check_item_model.CheckItem(
      dto.text,
      id: dto.id,
      done: dto.completed,
    );
  }

  static CheckItemDto _checkItemToDto(
    check_item_model.CheckItem item, {
    required String blockId,
    required int position,
  }) {
    return CheckItemDto(
      id: item.id,
      blockId: blockId,
      text: item.text,
      completed: item.done,
      position: position,
    );
  }
}
