import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'legal/privacy_policy_page.dart';
import 'legal/terms_of_use_page.dart';

// ============================================================
// PROFILE SETTINGS PAGE
// ============================================================
//
// Página dedicada para:
//
// - Preferências;
// - Segurança;
// - Sobre o aplicativo.
//
// Preferências são salvas no user_metadata do Supabase.
// Senha é alterada pelo Supabase Auth.
//
// ============================================================

enum ProfileSettingsSection {
  preferences,
  security,
  about,
}

class ProfileSettingsPage
    extends
        StatefulWidget {
  const ProfileSettingsPage({
    super.key,
    this.initialSection = ProfileSettingsSection.preferences,
  });

  final ProfileSettingsSection initialSection;

  @override
  State<
    ProfileSettingsPage
  >
  createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState
    extends
        State<
          ProfileSettingsPage
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
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

  static const Color _danger = Color(
    0xFFB3261E,
  );

  // ============================================================
  // STATE
  // ============================================================

  late ProfileSettingsSection _section;

  bool _compactMode = false;

  bool _reduceMotion = false;

  bool _confirmBeforeDelete = true;

  bool _savingPreferences = false;

  bool _changingPassword = false;

  String? _message;

  bool _messageIsError = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _section = widget.initialSection;

    _loadPreferences();
  }

  // ============================================================
  // USER
  // ============================================================

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _email =>
      _user?.email ??
      'E-mail não disponível';

  // ============================================================
  // LOAD PREFERENCES
  // ============================================================

  void _loadPreferences() {
    final metadata =
        _user?.userMetadata ??
        const <
          String,
          dynamic
        >{};

    _compactMode =
        metadata['ui_compact_mode'] ==
        true;

    _reduceMotion =
        metadata['ui_reduce_motion'] ==
        true;

    final confirm = metadata['confirm_before_delete'];

    _confirmBeforeDelete =
        confirm
            is bool
        ? confirm
        : true;
  }

  // ============================================================
  // SAVE PREFERENCES
  // ============================================================

  Future<
    void
  >
  _savePreferences() async {
    if (_savingPreferences) {
      return;
    }

    setState(
      () {
        _savingPreferences = true;
        _message = null;
      },
    );

    try {
      final current =
          Map<
            String,
            dynamic
          >.from(
            _user?.userMetadata ??
                const <
                  String,
                  dynamic
                >{},
          );

      current['ui_compact_mode'] = _compactMode;

      current['ui_reduce_motion'] = _reduceMotion;

      current['confirm_before_delete'] = _confirmBeforeDelete;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: current,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _message = 'Preferências salvas com sucesso.';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro salvando preferências: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _message = 'Não foi possível salvar as preferências.';
          _messageIsError = true;
        },
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _savingPreferences = false;
        },
      );
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<
    void
  >
  _changePassword() async {
    if (_changingPassword) {
      return;
    }

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    var obscurePassword = true;

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: _surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                            side: const BorderSide(
                              color: _border,
                            ),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.lock_reset_rounded,
                                color: _primaryDark,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Alterar senha',
                              ),
                            ],
                          ),
                          content: SizedBox(
                            width: 360,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: newPasswordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Nova senha',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setDialogState(
                                          () {
                                            obscurePassword = !obscurePassword;
                                          },
                                        );
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: obscurePassword,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar nova senha',
                                    prefixIcon: Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  false,
                                );
                              },
                              child: const Text(
                                'Cancelar',
                              ),
                            ),

                            FilledButton(
                              onPressed: () {
                                final password = newPasswordController.text;

                                final confirm = confirmPasswordController.text;

                                if (password.length <
                                    8) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'A senha deve ter pelo menos 8 caracteres.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                if (password !=
                                    confirm) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'As senhas não coincidem.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  true,
                                );
                              },
                              child: const Text(
                                'Atualizar senha',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    if (confirmed !=
        true) {
      newPasswordController.dispose();

      confirmPasswordController.dispose();

      return;
    }

    final password = newPasswordController.text;

    newPasswordController.dispose();

    confirmPasswordController.dispose();

    setState(
      () {
        _changingPassword = true;
        _message = null;
      },
    );

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _message = 'Senha atualizada com sucesso.';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro alterando senha: $error',
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _message = 'Não foi possível alterar a senha.';
          _messageIsError = true;
        },
      );
    } finally {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _changingPassword = false;
        },
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Perfil e configurações',
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 980,
            ),
            child: Padding(
              padding: const EdgeInsets.all(
                24,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: _buildNavigation(),
                  ),

                  const SizedBox(
                    width: 20,
                  ),

                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          _SettingsNavItem(
            icon: Icons.tune_rounded,
            label: 'Preferências',
            selected:
                _section ==
                ProfileSettingsSection.preferences,
            onTap: () {
              setState(
                () {
                  _section = ProfileSettingsSection.preferences;
                },
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.shield_outlined,
            label: 'Segurança',
            selected:
                _section ==
                ProfileSettingsSection.security,
            onTap: () {
              setState(
                () {
                  _section = ProfileSettingsSection.security;
                },
              );
            },
          ),

          const SizedBox(
            height: 8,
          ),

          _SettingsNavItem(
            icon: Icons.info_outline_rounded,
            label: 'Sobre',
            selected:
                _section ==
                ProfileSettingsSection.about,
            onTap: () {
              setState(
                () {
                  _section = ProfileSettingsSection.about;
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_message !=
            null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(
              12,
            ),
            decoration: BoxDecoration(
              color: _messageIsError
                  ? const Color(
                      0xFFFFECE9,
                    )
                  : _surfaceSoft,
              borderRadius: BorderRadius.circular(
                12,
              ),
              border: Border.all(
                color: _messageIsError
                    ? _danger.withValues(
                        alpha: 0.30,
                      )
                    : _border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _messageIsError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: _messageIsError
                      ? _danger
                      : _primaryDark,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _messageIsError
                          ? _danger
                          : _text,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),
        ],

        if (_section ==
            ProfileSettingsSection.preferences)
          _buildPreferences(),

        if (_section ==
            ProfileSettingsSection.security)
          _buildSecurity(),

        if (_section ==
            ProfileSettingsSection.about)
          _buildAbout(),
      ],
    );
  }

  // ============================================================
  // PREFERENCES
  // ============================================================

  Widget _buildPreferences() {
    return _SettingsPanel(
      icon: Icons.tune_rounded,
      title: 'Preferências',
      subtitle: 'Personalize o comportamento da sua experiência.',
      children: [
        _PreferenceSwitch(
          icon: Icons.view_compact_outlined,
          title: 'Modo compacto',
          subtitle: 'Reduz espaços e deixa as telas mais densas.',
          value: _compactMode,
          onChanged:
              (
                value,
              ) {
                setState(
                  () {
                    _compactMode = value;
                  },
                );
              },
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _PreferenceSwitch(
          icon: Icons.animation_outlined,
          title: 'Reduzir animações',
          subtitle: 'Diminui transições e movimentos visuais.',
          value: _reduceMotion,
          onChanged:
              (
                value,
              ) {
                setState(
                  () {
                    _reduceMotion = value;
                  },
                );
              },
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _PreferenceSwitch(
          icon: Icons.delete_sweep_outlined,
          title: 'Confirmar antes de apagar',
          subtitle: 'Pede confirmação antes de excluir registros.',
          value: _confirmBeforeDelete,
          onChanged:
              (
                value,
              ) {
                setState(
                  () {
                    _confirmBeforeDelete = value;
                  },
                );
              },
        ),

        const SizedBox(
          height: 18,
        ),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _savingPreferences
                ? null
                : _savePreferences,
            icon: _savingPreferences
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.save_outlined,
                    size: 18,
                  ),
            label: Text(
              _savingPreferences
                  ? 'Salvando...'
                  : 'Salvar preferências',
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurity() {
    return _SettingsPanel(
      icon: Icons.shield_outlined,
      title: 'Segurança',
      subtitle: 'Gerencie senha e dados de acesso da sua conta.',
      children: [
        _SecurityRow(
          icon: Icons.alternate_email_rounded,
          title: 'E-mail da conta',
          subtitle: _email,
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _SecurityRow(
          icon: Icons.lock_outline_rounded,
          title: 'Senha',
          subtitle: 'Altere sua senha de acesso.',
          trailing: FilledButton.tonalIcon(
            onPressed: _changingPassword
                ? null
                : _changePassword,
            icon: _changingPassword
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.edit_outlined,
                    size: 17,
                  ),
            label: const Text(
              'Alterar',
            ),
          ),
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        const _SecurityRow(
          icon: Icons.verified_user_outlined,
          title: 'Sessão',
          subtitle: 'Sua sessão atual está protegida pelo Supabase Auth.',
        ),
      ],
    );
  }

  // ============================================================
  // ABOUT
  // ============================================================

  Widget _buildAbout() {
    return _SettingsPanel(
      icon: Icons.info_outline_rounded,
      title: 'Sobre',
      subtitle: 'Informações sobre o EVRYLUX.',
      children: [
        const _AboutHero(),

        const Divider(
          height: 1,
          color: _border,
        ),

        _AboutActionRow(
          icon: Icons.info_outline_rounded,
          title: 'Sobre',
          subtitle: 'Conheça a proposta e a visão do EVRYLUX.',
          onTap: () {
            _showAboutInfoDialog(
              title: 'Sobre o EVRYLUX',
              icon: Icons.info_outline_rounded,
              content:
                  'EVRYLUX é uma plataforma de evolução pessoal criada para reunir, em um só lugar, áreas como estudos, treino, finanças, rotina e acompanhamento de progresso.\n\n'
                  'A proposta é ajudar você a organizar sua evolução de forma simples, visual e consistente.',
            );
          },
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _AboutActionRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de privacidade',
          subtitle: 'Veja como seus dados são tratados.',
          onTap: () {
            Navigator.of(
              context,
            ).push(
              MaterialPageRoute(
                builder:
                    (
                      _,
                    ) {
                      return const PrivacyPolicyPage();
                    },
              ),
            );
          },
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _AboutActionRow(
          icon: Icons.description_outlined,
          title: 'Termos de uso',
          subtitle: 'Consulte os termos de utilização do aplicativo.',
          onTap: () {
            Navigator.of(
              context,
            ).push(
              MaterialPageRoute(
                builder:
                    (
                      _,
                    ) {
                      return const TermsOfUsePage();
                    },
              ),
            );
          },
        ),

        const Divider(
          height: 1,
          color: _border,
        ),

        _AboutActionRow(
          icon: Icons.article_outlined,
          title: 'Licenças',
          subtitle: 'Bibliotecas e licenças utilizadas pelo aplicativo.',
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'EVRYLUX',
              applicationVersion: '1.0.0',
              applicationLegalese: 'Desenvolvido por João Vitor',
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // ABOUT INFO DIALOG
  // ============================================================

  Future<
    void
  >
  _showAboutInfoDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  20,
                ),
                side: const BorderSide(
                  color: _border,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: _primaryDark,
                      size: 20,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 440,
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: _muted,
                    height: 1.5,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child: const Text(
                    'Fechar',
                  ),
                ),
              ],
            );
          },
    );
  }
}

// ============================================================
// ABOUT HERO
// ============================================================

class _AboutHero
    extends
        StatelessWidget {
  const _AboutHero();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(
                22,
              ),
              border: Border.all(
                color: _ProfileSettingsPageState._border,
              ),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(
            width: 18,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVRYLUX',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),

                SizedBox(
                  height: 4,
                ),

                Text(
                  'Versão 1.0.0',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(
                  height: 12,
                ),

                Text(
                  'Sua plataforma de evolução pessoal.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Desenvolvido por João Vitor',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ABOUT ACTION ROW
// ============================================================

class _AboutActionRow
    extends
        StatelessWidget {
  const _AboutActionRow({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(
            14,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._primary,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _ProfileSettingsPageState._muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS NAV ITEM
// ============================================================

class _SettingsNavItem
    extends
        StatelessWidget {
  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;

  final String label;

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileSettingsPageState._primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              12,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: selected
                    ? _ProfileSettingsPageState._primaryDark
                    : _ProfileSettingsPageState._muted,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? _ProfileSettingsPageState._text
                        : _ProfileSettingsPageState._muted,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS PANEL
// ============================================================

class _SettingsPanel
    extends
        StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final List<
    Widget
  >
  children;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _ProfileSettingsPageState._border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._primary,
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 18,
          ),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._surfaceSoft,
              borderRadius: BorderRadius.circular(
                15,
              ),
              border: Border.all(
                color: _ProfileSettingsPageState._border,
              ),
            ),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PREFERENCE SWITCH
// ============================================================

class _PreferenceSwitch
    extends
        StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool value;

  final ValueChanged<
    bool
  >
  onChanged;

  @override
  Widget build(
    BuildContext context,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: _ProfileSettingsPageState._primaryDark,
      activeTrackColor: _ProfileSettingsPageState._primary,
      secondary: Icon(
        icon,
        color: _ProfileSettingsPageState._primaryDark,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: _ProfileSettingsPageState._text,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: _ProfileSettingsPageState._muted,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ============================================================
// SECURITY ROW
// ============================================================

class _SecurityRow
    extends
        StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final Widget? trailing;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              size: 19,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          if (trailing !=
              null) ...[
            const SizedBox(
              width: 10,
            ),

            trailing!,
          ],
        ],
      ),
    );
  }
}
