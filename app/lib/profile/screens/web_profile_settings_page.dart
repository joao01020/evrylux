import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/screen/brain_screen.dart';
import '../models/profile_preferences.dart';

enum WebProfileSettingsSection { preferences, telegram, security, brain, about }

/// Versão Web-safe de Perfil e configurações.
///
/// Não importa `app_dependencies.dart`, `dart:io`, SQLite ou APIs de desktop.
/// Mantém a mesma organização visual e reutiliza os mesmos dados de conta
/// (Supabase user_metadata) para preferências.
class WebProfileSettingsPage extends StatefulWidget {
  const WebProfileSettingsPage({
    super.key,
    this.initialSection = WebProfileSettingsSection.preferences,
  });

  final WebProfileSettingsSection initialSection;

  @override
  State<WebProfileSettingsPage> createState() => _WebProfileSettingsPageState();
}

class _WebProfileSettingsPageState extends State<WebProfileSettingsPage> {
  static const Color _background = Color(0xFFF7FBF1);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceSoft = Color(0xFFF3F8EE);
  static const Color _border = Color(0xFFC7DFC9);
  static const Color _primary = Color(0xFFBCF0B4);
  static const Color _primaryDark = Color(0xFF3B6939);
  static const Color _text = Color(0xFF172019);
  static const Color _muted = Color(0xFF68746B);
  late WebProfileSettingsSection _section;

  bool _compactMode = false;
  bool _reduceMotion = false;
  bool _confirmBeforeDelete = true;
  bool _saving = false;

