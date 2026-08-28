import 'package:flutter/material.dart';

class BrainSaveButton
    extends
        StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const BrainSaveButton({
    super.key,
    required this.isSaving,
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isSaving
            ? null
            : onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.save_outlined,
              ),
        label: Text(
          isSaving
              ? 'Salvando...'
              : 'Salvar em .md',
        ),
      ),
    );
  }
}
