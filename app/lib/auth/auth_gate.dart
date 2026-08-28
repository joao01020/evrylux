import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/data/profile_repository.dart';
import 'screen/complete_profile_screen.dart';
import 'screen/login_screen.dart';

// ============================================================
// AUTHENTICATED BUILDER
// ============================================================

typedef AuthenticatedBuilder =
    Widget Function(
      BuildContext context,
      User user,
    );

// ============================================================
// AUTH GATE
// ============================================================

class AuthGate
    extends
        StatefulWidget {
  const AuthGate({
    super.key,
    required this.authenticatedBuilder,
  });

  final AuthenticatedBuilder authenticatedBuilder;

  @override
  State<
    AuthGate
  >
  createState() {
    return _AuthGateState();
  }
}

// ============================================================
// AUTH GATE STATE
// ============================================================

class _AuthGateState
    extends
        State<
          AuthGate
        > {
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

  StreamSubscription<
    AuthState
  >?
  _authSubscription;

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

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileRepository = ProfileRepository(
      client: _supabase,
    );

    _initialize();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    try {
      debugPrint(
        '[AUTH GATE] Inicializando...',
      );

      // --------------------------------------------------------
      // Escuta login/logout/refresh.
      // --------------------------------------------------------

      _authSubscription = _supabase.auth.onAuthStateChange.listen(
        _onAuthChanged,
        onError:
            (
              Object error,
            ) {
              debugPrint(
                '[AUTH GATE] Erro no stream: $error',
              );

              if (!mounted) {
                return;
              }

              setState(
                () {
                  _errorMessage = error.toString();

                  _loading = false;
                },
              );
            },
      );

      // --------------------------------------------------------
      // Recupera sessão já existente.
      // --------------------------------------------------------

      final user = _supabase.auth.currentUser;

      debugPrint(
        '[AUTH GATE] Usuário atual: ${user?.id ?? 'null'}',
      );

      _user = user;

      // --------------------------------------------------------
      // Não autenticado.
      // --------------------------------------------------------

      if (user ==
          null) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _loading = false;
            _profileComplete = false;
            _errorMessage = null;
          },
        );

        return;
      }

      // --------------------------------------------------------
      // Autenticado.
      // Agora precisamos descobrir se o perfil está completo.
      // --------------------------------------------------------

      await _loadProfile(
        user,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[AUTH GATE] Erro ao inicializar: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = error.toString();

          _loading = false;
        },
      );
    }
  }

  // ============================================================
  // AUTH CHANGED
  // ============================================================

  Future<
    void
  >
  _onAuthChanged(
    AuthState state,
  ) async {
    if (!mounted) {
      return;
    }

    final user = state.session?.user;

    debugPrint(
      '[AUTH GATE] Evento: ${state.event}',
    );

    debugPrint(
      '[AUTH GATE] Usuário: ${user?.id ?? 'null'}',
    );

    // ----------------------------------------------------------
    // Logout
    // ----------------------------------------------------------

    if (user ==
        null) {
      _profileRequestId++;

      setState(
        () {
          _user = null;

          _profileComplete = false;

          _loading = false;

          _errorMessage = null;
        },
      );

      return;
    }

    // ----------------------------------------------------------
    // Login / sessão restaurada
    // ----------------------------------------------------------

    setState(
      () {
        _user = user;

        _loading = true;

        _profileComplete = false;

        _errorMessage = null;
      },
    );

    await _loadProfile(
      user,
    );
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<
    void
  >
  _loadProfile(
    User user,
  ) async {
    final requestId = ++_profileRequestId;

    try {
      debugPrint(
        '[AUTH GATE] Verificando perfil...',
      );

      debugPrint(
        '[AUTH GATE] User ID: ${user.id}',
      );

      final profile = await _profileRepository.getProfile(
        user.id,
      );

      // --------------------------------------------------------
      // Uma nova requisição começou antes desta terminar.
      // Ignoramos esta resposta antiga.
      // --------------------------------------------------------

      if (requestId !=
          _profileRequestId) {
        return;
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // Confere se o usuário ainda é o mesmo.
      // --------------------------------------------------------

      final currentUser = _supabase.auth.currentUser;

      if (currentUser ==
              null ||
          currentUser.id !=
              user.id) {
        return;
      }

      final profileComplete =
          profile !=
              null &&
          profile.hasName;

      debugPrint(
        '[AUTH GATE] Perfil encontrado: ${profile != null}',
      );

      debugPrint(
        '[AUTH GATE] Nome: ${profile?.fullName ?? 'não definido'}',
      );

      debugPrint(
        '[AUTH GATE] Perfil completo: $profileComplete',
      );

      setState(
        () {
          _user = currentUser;

          _profileComplete = profileComplete;

          _loading = false;

          _errorMessage = null;
        },
      );
    } on PostgrestException catch (
      error
    ) {
      if (requestId !=
          _profileRequestId) {
        return;
      }

      debugPrint(
        '[AUTH GATE] Erro Supabase ao buscar perfil.',
      );

      debugPrint(
        '[AUTH GATE] Code: ${error.code}',
      );

      debugPrint(
        '[AUTH GATE] Message: ${error.message}',
      );

      debugPrint(
        '[AUTH GATE] Details: ${error.details}',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;

          _errorMessage = _translateProfileError(
            error,
          );
        },
      );
    } catch (
      error
    ) {
      if (requestId !=
          _profileRequestId) {
        return;
      }

      debugPrint(
        '[AUTH GATE] Erro ao verificar perfil: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;

          _errorMessage = 'Não foi possível carregar seu perfil.\n\n$error';
        },
      );
    }
  }

  // ============================================================
  // PROFILE COMPLETED
  // ============================================================

  Future<
    void
  >
  _onProfileCompleted() async {
    debugPrint(
      '[AUTH GATE] Nome salvo. Recarregando perfil...',
    );

    final user = _supabase.auth.currentUser;

    if (user ==
        null) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _user = null;

          _profileComplete = false;

          _loading = false;

          _errorMessage = null;
        },
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _user = user;

        _loading = true;

        _errorMessage = null;
      },
    );

    await _loadProfile(
      user,
    );
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<
    void
  >
  _retry() async {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _loading = true;

        _errorMessage = null;
      },
    );

    try {
      final user = _supabase.auth.currentUser;

      if (user ==
          null) {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _user = null;

            _profileComplete = false;

            _loading = false;

            _errorMessage = null;
          },
        );

        return;
      }

      _user = user;

      await _loadProfile(
        user,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[AUTH GATE] Erro ao tentar novamente: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loading = false;

          _errorMessage = error.toString();
        },
      );
    }
  }

  // ============================================================
  // TRANSLATE PROFILE ERROR
  // ============================================================

  String _translateProfileError(
    PostgrestException error,
  ) {
    final code = error.code;

    final message = error.message.toLowerCase();

    // ----------------------------------------------------------
    // Tabela não existe
    // ----------------------------------------------------------

    if (code ==
            '42P01' ||
        message.contains(
              'relation',
            ) &&
            message.contains(
              'does not exist',
            )) {
      return 'A tabela "profiles" ainda não existe no Supabase.';
    }

    // ----------------------------------------------------------
    // Coluna não existe
    // ----------------------------------------------------------

    if (code ==
            '42703' ||
        message.contains(
              'column',
            ) &&
            message.contains(
              'does not exist',
            )) {
      return 'A estrutura da tabela "profiles" não corresponde ao aplicativo.';
    }

    // ----------------------------------------------------------
    // RLS
    // ----------------------------------------------------------

    if (code ==
            '42501' ||
        message.contains(
          'row-level security',
        )) {
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
  Widget build(
    BuildContext context,
  ) {
    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loading) {
      return const _AuthLoadingScreen();
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    if (_errorMessage !=
        null) {
      return _AuthErrorScreen(
        message: _errorMessage!,
        onRetry: _retry,
      );
    }

    // ==========================================================
    // NÃO AUTENTICADO
    // ==========================================================

    final user = _user;

    if (user ==
        null) {
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

    return widget.authenticatedBuilder(
      context,
      user,
    );
  }
}

// ============================================================
// LOADING SCREEN
// ============================================================

class _AuthLoadingScreen
    extends
        StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(
    BuildContext context,
  ) {
    return const Scaffold(
      backgroundColor: Color(
        0xFF090A0E,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color(
                0xFF7C5CFF,
              ),
              strokeWidth: 2,
            ),
            SizedBox(
              height: 16,
            ),
            Text(
              'Carregando sua conta...',
              style: TextStyle(
                color: Color(
                  0xFF9298A6,
                ),
                fontSize: 12,
              ),
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

class _AuthErrorScreen
    extends
        StatelessWidget {
  const _AuthErrorScreen({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final Future<
    void
  >
  Function()
  onRetry;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(
        0xFF090A0E,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Container(
              padding: const EdgeInsets.all(
                26,
              ),
              decoration: BoxDecoration(
                color: const Color(
                  0xFF111319,
                ),
                borderRadius: BorderRadius.circular(
                  18,
                ),
                border: Border.all(
                  color: const Color(
                    0xFF7C3047,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================================================
                  // ICON
                  // ==================================================
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: Color(
                      0xFFFF8DAA,
                    ),
                    size: 36,
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // ==================================================
                  // TITLE
                  // ==================================================
                  const Text(
                    'Não foi possível continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(
                        0xFFF5F7FA,
                      ),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  // ==================================================
                  // ERROR
                  // ==================================================
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(
                        0xFF9298A6,
                      ),
                      fontSize: 11,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ==================================================
                  // RETRY
                  // ==================================================
                  ElevatedButton.icon(
                    onPressed: () {
                      onRetry();
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(
                        0xFF7C5CFF,
                      ),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          11,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      size: 18,
                    ),
                    label: const Text(
                      'Tentar novamente',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
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
