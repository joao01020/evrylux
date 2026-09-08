import 'package:flutter/material.dart';

/// Ação de entrada da criação. Não conhece banco, Vault ou sincronização.
class BrainAddKnowledgeButton extends StatelessWidget {
  const BrainAddKnowledgeButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Novo conhecimento',
      child: IconButton(
        onPressed: isSaving ? null : onPressed,
        icon: const Icon(Icons.add_rounded),
      ),
    );
  }
}
