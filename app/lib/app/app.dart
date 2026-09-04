import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_gate.dart';

import '../core/constants/app_info.dart';

import '../core/sync/widgets/sync_status_indicator.dart';
import '../core/theme/app_theme.dart';

import '../evolution/controllers/evolution_controller.dart';

import '../profile/notifications/controllers/update_notification_controller.dart';
import '../profile/notifications/services/app_update_service.dart';
import '../profile/notifications/widgets/update_notification_bell.dart';
import '../profile/notifications/widgets/update_notification_panel.dart';
import '../profile/data/profile_repository.dart';
import '../profile/models/user_profile.dart';
import '../profile/screens/profile_settings_page.dart';

import '../reminders/models/reminder_model.dart';

import '../routine/screen/routine_screen.dart';

import '../study/study_screen.dart';

import '../training/training_screen.dart';

import '../welcome/welcome_screen.dart';

import 'dependencies/app_dependencies.dart';

class GhostApp
    extends
        StatefulWidget {
  const GhostApp({
    super.key,
    required this.evolutionController,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final EvolutionController evolutionController;

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    GhostApp
  >
  createState() {
    return _GhostAppState();
  }
}

class _GhostAppState
    extends
        State<
          GhostApp
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  // ============================================================
  // NAVIGATOR
  // ============================================================
  //
  // Permite que o ReminderService abra uma notificação
  // independentemente da tela atual do aplicativo.
  //
  // ============================================================

  final GlobalKey<
    NavigatorState
  >
  _navigatorKey =
      GlobalKey<
        NavigatorState
      >();

  // ============================================================
  // SCAFFOLD MESSENGER
  // ============================================================

  final GlobalKey<
    ScaffoldMessengerState
  >
  _scaffoldMessengerKey =
      GlobalKey<
        ScaffoldMessengerState
      >();

  // ============================================================
  // AUTH
  // ============================================================
  //
  // O ReminderService precisa ser iniciado somente quando
  // existir usuário autenticado.
  //
  // Também usamos o estado de autenticação para decidir se o
  // indicador global de sincronização deve aparecer.
  //
  // ============================================================

  StreamSubscription<
    AuthState
  >?
  _authSubscription;

  bool _authenticated = false;

  bool _isSigningOut = false;

  late final ProfileRepository _profileRepository;

  UserProfile? _profile;

  String? _cachedProfileEmail;

  bool _loadingProfile = true;

  String? _profileError;

  // ============================================================
  // REMINDER STATE
  // ============================================================

  bool _reminderServiceStarted = false;

  bool _showingReminder = false;

  // ============================================================
  // NOTIFICAÇÕES DE ATUALIZAÇÃO DO APP
  // ============================================================
  //
  // O controller fica no nível do GhostApp para que o sino
  // permaneça visível em todas as rotas do aplicativo.
  //
  // ============================================================

  late final UpdateNotificationController _updateNotificationController;

  bool _showingUpdateNotifications = false;

  bool _showingProfileModal = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // NOTIFICAÇÕES DE ATUALIZAÇÃO
    // ==========================================================
    //
    // Nesta primeira versão o sino já funciona globalmente.
    //
    // O AppUpdateService ainda não possui uma fonte remota
    // configurada. Depois podemos ligar fetchLatestUpdate ao
    // Supabase, GitHub Releases ou uma API própria.
    //
    // ==========================================================

    _profileRepository = ProfileRepository();

    unawaited(
      _loadProfile(),
    );
    unawaited(
      _profileRepository.syncPendingCurrentPreferences(),
    );

    _updateNotificationController = UpdateNotificationController(
      service: const AppUpdateService(
        currentVersion: AppInfo.version,
      ),
    );

    unawaited(
      _updateNotificationController.initialize(),
    );

    _authenticated =
        supabaseClient.auth.currentUser !=
        null;

    // ==========================================================
    // AUTH LISTENER
    // ==========================================================

    _authSubscription = supabaseClient.auth.onAuthStateChange.listen(
      (
        authState,
      ) {
        final isAuthenticated =
            authState.session?.user !=
            null;

        if (mounted &&
            _authenticated !=
                isAuthenticated) {
          setState(
            () {
              _authenticated = isAuthenticated;
            },
          );
        }

        if (isAuthenticated) {
          unawaited(
            _loadProfile(),
          );
          unawaited(
            _profileRepository.syncPendingCurrentPreferences(),
          );

          unawaited(
            _startReminderService(),
          );

          // Quando o usuário entra, pedimos uma nova tentativa
          // de sincronização. Isso é importante caso o app tenha
          // iniciado antes da sessão ser restaurada.
          syncService.requestSync();
        } else if (mounted) {
          setState(
            () {
              _profile = null;
              _cachedProfileEmail = null;
              _loadingProfile = true;
              _profileError = null;
            },
          );
        }
      },
    );

    // ==========================================================
    // ESPERA O MATERIAL APP SER MONTADO
    // ==========================================================

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (_authenticated) {
          unawaited(
            _startReminderService(),
          );
        }
      },
    );
  }

  // ============================================================
  // START REMINDER SERVICE
  // ============================================================

  Future<
    void
  >
  _startReminderService() async {
    if (_reminderServiceStarted) {
      return;
    }

    final user = supabaseClient.auth.currentUser;

    if (user ==
        null) {
      return;
    }

    _reminderServiceStarted = true;

    try {
      await reminderService.start(
        onReminderDue: _onReminderDue,
      );
    } catch (
      error
    ) {
      // Se o start falhar, permitimos uma nova tentativa futura.
      _reminderServiceStarted = false;

      debugPrint(
        '[APP] Erro ao iniciar ReminderService: $error',
      );
    }
  }

  // ============================================================
  // REMINDER DUE
  // ============================================================

  Future<
    void
  >
  _onReminderDue(
    ReminderModel reminder,
  ) async {
    // ==========================================================
    // EVITA DOIS MODAIS AO MESMO TEMPO
    // ==========================================================

    while (_showingReminder) {
      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );
    }

    final context = _navigatorKey.currentContext;

    if (context ==
        null) {
      return;
    }

    _showingReminder = true;

    try {
      final result =
          await showDialog<
            _ReminderAction
          >(
            context: context,
            barrierDismissible: false,
            builder:
                (
                  context,
                ) {
                  return _ReminderNotificationDialog(
                    reminder: reminder,
                  );
                },
          );

      if (result ==
          _ReminderAction.complete) {
        final success = await reminderController.complete(
          reminder.id,
        );

        if (success) {
          _showSuccessMessage(
            'Lembrete concluído.',
          );
        }
      }
    } catch (
      error
    ) {
      debugPrint(
        '[APP] Erro ao exibir lembrete: $error',
      );
    } finally {
      _showingReminder = false;
    }
  }

  // ============================================================
  // OPEN UPDATE NOTIFICATIONS
  // ============================================================
  //
  // IMPORTANTE:
  //
  // O sino fica na barra global criada pelo MaterialApp.builder.
  // Essa barra fica ACIMA do Navigator na árvore.
  //
  // Por isso o próprio sino não deve tentar usar:
  //
  // - Tooltip que dependa do Overlay do Navigator;
  // - showDialog/showGeneralDialog com o BuildContext da barra.
  //
  // Abrimos o painel usando o contexto do Navigator global.
  //
  // ============================================================

  Future<
    void
  >
  _openUpdateNotifications() async {
    // ==========================================================
    // EVITA ABRIR MAIS DE UM PAINEL AO MESMO TEMPO
    // ==========================================================

    if (_showingUpdateNotifications) {
      return;
    }

    final context = _navigatorKey.currentContext;

    if (context ==
        null) {
      return;
    }

    _showingUpdateNotifications = true;

    _updateNotificationController.markAsRead();

    try {
      await showGeneralDialog<
        void
      >(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        barrierLabel: 'Fechar notificações',
        barrierColor: Colors.black.withValues(
          alpha: .08,
        ),
        transitionDuration: const Duration(
          milliseconds: 160,
        ),
        pageBuilder:
            (
              dialogContext,
              animation,
              secondaryAnimation,
            ) {
              return SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 14,
                      right: 16,
                    ),
                    child: UpdateNotificationPanel(
                      controller: _updateNotificationController,
                    ),
                  ),
                ),
              );
            },
        transitionBuilder:
            (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );

              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale:
                      Tween<
                            double
                          >(
                            begin: .97,
                            end: 1,
                          )
                          .animate(
                            curved,
                          ),
                  alignment: Alignment.topRight,
                  child: child,
                ),
              );
            },
      );
    } finally {
      _showingUpdateNotifications = false;
    }
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<
    void
  >
  _loadProfile() async {
    UserProfile? cachedProfile;

    try {
      cachedProfile = await _profileRepository.getCachedCurrentProfile();

      final cachedEmail = await _profileRepository.getCachedCurrentEmail();

      if (mounted &&
          (cachedProfile !=
                  null ||
              cachedEmail !=
                  null)) {
        setState(
          () {
            _profile =
                cachedProfile ??
                _profile;
            _cachedProfileEmail =
                cachedEmail ??
                _cachedProfileEmail;
            _loadingProfile = false;
            _profileError = null;
          },
        );
      }
    } catch (
      error
    ) {
      debugPrint(
        '[APP] Erro lendo cache do perfil: $error',
      );
    }

    try {
      final profile = await _profileRepository.refreshCurrentProfile();

      final currentEmail = supabaseClient.auth.currentUser?.email;

      if (!mounted) {
        return;
      }

      setState(
        () {
          _profile =
              profile ??
              _profile;
          _cachedProfileEmail =
              currentEmail ??
              _cachedProfileEmail;
          _loadingProfile = false;
          _profileError = null;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[APP] Erro atualizando perfil remoto: $error',
      );

      if (!mounted) {
        return;
      }

      if (cachedProfile ==
              null &&
          _profile ==
              null) {
        setState(
          () {
            _loadingProfile = false;
            _profileError = error.toString();
          },
        );
      }
    }
  }

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
    final navigator = _navigatorKey.currentState;

    if (navigator ==
        null) {
      return;
    }

    await navigator.push(
      MaterialPageRoute<
        void
      >(
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
    // ==========================================================
    // EVITA ABRIR MAIS DE UM PERFIL AO MESMO TEMPO
    // ==========================================================

    if (_showingProfileModal) {
      return;
    }

    _showingProfileModal = true;

    try {
      final context = _navigatorKey.currentContext;

      if (context ==
          null) {
        return;
      }

      final colorScheme = Theme.of(
        context,
      ).colorScheme;

      final user = supabaseClient.auth.currentUser;

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
                                  _loadingProfile
                                      ? 'Carregando...'
                                      : _displayName,
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
                                      _cachedProfileEmail ??
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

                    if (_profileError !=
                        null) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton.icon(
                        onPressed: _loadProfile,
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                        label: const Text(
                          'Tentar carregar perfil novamente',
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 14,
                    ),

                    _GlobalProfileActionTile(
                      icon: Icons.tune_rounded,
                      title: 'Preferências',
                      subtitle: 'Ajuste comportamento e experiência do app.',
                      onTap: () async {
                        Navigator.of(
                          modalContext,
                        ).pop();

                        await _openProfileSettings(
                          ProfileSettingsSection.preferences,
                        );
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    _GlobalProfileActionTile(
                      icon: Icons.shield_outlined,
                      title: 'Segurança',
                      subtitle: 'Gerencie senha e dados de acesso.',
                      onTap: () async {
                        Navigator.of(
                          modalContext,
                        ).pop();

                        await _openProfileSettings(
                          ProfileSettingsSection.security,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
      );
    } finally {
      // ========================================================
      // LIBERA O PERFIL PARA SER ABERTO NOVAMENTE
      // ========================================================

      _showingProfileModal = false;
    }
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
      await supabaseClient.auth.signOut();
    } catch (
      error
    ) {
      debugPrint(
        '[APP] Erro ao sair da conta: $error',
      );

      _scaffoldMessengerKey.currentState?.showSnackBar(
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
  // SUCCESS MESSAGE
  // ============================================================

  void _showSuccessMessage(
    String message,
  ) {
    final messenger = _scaffoldMessengerKey.currentState;

    if (messenger ==
        null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _primaryDark,
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSubscription?.cancel();

    reminderService.dispose();

    _updateNotificationController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ========================================================
      // GLOBAL KEYS
      // ========================================================
      navigatorKey: _navigatorKey,

      scaffoldMessengerKey: _scaffoldMessengerKey,

      // ========================================================
      // THEME
      // ========================================================
      theme: AppTheme.theme,

      // ========================================================
      // GLOBAL SYNC OVERLAY
      // ========================================================
      //
      // O builder envolve TODAS as rotas do MaterialApp.
      //
      // Isso faz o indicador continuar visível em:
      //
      // Welcome
      // Study
      // Training
      // Routine
      // e novas telas adicionadas ao Navigator principal.
      //
      // Ele é ocultado enquanto não houver usuário autenticado.
      //
      // ========================================================
      builder:
          (
            context,
            child,
          ) {
            return _GlobalSyncOverlay(
              visible: _authenticated,
              updateNotificationController: _updateNotificationController,
              onNotificationTap: _openUpdateNotifications,
              onProfileTap: _showProfileModal,
              onLogoutTap: _signOut,
              isSigningOut: _isSigningOut,
              child:
                  child ??
                  const SizedBox.shrink(),
            );
          },

      // ========================================================
      // AUTH
      // ========================================================
      //
      // AuthGate decide:
      //
      // sem sessão
      //      ↓
      // LoginScreen
      //
      // com sessão
      //      ↓
      // WelcomeScreen
      //
      // ========================================================
      home: AuthGate(
        authenticatedBuilder:
            (
              context,
              user,
            ) {
              return WelcomeScreen(
                controller: widget.evolutionController,
              );
            },
      ),

      // ========================================================
      // ROUTES
      // ========================================================
      routes: {
        '/study':
            (
              context,
            ) {
              return const StudyScreen();
            },

        '/training':
            (
              context,
            ) {
              return const TrainingScreen();
            },

        '/routine':
            (
              context,
            ) {
              return const RoutineScreen();
            },
      },
    );
  }
}

// ============================================================
// GLOBAL SYNC OVERLAY
// ============================================================
//
// Mantém o status de conexão/sincronização visível globalmente.
//
// Estados:
//
// 🔔   ☁   👤   ↪
//
// Notificações • Sync • Perfil • Sair
//
// ============================================================

class _GlobalSyncOverlay
    extends
        StatelessWidget {
  const _GlobalSyncOverlay({
    required this.visible,
    required this.updateNotificationController,
    required this.onNotificationTap,
    required this.onProfileTap,
    required this.onLogoutTap,
    required this.isSigningOut,
    required this.child,
  });

  final bool visible;

  final UpdateNotificationController updateNotificationController;

  final VoidCallback onNotificationTap;

  final VoidCallback onProfileTap;

  final VoidCallback onLogoutTap;

  final bool isSigningOut;

  final Widget child;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        // ======================================================
        // ÁREA FIXA DO STATUS
        // ======================================================
        //
        // IMPORTANTE:
        //
        // Esta área existe desde o PRIMEIRO frame do app.
        //
        // Mesmo antes de o Supabase terminar de restaurar a
        // sessão, os 46px já estão reservados.
        //
        // Isso evita o efeito em que a página nasce no topo e,
        // alguns milissegundos depois, é empurrada para baixo
        // quando "Online • sincronizado" aparece.
        //
        // ======================================================
        SafeArea(
          bottom: false,
          child: Container(
            width: double.infinity,
            height: 46,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            decoration: const BoxDecoration(
              color: _background,
              border: Border(
                bottom: BorderSide(
                  color: _border,
                  width: 1,
                ),
              ),
            ),
            alignment: Alignment.centerRight,

            // ==================================================
            // INDICADOR
            // ==================================================
            //
            // O espaço continua reservado mesmo quando o usuário
            // ainda não está autenticado.
            //
            // Apenas o conteúdo do indicador é escondido.
            //
            // ==================================================
            child: visible
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==========================================
                      // NOTIFICAÇÕES DE ATUALIZAÇÃO
                      // ==========================================
                      //
                      // Fica à esquerda do status:
                      //
                      // Online • sincronizado
                      //
                      // ==========================================
                      UpdateNotificationBell(
                        controller: updateNotificationController,
                        onTap: onNotificationTap,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      SyncStatusIndicator(
                        syncService: syncService,
                        connectivityService: connectivityService,
                      ),

                      const SizedBox(
                        width: 8,
                      ),

                      _GlobalTopIconButton(
                        semanticsLabel: 'Meu perfil',
                        icon: Icons.person_outline_rounded,
                        onTap: onProfileTap,
                        filled: true,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      _GlobalTopIconButton(
                        semanticsLabel: isSigningOut
                            ? 'Saindo da conta'
                            : 'Sair da conta',
                        icon: Icons.logout_rounded,
                        onTap: isSigningOut
                            ? null
                            : onLogoutTap,
                        loading: isSigningOut,
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // ======================================================
        // CONTEÚDO DO APP
        // ======================================================
        //
        // ClipRect impede transições/animações das rotas de
        // desenharem por cima da barra global.
        //
        // ======================================================
        Expanded(
          child: ClipRect(
            child: child,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// GLOBAL TOP ICON BUTTON
// ============================================================

class _GlobalTopIconButton
    extends
        StatelessWidget {
  const _GlobalTopIconButton({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.loading = false,
  });

  final String semanticsLabel;

  final IconData icon;

  final VoidCallback? onTap;

  final bool filled;

  final bool loading;

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _primarySoft = Color(
    0xFFBCF0B4,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            999,
          ),
          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: filled
                  ? _primarySoft
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: filled
                  ? Border.all(
                      color: _primary.withValues(
                        alpha: 0.28,
                      ),
                    )
                  : null,
            ),
            child: loading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: _primary,
                    ),
                  )
                : Icon(
                    icon,
                    size: 18,
                    color: _primary,
                  ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// GLOBAL PROFILE ACTION TILE
// ============================================================

class _GlobalProfileActionTile
    extends
        StatelessWidget {
  const _GlobalProfileActionTile({
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

// ============================================================
// REMINDER ACTION
// ============================================================

enum _ReminderAction {
  dismiss,
  complete,
}

// ============================================================
// REMINDER NOTIFICATION DIALOG
// ============================================================

class _ReminderNotificationDialog
    extends
        StatelessWidget {
  const _ReminderNotificationDialog({
    required this.reminder,
  });

  // ============================================================
  // REMINDER
  // ============================================================

  final ReminderModel reminder;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 450,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x1A000000,
                ),
                blurRadius: 30,
                offset: Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =============================================
                // HEADER
                // =============================================
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: _primaryDark,
                        size: 24,
                      ),
                    ),

                    const SizedBox(
                      width: 13,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lembrete',
                            style: TextStyle(
                              color: _text,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),

                          SizedBox(
                            height: 2,
                          ),

                          Text(
                            'Chegou a hora de lembrar.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // =============================================
                // CONTEÚDO
                // =============================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(
                    16,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceSoft,
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                    border: Border.all(
                      color: _border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      if (reminder.message.trim().isNotEmpty) ...[
                        const SizedBox(
                          height: 8,
                        ),

                        Text(
                          reminder.message,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 14,
                      ),

                      _ReminderTime(
                        date: reminder.remindAt.toLocal(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =============================================
                // ACTIONS
                // =============================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          _ReminderAction.dismiss,
                        );
                      },
                      child: const Text(
                        'Fechar',
                        style: TextStyle(
                          color: _muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          _ReminderAction.complete,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _primary,
                        foregroundColor: _primaryDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ),
                        ),
                      ),
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Concluir',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REMINDER TIME
// ============================================================

class _ReminderTime
    extends
        StatelessWidget {
  const _ReminderTime({
    required this.date,
  });

  final DateTime date;

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // FORMAT
  // ============================================================

  String _twoDigits(
    int value,
  ) {
    return value.toString().padLeft(
      2,
      '0',
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final day = _twoDigits(
      date.day,
    );

    final month = _twoDigits(
      date.month,
    );

    final hour = _twoDigits(
      date.hour,
    );

    final minute = _twoDigits(
      date.minute,
    );

    return Row(
      children: [
        const Icon(
          Icons.schedule_rounded,
          size: 16,
          color: _primaryDark,
        ),

        const SizedBox(
          width: 6,
        ),

        Text(
          '$day/$month/${date.year} às $hour:$minute',
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
