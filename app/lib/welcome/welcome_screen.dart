import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../profile/data/profile_repository.dart';
import '../profile/models/user_profile.dart';
import '../profile/screens/profile_settings_page.dart';

import '../evolution/controllers/evolution_controller.dart';
import '../evolution/evolution_screen.dart';
import '../finance/screen/finance_screen.dart';
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
  // OPEN PROFILE SETTINGS
  // ============================================================

  Future<
    void
  >
  _openProfileSettings(
    ProfileSettingsSection section,
  ) async {
    Navigator.of(
      context,
    ).pop();

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return ProfileSettingsPage(
                initialSection: section,
              );
            },
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadProfile();
  }

  // ============================================================
  // PROFILE MODAL
  // ============================================================

  Future<
    void
  >
  _showProfileModal() async {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final user = Supabase.instance.client.auth.currentUser;

    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 560,
      ),
      builder:
          (
            modalContext,
          ) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            14,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: colorScheme.primary,
                          size: 23,
                        ),
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Meu perfil',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(
                              height: 3,
                            ),
                            Text(
                              'Informações da sua conta.',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      IconButton(
                        tooltip: 'Fechar',
                        onPressed: () {
                          Navigator.of(
                            modalContext,
                          ).pop();
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 22,
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      18,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(
                        18,
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.primary.withValues(
                                alpha: 0.20,
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: colorScheme.primary,
                            size: 32,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(
                                height: 5,
                              ),

                              Text(
                                user?.email ??
                                    'E-mail não disponível',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      14,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                      border: Border.all(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      children: [
                        _ProfileInfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Nome',
                          value: _displayName,
                        ),

                        Divider(
                          height: 24,
                          color: colorScheme.outlineVariant,
                        ),

                        _ProfileInfoRow(
                          icon: Icons.alternate_email_rounded,
                          label: 'E-mail',
                          value:
                              user?.email ??
                              'Não disponível',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _ProfileActionTile(
                    icon: Icons.tune_rounded,
                    title: 'Preferências',
                    subtitle: 'Ajuste comportamento e experiência do app.',
                    onTap: () {
                      _openProfileSettings(
                        ProfileSettingsSection.preferences,
                      );
                    },
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  _ProfileActionTile(
                    icon: Icons.shield_outlined,
                    title: 'Segurança',
                    subtitle: 'Gerencie senha e dados de acesso.',
                    onTap: () {
                      _openProfileSettings(
                        ProfileSettingsSection.security,
                      );
                    },
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(
                            modalContext,
                          ).pop();
                        },
                        child: const Text(
                          'Fechar',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
    );
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
            // PROFILE + LOGOUT
            // ==================================================
            Positioned(
              top: 12,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileButton(),

                  const SizedBox(
                    width: 8,
                  ),

                  _buildLogoutButton(),
                ],
              ),
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
  // PROFILE BUTTON
  // ============================================================

  Widget _buildProfileButton() {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Tooltip(
      message: 'Meu perfil',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showProfileModal,
          borderRadius: BorderRadius.circular(
            999,
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(
                  alpha: 0.22,
                ),
              ),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: 21,
              color: colorScheme.primary,
            ),
          ),
        ),
      ),
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

// ============================================================
// PROFILE INFO ROW
// ============================================================

class _ProfileInfoRow
    extends
        StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;

  final String label;

  final String value;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            size: 17,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PROFILE ACTION TILE
// ============================================================

class _ProfileActionTile
    extends
        StatelessWidget {
  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          14,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(
            13,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(
              14,
            ),
            border: Border.all(
              color: colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: colorScheme.primary,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
