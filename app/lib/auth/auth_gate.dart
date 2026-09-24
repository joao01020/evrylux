import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/data/profile_repository.dart';
import 'screen/complete_profile_screen.dart';
import 'screen/login_screen.dart';

// ============================================================
// AUTHENTICATED BUILDER
// ============================================================

typedef AuthenticatedBuilder = Widget Function(BuildContext context, User user);

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    required this.authenticatedBuilder,
    required this.prepareUser,
    required this.onUserChanged,
  });

  final AuthenticatedBuilder authenticatedBuilder;
  final Future<void> Function(String userId) prepareUser;
  final void Function(String? userId) onUserChanged;

  @override
  State<AuthGate> createState() {
    return _AuthGateState();
  }
}

// ============================================================
// AUTH GATE STATE
// ============================================================

class _AuthGateState extends State<AuthGate> {
  final Stopwatch _startupWatch = Stopwatch()..start();

  void _startupLog(String message) {
    debugPrint(
      '[STARTUP][AUTH] +${_startupWatch.elapsedMilliseconds}ms $message',
    );
  }

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _supabase {
    return Supabase.instance.client;
  }

  // ============================================================
  // PROFILE
  // ============================================================

  late final ProfileRepository _profileRepository;

  // ============================================================
  // AUTH SUBSCRIPTION
  // ============================================================

  StreamSubscription<AuthState>? _authSubscription;

  // ============================================================
  // STATE
  // ============================================================

  User? _user;

  bool _loading = true;

  bool _profileComplete = false;

  String? _errorMessage;

  // ============================================================
  // REQUEST CONTROL
  // ============================================================

  int _profileRequestId = 0;

  String? _backgroundPrepareUserId;
  Future<void>? _backgroundPrepareFuture;
  String? _scheduledPrepareUserId;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileRepository = ProfileRepository(client: _supabase);

    _startupLog('AuthGate criado');
    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> _initialize() async {
    try {
      debugPrint('[AUTH GATE] Inicializando...');
      _startupLog('inicialização iniciada');

      // --------------------------------------------------------
      // Escuta login/logout/refresh.
      // --------------------------------------------------------

      _authSubscription = _supabase.auth.onAuthStateChange.listen(
        _onAuthChanged,
        onError: (Object error) {
          debugPrint('[AUTH GATE] Erro no stream: $error');

          if (!mounted) {
            return;
          }

          setState(() {
            _errorMessage = error.toString();

            _loading = false;
          });
        },
      );

      // --------------------------------------------------------
      // Recupera sessão já existente.
      // --------------------------------------------------------

      final user = _supabase.auth.currentUser;
      _startupLog(
        user == null ? 'sessão local sem usuário' : 'sessão local encontrada',
      );

      debugPrint('[AUTH GATE] Usuário atual: ${user?.id ?? 'null'}');

      _user = user;
      widget.onUserChanged(user?.id);

      // --------------------------------------------------------
      // Não autenticado.
      // --------------------------------------------------------

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _profileComplete = false;
          _errorMessage = null;
        });

