import 'package:flutter/material.dart';

import '../controllers/body_map_controller.dart';
import '../services/body_map_service.dart';
import 'body_map_dialog.dart';

// ============================================================
// BODY MAP LAUNCHER BUTTON
// ============================================================
//
// Botão responsável por abrir o modal do mapa corporal.
//
// Pode ser usado:
//
// - como ícone junto aos outros botões da tela de treino;
// - como botão completo com texto.
//
// ============================================================

class BodyMapLauncherButton
    extends
        StatelessWidget {
  const BodyMapLauncherButton({
    super.key,
    this.controller,
    this.service,
    this.iconOnly = true,
    this.tooltip = 'Mapa corporal',
  });

  final BodyMapController? controller;

  final BodyMapService? service;

  final bool iconOnly;

  final String tooltip;

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  Future<
    void
  >
  _open(
    BuildContext context,
  ) async {
    await BodyMapDialog.show(
      context,
      controller: controller,
      service: service,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (iconOnly) {
      return Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _open(
                context,
              );
            },
            borderRadius: BorderRadius.circular(
              12,
            ),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: const Icon(
                Icons.accessibility_new_rounded,
                color: _primaryDark,
                size: 21,
              ),
            ),
          ),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () {
        _open(
          context,
        );
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: _primaryDark,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 13,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          side: const BorderSide(
            color: _border,
          ),
        ),
      ),
      icon: const Icon(
        Icons.accessibility_new_rounded,
        size: 19,
      ),
      label: const Text(
        'Mapa corporal',
        style: TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
