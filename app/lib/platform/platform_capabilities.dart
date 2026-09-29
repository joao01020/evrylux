import 'package:flutter/foundation.dart';

/// Fonte única para decisões simples de plataforma na camada de UI.
///
/// A Fase 1 evita espalhar verificações de Web pelo aplicativo. Recursos que
/// exigem implementação própria devem evoluir para portas/adapters nas fases
/// seguintes, em vez de adicionar vários `if (kIsWeb)` nas telas.
abstract final class PlatformCapabilities {
  static bool get isWeb => kIsWeb;
  static bool get supportsDesktopWindows => !kIsWeb;
  static bool get supportsNativeUpdater => !kIsWeb;
  static bool get supportsNativeFileSystem => !kIsWeb;
  static bool get supportsNativeSqlite => !kIsWeb;
}
