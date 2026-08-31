import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_gate.dart';

import '../core/sync/widgets/sync_status_indicator.dart';
import '../core/theme/app_theme.dart';

import '../evolution/controllers/evolution_controller.dart';

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

  // ============================================================
  // REMINDER STATE
  // ============================================================

  bool _reminderServiceStarted = false;

  bool _showingReminder = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

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
            _startReminderService(),
          );

          // Quando o usuário entra, pedimos uma nova tentativa
          // de sincronização. Isso é importante caso o app tenha
          // iniciado antes da sessão ser restaurada.
          syncService.requestSync();
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
// Online • sincronizado
// Sincronizando...
// N pendentes
// Offline • salvo localmente
// Erro ao sincronizar
//
// ============================================================

class _GlobalSyncOverlay
    extends
        StatelessWidget {
  const _GlobalSyncOverlay({
    required this.visible,
    required this.child,
  });

  final bool visible;

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
                ? SyncStatusIndicator(
                    syncService: syncService,
                    connectivityService: connectivityService,
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
