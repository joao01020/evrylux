import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/models/user_profile.dart';

import '../evolution/controllers/evolution_controller.dart';
import '../evolution/evolution_screen.dart';
import '../finance/finance_screen.dart';
import '../routine/screen/routine_screen.dart';
import '../study/study_screen.dart';
import '../training/training_screen.dart';

class WelcomeScreen
    extends
        StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
  });

  final EvolutionController controller;

  @override
  State<
    WelcomeScreen
  >
  createState() {
    return _WelcomeScreenState();
  }
}

class _WelcomeScreenState
    extends
        State<
          WelcomeScreen
        > {
  // ============================================================
  // PROFILE
  // ============================================================

  late final ProfileRepository _profileRepository;

  UserProfile? _profile;

  bool _loadingProfile = true;

  String? _profileError;

  // ============================================================
  // AUTH
  // ============================================================

  bool _isSigningOut = false;

  // ============================================================
  // OBJECTIVES
  // ============================================================

  final List<
    Map<
      String,
      String
    >
  >
  objectives = [
    {
      'name': 'Estudar',
      'emoji': '🧠',
      'description': 'Evolua sua mente através dos estudos e aprendizado.',
    },
    {
      'name': 'Treinar',
      'emoji': '❤️',
      'description': 'Cuide do seu corpo através de movimento e hábitos saudáveis.',
    },
    {
      'name': 'Financeiro',
      'emoji': '💰',
      'description': 'Organize suas finanças e acompanhe sua evolução financeira.',
    },
    {
      'name': 'Rotina',
      'emoji': '📅',
      'description': 'Planeje sua semana, organize tarefas e registre suas ideias.',
    },
    {
      'name': 'Evolução',
      'emoji': '📈',
      'description': 'Veja seu progresso e acompanhe sua transformação.',
    },
  ];

  // ============================================================
  // STATE
  // ============================================================

  bool showOptions = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileRepository = ProfileRepository();

    _loadProfile();

    Future.delayed(
      const Duration(
        milliseconds: 1200,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            showOptions = true;
          },
        );
      },
    );
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<
    void
  >
  _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _profile = profile;

          _loadingProfile = false;

          _profileError = null;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[WELCOME] Erro ao carregar perfil: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loadingProfile = false;

          _profileError = error.toString();
        },
      );
    }
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String get _displayName {
    final name = _profile?.fullName.trim();

    if (name ==
            null ||
        name.isEmpty) {
      return 'Usuário';
    }

    return name;
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<
    void
  >
  _signOut() async {
    if (_isSigningOut) {
      return;
    }

    setState(
      () {
        _isSigningOut = true;
      },
    );

    try {
      debugPrint(
        '[WELCOME] Saindo da conta...',
      );

      await Supabase.instance.client.auth.signOut();

      debugPrint(
        '[WELCOME] Logout realizado com sucesso.',
      );

      // --------------------------------------------------------
      // Não usamos Navigator aqui.
      //
      // O AuthGate está escutando onAuthStateChange.
      // Assim que o Supabase emitir signedOut, ele troca
      // automaticamente esta tela pela LoginScreen.
      // --------------------------------------------------------
    } catch (
      error
    ) {
      debugPrint(
        '[WELCOME] Erro ao sair da conta: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível sair da conta: $error',
          ),
        ),
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _isSigningOut = false;
        },
      );
    }
  }

  // ============================================================
  // OPEN OBJECTIVE
  // ============================================================

  void openObjective(
    String name,
  ) {
    final Widget? page = switch (name) {
      'Estudar' => const StudyScreen(),

      'Treinar' => const TrainingScreen(),

      'Financeiro' => const FinanceScreen(),

      'Rotina' => const RoutineScreen(),

      'Evolução' => EvolutionScreen(
        controller: widget.controller,
      ),

      _ => null,
    };

    if (page ==
        null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return page;
            },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // GREETING
            // ==================================================
            AnimatedAlign(
              duration: const Duration(
                milliseconds: 900,
              ),
              curve: Curves.easeInOutCubic,
              alignment: showOptions
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  top: showOptions
                      ? 70
                      : 0,
                ),
                child: _buildGreeting(),
              ),
            ),

            // ==================================================
            // OPTIONS
            // ==================================================
            IgnorePointer(
              ignoring: !showOptions,
              child: AnimatedOpacity(
                duration: const Duration(
                  milliseconds: 700,
                ),
                opacity: showOptions
                    ? 1
                    : 0,
                child: AnimatedSlide(
                  duration: const Duration(
                    milliseconds: 900,
                  ),
                  curve: Curves.easeOutCubic,
                  offset: showOptions
                      ? Offset.zero
                      : const Offset(
                          0,
                          0.25,
                        ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      150,
                      16,
                      32,
                    ),
                    children: [
                      const Text(
                        'Qual evolução deseja iniciar?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),

                      const SizedBox(
                        height: 32,
                      ),

                      ...objectives.map(
                        (
                          objective,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Text(
                                  objective['emoji']!,
                                  style: const TextStyle(
                                    fontSize: 30,
                                  ),
                                ),
                                title: Text(
                                  objective['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  objective['description']!,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                                onTap: () {
                                  openObjective(
                                    objective['name']!,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ==================================================
            // LOGOUT
            // ==================================================
            Positioned(
              top: 12,
              right: 16,
              child: _buildLogoutButton(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    if (_loadingProfile) {
      return const SizedBox(
        height: 44,
        width: 44,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Olá, 👋 $_displayName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),

        if (_profileError !=
            null) ...[
          const SizedBox(
            height: 8,
          ),
          TextButton(
            onPressed: _loadProfile,
            child: const Text(
              'Tentar carregar nome novamente',
            ),
          ),
        ],
      ],
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton() {
    return Tooltip(
      message: 'Sair da conta',
      child: TextButton.icon(
        onPressed: _isSigningOut
            ? null
            : _signOut,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
        ),
        icon: _isSigningOut
            ? const SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
            : const Icon(
                Icons.logout_rounded,
                size: 18,
              ),
        label: Text(
          _isSigningOut
              ? 'Saindo...'
              : 'Sair',
        ),
      ),
    );
  }
}
