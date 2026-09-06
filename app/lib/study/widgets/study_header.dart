import 'package:flutter/material.dart';

// ============================================================
// STUDY HEADER
// ============================================================
//
// O antigo texto introdutório foi removido.
// Mantemos o widget para não quebrar os pontos que ainda usam
// const StudyHeader() na tela de Conhecimento.
//
// ============================================================

class StudyHeader
    extends
        StatelessWidget {
  const StudyHeader({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return const SizedBox.shrink();
  }
}
