import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_info.dart';

import '../../app/dependencies/app_dependencies.dart';
import '../../study/brain/devices/models/brain_device_record.dart';
import 'legal/privacy_policy_page.dart';
import 'legal/terms_of_use_page.dart';

// ============================================================
// PROFILE SETTINGS PAGE
// ============================================================
//
// Página dedicada para:
//
// - Preferências;
// - Segurança da conta;
// - Cérebro;
// - Sobre o aplicativo.
//
// Preferências são salvas no user_metadata do Supabase.
// Senha é alterada pelo Supabase Auth.
//
// ============================================================

enum ProfileSettingsSection { preferences, security, brain, about }

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({
    super.key,
    this.initialSection = ProfileSettingsSection.preferences,
  });

  final ProfileSettingsSection initialSection;

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(0xFFF7FBF1);

  static const Color _surface = Color(0xFFFFFFFF);

  static const Color _surfaceSoft = Color(0xFFF3F8EE);

  static const Color _border = Color(0xFFC7DFC9);

  static const Color _primary = Color(0xFFBCF0B4);

  static const Color _primaryDark = Color(0xFF3B6939);

  static const Color _text = Color(0xFF172019);

  static const Color _muted = Color(0xFF68746B);

  static const Color _danger = Color(0xFFB3261E);

  // ============================================================
  // STATE
  // ============================================================

  late ProfileSettingsSection _section;

  bool _compactMode = false;

  bool _reduceMotion = false;

  bool _confirmBeforeDelete = true;

  bool _savingPreferences = false;

  bool _changingPassword = false;

  // ============================================================
  // BRAIN SETTINGS
  // ============================================================

  bool _loadingBrainSettings = false;

  bool _switchingBrainMode = false;

  bool _brainCloudMode = false;

  String? _brainVaultId;

  int? _brainKeyVersion;

  bool _brainMasterKeyAvailable = false;

  // ============================================================
  // BRAIN DEVICES
  // ============================================================

  bool _loadingBrainDevices = false;

  String? _brainDevicesError;

  String? _currentBrainDeviceId;

  String? _revokingBrainDeviceId;

  List<BrainDeviceRecord> _brainDevices = const <BrainDeviceRecord>[];

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

    _loadBrainSettings();
  }

  // ============================================================
  // USER
  // ============================================================

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _email => _user?.email ?? 'E-mail não disponível';

  // ============================================================
  // LOAD PREFERENCES
  // ============================================================

  void _loadPreferences() {
    final metadata = _user?.userMetadata ?? const <String, dynamic>{};

    _compactMode = metadata['ui_compact_mode'] == true;

    _reduceMotion = metadata['ui_reduce_motion'] == true;

    final confirm = metadata['confirm_before_delete'];

    _confirmBeforeDelete = confirm is bool ? confirm : true;
  }

  // ============================================================
  // SAVE PREFERENCES
  // ============================================================

  Future<void> _savePreferences() async {
    if (_savingPreferences) {
      return;
    }

    setState(() {
      _savingPreferences = true;
      _message = null;
    });

    try {
      final current = Map<String, dynamic>.from(
        _user?.userMetadata ?? const <String, dynamic>{},
      );

      current['ui_compact_mode'] = _compactMode;

      current['ui_reduce_motion'] = _reduceMotion;

      current['confirm_before_delete'] = _confirmBeforeDelete;

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: current),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Preferências salvas com sucesso.';
        _messageIsError = false;
      });
    } catch (error) {
      debugPrint('[PROFILE SETTINGS] Erro salvando preferências: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Não foi possível salvar as preferências.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingPreferences = false;
        });
      }
    }
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _changePassword() async {
    if (_changingPassword) {
      return;
    }

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    var obscurePassword = true;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _border),
              ),
              title: const Row(
                children: [
                  Icon(Icons.lock_reset_rounded, color: _primaryDark),
                  SizedBox(width: 10),
                  Text('Alterar senha'),
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
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setDialogState(() {
                              obscurePassword = !obscurePassword;
                            });
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

                    const SizedBox(height: 12),

                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar nova senha',
                        prefixIcon: Icon(Icons.verified_user_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(false);
                  },
                  child: const Text('Cancelar'),
                ),

                FilledButton(
                  onPressed: () {
                    final password = newPasswordController.text;

                    final confirm = confirmPasswordController.text;

                    if (password.length < 8) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'A senha deve ter pelo menos 8 caracteres.',
                          ),
                        ),
                      );

                      return;
                    }

                    if (password != confirm) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('As senhas não coincidem.'),
                        ),
                      );

                      return;
                    }

                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('Atualizar senha'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      newPasswordController.dispose();

      confirmPasswordController.dispose();

      return;
    }

    final password = newPasswordController.text;

    newPasswordController.dispose();

    confirmPasswordController.dispose();

    setState(() {
      _changingPassword = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Senha atualizada com sucesso.';
        _messageIsError = false;
      });
    } catch (error) {
      debugPrint('[PROFILE SETTINGS] Erro alterando senha: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Não foi possível alterar a senha.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _changingPassword = false;
        });
      }
    }
  }

  // ============================================================
  // LOAD BRAIN SETTINGS
  // ============================================================

  Future<void> _loadBrainSettings() async {
    if (_loadingBrainSettings) {
      return;
    }

    setState(() {
      _loadingBrainSettings = true;
    });

    try {
      if (!brainDataModeController.isInitialized) {
        await brainDataModeController.initialize();
      }

      final manifest = await brainVaultService.openVault();

      final hasMasterKey = await brainKeyService.hasKeyBundle(
        vaultId: manifest.vaultId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _brainCloudMode = brainDataModeController.isCloudMode;

        _brainVaultId = manifest.vaultId;

        _brainKeyVersion = manifest.keyVersion;

        _brainMasterKeyAvailable = hasMasterKey;
      });

      await _loadBrainDevices();
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro carregando configurações do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Não foi possível carregar todas as configurações do Cérebro.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBrainSettings = false;
        });
      }
    }
  }

  // ============================================================
  // SWITCH BRAIN DATA MODE
  // ============================================================

  Future<void> _setBrainCloudMode(bool cloud) async {
    if (_switchingBrainMode) {
      return;
    }

    setState(() {
      _switchingBrainMode = true;
      _message = null;
    });

    try {
      if (cloud) {
        if (_user == null) {
          throw StateError('Entre na sua conta antes de ativar o modo Cloud.');
        }

        await brainDataModeController.useCloudMode();
      } else {
        await brainDataModeController.useLocalMode();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _brainCloudMode = brainDataModeController.isCloudMode;

        _message = cloud
            ? 'Modo Cloud ativado. O Cérebro continua local-first e sincroniza somente objetos criptografados.'
            : 'Modo Local ativado. O Cérebro não realizará sincronização em nuvem.';

        _messageIsError = false;
      });

      if (cloud) {
        syncService.requestSync();
      }
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro alterando modo do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Não foi possível alterar o modo de dados do Cérebro.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _switchingBrainMode = false;
        });
      }
    }
  }

  // ============================================================
  // BRAIN BACKUP INFO
  // ============================================================
  //
  // A infraestrutura .evbrain já existe na camada de backup.
  //
  // Nesta tela deixamos a entrada centralizada. O seletor de
  // arquivo/exportação física será conectado no próximo bloco
  // específico da Fase 08 sem misturar file picker nesta página.
  //
  // ============================================================

  void _showBrainBackupPending({required bool importBackup}) {
    setState(() {
      _message = importBackup
          ? 'Importação .evbrain: infraestrutura pronta; falta conectar o seletor de arquivo nesta tela.'
          : 'Exportação .evbrain: infraestrutura pronta; falta conectar o seletor de destino nesta tela.';

      _messageIsError = false;
    });
  }

  // ============================================================
  // LOAD BRAIN DEVICES
  // ============================================================
  //
  // A tela não conversa diretamente com RPCs do Supabase.
  //
  // ProfileSettingsPage
  //        ↓
  // BrainDeviceAuthorizationService
  //        ↓
  // BrainDeviceRemotePort
  //        ↓
  // BrainDeviceSupabaseService
  //
  // ============================================================

  Future<void> _loadBrainDevices() async {
    if (_loadingBrainDevices) {
      return;
    }

    setState(() {
      _loadingBrainDevices = true;
      _brainDevicesError = null;
    });

    try {
      final manifest = await brainVaultService.openVault();

      final local = await brainDeviceIdentityService.loadLocalSecrets();

      final devices = await brainDeviceAuthorizationService.listDevices(
        vaultId: manifest.vaultId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentBrainDeviceId = local?.deviceId;

        _brainDevices = List<BrainDeviceRecord>.unmodifiable(devices);

        _brainDevicesError = null;
      });
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro carregando dispositivos do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _brainDevicesError =
            'Não foi possível carregar os dispositivos do Cérebro.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingBrainDevices = false;
        });
      }
    }
  }

  // ============================================================
  // CONFIRM REVOKE DEVICE
  // ============================================================

  Future<void> _confirmRevokeBrainDevice(BrainDeviceRecord device) async {
    if (_revokingBrainDeviceId != null) {
      return;
    }

    final isCurrentDevice = device.deviceId == _currentBrainDeviceId;

    if (isCurrentDevice) {
      setState(() {
        _message = 'Este dispositivo não pode ser revogado por esta tela.';
        _messageIsError = true;
      });

      return;
    }

    if (device.isRevoked) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          title: const Row(
            children: [
              Icon(Icons.phonelink_erase_rounded, color: _danger),
              SizedBox(width: 10),
              Expanded(child: Text('Revogar acesso')),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              'Revogar o acesso de "${device.deviceName}"?\n\n'
              'Este dispositivo não poderá mais sincronizar '
              'novos dados do Cérebro pela nuvem.\n\n'
              'Dados e chaves que já existam localmente nesse '
              'computador não podem ser apagados remotamente.',
              style: const TextStyle(color: _muted, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              icon: const Icon(Icons.block_rounded, size: 18),
              label: const Text('Revogar acesso'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _revokeBrainDevice(device);
  }

  // ============================================================
  // REVOKE DEVICE
  // ============================================================

  Future<void> _revokeBrainDevice(BrainDeviceRecord device) async {
    if (_revokingBrainDeviceId != null) {
      return;
    }

    setState(() {
      _revokingBrainDeviceId = device.deviceId;

      _message = null;
    });

    try {
      final manifest = await brainVaultService.openVault();

      await brainDeviceAuthorizationService.revokeDevice(
        vaultId: manifest.vaultId,
        targetDeviceId: device.deviceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message = 'Acesso de "${device.deviceName}" revogado com sucesso.';
        _messageIsError = false;
      });

      await _loadBrainDevices();
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro revogando dispositivo: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _message =
            'Não foi possível revogar o acesso de '
            '"${device.deviceName}".';
        _messageIsError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _revokingBrainDeviceId = null;
        });
      }
    }
  }

  // ============================================================
  // BRAIN DEVICE STATUS
  // ============================================================

  String _brainDeviceStatusLabel(BrainDeviceRecord device) {
    if (device.isAuthorized) {
      return 'Autorizado';
    }

    if (device.isPending) {
      return 'Pendente';
    }

    return 'Revogado';
  }

  Color _brainDeviceStatusColor(BrainDeviceRecord device) {
    if (device.isAuthorized) {
      return _primaryDark;
    }

    if (device.isPending) {
      return const Color(0xFF9A6700);
    }

    return _danger;
  }

  // ============================================================
  // DATE LABEL
  // ============================================================

  String _formatBrainDeviceDate(DateTime? value) {
    if (value == null) {
      return 'sem registro';
    }

    final local = value.toLocal();

    final day = local.day.toString().padLeft(2, '0');

    final month = local.month.toString().padLeft(2, '0');

    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(2, '0');

    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  // ============================================================
  // BRAIN DEVICES SECTION
  // ============================================================

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
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_brainDevicesError != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                _brainDevicesError!,
                style: const TextStyle(
                  color: _danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(width: 10),

            TextButton.icon(
              onPressed: _loadBrainDevices,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_brainDevices.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Nenhum dispositivo do Cérebro foi encontrado.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            IconButton(
              tooltip: 'Atualizar',
              onPressed: _loadBrainDevices,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      );
    }

    return Column(
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
                      'Controle quais computadores podem sincronizar seus dados criptografados.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Atualizar dispositivos',
                onPressed: _loadingBrainDevices ? null : _loadBrainDevices,
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

        const Divider(height: 1, color: _border),

        for (var index = 0; index < _brainDevices.length; index++) ...[
          _buildBrainDeviceRow(_brainDevices[index]),

          if (index < _brainDevices.length - 1)
            const Divider(height: 1, color: _border),
        ],
      ],
    );
  }

  // ============================================================
  // BRAIN DEVICE ROW
  // ============================================================

  Widget _buildBrainDeviceRow(BrainDeviceRecord device) {
    final isCurrent = device.deviceId == _currentBrainDeviceId;

    final revoking = _revokingBrainDeviceId == device.deviceId;

    final statusColor = _brainDeviceStatusColor(device);

    final canRevoke =
        !isCurrent && device.isAuthorized && _revokingBrainDeviceId == null;

    final lastSeen = _formatBrainDeviceDate(device.lastSeenAt);

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCurrent ? _primary : _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? _primaryDark.withValues(alpha: 0.25)
                    : _border,
              ),
            ),
            child: Icon(
              isCurrent ? Icons.computer_rounded : Icons.devices_other_rounded,
              size: 20,
              color: isCurrent ? _primaryDark : _muted,
            ),
          ),

          const SizedBox(width: 12),

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
                      device.deviceName,
                      style: const TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        _brainDeviceStatusLabel(device),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Fingerprint: ${device.keyFingerprint}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Último acesso: $lastSeen',
                  style: const TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          if (revoking)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (canRevoke)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _danger,
                side: BorderSide(color: _danger.withValues(alpha: 0.35)),
              ),
              onPressed: () {
                _confirmRevokeBrainDevice(device);
              },
              icon: const Icon(Icons.block_rounded, size: 16),
              label: const Text('Revogar acesso'),
            )
          else if (device.isRevoked)
            const Icon(Icons.block_rounded, color: _danger, size: 20),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Perfil e configurações'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 220, child: _buildNavigation()),

                  const SizedBox(width: 20),

                  Expanded(child: _buildContent()),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          _SettingsNavItem(
            icon: Icons.tune_rounded,
            label: 'Preferências',
            selected: _section == ProfileSettingsSection.preferences,
            onTap: () {
              setState(() {
                _section = ProfileSettingsSection.preferences;
              });
            },
          ),

          const SizedBox(height: 8),

          _SettingsNavItem(
            icon: Icons.shield_outlined,
            label: 'Segurança',
            selected: _section == ProfileSettingsSection.security,
            onTap: () {
              setState(() {
                _section = ProfileSettingsSection.security;
              });
            },
          ),

          const SizedBox(height: 8),

          _SettingsNavItem(
            icon: Icons.psychology_alt_outlined,
            label: 'Cérebro',
            selected: _section == ProfileSettingsSection.brain,
            onTap: () {
              setState(() {
                _section = ProfileSettingsSection.brain;
              });

              _loadBrainSettings();
            },
          ),

          const SizedBox(height: 8),

          _SettingsNavItem(
            icon: Icons.info_outline_rounded,
            label: 'Sobre',
            selected: _section == ProfileSettingsSection.about,
            onTap: () {
              setState(() {
                _section = ProfileSettingsSection.about;
              });
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
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        primary: true,
        padding: const EdgeInsets.only(right: 8, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_message != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _messageIsError
                      ? const Color(0xFFFFECE9)
                      : _surfaceSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _messageIsError
                        ? _danger.withValues(alpha: 0.30)
                        : _border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _messageIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _messageIsError ? _danger : _primaryDark,
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: _messageIsError ? _danger : _text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
            ],

            if (_section == ProfileSettingsSection.preferences)
              _buildPreferences(),

            if (_section == ProfileSettingsSection.security) _buildSecurity(),

            if (_section == ProfileSettingsSection.brain) _buildBrainSettings(),

            if (_section == ProfileSettingsSection.about) _buildAbout(),
          ],
        ),
      ),
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
          onChanged: (value) {
            setState(() {
              _compactMode = value;
            });
          },
        ),

        const Divider(height: 1, color: _border),

        _PreferenceSwitch(
          icon: Icons.animation_outlined,
          title: 'Reduzir animações',
          subtitle: 'Diminui transições e movimentos visuais.',
          value: _reduceMotion,
          onChanged: (value) {
            setState(() {
              _reduceMotion = value;
            });
          },
        ),

        const Divider(height: 1, color: _border),

        _PreferenceSwitch(
          icon: Icons.delete_sweep_outlined,
          title: 'Confirmar antes de apagar',
          subtitle: 'Pede confirmação antes de excluir registros.',
          value: _confirmBeforeDelete,
          onChanged: (value) {
            setState(() {
              _confirmBeforeDelete = value;
            });
          },
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

        const Divider(height: 1, color: _border),

        _SecurityRow(
          icon: Icons.lock_outline_rounded,
          title: 'Senha',
          subtitle: 'Altere sua senha de acesso.',
          trailing: FilledButton.tonalIcon(
            onPressed: _changingPassword ? null : _changePassword,
            icon: _changingPassword
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Alterar'),
          ),
        ),

        const Divider(height: 1, color: _border),

        const _SecurityRow(
          icon: Icons.verified_user_outlined,
          title: 'Sessão',
          subtitle: 'Sua sessão atual está protegida pelo Supabase Auth.',
        ),
      ],
    );
  }

  // ============================================================
  // BRAIN SETTINGS
  // ============================================================

  Widget _buildBrainSettings() {
    return _SettingsPanel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle:
          'Controle onde seus conhecimentos ficam, como são sincronizados e como são protegidos.',
      children: [
        _buildBrainDataModeSection(),

        const Divider(height: 1, color: _border),

        _buildBrainVaultSection(),

        const Divider(height: 1, color: _border),

        _buildBrainDevicesSection(),

        const Divider(height: 1, color: _border),

        _buildBrainBackupSection(),

        const Divider(height: 1, color: _border),

        _buildBrainSecuritySection(),

        const Divider(height: 1, color: _border),

        _buildBrainRecoverySection(),
      ],
    );
  }

  // ============================================================
  // BRAIN DATA MODE
  // ============================================================

  Widget _buildBrainDataModeSection() {
    return Padding(
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
                      'Escolha se o Cérebro fica somente neste dispositivo ou também sincroniza pela nuvem.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _BrainModeOption(
                  icon: Icons.laptop_rounded,
                  title: 'Local',
                  subtitle:
                      'Seus dados permanecem neste dispositivo. Nenhum sync do Cérebro é realizado.',
                  selected: !_brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudMode(false);
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _BrainModeOption(
                  icon: Icons.cloud_done_outlined,
                  title: 'Cloud',
                  subtitle:
                      'Local-first + sincronização E2EE somente entre dispositivos autorizados.',
                  selected: _brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudMode(true);
                  },
                ),
              ),
            ],
          ),

          if (_switchingBrainMode) ...[
            const SizedBox(height: 12),

            const LinearProgressIndicator(minHeight: 2),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN VAULT
  // ============================================================

  Widget _buildBrainVaultSection() {
    final vaultId = _brainVaultId ?? 'Carregando...';

    final keyVersion = _brainKeyVersion?.toString() ?? '-';

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 20,
                color: _primaryDark,
              ),

              const SizedBox(width: 10),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vault',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Identidade e estado criptográfico do seu Cérebro local.',
                      style: TextStyle(color: _muted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Atualizar',
                onPressed: _loadingBrainSettings ? null : _loadBrainSettings,
                icon: _loadingBrainSettings
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _BrainInfoRow(label: 'Vault ID', value: vaultId),

          const SizedBox(height: 8),

          _BrainInfoRow(label: 'Versão da chave', value: keyVersion),

          const SizedBox(height: 8),

          _BrainInfoRow(
            label: 'Master Key',
            value: _brainMasterKeyAvailable
                ? 'Disponível no secure storage'
                : 'Indisponível',
            good: _brainMasterKeyAvailable,
          ),

          const SizedBox(height: 8),

          _BrainInfoRow(
            label: 'Sincronização',
            value: _brainCloudMode ? 'Cloud E2EE' : 'Somente local',
            good: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN BACKUP
  // ============================================================

  Widget _buildBrainBackupSection() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.backup_outlined, size: 20, color: _primaryDark),

          const SizedBox(width: 10),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Backup .evbrain',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Backup portátil criptografado do Vault. O arquivo não contém a Master Key em plaintext.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          OutlinedButton.icon(
            onPressed: () {
              _showBrainBackupPending(importBackup: true);
            },
            icon: const Icon(Icons.file_open_outlined, size: 17),
            label: const Text('Importar'),
          ),

          const SizedBox(width: 8),

          FilledButton.tonalIcon(
            onPressed: () {
              _showBrainBackupPending(importBackup: false);
            },
            icon: const Icon(Icons.download_outlined, size: 17),
            label: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN SECURITY
  // ============================================================

  Widget _buildBrainSecuritySection() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.enhanced_encryption_outlined,
            size: 20,
            color: _primaryDark,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proteção dos dados',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  '• O Vault usa criptografia local.\n'
                  '• A Master Key fica no secure storage do sistema operacional.\n'
                  '• O Supabase recebe somente objetos criptografados do Cérebro.\n'
                  '• Cloud exige conta autenticada, Master Key e dispositivo autorizado.',
                  style: TextStyle(color: _muted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN RECOVERY
  // ============================================================

  Widget _buildBrainRecoverySection() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(Icons.settings_backup_restore_rounded, size: 20, color: _muted),

          SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recovery Device',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 2),
                Text(
                  'Recuperação segura em um novo dispositivo será concluída na Fase 16.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),

          _PhaseBadge(text: 'Fase 16'),
        ],
      ),
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

        const Divider(height: 1, color: _border),

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

        const Divider(height: 1, color: _border),

        _AboutActionRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Política de privacidade',
          subtitle: 'Veja como seus dados são tratados.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) {
                  return const PrivacyPolicyPage();
                },
              ),
            );
          },
        ),

        const Divider(height: 1, color: _border),

        _AboutActionRow(
          icon: Icons.description_outlined,
          title: 'Termos de uso',
          subtitle: 'Consulte os termos de utilização do aplicativo.',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) {
                  return const TermsOfUsePage();
                },
              ),
            );
          },
        ),

        const Divider(height: 1, color: _border),

        _AboutActionRow(
          icon: Icons.article_outlined,
          title: 'Licenças',
          subtitle: 'Bibliotecas e licenças utilizadas pelo aplicativo.',
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: AppInfo.version,
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

  Future<void> _showAboutInfoDialog({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: _border),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primaryDark, size: 20),
              ),

              const SizedBox(width: 10),

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
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              content,
              style: const TextStyle(color: _muted, height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Fechar'),
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

class _AboutHero extends StatelessWidget {
  const _AboutHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _ProfileSettingsPageState._border),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 34,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(width: 18),

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

                SizedBox(height: 4),

                Text(
                  AppInfo.versionLabel,
                  style: TextStyle(
                    color: _ProfileSettingsPageState._primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 12),

                Text(
                  'Sua plataforma de evolução pessoal.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 5),

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

class _AboutActionRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(width: 12),

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

                    const SizedBox(height: 2),

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

              const SizedBox(width: 10),

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

class _SettingsNavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileSettingsPageState._primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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

              const SizedBox(width: 9),

              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? _ProfileSettingsPageState._text
                        : _ProfileSettingsPageState._muted,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
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

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _ProfileSettingsPageState._border),
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
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: _ProfileSettingsPageState._primaryDark,
                ),
              ),

              const SizedBox(width: 12),

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

                    const SizedBox(height: 2),

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

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._surfaceSoft,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: _ProfileSettingsPageState._border),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PREFERENCE SWITCH
// ============================================================

