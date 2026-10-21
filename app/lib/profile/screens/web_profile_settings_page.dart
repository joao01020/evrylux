import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/screen/brain_screen.dart';
import '../../study/brain/devices/models/brain_device_record.dart';
import '../../study/brain/security/keys/brain_key_service.dart';
import '../../web_app/services/web_brain_device_service.dart';
import '../../web_app/services/web_brain_device_management_service.dart';
import '../../web_app/services/web_brain_recovery_key_service.dart';
import '../../web_app/services/web_brain_secure_storage.dart';
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

  // WEB BRAIN RECOVERY EXPORT - AUTHORIZED BROWSER
  late final WebBrainSecureStorage _brainStorage;
  late final WebBrainDeviceService _brainDeviceService;
  late final WebBrainRecoveryKeyService _brainRecoveryService;
  late final WebBrainDeviceManagementService _brainDeviceManagementService;

  bool _loadingBrainRecovery = true;
  bool _loadingBrainDevices = false;
  bool _brainAuthorized = false;
  bool _brainHasMasterKey = false;
  int? _brainKeyVersion;
  String? _currentBrainDeviceId;
  String? _brainDevicesError;
  String? _brainDeviceActionId;
  final Set<String> _visibleBrainFingerprints = <String>{};
  List<BrainDeviceRecord> _brainDevices = const <BrainDeviceRecord>[];
  Map<String, String> _brainDeviceCustomNames = const <String, String>{};
  bool _brainRecoveryAvailable = false;
  String? _brainRecoveryVaultId;

  User? get _user => Supabase.instance.client.auth.currentUser;
  String get _email => _user?.email ?? 'E-mail não disponível';

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;

    _brainStorage = WebBrainSecureStorage();
    _brainDeviceService = WebBrainDeviceService(storage: _brainStorage);
    _brainRecoveryService = WebBrainRecoveryKeyService(storage: _brainStorage);
    _brainDeviceManagementService = WebBrainDeviceManagementService(
      storage: _brainStorage,
    );

    _loadPreferences();
    unawaited(_loadBrainRecoveryAvailability());
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

  // WEB BRAIN RECOVERY EXPORT - AUTHORIZED BROWSER
  //
  // A opção de download não depende do app Linux.
  // O próprio navegador Web pode gerar a .evkey quando:
  //
  // - está autenticado;
  // - possui identidade Web local;
  // - a identidade está authorized no backend;
  // - possui a Master Key local deste Vault.
  //
  // A Master Key não é enviada ao Supabase durante o download.
  // O servidor recebe apenas o verifier necessário para permitir
  // futura recuperação por .evkey.
  // ============================================================

  Future<void> _loadBrainRecoveryAvailability() async {
    if (!mounted || _loadingBrainDevices) {
      return;
    }

    setState(() {
      _loadingBrainRecovery = true;
      _loadingBrainDevices = true;
      _brainDevicesError = null;
    });

    try {
      var vaultId = await _brainStorage.loadVaultId();

      if (vaultId == null || vaultId.trim().isEmpty) {
        vaultId = await _brainDeviceService.discoverVaultId();
      }

      final cleanVaultId = vaultId?.trim() ?? '';

      if (cleanVaultId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _brainRecoveryVaultId = null;
          _brainRecoveryAvailable = false;
          _brainAuthorized = false;
          _brainHasMasterKey = false;
          _brainKeyVersion = null;
          _currentBrainDeviceId = null;
          _brainDevices = const <BrainDeviceRecord>[];
          _brainDeviceCustomNames = const <String, String>{};
        });

        return;
      }

      final localDevice = await _brainStorage.loadDevice();
      final bundle = await _brainStorage.loadKeyBundle(vaultId: cleanVaultId);

      final authorized =
          localDevice != null &&
          await _brainDeviceService.isAuthorized(vaultId: cleanVaultId);

      var devices = const <BrainDeviceRecord>[];
      var customNames = const <String, String>{};
      String? devicesError;

      if (authorized && localDevice != null) {
        try {
          devices = await _brainDeviceManagementService.listDevices(
            vaultId: cleanVaultId,
          );
          customNames = await _brainDeviceManagementService.listCustomNames(
            vaultId: cleanVaultId,
          );
        } catch (error) {
          debugPrint(
            '[WEB PROFILE][BRAIN DEVICES] '
            'Falha ao carregar dispositivos: ${error.runtimeType}',
          );
          devicesError =
              'Não foi possível carregar os dispositivos do Cérebro.';
        }
      }

      if (!mounted) return;

      setState(() {
        _brainRecoveryVaultId = cleanVaultId;
        _brainAuthorized = authorized;
        _brainHasMasterKey = bundle != null;
        _brainKeyVersion = bundle?.keyVersion;
        _brainRecoveryAvailable = authorized && bundle != null;
        _currentBrainDeviceId = localDevice?.deviceId;
        _brainDevices = List<BrainDeviceRecord>.unmodifiable(devices);
        _brainDeviceCustomNames = Map<String, String>.unmodifiable(customNames);
        _brainDevicesError = devicesError;
      });
    } catch (error) {
      debugPrint(
        '[WEB PROFILE][BRAIN SETTINGS] '
        'Não foi possível validar o navegador atual: '
        '${error.runtimeType}',
      );

      if (!mounted) return;

      setState(() {
        _brainRecoveryAvailable = false;
        _brainAuthorized = false;
        _brainHasMasterKey = false;
        _brainKeyVersion = null;
        _brainDevices = const <BrainDeviceRecord>[];
        _brainDeviceCustomNames = const <String, String>{};
        _brainDevicesError = 'Não foi possível atualizar o status do Cérebro.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBrainRecovery = false;
          _loadingBrainDevices = false;
        });
      }
    }
  }

  String _brainRecoveryFileName() {
    final now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    final date = '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}';

    final time =
        '${twoDigits(now.hour)}'
        '${twoDigits(now.minute)}'
        '${twoDigits(now.second)}';

    return 'EVRYLUX_Brain_Recovery_$date-$time.evkey';
  }

  Future<String?> _askBrainRecoveryPassword() async {
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();

    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          var obscure = true;
          var errorText = '';

          return StatefulBuilder(
            builder: (context, setDialogState) {
              void submit() {
                final password = passwordController.text;
                final confirmation = confirmationController.text;

                if (password.length <
                    BrainKeyService.minimumRecoveryPasswordLength) {
                  setDialogState(() {
                    errorText =
                        'Use pelo menos '
                        '${BrainKeyService.minimumRecoveryPasswordLength} '
                        'caracteres.';
                  });
                  return;
                }

                if (password != confirmation) {
                  setDialogState(() {
                    errorText = 'As senhas não coincidem.';
                  });
                  return;
                }

                Navigator.of(dialogContext).pop(password);
              }

              return AlertDialog(
                title: const Text('Baixar chave de recuperação'),
                content: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Crie uma senha para proteger o arquivo '
                        '.evkey. A chave principal não será salva '
                        'em texto puro.',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        autofocus: true,
                        obscureText: obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Senha de proteção',
                          suffixIcon: IconButton(
                            tooltip: obscure
                                ? 'Mostrar senha'
                                : 'Ocultar senha',
                            onPressed: () {
                              setDialogState(() {
                                obscure = !obscure;
                              });
                            },
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmationController,
                        obscureText: obscure,
                        enableSuggestions: false,
                        autocorrect: false,
                        onSubmitted: (_) => submit(),
                        decoration: const InputDecoration(
                          labelText: 'Confirmar senha',
                        ),
                      ),
                      if (errorText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText,
                          style: const TextStyle(
                            color: Color(0xFFB3261E),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      const Text(
                        'Guarde o arquivo e a senha em locais '
                        'seguros. Eles permitem recuperar o '
                        'acesso ao Cérebro.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Baixar'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      passwordController.dispose();
      confirmationController.dispose();
    }
  }

  Future<void> _downloadBrainRecoveryKey() async {
    if (_loadingBrainRecovery) {
      return;
    }

    // Revalida no backend imediatamente antes de exportar.
    await _loadBrainRecoveryAvailability();

    if (!mounted) return;

    final vaultId = _brainRecoveryVaultId?.trim() ?? '';

    if (!_brainRecoveryAvailable || vaultId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Este navegador precisa estar autorizado '
              'e possuir a chave local do Cérebro.',
            ),
          ),
        );
      return;
    }

    final password = await _askBrainRecoveryPassword();

    if (password == null || !mounted) {
      return;
    }

    setState(() {
      _loadingBrainRecovery = true;
    });

    try {
      final bytes = await _brainRecoveryService.exportRecoveryFile(
        vaultId: vaultId,
        password: password,
      );

      final saved = await FilePicker.saveFile(
        dialogTitle: 'Salvar chave de recuperação do Cérebro',
        fileName: _brainRecoveryFileName(),
        bytes: bytes,
      );

      if (!mounted || saved == null) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Chave de recuperação .evkey '
              'baixada com sucesso.',
            ),
          ),
        );
    } catch (error) {
      debugPrint(
        '[WEB PROFILE][BRAIN RECOVERY] '
        'Falha ao exportar .evkey: '
        '${error.runtimeType}',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível baixar a chave. '
              'Confirme que este navegador continua '
              'autorizado.',
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _loadingBrainRecovery = false;
        });
      }
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

  void _selectSection(WebProfileSettingsSection section) {
    setState(() {
      _section = section;
    });

    if (section == WebProfileSettingsSection.brain) {
      unawaited(_loadBrainRecoveryAvailability());
    }
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
        onSelected: (_) => _selectSection(section),
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
          onTap: () => _selectSection(section),
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

  static const int _brainAuthorizedDeviceLimit = 6;

  List<BrainDeviceRecord> _brainDevicesForDisplay() {
    final devices = _brainDevices
        .where((device) => !device.isRevoked)
        .toList(growable: true);

    devices.sort((a, b) {
      final aCurrent = a.deviceId == _currentBrainDeviceId;
      final bCurrent = b.deviceId == _currentBrainDeviceId;

      if (aCurrent != bCurrent) {
        return aCurrent ? -1 : 1;
      }

      if (a.isPending != b.isPending) {
        return a.isPending ? -1 : 1;
      }

      final aDate = a.lastSeenAt ?? a.createdAt;
      final bDate = b.lastSeenAt ?? b.createdAt;

      return bDate.compareTo(aDate);
    });

    return List<BrainDeviceRecord>.unmodifiable(devices);
  }

  int _brainAuthorizedDeviceCount() {
    return _brainDevices.where((device) => device.isAuthorized).length;
  }

  String _brainDeviceDisplayName(BrainDeviceRecord device) {
    final custom = _brainDeviceCustomNames[device.deviceId]?.trim();

    if (custom != null && custom.isNotEmpty) {
      return custom;
    }

    return device.deviceName;
  }

  String _maskedBrainFingerprint(String fingerprint) {
    final clean = fingerprint.trim();

    if (clean.isEmpty) {
      return '••••••••••••';
    }

    final groups = clean.split(':');

    if (groups.length > 1) {
      return List<String>.filled(groups.length, '••').join(':');
    }

    return List<String>.filled(clean.length.clamp(8, 24), '•').join();
  }

  String _formatBrainDeviceDate(DateTime? date) {
    if (date == null) {
      return 'Sem registro';
    }

    final local = date.toLocal();

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} '
        'às ${two(local.hour)}:${two(local.minute)}';
  }

  String _brainDeviceStatusLabel(BrainDeviceRecord device) {
    if (device.isAuthorized) {
      return 'Autorizado';
    }

    if (device.isPending) {
      return device.isRecoveryExpired ? 'Expirado' : 'Pendente';
    }

    return 'Revogado';
  }

  Color _brainDeviceStatusColor(BrainDeviceRecord device) {
    if (device.isAuthorized) {
      return _primaryDark;
    }

    if (device.isPending && !device.isRecoveryExpired) {
      return const Color(0xFF9A6700);
    }

    return const Color(0xFFB3261E);
  }

  Future<void> _showBrainMessage(String message, {bool error = false}) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? const Color(0xFFB3261E) : null,
        ),
      );
  }

  Future<void> _showRenameBrainDeviceDialog(BrainDeviceRecord device) async {
    if (_brainDeviceActionId != null) {
      return;
    }

    final controller = TextEditingController(
      text: _brainDeviceDisplayName(device),
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final clean = controller.text.trim();

              if (clean.length < 2) {
                setDialogState(() {
                  validationError = 'Use pelo menos 2 caracteres.';
                });
                return;
              }

              if (clean.length > 80) {
                setDialogState(() {
                  validationError = 'Use no máximo 80 caracteres.';
                });
                return;
              }

              Navigator.of(dialogContext).pop(clean);
            }

            return AlertDialog(
              title: const Text('Renomear dispositivo'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 80,
                  onSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Nome do dispositivo',
                    hintText: 'Ex.: Chrome - PC principal',
                    errorText: validationError,
                    prefixIcon: const Icon(Icons.devices_other_rounded),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: submit,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (newName == null || !mounted) {
      return;
    }

    setState(() {
      _brainDeviceActionId = device.deviceId;
    });

    try {
      final vaultId = _brainRecoveryVaultId?.trim() ?? '';

      if (vaultId.isEmpty) {
        throw StateError('Vault não disponível.');
      }

      final savedName = await _brainDeviceManagementService.renameDevice(
        vaultId: vaultId,
        targetDeviceId: device.deviceId,
        newName: newName,
      );

      if (!mounted) return;

      setState(() {
        _brainDeviceCustomNames = <String, String>{
          ..._brainDeviceCustomNames,
          device.deviceId: savedName,
        };
      });

      await _showBrainMessage('Dispositivo renomeado para "$savedName".');

      await _loadBrainRecoveryAvailability();
    } catch (error) {
      await _showBrainMessage(
        'Não foi possível renomear o dispositivo.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _brainDeviceActionId = null;
        });
      }
    }
  }

  Future<void> _showAddBrainDeviceDialog() async {
    final count = _brainAuthorizedDeviceCount();
    final limitReached = count >= _brainAuthorizedDeviceLimit;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Adicionar dispositivo'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              limitReached
                  ? 'O limite de 6 dispositivos autorizados foi atingido. '
                        'Revogue um acesso antes de autorizar outro.'
                  : 'No novo dispositivo ou navegador, abra o Cérebro e '
                        'solicite acesso. A solicitação aparecerá aqui como '
                        'Pendente para você conferir o fingerprint e aprovar.',
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRevokeBrainDevice(
    BrainDeviceRecord device, {
    bool denyPending = false,
  }) async {
    if (_brainDeviceActionId != null ||
        device.deviceId == _currentBrainDeviceId) {
      return;
    }

    final title = denyPending ? 'Negar solicitação' : 'Revogar acesso';
    final action = denyPending ? 'Negar' : 'Revogar acesso';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              denyPending
                  ? 'Negar a solicitação de '
                        '"${_brainDeviceDisplayName(device)}"?\n\n'
                        'O dispositivo poderá criar uma nova solicitação '
                        'no futuro.'
                  : 'Revogar o acesso de '
                        '"${_brainDeviceDisplayName(device)}"?\n\n'
                        'Ele não poderá mais sincronizar novos dados do '
                        'Cérebro pela nuvem. Dados já existentes localmente '
                        'não podem ser apagados remotamente.',
              style: const TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB3261E),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: Icon(
                denyPending ? Icons.close_rounded : Icons.block_rounded,
                size: 18,
              ),
              label: Text(action),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _brainDeviceActionId = device.deviceId;
    });

    try {
      final vaultId = _brainRecoveryVaultId?.trim() ?? '';

      if (vaultId.isEmpty) {
        throw StateError('Vault não disponível.');
      }

      await _brainDeviceManagementService.revokeDevice(
        vaultId: vaultId,
        target: device,
      );

      await _showBrainMessage(
        denyPending
            ? 'Solicitação de "${_brainDeviceDisplayName(device)}" negada.'
            : 'Acesso de "${_brainDeviceDisplayName(device)}" revogado.',
      );

      await _loadBrainRecoveryAvailability();
    } catch (error) {
      await _showBrainMessage(
        denyPending
            ? 'Não foi possível negar a solicitação.'
            : 'Não foi possível revogar o dispositivo.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _brainDeviceActionId = null;
        });
      }
    }
  }

  Future<void> _confirmApproveBrainDevice(BrainDeviceRecord device) async {
    if (_brainDeviceActionId != null || !device.isPending) {
      return;
    }

    if (_brainAuthorizedDeviceCount() >= _brainAuthorizedDeviceLimit) {
      await _showBrainMessage(
        'Limite de 3 dispositivos autorizados atingido. '
        'Revogue um acesso antes de aprovar outro.',
        error: true,
      );
      return;
    }

    if (device.isRecoveryExpired) {
      await _showBrainMessage(
        'Esta solicitação expirou. Gere uma nova solicitação '
        'no dispositivo.',
        error: true,
      );
      return;
    }

    final controller = TextEditingController();

    final fingerprint = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aprovar dispositivo'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _brainDeviceDisplayName(device),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Compare o fingerprint mostrado no novo dispositivo e '
                  'digite-o abaixo exatamente como aparece.',
                  style: TextStyle(height: 1.45),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Fingerprint do novo dispositivo',
                    hintText: 'AA:BB:CC:DD:EE:FF:...',
                    prefixIcon: Icon(Icons.fingerprint_rounded),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                final clean = controller.text.trim();

                if (clean.isNotEmpty) {
                  Navigator.of(dialogContext).pop(clean);
                }
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Aprovar'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (fingerprint == null || !mounted) {
      return;
    }

    setState(() {
      _brainDeviceActionId = device.deviceId;
    });

    try {
      final vaultId = _brainRecoveryVaultId?.trim() ?? '';

      if (vaultId.isEmpty) {
        throw StateError('Vault não disponível.');
      }

      await _brainDeviceManagementService.approvePendingDevice(
        vaultId: vaultId,
        target: device,
        expectedFingerprint: fingerprint,
      );

      await _showBrainMessage(
        'Dispositivo "${_brainDeviceDisplayName(device)}" aprovado.',
      );

      await _loadBrainRecoveryAvailability();
    } catch (error) {
      await _showBrainMessage(
        'Não foi possível aprovar o dispositivo. '
        'Confira o fingerprint informado.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _brainDeviceActionId = null;
        });
      }
    }
  }

  Widget _buildBrainModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required bool enabled,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? _primary.withValues(alpha: 0.82) : _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? _primaryDark.withValues(alpha: 0.35) : _border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: enabled ? _primaryDark : _muted),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled ? _text : _muted,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryDark.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: _primaryDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            size: 18,
            color: enabled ? _primaryDark : _muted,
          ),
        ],
      ),
    );
  }

  Widget _buildBrainDataModeSection() {
    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_alt_rounded, size: 20, color: _primaryDark),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo de dados',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Escolha onde o Cérebro mantém seus dados.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 540;

              final local = _buildBrainModeCard(
                icon: Icons.laptop_rounded,
                title: 'Local',
                subtitle:
                    'No navegador, o modo Local isolado ainda não possui '
                    'o mesmo filesystem do app desktop.',
                selected: false,
                enabled: false,
                badge: 'Desktop',
              );

              final cloud = _buildBrainModeCard(
                icon: Icons.cloud_done_outlined,
                title: 'Cloud  •  Recomendado',
                subtitle:
                    'Cópia criptografada na nuvem com proteção E2EE e '
                    'sincronização entre dispositivos autorizados.',
                selected: true,
                enabled: true,
              );

              if (compact) {
                return Column(
                  children: [local, const SizedBox(height: 10), cloud],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: local),
                  const SizedBox(width: 10),
                  Expanded(child: cloud),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBrainProtectionSection() {
    final vaultId = _brainRecoveryVaultId?.trim();
    final protectionReady = _brainAuthorized && _brainHasMasterKey;

    final statusLabel = _loadingBrainRecovery
        ? 'Verificando...'
        : protectionReady
        ? 'Proteção ativa'
        : _brainAuthorized
        ? 'Chave local indisponível'
        : 'Navegador não autorizado';

    final keyLabel = _loadingBrainRecovery
        ? 'Verificando...'
        : _brainHasMasterKey
        ? 'Disponível neste navegador'
        : 'Indisponível';

    final cloudLabel = protectionReady
        ? 'Proteção automática na nuvem'
        : 'Cloud E2EE aguardando autorização';

    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 20, color: _primaryDark),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proteção do Cérebro',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Seus dados ficam criptografados antes de sair '
                      'deste navegador.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Atualizar status de proteção',
                onPressed: _loadingBrainRecovery
                    ? null
                    : _loadBrainRecoveryAvailability,
                icon: _loadingBrainRecovery
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildBrainProtectionStatusRow(
            icon: protectionReady
                ? Icons.verified_user_outlined
                : Icons.shield_outlined,
            label: 'Status',
            value: statusLabel,
            good: protectionReady,
          ),
          const SizedBox(height: 10),
          _buildBrainProtectionStatusRow(
            icon: Icons.key_rounded,
            label: 'Chave de segurança',
            value: keyLabel,
            good: _brainHasMasterKey,
          ),
          const SizedBox(height: 10),
          _buildBrainProtectionStatusRow(
            icon: Icons.cloud_done_outlined,
            label: 'Proteção na nuvem',
            value: cloudLabel,
            good: protectionReady,
          ),
          const SizedBox(height: 14),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 4, bottom: 2),
              leading: const Icon(Icons.tune_rounded, size: 18, color: _muted),
              title: const Text(
                'Detalhes técnicos',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: const Text(
                'Informações úteis para diagnóstico e suporte.',
                style: TextStyle(color: _muted, fontSize: 10),
              ),
              children: [
                _buildBrainTechnicalRow(
                  'Vault ID',
                  vaultId == null || vaultId.isEmpty ? 'Indisponível' : vaultId,
                ),
                const SizedBox(height: 8),
                _buildBrainTechnicalRow(
                  'Versão da chave',
                  _brainKeyVersion?.toString() ?? '-',
                ),
                const SizedBox(height: 8),
                _buildBrainTechnicalRow(
                  'Chave principal',
                  _brainHasMasterKey ? 'Disponível' : 'Indisponível',
                  good: _brainHasMasterKey,
                ),
                const SizedBox(height: 8),
                _buildBrainTechnicalRow(
                  'Modo técnico',
                  'Cloud E2EE',
                  good: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainProtectionStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool good,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: good ? _primary.withValues(alpha: 0.38) : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: good ? _primaryDark.withValues(alpha: 0.18) : _border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: good ? _primaryDark : _muted),
          const SizedBox(width: 10),
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: good ? _primaryDark : _text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainTechnicalRow(
    String label,
    String value, {
    bool good = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: TextStyle(
              color: good ? _primaryDark : _text,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrainRecoveryKeySection() {
    final subtitle = _loadingBrainRecovery
        ? 'Verificando a autorização deste navegador...'
        : _brainRecoveryAvailable
        ? 'Baixe uma cópia protegida da chave deste Cérebro. '
              'Ela só funciona junto da senha criada no download.'
        : 'Disponível somente quando este navegador estiver '
              'autorizado e possuir a chave local do Cérebro.';

    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          final text = _rowText('Chave de recuperação', subtitle);

          final action = OutlinedButton.icon(
            onPressed: _brainRecoveryAvailable && !_loadingBrainRecovery
                ? _downloadBrainRecoveryKey
                : null,
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Baixar chave'),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _brainRecoveryAvailable
                          ? Icons.key_rounded
                          : Icons.key_off_outlined,
                      color: _primaryDark,
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: text),
                  ],
                ),
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerLeft, child: action),
              ],
            );
          }

          return Row(
            children: [
              Icon(
                _brainRecoveryAvailable
                    ? Icons.key_rounded
                    : Icons.key_off_outlined,
                color: _primaryDark,
              ),
              const SizedBox(width: 12),
              Expanded(child: text),
              const SizedBox(width: 12),
              action,
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrainDevicesSection() {
    if (_loadingBrainDevices && _brainDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Carregando dispositivos autorizados...',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (!_brainAuthorized) {
      return _infoRow(
        icon: Icons.devices_other_rounded,
        title: 'Dispositivos do Cérebro',
        subtitle:
            'Autorize este navegador para gerenciar os dispositivos '
            'que podem acessar o Cérebro.',
      );
    }

    if (_brainDevicesError != null) {
      return _actionRow(
        icon: Icons.error_outline_rounded,
        title: 'Dispositivos do Cérebro',
        subtitle: _brainDevicesError!,
        actionLabel: 'Tentar novamente',
        onTap: _loadBrainRecoveryAvailability,
      );
    }

    final devices = _brainDevicesForDisplay();
    final count = _brainAuthorizedDeviceCount();
    final limitReached = count >= _brainAuthorizedDeviceLimit;

    return Container(
      color: _surfaceSoft,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispositivos do Cérebro',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Controle quais computadores e navegadores '
                        'podem sincronizar seus dados criptografados.',
                        style: TextStyle(color: _muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: limitReached
                        ? const Color(0xFFB3261E).withValues(alpha: 0.08)
                        : _primaryDark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count/$_brainAuthorizedDeviceLimit',
                    style: TextStyle(
                      color: limitReached
                          ? const Color(0xFFB3261E)
                          : _primaryDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: limitReached
                      ? 'Limite de 3 dispositivos atingido'
                      : 'Adicionar dispositivo',
                  onPressed: _showAddBrainDeviceDialog,
                  icon: Icon(
                    Icons.add_rounded,
                    color: limitReached ? _muted : _primaryDark,
                  ),
                ),
                IconButton(
                  tooltip: 'Atualizar dispositivos',
                  onPressed: _loadingBrainDevices
                      ? null
                      : _loadBrainRecoveryAvailability,
                  icon: _loadingBrainDevices
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          _divider(),
          if (devices.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Nenhum dispositivo do Cérebro foi encontrado.',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ),
            )
          else
            for (var index = 0; index < devices.length; index++) ...[
              _buildBrainDeviceRow(devices[index]),
              if (index < devices.length - 1) _divider(),
            ],
        ],
      ),
    );
  }

  Widget _buildBrainDeviceRow(BrainDeviceRecord device) {
    final isCurrent = device.deviceId == _currentBrainDeviceId;
    final actionRunning = _brainDeviceActionId == device.deviceId;
    final actionFree = _brainDeviceActionId == null;
    final fingerprintVisible = _visibleBrainFingerprints.contains(
      device.deviceId,
    );
    final count = _brainAuthorizedDeviceCount();
    final limitReached = count >= _brainAuthorizedDeviceLimit;
    final canApprove =
        !isCurrent &&
        device.isPending &&
        !device.isRecoveryExpired &&
        !limitReached &&
        actionFree;
    final canDeny = !isCurrent && device.isPending && actionFree;
    final canRevoke = !isCurrent && device.isAuthorized && actionFree;

    Widget action() {
      if (actionRunning) {
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (device.isPending && !isCurrent) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
              ),
              onPressed: canDeny
                  ? () => _confirmRevokeBrainDevice(device, denyPending: true)
                  : null,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Negar'),
            ),
            FilledButton.tonalIcon(
              onPressed: canApprove
                  ? () => _confirmApproveBrainDevice(device)
                  : null,
              icon: Icon(
                device.isRecoveryExpired
                    ? Icons.timer_off_outlined
                    : Icons.verified_user_outlined,
                size: 16,
              ),
              label: Text(
                device.isRecoveryExpired
                    ? 'Expirado'
                    : limitReached
                    ? 'Limite 6/6'
                    : 'Aprovar',
              ),
            ),
          ],
        );
      }

      if (canRevoke) {
        return OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFB3261E),
          ),
          onPressed: () => _confirmRevokeBrainDevice(device),
          icon: const Icon(Icons.block_rounded, size: 16),
          label: const Text('Revogar acesso'),
        );
      }

      return const SizedBox.shrink();
    }

    Widget details() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _brainDeviceDisplayName(device),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: 'Renomear dispositivo',
                      onPressed: actionFree
                          ? () => _showRenameBrainDeviceDialog(device)
                          : null,
                      icon: const Icon(Icons.edit_outlined, size: 15),
                    ),
                  ),
                ],
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Este dispositivo',
                    style: TextStyle(
                      color: _primaryDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _brainDeviceStatusColor(
                    device,
                  ).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _brainDeviceStatusLabel(device),
                  style: TextStyle(
                    color: _brainDeviceStatusColor(device),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Flexible(
                child: SelectableText(
                  fingerprintVisible
                      ? 'Fingerprint: ${device.keyFingerprint}'
                      : 'Fingerprint: ${_maskedBrainFingerprint(device.keyFingerprint)}',
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 26,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: fingerprintVisible
                      ? 'Ocultar fingerprint'
                      : 'Mostrar fingerprint',
                  onPressed: () {
                    setState(() {
                      if (fingerprintVisible) {
                        _visibleBrainFingerprints.remove(device.deviceId);
                      } else {
                        _visibleBrainFingerprints.add(device.deviceId);
                      }
                    });
                  },
                  icon: Icon(
                    fingerprintVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 15,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            'Último acesso: '
            '${_formatBrainDeviceDate(device.lastSeenAt)}',
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      );
    }

    final deviceIcon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isCurrent ? _primary : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Icon(
        isCurrent ? Icons.computer_rounded : Icons.devices_other_rounded,
        size: 20,
        color: isCurrent ? _primaryDark : _muted,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

        if (compact) {
          return Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    deviceIcon,
                    const SizedBox(width: 12),
                    Expanded(child: details()),
                  ],
                ),
                if (canApprove || canDeny || canRevoke || actionRunning) ...[
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: action()),
                ],
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              deviceIcon,
              const SizedBox(width: 12),
              Expanded(child: details()),
              const SizedBox(width: 12),
              action(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrainDataProtectionSection() {
    return Container(
      color: _surfaceSoft,
      padding: const EdgeInsets.all(14),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 20, color: _primaryDark),
              SizedBox(width: 10),
              Text(
                'Proteção dos dados',
                style: TextStyle(color: _text, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '• A Master Key permanece somente nos dispositivos autorizados.\n'
            '• Uma cópia criptografada dos objetos é mantida na nuvem.\n'
            '• O banco recebe apenas objetos criptografados.\n'
            '• Revogar um dispositivo impede novas operações Cloud.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.55),
          ),
        ],
      ),
    );
  }

  Widget _buildBrainRecoveryDeviceSection() {
    final protected = _brainAuthorized && _brainHasMasterKey;

    if (protected) {
      return Container(
        color: _surfaceSoft,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.verified_user_outlined, color: _primaryDark),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recuperar em outro dispositivo',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Este navegador já possui acesso ao seu Cérebro. '
                    'Para autorizar outro, abra o Cérebro no novo '
                    'dispositivo e aprove a solicitação acima.',
                    style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            _BrainWebBadge(text: 'Protegido', good: true),
          ],
        ),
      );
    }

    return _actionRow(
      icon: Icons.shield_outlined,
      title: 'Recuperar em outro dispositivo',
      subtitle:
          'Este navegador ainda precisa concluir a autorização. '
          'Abra o Cérebro para usar aprovação ou arquivo .evkey.',
      actionLabel: 'Recuperar',
      onTap: _openBrain,
    );
  }

  Widget _buildBrain() {
    return _panel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle:
          'Controle onde seus conhecimentos ficam, como são '
          'protegidos e como podem ser recuperados.',
      children: [
        _buildBrainDataModeSection(),
        _divider(),
        _buildBrainProtectionSection(),
        _divider(),
        _buildBrainRecoveryKeySection(),
        _divider(),
        _buildBrainDevicesSection(),
        _divider(),
        _buildBrainDataProtectionSection(),
        _divider(),
        _buildBrainRecoveryDeviceSection(),
        _divider(),
        _actionRow(
          icon: Icons.psychology_alt_outlined,
          title: 'Abrir Cérebro',
          subtitle: 'Acesse suas notas, trilhas e o gerenciamento do Cérebro.',
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

class _BrainWebBadge extends StatelessWidget {
  const _BrainWebBadge({required this.text, required this.good});

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) {
    const goodColor = Color(0xFF3B6939);
    const neutralColor = Color(0xFF68746B);

    final color = good ? goodColor : neutralColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
