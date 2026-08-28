import 'package:flutter/material.dart';

abstract final class RoutineColors {
  // ============================================================
  // BACKGROUND
  // ============================================================

  static const Color background = Color(
    0xFF090A0D,
  );

  static const Color backgroundSoft = Color(
    0xFF0D0F14,
  );

  // ============================================================
  // SURFACES
  // ============================================================

  static const Color surface = Color(
    0xFF101217,
  );

  static const Color surfaceSoft = Color(
    0xFF13161C,
  );

  static const Color surfaceLight = Color(
    0xFF171A22,
  );

  static const Color surfaceElevated = Color(
    0xFF1C2029,
  );

  // ============================================================
  // BORDER
  // ============================================================

  static const Color border = Color(
    0xFF252832,
  );

  static const Color borderSoft = Color(
    0xFF1D212A,
  );

  static const Color borderStrong = Color(
    0xFF343946,
  );

  // ============================================================
  // PRIMARY
  // ============================================================

  static const Color primary = Color(
    0xFF7C5CFF,
  );

  static const Color primaryLight = Color(
    0xFFA18CFF,
  );

  static const Color primaryDark = Color(
    0xFF6244DD,
  );

  static const Color primarySurface = Color(
    0xFF201A3A,
  );

  // ============================================================
  // ACCENT
  // ============================================================

  static const Color accent = Color(
    0xFF8BFFB0,
  );

  static const Color accentSoft = Color(
    0xFF1B3325,
  );

  // ============================================================
  // TEXT
  // ============================================================

  static const Color textPrimary = Color(
    0xFFF5F7FA,
  );

  static const Color textSecondary = Color(
    0xFF9BA1AD,
  );

  static const Color textMuted = Color(
    0xFF686F7C,
  );

  static const Color textDisabled = Color(
    0xFF4B505A,
  );

  // ============================================================
  // STATUS
  // ============================================================

  static const Color success = Color(
    0xFF8BFFB0,
  );

  static const Color warning = Color(
    0xFFFFD27A,
  );

  static const Color danger = Color(
    0xFFFF6B7A,
  );

  static const Color info = Color(
    0xFF70B7FF,
  );

  // ============================================================
  // BLOCK TYPES
  // ============================================================

  static const Color note = Color(
    0xFFFFD27A,
  );

  static const Color task = Color(
    0xFF8BFFB0,
  );

  static const Color content = Color(
    0xFF70B7FF,
  );

  static const Color photo = Color(
    0xFFFF8EC7,
  );

  static const Color mindMap = Color(
    0xFFA18CFF,
  );

  // ============================================================
  // CALENDAR
  // ============================================================

  static const Color calendarSelected = primary;

  static const Color calendarToday = primaryLight;

  static const Color calendarInactive = textMuted;

  // ============================================================
  // MIND MAP
  // ============================================================

  static const Color mindMapBackground = Color(
    0xFF0D0F14,
  );

  static const Color mindMapNode = Color(
    0xFF171A22,
  );

  static const Color mindMapNodeSelected = Color(
    0xFF201A3A,
  );

  static const Color mindMapConnection = Color(
    0xFF686F7C,
  );

  static const Color mindMapPort = Color(
    0xFFA18CFF,
  );

  // ============================================================
  // OVERLAYS
  // ============================================================

  static const Color overlay = Color(
    0x99000000,
  );

  static const Color transparent = Colors.transparent;

  // ============================================================
  // HELPERS
  // ============================================================

  static Color primaryWithOpacity(
    double opacity,
  ) {
    return primary.withValues(
      alpha: opacity,
    );
  }

  static Color surfaceWithOpacity(
    double opacity,
  ) {
    return surface.withValues(
      alpha: opacity,
    );
  }

  static Color borderWithOpacity(
    double opacity,
  ) {
    return border.withValues(
      alpha: opacity,
    );
  }

  static Color textWithOpacity(
    double opacity,
  ) {
    return textPrimary.withValues(
      alpha: opacity,
    );
  }
}