class _PreferenceSwitch extends StatelessWidget {
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

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: _ProfileSettingsPageState._primaryDark,
      activeTrackColor: _ProfileSettingsPageState._primary,
      secondary: Icon(icon, color: _ProfileSettingsPageState._primaryDark),
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
// BRAIN MODE OPTION
// ============================================================

class _BrainModeOption extends StatelessWidget {
  const _BrainModeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool selected;

  final bool enabled;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected
                ? _ProfileSettingsPageState._primary
                : _ProfileSettingsPageState._surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _ProfileSettingsPageState._primaryDark.withValues(
                      alpha: 0.35,
                    )
                  : _ProfileSettingsPageState._border,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected
                    ? _ProfileSettingsPageState._primaryDark
                    : _ProfileSettingsPageState._muted,
                size: 21,
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: _ProfileSettingsPageState._text,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selected
                              ? _ProfileSettingsPageState._primaryDark
                              : _ProfileSettingsPageState._muted,
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 10,
                        height: 1.35,
                      ),
                    ),
                  ],
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
// BRAIN INFO ROW
// ============================================================

class _BrainInfoRow extends StatelessWidget {
  const _BrainInfoRow({
    required this.label,
    required this.value,
    this.good = false,
  });

  final String label;

  final String value;

  final bool good;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(
              color: _ProfileSettingsPageState._muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: good
                  ? _ProfileSettingsPageState._primaryDark
                  : _ProfileSettingsPageState._text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// PHASE BADGE
// ============================================================

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _ProfileSettingsPageState._border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: _ProfileSettingsPageState._muted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ============================================================
// SECURITY ROW
// ============================================================

class _SecurityRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _ProfileSettingsPageState._primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 19,
              color: _ProfileSettingsPageState._primaryDark,
            ),
          ),

          const SizedBox(width: 12),

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

                const SizedBox(height: 2),

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

          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}
