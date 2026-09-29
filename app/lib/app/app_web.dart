import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_gate.dart';
import '../core/theme/app_theme.dart';
import '../profile/security/devices/repositories/account_device_repository.dart';
import '../profile/security/devices/services/account_device_identity_service.dart';
import '../profile/security/devices/services/account_device_presence_service.dart';
import '../welcome/welcome_screen_web.dart';
import 'widgets/web_global_header_shell.dart';

final AccountDeviceIdentityService _webAccountDeviceIdentityService =
    AccountDeviceIdentityService();

final AccountDeviceRepository _webAccountDeviceRepository =
    AccountDeviceRepository(client: Supabase.instance.client);

final AccountDevicePresenceService _webAccountDevicePresenceService =
    AccountDevicePresenceService(
      client: Supabase.instance.client,
      repository: _webAccountDeviceRepository,
      identityService: _webAccountDeviceIdentityService,
      heartbeatInterval: const Duration(minutes: 1),
    );

Future<void> _startWebAccountDevicePresence() async {
  final client = Supabase.instance.client;
  final user = client.auth.currentUser;
  final session = client.auth.currentSession;

  if (user == null || session == null) {
    _webAccountDevicePresenceService.stop();

    debugPrint('[ACCOUNT DEVICE][WEB] presença aguardando sessão autenticada.');

    return;
  }

  try {
    final deviceId = await _webAccountDeviceIdentityService
        .getOrCreateDeviceId();

    debugPrint(
      '[ACCOUNT DEVICE][WEB] iniciando presença '
      'user=${user.id} device=$deviceId',
    );

    await _webAccountDevicePresenceService.start(
      onRevoked: () async {
        _webAccountDevicePresenceService.stop();

        try {
          await client.auth.signOut(scope: SignOutScope.local);
        } catch (error) {
          debugPrint(
            '[ACCOUNT DEVICE][WEB] '
            'Erro encerrando sessão revogada: $error',
          );
        }
      },
    );

    // Confirmação explícita logo após o start.
    //
    // Isso evita depender apenas do heartbeat periódico e também deixa no
    // console uma evidência inequívoca de que o navegador entrou em
    // user_devices.
    final registered = await _webAccountDeviceRepository.registerDevice(
      deviceId: deviceId,
      deviceName: _webAccountDeviceIdentityService.deviceName,
      platform: _webAccountDeviceIdentityService.platformLabel,
      appVersion: 'Web',
    );

    final devices = await _webAccountDeviceRepository.listActiveDevices();

    debugPrint(
      '[ACCOUNT DEVICE][WEB] registrado=$registered '
      'dispositivosAtivos=${devices.length}',
    );
  } catch (error, stackTrace) {
    debugPrint('[ACCOUNT DEVICE][WEB] presença indisponível: $error');
    debugPrint('$stackTrace');
  }
}

final GlobalKey<NavigatorState> webNavigatorKey = GlobalKey<NavigatorState>();

class EvryluxWebApp extends StatelessWidget {
  const EvryluxWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _WebAccountPresenceBridge(
      child: MaterialApp(
        title: 'EVRYLUX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        navigatorKey: webNavigatorKey,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        builder: (context, child) {
          return WebGlobalHeaderShell(
            navigatorKey: webNavigatorKey,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: AuthGate(
          prepareUser: _prepareWebUser,
          onUserChanged: _onWebUserChanged,
          authenticatedBuilder: (context, user) {
            return const WebWelcomeScreen();
          },
        ),
      ),
    );
  }

  static Future<void> _prepareWebUser(String userId) async {
    await _startWebAccountDevicePresence();
  }

  static void _onWebUserChanged(String? userId) {
    if (userId == null) {
      _webAccountDevicePresenceService.stop();
      return;
    }

    unawaited(_startWebAccountDevicePresence());
  }
}

/// Garante registro da sessão Web mesmo quando o AuthGate já inicia com uma
/// sessão persistida e nenhum evento de login novo é disparado.
///
/// Esse era o ponto que fazia o navegador ficar fora de `user_devices` em
/// alguns boots/deploys.
class _WebAccountPresenceBridge extends StatefulWidget {
  const _WebAccountPresenceBridge({required this.child});

  final Widget child;

  @override
  State<_WebAccountPresenceBridge> createState() =>
      _WebAccountPresenceBridgeState();
}

class _WebAccountPresenceBridgeState extends State<_WebAccountPresenceBridge>
    with WidgetsBindingObserver {
  StreamSubscription<AuthState>? _authSubscription;

  Timer? _bootRetryTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      authState,
    ) {
      if (authState.session == null) {
        _webAccountDevicePresenceService.stop();
        return;
      }

      unawaited(_startWebAccountDevicePresence());
    });

    // Sessão restaurada do storage pode já existir antes de o AuthGate
    // registrar listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startWebAccountDevicePresence());
    });

    // Retry curto cobre a janela em que a sessão persistida ainda está sendo
    // restaurada pelo supabase_flutter durante o primeiro frame.
    _bootRetryTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_startWebAccountDevicePresence());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_startWebAccountDevicePresence());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _bootRetryTimer?.cancel();
    _authSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