  User? get _user => Supabase.instance.client.auth.currentUser;
  String get _email => _user?.email ?? 'E-mail não disponível';

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _loadPreferences();
  }

  void _loadPreferences() {
    final metadata = Map<String, dynamic>.from(
      _user?.userMetadata ?? const <String, dynamic>{},
    );
    final preferences = ProfilePreferences.fromMetadata(metadata);

    _compactMode = preferences.compactMode;
    _reduceMotion = preferences.reduceMotion;
    _confirmBeforeDelete = preferences.confirmBeforeDelete;
  }

  Future<void> _savePreferences() async {
    if (_saving || _user == null) return;

    setState(() => _saving = true);

    try {
      final metadata = Map<String, dynamic>.from(
        _user?.userMetadata ?? const <String, dynamic>{},
      );

      final updated = ProfilePreferences(
        compactMode: _compactMode,
        reduceMotion: _reduceMotion,
        confirmBeforeDelete: _confirmBeforeDelete,
      ).applyToMetadata(metadata);

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: updated),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    String? error;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Alterar senha'),
              content: TextField(
                controller: controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Nova senha',
                  errorText: error,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.length < 8) {
                      setDialogState(() {
                        error = 'Use pelo menos 8 caracteres.';
                      });
                      return;
                    }
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Alterar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      controller.dispose();
      return;
    }

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: controller.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Senha atualizada.')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível alterar a senha: $error')),
      );
    } finally {
      controller.dispose();
    }
  }

  void _openBrain() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const BrainScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Column(
          children: [
            _buildPageHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 820;

                  if (compact) {
                    return Column(
                      children: [
                        _buildMobileTabs(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
                            child: _buildSection(),
                          ),
                        ),
                      ],
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 860),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(width: 220, child: _buildSidebar()),
                            const SizedBox(width: 20),
                            Expanded(
                              child: SingleChildScrollView(
                                child: _buildSection(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 10),
          const Text(
            'Perfil e configurações',
            style: TextStyle(
              color: _text,
              fontSize: 23,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _navItem(
            WebProfileSettingsSection.preferences,
            Icons.tune_rounded,
            'Preferências',
          ),
          _navItem(
            WebProfileSettingsSection.telegram,
            Icons.send_rounded,
            'Telegram',
          ),
          _navItem(
            WebProfileSettingsSection.security,
            Icons.shield_outlined,
            'Segurança',
          ),
          _navItem(
            WebProfileSettingsSection.brain,
            Icons.psychology_alt_outlined,
            'Cérebro',
          ),
          _navItem(
            WebProfileSettingsSection.about,
            Icons.info_outline_rounded,
            'Sobre',
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTabs() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          _mobileTab(WebProfileSettingsSection.preferences, 'Preferências'),
          _mobileTab(WebProfileSettingsSection.telegram, 'Telegram'),
          _mobileTab(WebProfileSettingsSection.security, 'Segurança'),
          _mobileTab(WebProfileSettingsSection.brain, 'Cérebro'),
          _mobileTab(WebProfileSettingsSection.about, 'Sobre'),
        ],
      ),
    );
  }

  Widget _mobileTab(WebProfileSettingsSection section, String label) {
    final selected = _section == section;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        label: Text(label),
        onSelected: (_) => setState(() => _section = section),
      ),
    );
  }

  Widget _navItem(
    WebProfileSettingsSection section,
    IconData icon,
    String label,
  ) {
    final selected = _section == section;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? _primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _section = section),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 19, color: selected ? _primaryDark : _muted),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _text : _muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection() {
    return switch (_section) {
      WebProfileSettingsSection.preferences => _buildPreferences(),
      WebProfileSettingsSection.telegram => _buildTelegram(),
      WebProfileSettingsSection.security => _buildSecurity(),
      WebProfileSettingsSection.brain => _buildBrain(),
      WebProfileSettingsSection.about => _buildAbout(),
    };
  }

  Widget _panel({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: _primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPreferences() {
    return _panel(
      icon: Icons.tune_rounded,
      title: 'Preferências',
      subtitle: 'Personalize o comportamento da sua experiência.',
      children: [
        _switchRow(
          icon: Icons.grid_on_rounded,
          title: 'Modo compacto',
          subtitle: 'Reduz espaços e deixa as telas mais densas.',
          value: _compactMode,
          onChanged: (value) {
            setState(() => _compactMode = value);
            _savePreferences();
          },
        ),
        _divider(),
        _switchRow(
          icon: Icons.motion_photos_off_outlined,
          title: 'Reduzir animações',
          subtitle: 'Diminui transições e movimentos visuais.',
          value: _reduceMotion,
          onChanged: (value) {
            setState(() => _reduceMotion = value);
            _savePreferences();
          },
        ),
        _divider(),
        _switchRow(
          icon: Icons.delete_outline_rounded,
          title: 'Confirmar antes de apagar',
          subtitle: 'Pede confirmação antes de excluir registros.',
          value: _confirmBeforeDelete,
          onChanged: (value) {
            setState(() => _confirmBeforeDelete = value);
            _savePreferences();
          },
        ),
        if (_saving) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(minHeight: 2),
        ],
      ],
    );
  }

  Widget _buildTelegram() {
    return _panel(
      icon: Icons.send_rounded,
      title: 'Telegram',
      subtitle: 'Integrações de comunicação da sua conta.',
      children: [
        _infoRow(
          icon: Icons.telegram,
          title: 'Telegram',
          subtitle:
              'A integração desktop continua preservada. No Web, a conexão deve ser concluída pela versão compatível quando disponível.',
        ),
      ],
    );
  }

  Widget _buildSecurity() {
    return _panel(
      icon: Icons.shield_outlined,
      title: 'Segurança',
      subtitle: 'Gerencie senha, sessão e dados de acesso.',
      children: [
        _infoRow(
          icon: Icons.alternate_email_rounded,
          title: 'E-mail da conta',
          subtitle: _email,
        ),
        _divider(),
        _actionRow(
          icon: Icons.lock_outline_rounded,
          title: 'Senha',
          subtitle: 'Altere sua senha de acesso.',
          actionLabel: 'Alterar',
          onTap: _changePassword,
        ),
      ],
    );
  }

  Widget _buildBrain() {
    return _panel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle: 'Controle o acesso e a proteção do seu conhecimento.',
      children: [
        _infoRow(
          icon: Icons.cloud_done_outlined,
          title: 'Modo de dados',
          subtitle:
              'Na Web, o Cérebro usa Cloud com armazenamento criptografado.',
        ),
        _divider(),
        _infoRow(
          icon: Icons.shield_outlined,
          title: 'Proteção',
          subtitle:
              'A autorização do navegador permanece válida até revogação ou expiração.',
        ),
        _divider(),
        _actionRow(
          icon: Icons.psychology_alt_outlined,
          title: 'Abrir Cérebro',
          subtitle:
              'Acesse o Cérebro real e o gerenciamento Web já configurado.',
          actionLabel: 'Abrir',
          onTap: _openBrain,
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return _panel(
      icon: Icons.info_outline_rounded,
      title: 'Sobre',
      subtitle: 'Conheça a ideia por trás do EVRYLUX.',
      children: [
        _infoRow(
          icon: Icons.auto_awesome_outlined,
          title: 'EVRYLUX',
          subtitle:
              'Seu espaço para organizar conhecimento, estudo e evolução.',
        ),
        _divider(),
        _infoRow(
          icon: Icons.lock_outline_rounded,
          title: 'Privacidade',
          subtitle:
              'O Cérebro usa proteção criptografada e controle explícito de dispositivos.',
        ),
      ],
    );
  }

  Widget _switchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryDark),
          const SizedBox(width: 12),
          Expanded(child: _rowText(title, subtitle)),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _primaryDark),
          const SizedBox(width: 12),
          Expanded(child: _rowText(title, subtitle)),
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: _primaryDark),
          const SizedBox(width: 12),
          Expanded(child: _rowText(title, subtitle)),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _rowText(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: _text, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }

  Widget _divider() => const Divider(height: 1, color: _border);
}