        return;
      }

      // --------------------------------------------------------
      // Autenticado.
      // Agora precisamos descobrir se o perfil está completo.
      // --------------------------------------------------------

      await _loadProfile(user);
    } catch (error) {
      debugPrint('[AUTH GATE] Erro ao inicializar: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();

        _loading = false;
      });
    }
  }

  // ============================================================
  // AUTH CHANGED
  // ============================================================

  Future<void> _onAuthChanged(AuthState state) async {
    if (!mounted) {
      return;
    }

    final user = state.session?.user;

    debugPrint('[AUTH GATE] Evento: ${state.event}');

    debugPrint('[AUTH GATE] Usuário: ${user?.id ?? 'null'}');

    // O Supabase normalmente emite initialSession logo depois que
    // currentUser já foi lido em _initialize(). Nesse caso, não
    // repetimos o mesmo carregamento de perfil/startup da conta.
    if (state.event == AuthChangeEvent.initialSession &&
        user != null &&
        _user?.id == user.id) {
      _startupLog('initialSession duplicada ignorada');
      return;
    }

    // ----------------------------------------------------------
    // Logout
    // ----------------------------------------------------------

    if (user == null) {
      widget.onUserChanged(null);
      _profileRequestId++;
      _scheduledPrepareUserId = null;

      setState(() {
        _user = null;

        _profileComplete = false;

        _loading = false;

        _errorMessage = null;
      });

      return;
    }

    // ----------------------------------------------------------
    // Login / sessão restaurada
    // ----------------------------------------------------------

    widget.onUserChanged(user.id);

    setState(() {
      _user = user;

      _loading = true;

      _profileComplete = false;

      _errorMessage = null;
    });

    await _loadProfile(user);
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<void> _loadProfile(User user) async {
    final requestId = ++_profileRequestId;

    try {
      // A preparação privada da conta (Vault, migração, E2EE e sync)
      // NÃO participa do caminho crítico da primeira tela útil.
      // Primeiro validamos o perfil e liberamos a interface. Depois que
      // o frame autenticado for renderizado, iniciamos esse trabalho.

      if (requestId != _profileRequestId ||
          !mounted ||
          _supabase.auth.currentUser?.id != user.id) {
        return;
      }

      debugPrint('[AUTH GATE] Verificando perfil...');

      debugPrint('[AUTH GATE] User ID: ${user.id}');

      _startupLog('getProfile iniciado');
      final profileStage = Stopwatch()..start();
      final profile = await _profileRepository.getProfile(user.id);
      _startupLog(
        'getProfile concluído (${profileStage.elapsedMilliseconds}ms)',
      );

      // --------------------------------------------------------
      // Uma nova requisição começou antes desta terminar.
      // Ignoramos esta resposta antiga.
      // --------------------------------------------------------

      if (requestId != _profileRequestId) {
        return;
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // Confere se o usuário ainda é o mesmo.
      // --------------------------------------------------------

      final currentUser = _supabase.auth.currentUser;

      if (currentUser == null || currentUser.id != user.id) {
        return;
      }

      final profileComplete = profile != null && profile.hasName;

      debugPrint('[AUTH GATE] Perfil encontrado: ${profile != null}');

      debugPrint('[AUTH GATE] Nome: ${profile?.fullName ?? 'não definido'}');

      debugPrint('[AUTH GATE] Perfil completo: $profileComplete');

      _startupLog('interface autenticada liberada');

      setState(() {
        _user = currentUser;

        _profileComplete = profileComplete;

        _loading = false;

        _errorMessage = null;
      });

      _schedulePrepareUserAfterAuthenticatedFrame(currentUser.id);
    } on PostgrestException catch (error) {
      if (requestId != _profileRequestId ||
          _supabase.auth.currentUser?.id != user.id) {
        return;
      }

      debugPrint('[AUTH GATE] Erro Supabase ao buscar perfil.');

      debugPrint('[AUTH GATE] Code: ${error.code}');

      debugPrint('[AUTH GATE] Message: ${error.message}');

      debugPrint('[AUTH GATE] Details: ${error.details}');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _errorMessage = _translateProfileError(error);
      });
    } catch (error) {
      if (requestId != _profileRequestId) {
        return;
      }

      if (_supabase.auth.currentUser?.id != user.id) return;
      debugPrint('[AUTH GATE] Erro ao verificar perfil: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _errorMessage = 'Não foi possível carregar seu perfil.\n\n$error';
      });
    }
  }

  // ============================================================
  // SCHEDULE PREPARE USER AFTER AUTHENTICATED FRAME
  // ============================================================

  void _schedulePrepareUserAfterAuthenticatedFrame(String userId) {
    if (_scheduledPrepareUserId == userId ||
        (_backgroundPrepareUserId == userId &&
            _backgroundPrepareFuture != null)) {
      return;
    }

    _scheduledPrepareUserId = userId;
    _startupLog('prepareUser agendado após frame autenticado');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_scheduledPrepareUserId != userId ||
          _supabase.auth.currentUser?.id != userId) {
        return;
      }

      _scheduledPrepareUserId = null;
      _startupLog('frame autenticado renderizado; iniciando prepareUser');
      _startPrepareUserInBackground(userId);
    });
  }

  // ============================================================
  // PREPARE USER IN BACKGROUND
  // ============================================================

  void _startPrepareUserInBackground(String userId) {
    if (_backgroundPrepareUserId == userId &&
        _backgroundPrepareFuture != null) {
      _startupLog('prepareUser já está em andamento; reutilizando');
      return;
    }

    _backgroundPrepareUserId = userId;
    final stage = Stopwatch()..start();
    _startupLog('prepareUser em background iniciado');

    late final Future<void> future;
    future = widget
        .prepareUser(userId)
        .then<void>((_) {
          _startupLog(
            'prepareUser em background concluído (${stage.elapsedMilliseconds}ms)',
          );
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('[AUTH GATE] prepareUser em background falhou: $error');
          _startupLog(
            'prepareUser em background falhou (${stage.elapsedMilliseconds}ms)',
          );
        })
        .whenComplete(() {
          if (identical(_backgroundPrepareFuture, future)) {
            _backgroundPrepareFuture = null;
          }
        });

    _backgroundPrepareFuture = future;
    unawaited(future);
  }

  // ============================================================
  // PROFILE COMPLETED
  // ============================================================

  Future<void> _onProfileCompleted() async {
    debugPrint('[AUTH GATE] Nome salvo. Recarregando perfil...');

    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _user = null;

        _profileComplete = false;

        _loading = false;

        _errorMessage = null;
      });

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _user = user;

      _loading = true;

      _errorMessage = null;
    });

    await _loadProfile(user);
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> _retry() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _loading = true;

      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _user = null;

          _profileComplete = false;

          _loading = false;

          _errorMessage = null;
        });

        return;
      }

      _user = user;

      await _loadProfile(user);
    } catch (error) {
      debugPrint('[AUTH GATE] Erro ao tentar novamente: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;

        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // TRANSLATE PROFILE ERROR
  // ============================================================

  String _translateProfileError(PostgrestException error) {
    final code = error.code;

    final message = error.message.toLowerCase();

    // ----------------------------------------------------------
    // Tabela não existe
    // ----------------------------------------------------------

    if (code == '42P01' ||
        message.contains('relation') && message.contains('does not exist')) {
      return 'A tabela "profiles" ainda não existe no Supabase.';
    }

    // ----------------------------------------------------------
    // Coluna não existe
    // ----------------------------------------------------------

    if (code == '42703' ||
        message.contains('column') && message.contains('does not exist')) {
      return 'A estrutura da tabela "profiles" não corresponde ao aplicativo.';
    }

    // ----------------------------------------------------------
    // RLS
    // ----------------------------------------------------------

    if (code == '42501' || message.contains('row-level security')) {
      return 'O Supabase bloqueou o acesso ao perfil pelas regras de segurança (RLS).';
    }

    return 'Não foi possível carregar seu perfil.\n\n${error.message}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _profileRequestId++;

    _authSubscription?.cancel();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loading) {
      return const _AuthLoadingScreen();
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage != null) {
      return _AuthErrorScreen(message: _errorMessage!, onRetry: _retry);
    }

    // ==========================================================
    // NÃO AUTENTICADO
    // ==========================================================

    final user = _user;

    if (user == null) {
      return const LoginScreen();
    }

    // ==========================================================
    // PERFIL INCOMPLETO
    // ==========================================================

    if (!_profileComplete) {
      return CompleteProfileScreen(
        repository: _profileRepository,
        onCompleted: _onProfileCompleted,
      );
    }

    // ==========================================================
    // AUTENTICADO + PERFIL COMPLETO
    // ==========================================================

    return widget.authenticatedBuilder(context, user);
  }
}

// ============================================================
// LOADING SCREEN
// ============================================================

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7FBF1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF3B6939), strokeWidth: 2),
            SizedBox(height: 16),
            Text(
              'Carregando sua conta...',
              style: TextStyle(color: Color(0xFF68746B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR SCREEN
// ============================================================

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message, required this.onRetry});

  final String message;

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF1),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE3B7B7)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // ICON
                  // ==================================================
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Color(0xFFB3261E),
                    size: 36,
                  ),

                  const SizedBox(height: 16),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    'Não foi possível continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF172019),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ==================================================
                  // ERROR
                  // ==================================================
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF68746B),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // RETRY
                  // ==================================================
                  ElevatedButton.icon(
                    onPressed: () {
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFFBCF0B4),
                      foregroundColor: const Color(0xFF3B6939),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Tentar novamente',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
