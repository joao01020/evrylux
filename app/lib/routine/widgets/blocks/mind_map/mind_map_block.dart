import 'package:flutter/material.dart';

import '../../../controllers/mind_map_controller.dart';
import '../../../models/board_block.dart';

import 'mind_map_canvas.dart';

class MindMapBlock
    extends
        StatelessWidget {
  const MindMapBlock({
    super.key,
    required this.block,
    required this.controller,
  });

  final BoardBlock block;

  final MindMapController controller;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        4,
        14,
        2,
      ),
      child: MindMapCanvas(
        block: block,
        controller: controller,
      ),
    );
  }
}
