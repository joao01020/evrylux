import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../auth/auth_gate.dart';
import '../core/theme/app_theme.dart';
import '../welcome/welcome_screen_web.dart';
import 'widgets/web_global_header_shell.dart';

final GlobalKey<NavigatorState> webNavigatorKey =
    GlobalKey<NavigatorState>();

/// Entrada Web da mesma aplicação EVRYLUX.
///
/// O header global Web replica o mesmo shell visual do app desktop e é
/// instalado no MaterialApp.builder. Assim ele permanece visível em todas
/// as rotas abertas pelo Navigator sem precisar duplicar header nas telas.
class EvryluxWebApp extends StatelessWidget {
  const EvryluxWebApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EVRYLUX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      navigatorKey: webNavigatorKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      builder: (context, child) {
        return WebGlobalHeaderShell(
          navigatorKey: webNavigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AuthGate(
        prepareUser: _prepareWebUser,
        onUserChanged: _onWebUserChanged,
        authenticatedBuilder: (
          context,
          user,
        ) {
          return const WebWelcomeScreen();
        },
      ),
    );
  }

  static Future<void> _prepareWebUser(String userId) async {
    // Supabase/Auth já foi inicializado no bootstrap.
  }

  static void _onWebUserChanged(String? userId) {
    // Mantém o contrato do AuthGate sem importar dependências nativas.
  }
}
